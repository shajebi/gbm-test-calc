#!/usr/bin/env pwsh
# Purpose: Upload specification files to S3 with presigned URLs (PowerShell)
# Why: Enables centralized spec storage and analysis across projects on Windows
# How: Generates presigned URLs, uploads files in parallel, handles errors gracefully
#
# Usage:
#   .\upload-spec.ps1                    # Auto-detect current spec directory
#   .\upload-spec.ps1 C:\path\to\spec    # Upload specific spec directory
#   .\upload-spec.ps1 -DryRun            # Validate without uploading
#   .\upload-spec.ps1 -Help              # Show help
#
# Requirements:
#   - Python 3.8+ with boto3 and requests libraries
#   - AWS credentials configured (via ~/.aws/credentials, SSO, or environment)
#   - S3 bucket write permissions
#
# Configuration (priority: env vars > config file > defaults):
#   Config file: .gobuildme/config.yaml
#     upload_spec:
#       s3_bucket: "my-custom-bucket"
#       url_expiration: 7200
#
# Environment Variables:
#   GBM_S3_BUCKET    - Override S3 bucket (highest priority)
#   AWS_PROFILE      - AWS profile to use for credentials
#   AWS_REGION       - AWS region (default: us-west-2)

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$SpecDir = "",

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [switch]$Verbose,

    [Parameter()]
    [switch]$Quiet,

    [Parameter()]
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Get script directory and load common functions
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir/common.ps1"
$RepoRoot = Get-RepoRoot

# Choose Python interpreter (prefer active virtualenv, allow override)
if ($env:GBM_PYTHON) {
    $PythonBin = $env:GBM_PYTHON
} elseif ($env:VIRTUAL_ENV -and (Test-Path (Join-Path $env:VIRTUAL_ENV "Scripts/python.exe"))) {
    $PythonBin = Join-Path $env:VIRTUAL_ENV "Scripts/python.exe"
} elseif ($env:VIRTUAL_ENV -and (Test-Path (Join-Path $env:VIRTUAL_ENV "bin/python"))) {
    $PythonBin = Join-Path $env:VIRTUAL_ENV "bin/python"
} elseif (Test-Path (Join-Path $RepoRoot ".venv/Scripts/python.exe")) {
    $PythonBin = Join-Path $RepoRoot ".venv/Scripts/python.exe"
} elseif (Test-Path (Join-Path $RepoRoot ".venv/bin/python")) {
    $PythonBin = Join-Path $RepoRoot ".venv/bin/python"
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    $PythonBin = "python3"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $PythonBin = "python"
} else {
    Write-Error "[upload-spec] Python 3 is required but not found."
    exit 1
}

# Default configuration
$DefaultS3Bucket = "tools-ai-agents-spec-driven-development-gfm"
$ConfigFilePath = ".gobuildme/config.yaml"

# Function to read config value from .gobuildme/config.yaml
# Uses powershell-yaml if available, falls back to Python, or returns $null
function Read-ConfigValue {
    param([string]$Key)

    $ConfigFile = $null

    # Find config file (check current dir and repo root)
    if (Test-Path $ConfigFilePath) {
        $ConfigFile = $ConfigFilePath
    } elseif (Test-Path (Join-Path $RepoRoot $ConfigFilePath)) {
        $ConfigFile = Join-Path $RepoRoot $ConfigFilePath
    } else {
        # Config file not found
        return $null
    }

    # Try PowerShell ConvertFrom-Yaml (from powershell-yaml module) first
    try {
        if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
            $content = Get-Content -Path $ConfigFile -Raw
            $config = $content | ConvertFrom-Yaml
            if ($config -and $config.upload_spec -and $config.upload_spec.$Key) {
                return $config.upload_spec.$Key
            }
        }
    } catch {
        # ConvertFrom-Yaml failed, try fallback
    }

    # Fallback to Python (usually available)
    try {
        $pythonResult = & $PythonBin -c @"
import sys
try:
    import yaml
    with open('$ConfigFile', 'r') as f:
        config = yaml.safe_load(f)
    if config and 'upload_spec' in config and '$Key' in config['upload_spec']:
        print(config['upload_spec']['$Key'])
except:
    pass
"@ 2>$null

        if ($LASTEXITCODE -eq 0 -and $pythonResult) {
            return $pythonResult.Trim()
        }

        # Fallback: regex-based parsing (last resort)
        $pythonResult = & $PythonBin -c @"
import re
try:
    with open('$ConfigFile', 'r') as f:
        content = f.read()
    match = re.search(r'upload_spec:.*?$Key:\s*[\"\'']?([^\"\'\n#]+)', content, re.DOTALL)
    if match:
        print(match.group(1).strip().strip('\"').strip(\"'\"))
except:
    pass
"@ 2>$null

        if ($LASTEXITCODE -eq 0 -and $pythonResult) {
            return $pythonResult.Trim()
        }
    } catch {
        # Python fallback failed
    }

    return $null
}

# Get S3 bucket with priority: env var > config file > default
function Get-S3Bucket {
    # Priority 1: Environment variable
    if ($env:GBM_S3_BUCKET) {
        return $env:GBM_S3_BUCKET
    }

    # Priority 2: Config file
    $configValue = Read-ConfigValue -Key "s3_bucket"
    if ($configValue) {
        return $configValue
    }

    # Priority 3: Default
    return $DefaultS3Bucket
}

# Configuration (priority: env var > config file > default)
$S3Bucket = Get-S3Bucket

# Python scripts paths (in .gobuildme/scripts/ for target projects)
$GenerateUrlsScript = Join-Path $ScriptDir "../generate-spec-presigned-urls.py"
$UploadScript = Join-Path $ScriptDir "../upload-presigned-urls.py"
$PresignedUrlsJson = Join-Path $ScriptDir "../presigned_urls_output.json"

# Helper functions
function Write-Info {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[upload-spec] " -ForegroundColor Green -NoNewline
        Write-Host $Message
    }
}

function Write-Debug-Message {
    param([string]$Message)
    if ($Verbose -and -not $Quiet) {
        Write-Host "[upload-spec] " -ForegroundColor Blue -NoNewline
        Write-Host $Message
    }
}

function Write-Warn {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[upload-spec] " -ForegroundColor Yellow -NoNewline
        Write-Host $Message
    }
}

function Write-Err {
    param([string]$Message)
    # Errors always show, even in quiet mode
    Write-Host "[upload-spec] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Cleanup {
    if (Test-Path $PresignedUrlsJson) {
        Remove-Item -Force $PresignedUrlsJson -ErrorAction SilentlyContinue
    }
}

function Show-Help {
    @"
Upload specification files to S3 for centralized storage and analysis.

Usage:
    .\upload-spec.ps1 [OPTIONS] [SPEC_DIR]

Arguments:
    SPEC_DIR            Path to spec directory (auto-detected if not provided)

Options:
    -DryRun             Validate credentials and list files without uploading
    -Verbose            Show detailed progress information
    -Quiet              Suppress all output except errors
    -Help               Show this help message

Examples:
    # Upload current feature spec (auto-detect from git branch)
    .\upload-spec.ps1

    # Upload specific spec directory
    .\upload-spec.ps1 .gobuildme\specs\AT-201

    # Validate without uploading
    .\upload-spec.ps1 -DryRun

    # Verbose output
    .\upload-spec.ps1 -Verbose .gobuildme\specs\my-feature

Requirements:
    - Python 3.8+ with boto3 and requests libraries
      Install: pip install boto3 requests
    - AWS credentials configured:
      - ~/.aws/credentials file
      - AWS SSO: aws sso login --profile <profile>
      - Environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
    - S3 bucket write permissions

Configuration:
    Settings can be configured via environment variables or .gobuildme/config.yaml.
    Priority order: environment variables > config file > defaults

    Config file format (.gobuildme/config.yaml):
        upload_spec:
          s3_bucket: "my-custom-bucket"
          url_expiration: 7200  # 2 hours in seconds

Environment Variables:
    GBM_S3_BUCKET    Override default S3 bucket (highest priority)
    AWS_PROFILE      AWS profile to use
    AWS_REGION       AWS region (default: us-west-2)

Exit Codes:
    0 - Success (all files uploaded)
    1 - Failure (validation failed or no files uploaded)
    2 - Partial success (some files uploaded, some failed)

Troubleshooting:
    AWS SSO expired:     aws sso login --profile <your-profile>
    Missing boto3:       pip install boto3 requests
    Permission denied:   Check IAM policy for s3:PutObject permission
"@
}

# Register cleanup handler
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Cleanup } -ErrorAction SilentlyContinue

# Show help if requested
if ($Help) {
    Show-Help
    exit 0
}

# Step 0: Validate prerequisites
Write-Debug-Message "Checking prerequisites..."

# Check Python 3 is available
try {
    $null = & $PythonBin --version 2>&1
} catch {
    Write-Err "Python 3 is required but not found. Please install Python 3.8+."
    exit 1
}

# Check required Python packages
try {
    & $PythonBin -c "import boto3" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Python package 'boto3' is required. Install with: pip install boto3"
        exit 1
    }
} catch {
    Write-Err "Python package 'boto3' is required. Install with: pip install boto3"
    exit 1
}

try {
    & $PythonBin -c "import requests" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Python package 'requests' is required. Install with: pip install requests"
        exit 1
    }
} catch {
    Write-Err "Python package 'requests' is required. Install with: pip install requests"
    exit 1
}

# Check Python scripts exist
if (-not (Test-Path $GenerateUrlsScript)) {
    Write-Err "Generate URLs script not found: $GenerateUrlsScript"
    exit 1
}

if (-not (Test-Path $UploadScript)) {
    Write-Err "Upload script not found: $UploadScript"
    exit 1
}

# Auto-detect spec directory if not provided using common.ps1 functions
if ([string]::IsNullOrEmpty($SpecDir)) {
    Write-Info "Auto-detecting spec directory from current branch..."

    $paths = Get-FeaturePathsEnv
    $SpecDir = $paths.FEATURE_DIR

    if ([string]::IsNullOrEmpty($SpecDir)) {
        Write-Err "Could not auto-detect spec directory. Please provide path as argument."
        exit 1
    }
}

# Validate spec directory
if (-not (Test-Path $SpecDir -PathType Container)) {
    Write-Err "Spec directory does not exist: $SpecDir"
    exit 1
}

$SpecDir = (Resolve-Path $SpecDir).Path  # Get absolute path
$SpecName = Split-Path -Leaf $SpecDir

# Check spec directory has files
$fileCount = (Get-ChildItem -Path $SpecDir -File -Recurse | Measure-Object).Count
if ($fileCount -eq 0) {
    Write-Warn "Spec directory is empty: $SpecDir"
    exit 0
}

Write-Info "Uploading spec directory: $SpecDir"
Write-Info "Spec name: $SpecName"
Write-Info "Files found: $fileCount"
Write-Debug-Message "S3 bucket: $S3Bucket"

# Step 1: Validate AWS credentials and connectivity (dry-run)
Write-Info "Validating AWS credentials and S3 access..."
try {
    if ($Quiet) {
        $result = & $PythonBin $GenerateUrlsScript $SpecDir --dry-run 2>&1 | Out-Null
    } else {
        $result = & $PythonBin $GenerateUrlsScript $SpecDir --dry-run 2>&1
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Err "AWS validation failed. Check credentials and S3 bucket access."
        Cleanup
        exit 1
    }
} catch {
    Write-Err "AWS validation failed: $_"
    Cleanup
    exit 1
}

Write-Info "AWS validation successful ✓"

# If dry-run mode, exit here
if ($DryRun) {
    Write-Info "Dry-run mode: validation passed, no files uploaded"
    Write-Info "Would upload $fileCount files to s3://$S3Bucket/spec-repository/$SpecName/"
    exit 0
}

# Step 2: Generate presigned URLs
Write-Info "Generating presigned URLs for spec files..."
$verboseFlag = if ($Verbose) { "--debug" } else { "" }
try {
    if ($Quiet) {
        $result = & $PythonBin $GenerateUrlsScript $SpecDir $verboseFlag 2>&1 | Out-Null
    } elseif ($Verbose) {
        $result = & $PythonBin $GenerateUrlsScript $SpecDir --debug 2>&1 | Out-Null
    } else {
        $result = & $PythonBin $GenerateUrlsScript $SpecDir 2>&1 | Out-Null
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to generate presigned URLs"
        Cleanup
        exit 1
    }
} catch {
    Write-Err "Failed to generate presigned URLs: $_"
    Cleanup
    exit 1
}

# Count files from JSON
try {
    $urlsData = Get-Content $PresignedUrlsJson | ConvertFrom-Json
    $totalFiles = ($urlsData.PSObject.Properties | Measure-Object).Count
    Write-Info "Generated presigned URLs for $totalFiles files ✓"
} catch {
    Write-Warn "Could not count files from JSON"
}

# Step 3: Upload files to S3
Write-Info "Uploading files to S3..."
$uploadExitCode = 0
try {
    if ($Quiet) {
        & $PythonBin $UploadScript $PresignedUrlsJson --spec-dir $SpecDir $verboseFlag 2>&1 | Out-Null
        $uploadExitCode = $LASTEXITCODE
    } elseif ($Verbose) {
        & $PythonBin $UploadScript $PresignedUrlsJson --spec-dir $SpecDir --debug
        $uploadExitCode = $LASTEXITCODE
    } else {
        & $PythonBin $UploadScript $PresignedUrlsJson --spec-dir $SpecDir
        $uploadExitCode = $LASTEXITCODE
    }
} catch {
    $uploadExitCode = 1
}

# Step 4: Report results and exit with appropriate code
Cleanup

if ($uploadExitCode -eq 0) {
    Write-Info "✅ All files uploaded successfully"
    Write-Info "S3 location: s3://$S3Bucket/spec-repository/$SpecName/"
    exit 0
} elseif ($uploadExitCode -eq 2) {
    Write-Warn "⚠️  Partial success - some files were skipped"
    Write-Warn "S3 location: s3://$S3Bucket/spec-repository/$SpecName/"
    exit 2
} else {
    Write-Err "❌ Upload failed"
    exit 1
}

