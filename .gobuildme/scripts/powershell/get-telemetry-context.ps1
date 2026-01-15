#!/usr/bin/env pwsh
# Purpose: Get telemetry context for GoBuildMe command instrumentation (v3 - REST API)
# Why: Provides git context, session tracking, timestamps, command IDs, version info, and other metadata for telemetry
# How: Detects git branch/commit, manages session ID, generates timestamps and UUIDs, detects versions, calls REST API
#
# VERSION 3 CHANGES:
# - Uses REST API endpoints instead of MCP tools for telemetry tracking
# - Calls POST /api/v1/commands/start and POST /api/v1/commands/complete
# - Handles all telemetry logic internally (no MCP tool calls needed in .md files)
# - Configurable API endpoint via TELEMETRY_API_URL environment variable
#
# TELEMETRY API ENVIRONMENTS:
# The telemetry API URL can be configured via the TELEMETRY_API_URL environment variable.
#
# Available environments:
#   - Internal (default):   https://ai-cli-telemetry.classy-test.org
#   - Local development:    http://localhost:8080
#
# To change the environment, set TELEMETRY_API_URL before running commands:
#   $env:TELEMETRY_API_URL = "http://localhost:8080"  # Local dev
#
# Default: Internal environment (https://ai-cli-telemetry.classy-test.org)
# - INSERT-UPDATE pattern support (v3.1):
#   * /api/v1/commands/start uses INSERT pattern (creates record with start_timestamp)
#   * /api/v1/commands/complete uses UPDATE pattern (updates record with complete_timestamp)
#   * Handles 409 Conflict (duplicate command_id on INSERT)
#   * Handles 404 Not Found (missing command_id on UPDATE)
#   * Duration computed from timestamps (no duration_ms in payload)
#
# Enhanced Features:
# - Duration calculation between two timestamps (-CommandStartTime)
# - Spec ID extraction from feature directory (-FeatureDir)
# - Spec ID auto-detection from check-prerequisites.sh when -FeatureDir not provided
# - Agent version auto-detection (dynamically queries agent CLI, e.g., auggie --version)
# - Model name auto-detection (reads from settings.json or environment variables)
# - Username auto-detection (from git config, or -Username override, or GIT_USER_NAME env var)
# - Optional command ID generation (-GenerateCommandId, enabled by default)
# - REST API telemetry tracking (-TrackStart and -TrackComplete modes)
# - Quiet mode (-Quiet) to suppress non-essential warnings
#
# Auto-Detection:
# - Spec ID: Automatically detects from check-prerequisites.sh output when -FeatureDir not provided
#   Supports both uppercase FEATURE_DIR (current) and lowercase feature_dir (legacy)
# - Agent Version: Dynamically queries agent CLI (e.g., auggie --version) and extracts version number
#   For Augment Agent: Runs "auggie --version" and extracts version (e.g., "0.7.0" from "0.7.0 (commit 9a05382c)")
#   Priority: AGENT_VERSION env > agent CLI query > default "0.6.1"
# - Model: Detects based on agent name and configuration files
#   Priority: -Model param > MODEL_NAME env > AUGMENT_MODEL env > .augment/settings.json (local) > ~/.augment/settings.json (home) > default
#   For Augment Agent: Reads "model" field from settings.json as-is (no conversion)
#   Example: "haiku4.5" or "claude-haiku-4-5" are reported as-is
# - Username: Detects from git config user.email (preferred), user.name, or whoami
#   Priority: -Username param > GIT_USER_NAME env > git config user.email > git config user.name > whoami
#
# Usage:
#   Basic context: ./get-telemetry-context.ps1 -NoCommandId [-Quiet]
#   Track start (INSERT): ./get-telemetry-context.ps1 -TrackStart -CommandName "gbm.analyze" [-FeatureDir /path] [-Parameters '{"key":"value"}'] [-Quiet]
#   Track complete (UPDATE): ./get-telemetry-context.ps1 -TrackComplete -CommandId UUID -Status success -Results '{"key":"value"}' [-ErrorMessage "error message"] [-Quiet]
#
# INSERT-UPDATE Pattern:
#   - Track start creates a single record with start_timestamp (INSERT)
#   - Track complete updates the same record with complete_timestamp, status, results, error (UPDATE)
#   - Duration is computed from timestamps (no duration_ms in payload)
#   - Returns 409 Conflict if command_id already exists (duplicate INSERT)
#   - Returns 404 Not Found if command_id doesn't exist (UPDATE without INSERT)
#
# Quiet Mode:
#   Use -Quiet to suppress non-essential warnings (e.g., API failures). The script will still output JSON results.
#   Useful for cleaner logs when telemetry failures are expected or acceptable.

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [long]$CommandStartTime = 0,

    [Parameter(Mandatory=$false)]
    [string]$FeatureDir = "",

    [Parameter(Mandatory=$false)]
    [string]$Model = "",

    [Parameter(Mandatory=$false)]
    [string]$Username = "",

    [Parameter(Mandatory=$false)]
    [switch]$GenerateCommandId = $true,

    [Parameter(Mandatory=$false)]
    [switch]$NoCommandId,

    [Parameter(Mandatory=$false)]
    [switch]$TrackStart,

    [Parameter(Mandatory=$false)]
    [switch]$TrackComplete,

    [Parameter(Mandatory=$false)]
    [string]$CommandName = "",

    [Parameter(Mandatory=$false)]
    [string]$CommandId = "",

    [Parameter(Mandatory=$false)]
    [string]$Parameters = "",

    [Parameter(Mandatory=$false)]
    [string]$Status = "",

    [Parameter(Mandatory=$false)]
    [string]$Results = "",

    [Parameter(Mandatory=$false)]
    [string]$ErrorMessage = "",

    [Parameter(Mandatory=$false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# TELEMETRY OPT-OUT CHECK (EARLY EXIT)
# ============================================================================
# Check if telemetry is enabled BEFORE doing any processing
# This ensures zero overhead when telemetry is disabled
# Priority: env var > manifest > default

# Check if TELEMETRY_ENABLED env var is explicitly set
if (Test-Path env:TELEMETRY_ENABLED) {
    # Env var IS set - use it (respects env var > manifest priority)
    $TelemetryEnabled = $env:TELEMETRY_ENABLED.ToLower()
} else {
    # Env var NOT set - check manifest
    $ManifestFile = ".gobuildme/manifest.json"
    if (Test-Path $ManifestFile) {
        try {
            $Manifest = Get-Content $ManifestFile -Raw | ConvertFrom-Json
            if ($Manifest.PSObject.Properties.Name -contains "telemetry") {
                if ($Manifest.telemetry.enabled -eq $false) {
                    $TelemetryEnabled = "false"
                } else {
                    $TelemetryEnabled = "true"
                }
            } else {
                # No telemetry field - default to enabled
                $TelemetryEnabled = "true"
            }
        } catch {
            # Error reading manifest - default to enabled
            $TelemetryEnabled = "true"
        }
    } else {
        # No manifest - default to enabled
        $TelemetryEnabled = "true"
    }
}

# Early exit if telemetry is disabled - NO processing, NO output, NO API calls
if ($TelemetryEnabled -ne "true") {
    # Silent exit - don't even output JSON
    # Commands should handle missing telemetry gracefully
    exit 0
}

# Configuration
$TELEMETRY_API_URL = if ($env:TELEMETRY_API_URL) { $env:TELEMETRY_API_URL } else { "https://ai-cli-telemetry.classy-test.org" }
$TELEMETRY_TIMEOUT = if ($env:TELEMETRY_TIMEOUT) { [int]$env:TELEMETRY_TIMEOUT } else { 5 }

# Handle -NoCommandId flag
if ($NoCommandId) {
    $GenerateCommandId = $false
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Function to call REST API endpoint
function Invoke-TelemetryApi {
    param(
        [string]$Endpoint,
        [string]$Payload
    )

    try {
        # Generate correlation ID
        # X-Correlation-ID: Used for distributed tracing and grouping related commands
        #   Currently generates random UUID per API call
        #   Future: Could use session_id for tracking complete workflows
        $correlationId = [guid]::NewGuid().ToString()

        # Build request parameters
        $headers = @{
            'Content-Type' = 'application/json'
            'X-Correlation-ID' = $correlationId
        }

        $uri = "${TELEMETRY_API_URL}${Endpoint}"

        # Call API with timeout and capture response with status code
        # Use Invoke-WebRequest instead of Invoke-RestMethod to get status code
        $webResponse = Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body $Payload -TimeoutSec $TELEMETRY_TIMEOUT -ErrorAction Stop

        # Parse JSON response
        $response = $webResponse.Content | ConvertFrom-Json

        # Get actual status code
        $actualStatusCode = [int]$webResponse.StatusCode

        # Success - return response as JSON
        # Accept both 200 OK and 201 Created as success
        if ($actualStatusCode -eq 200 -or $actualStatusCode -eq 201) {
            return @{
                status = "success"
                http_code = $actualStatusCode
                response = $response
            } | ConvertTo-Json -Compress
        } else {
            # Unexpected success code
            if (-not $Quiet) {
                Write-Warning "Unexpected HTTP status code: $actualStatusCode"
            }
            return @{
                status = "warning"
                http_code = $actualStatusCode
                response = $response
            } | ConvertTo-Json -Compress
        }

    } catch {
        $statusCode = 0
        $errorDetail = $_.Exception.Message

        # Try to extract HTTP status code
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }

        # Handle specific HTTP status codes
        switch ($statusCode) {
            { $_ -in 301, 302, 303, 307, 308 } {
                # Redirect - treat as error (API should not redirect)
                if (-not $Quiet) {
                    Write-Warning "Telemetry API returned redirect (HTTP ${statusCode}): $Endpoint"
                }
                return @{
                    status = "error"
                    message = "Unexpected redirect (HTTP $statusCode)"
                    http_code = $statusCode
                } | ConvertTo-Json -Compress
            }
            409 {
                # Conflict (duplicate command_id on INSERT)
                if (-not $Quiet) {
                    Write-Warning "Command ID already exists (409 Conflict)"
                }
                return @{
                    status = "conflict"
                    message = "Command ID already exists"
                    http_code = 409
                    detail = $errorDetail
                } | ConvertTo-Json -Compress
            }
            404 {
                # Not Found (missing command_id on UPDATE)
                if (-not $Quiet) {
                    Write-Warning "Command ID not found (404 Not Found)"
                }
                return @{
                    status = "not_found"
                    message = "Command ID not found"
                    http_code = 404
                    detail = $errorDetail
                } | ConvertTo-Json -Compress
            }
            default {
                # Other errors or API unavailable
                if (-not $Quiet) {
                    Write-Warning "Telemetry API call failed (non-blocking): $Endpoint - $errorDetail"
                }
                return @{
                    status = "error"
                    message = if ($statusCode -gt 0) { "HTTP $statusCode" } else { "API unavailable" }
                    http_code = $statusCode
                    detail = $errorDetail
                } | ConvertTo-Json -Compress
            }
        }
    }
}

# Function to detect agent version
function Get-AgentVersion {
    param([string]$AgentName)

    $detectedVersion = ""
    $agentLower = $AgentName.ToLower()

    switch -Regex ($agentLower) {
        'augment' {
            # Augment Agent - use auggie --version command
            if (Get-Command auggie -ErrorAction SilentlyContinue) {
                try {
                    $versionOutput = auggie --version 2>$null
                    # Extract version number (e.g., "0.7.0" from "0.7.0 (commit 9a05382c)")
                    if ($versionOutput -match '^([0-9]+\.[0-9]+\.[0-9]+)') {
                        $detectedVersion = $matches[1]
                    }
                } catch {
                    # Ignore errors
                }
            }
        }
        'copilot' {
            # GitHub Copilot CLI - use gh copilot --version command
            if (Get-Command gh -ErrorAction SilentlyContinue) {
                try {
                    $versionOutput = gh copilot --version 2>$null
                    # Extract version number (e.g., "1.1.1" from "version 1.1.1 (2025-06-17)")
                    if ($versionOutput -match 'version\s+([0-9]+\.[0-9]+\.[0-9]+)') {
                        $detectedVersion = $matches[1]
                    }
                } catch {
                    # Ignore errors
                }
            }
            # Fallback to environment variable
            if (-not $detectedVersion) {
                $detectedVersion = $env:COPILOT_VERSION
            }
        }
        'claude' {
            if (Get-Command claude -ErrorAction SilentlyContinue) {
                try {
                    $detectedVersion = claude --version 2>$null
                } catch {
                    # Ignore errors
                }
            }
        }
        'cursor' {
            # Cursor Editor - use cursor --version command
            if (Get-Command cursor -ErrorAction SilentlyContinue) {
                try {
                    $versionOutput = cursor --version 2>$null
                    # Extract version number (first line)
                    if ($versionOutput -match '^([0-9]+\.[0-9]+\.[0-9]+)') {
                        $detectedVersion = $matches[1]
                    }
                } catch {
                    # Ignore errors
                }
            }
            # Fallback to environment variable
            if (-not $detectedVersion) {
                $detectedVersion = $env:CURSOR_VERSION
            }
        }
        'cline' {
            # Cline (VS Code extension) - use code --list-extensions --show-versions
            if (Get-Command code -ErrorAction SilentlyContinue) {
                try {
                    $extensionInfo = code --list-extensions --show-versions 2>$null | Select-String "saoudrizwan.claude-dev"
                    # Extract version number (e.g., "2.1.0" from "saoudrizwan.claude-dev@2.1.0")
                    if ($extensionInfo -match '@([0-9]+\.[0-9]+\.[0-9]+)') {
                        $detectedVersion = $matches[1]
                    }
                } catch {
                    # Ignore errors
                }
            }
            # Fallback to environment variable
            if (-not $detectedVersion) {
                $detectedVersion = $env:CLINE_VERSION
            }
        }
        'aider' {
            # Aider - use aider --version command
            if (Get-Command aider -ErrorAction SilentlyContinue) {
                try {
                    $versionOutput = (aider --version 2>$null | Select-Object -First 1)
                    # Extract version number (e.g., "0.45.0")
                    if ($versionOutput -match '^aider\s+') {
                        $versionOutput = $versionOutput -replace '^aider\s+', ''
                    }
                    if ($versionOutput -match '^([0-9]+\.[0-9]+\.[0-9]+)') {
                        $detectedVersion = $matches[1]
                    }
                } catch {
                    # Ignore errors
                }
            }
            # Fallback to environment variable
            if (-not $detectedVersion) {
                $detectedVersion = $env:AIDER_VERSION
            }
        }
        'continue' {
            $detectedVersion = $env:CONTINUE_VERSION
        }
    }

    return $detectedVersion
}

# Function to detect model from settings.json
function Get-ModelFromSettings {
    param([string]$AgentName)

    $detectedModel = ""
    $agentLower = $AgentName.ToLower()

    switch -Regex ($agentLower) {
        'augment' {
            # Augment Agent - try to detect from settings.json
            # Priority: AUGMENT_MODEL env > .augment/settings.json (local) > ~/.augment/settings.json (home)

            # Check environment variable first
            if ($env:AUGMENT_MODEL) {
                $detectedModel = $env:AUGMENT_MODEL
            }
            # Check local project settings
            elseif (Test-Path ".augment/settings.json") {
                try {
                    $settings = Get-Content ".augment/settings.json" -Raw | ConvertFrom-Json
                    if ($settings.model) {
                        # Report model as-is (no conversion)
                        $detectedModel = $settings.model
                    }
                } catch {
                    # Ignore JSON parsing errors
                }
            }
            # Check home directory settings
            else {
                $homeDir = if ($env:HOME) { $env:HOME } elseif ($env:USERPROFILE) { $env:USERPROFILE } else { $null }
                if ($homeDir -and (Test-Path "$homeDir/.augment/settings.json")) {
                    try {
                        $settings = Get-Content "$homeDir/.augment/settings.json" -Raw | ConvertFrom-Json
                        if ($settings.model) {
                            # Report model as-is (no conversion)
                            $detectedModel = $settings.model
                        }
                    } catch {
                        # Ignore JSON parsing errors
                    }
                }
            }
        }
    }

    return $detectedModel
}

# Function to detect all context (git, versions, etc.)
function Get-AllContext {
    # Detect username if not provided
    if (-not $script:Username) {
        # Check environment variable
        $script:Username = $env:GIT_USER_NAME

        # Try git config user.email first and extract username (preferred method)
        if (-not $script:Username) {
            try {
                $gitEmail = git config user.email 2>$null
                if ($gitEmail) {
                    # Extract username from email (part before @)
                    $script:Username = $gitEmail.Split('@')[0]
                }
            } catch {
                # Ignore errors
            }
        }

        # If still empty, try git config user.name (fallback to full name)
        if (-not $script:Username) {
            try {
                $script:Username = git config user.name 2>$null
            } catch {
                # Ignore errors
            }
        }

        # If still empty, try whoami
        if (-not $script:Username) {
            try {
                $script:Username = whoami 2>$null
            } catch {
                # Ignore errors
            }
        }
    }

    # Detect git context
    try {
        $script:gitBranch = git rev-parse --abbrev-ref HEAD 2>$null
    } catch {
        $script:gitBranch = $null
    }

    try {
        $script:gitCommit = git rev-parse HEAD 2>$null
    } catch {
        $script:gitCommit = $null
    }

    try {
        $gitRemote = git config --get remote.origin.url 2>$null
        if ($gitRemote) {
            # Handle both SSH and HTTPS URLs
            $script:gitRepo = $gitRemote -replace '^(https?://|git@)', '' -replace '^[^:/]+[:/]', '' -replace '\.git$', ''
        } else {
            $script:gitRepo = $null
        }
    } catch {
        $script:gitRepo = $null
    }

    # Detect GoBuildMe CLI version
    try {
        $gobuildmeVersionRaw = gobuildme --version 2>$null
        if ($gobuildmeVersionRaw -match '(\d+\.\d+\.\d+)') {
            $script:gobuildmeVersion = $matches[1]
        } else {
            $script:gobuildmeVersion = $null
        }
    } catch {
        $script:gobuildmeVersion = $null
    }

    # Detect agent name and version
    $script:agentName = if ($env:AGENT_NAME) { $env:AGENT_NAME } else { "Augment Agent" }
    if (-not $env:AGENT_VERSION) {
        $script:agentVersion = Get-AgentVersion -AgentName $script:agentName
        # Fallback to default if detection failed
        if (-not $script:agentVersion) {
            $script:agentVersion = "0.6.1"
        }
    } else {
        $script:agentVersion = $env:AGENT_VERSION
    }

    # Detect model name
    if (-not $script:Model) {
        $script:Model = Get-ModelFromSettings -AgentName $script:agentName
        # Fallback to default if detection failed
        if (-not $script:Model) {
            $script:Model = "Claude Sonnet 4.5"
        }
    }

    # Extract spec_id from feature directory
    $script:specId = $null
    if ($script:FeatureDir) {
        $script:specId = Split-Path -Leaf $script:FeatureDir
    } else {
        # Auto-detect feature directory if not provided
        # Try to find it from check-prerequisites.sh
        $prereqScript = ".gobuildme/scripts/bash/check-prerequisites.sh"
        if (Test-Path $prereqScript) {
            try {
                $prereqJson = & $prereqScript --json 2>$null | ConvertFrom-Json
                # Try uppercase FEATURE_DIR first (current format), then lowercase (legacy)
                $autoFeatureDir = if ($prereqJson.FEATURE_DIR) { $prereqJson.FEATURE_DIR } else { $prereqJson.feature_dir }
                if ($autoFeatureDir) {
                    $script:FeatureDir = $autoFeatureDir
                    $script:specId = Split-Path -Leaf $script:FeatureDir
                }
            } catch {
                # Ignore errors
            }
        }
    }

    # Get session ID (persistent across commands in same session)
    $homeDir = if ($env:HOME) { $env:HOME } elseif ($env:USERPROFILE) { $env:USERPROFILE } else { $null }
    if ($homeDir) {
        $sessionFile = Join-Path $homeDir ".gobuildme" "session_id"
        if (Test-Path $sessionFile) {
            $script:sessionId = Get-Content $sessionFile -Raw
            $script:sessionId = $script:sessionId.Trim()
        } else {
            try {
                $script:sessionId = [guid]::NewGuid().ToString()
                $sessionDir = Split-Path $sessionFile -Parent
                if (-not (Test-Path $sessionDir)) {
                    New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
                }
                Set-Content -Path $sessionFile -Value $script:sessionId
            } catch {
                $script:sessionId = $null
            }
        }
    } else {
        # No home directory available - generate session ID without persistence
        try {
            $script:sessionId = [guid]::NewGuid().ToString()
        } catch {
            $script:sessionId = $null
        }
    }
}

# ============================================================================
# TRACK START MODE
# ============================================================================

if ($TrackStart) {
    # Validate required parameters
    if (-not $CommandName) {
        Write-Error "Error: -CommandName is required in -TrackStart mode"
        exit 1
    }

    # Generate command ID if not provided
    if (-not $CommandId) {
        try {
            $CommandId = [guid]::NewGuid().ToString()
        } catch {
            Write-Error "Error: Failed to generate command ID"
            exit 1
        }
    }

    # Detect all context
    Get-AllContext

    # Build payload for POST /api/v1/commands/start
    $payload = @{
        command_name = $CommandName
        command_id = $CommandId
    }

    # Add optional fields if they have values
    if ($specId) { $payload.spec_id = $specId }
    if ($agentName) { $payload.agent = $agentName }
    if ($Model) { $payload.model = $Model }
    if ($Username) { $payload.username = $Username }
    if ($agentVersion) { $payload.agent_version = $agentVersion }
    if ($gobuildmeVersion) { $payload.gobuildme_version = $gobuildmeVersion }
    if ($sessionId) { $payload.session_id = $sessionId }
    if ($gitBranch) { $payload.git_branch = $gitBranch }
    if ($gitCommit) { $payload.git_commit_sha = $gitCommit }
    if ($gitRepo) { $payload.git_repo = $gitRepo }

    # Add parameters if provided
    if ($Parameters) {
        try {
            $payload.parameters = $Parameters | ConvertFrom-Json
        } catch {
            Write-Error "Error: -Parameters must be valid JSON"
            exit 1
        }
    }

    # Convert payload to JSON
    $payloadJson = $payload | ConvertTo-Json -Compress

    # Call REST API
    $apiResponse = Invoke-TelemetryApi -Endpoint "/api/v1/commands/start" -Payload $payloadJson

    # Get current timestamp
    try {
        $timestampMs = [int64]([datetime]::UtcNow - [datetime]'1970-01-01').TotalMilliseconds
    } catch {
        $timestampMs = 0
    }

    # Output JSON with command_id for caller to use
    $output = @{
        command_id = $CommandId
        timestamp_ms = $timestampMs
        api_response = $apiResponse | ConvertFrom-Json
    }
    if ($specId) { $output.spec_id = $specId }

    $output | ConvertTo-Json -Compress
    exit 0
}

# ============================================================================
# TRACK COMPLETE MODE
# ============================================================================

if ($TrackComplete) {
    # Validate required parameters
    if (-not $CommandId) {
        Write-Error "Error: -CommandId is required in -TrackComplete mode"
        exit 1
    }
    if (-not $Status) {
        Write-Error "Error: -Status is required in -TrackComplete mode"
        exit 1
    }
    if (-not $Results) {
        Write-Error "Error: -Results is required in -TrackComplete mode"
        exit 1
    }

    # Build payload for POST /api/v1/commands/complete
    $payload = @{
        command_id = $CommandId
        status = $Status
    }

    # Add results
    try {
        $payload.results = $Results | ConvertFrom-Json
    } catch {
        Write-Error "Error: -Results must be valid JSON"
        exit 1
    }

    # Add error if provided
    if ($ErrorMessage) {
        $payload.error = $ErrorMessage
    }

    # Convert payload to JSON
    $payloadJson = $payload | ConvertTo-Json -Compress

    # Call REST API
    $apiResponse = Invoke-TelemetryApi -Endpoint "/api/v1/commands/complete" -Payload $payloadJson

    # Output JSON with response
    $output = @{
        command_id = $CommandId
        status = $Status
        api_response = $apiResponse | ConvertFrom-Json
    }

    $output | ConvertTo-Json -Compress
    exit 0
}

# ============================================================================
# NORMAL CONTEXT MODE (for backward compatibility)
# ============================================================================

# Get current timestamp in milliseconds
try {
    $timestampMs = [int64]([datetime]::UtcNow - [datetime]'1970-01-01').TotalMilliseconds
} catch {
    $timestampMs = $null
}

# Generate a new command ID (UUID v4) for this invocation (if requested)
if ($GenerateCommandId) {
    try {
        $commandIdGenerated = [guid]::NewGuid().ToString()
    } catch {
        $commandIdGenerated = $null
    }
} else {
    $commandIdGenerated = $null
}

# Calculate duration if command start time provided
$durationMs = $null
if ($CommandStartTime -gt 0 -and $timestampMs) {
    $durationMs = $timestampMs - $CommandStartTime
}

# Detect all context
Get-AllContext

# Build JSON object (using field names that match telemetry schema)
$context = [ordered]@{}

if ($timestampMs) { $context.timestamp_ms = $timestampMs }
if ($commandIdGenerated) { $context.command_id = $commandIdGenerated }
if ($durationMs) { $context.duration_ms = $durationMs }
if ($specId) { $context.spec_id = $specId }
if ($agentName) { $context.agent = $agentName }
if ($Model) { $context.model = $Model }
if ($Username) { $context.username = $Username }
if ($agentVersion) { $context.agent_version = $agentVersion }
if ($gobuildmeVersion) { $context.gobuildme_version = $gobuildmeVersion }
if ($sessionId) { $context.session_id = $sessionId }
if ($gitBranch) { $context.git_branch = $gitBranch }
if ($gitCommit) { $context.git_commit_sha = $gitCommit }
if ($gitRepo) { $context.git_repo = $gitRepo }

# Output as JSON
$context | ConvertTo-Json -Compress

exit 0
