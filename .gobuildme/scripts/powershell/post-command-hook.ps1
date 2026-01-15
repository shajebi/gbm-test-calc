# ============================================================================
# post-command-hook.ps1 - Orchestrate post-command actions
# ============================================================================
#
# This script is called after GoBuildMe commands complete. It orchestrates
# all post-command actions with proper separation of concerns:
#   1. Telemetry tracking (if enabled)
#   2. Auto-upload to S3 (if enabled)
#   3. Future hooks can be added here
#
# Usage:
#   post-command-hook.ps1 -Command <name> -Status <success|failure> [OPTIONS]
#
# Parameters:
#   -Command <name>      Command name (e.g., gbm.specify)
#   -Status <status>     Command status (success or failure)
#   -FeatureDir <path>   Path to feature spec directory
#   -CommandId <uuid>    Unique command execution ID
#   -StartTime <ms>      Command start time in milliseconds
#
# Environment Variables:
#   GBM_SKIP_TELEMETRY=true     Skip telemetry for this command
#   GBM_SKIP_AUTO_UPLOAD=true   Skip auto-upload for this command
#
# ============================================================================

param(
    [string]$Command = "",
    [string]$Status = "",
    [string]$FeatureDir = "",
    [string]$CommandId = "",
    [string]$StartTime = "",
    [string]$Results = "",
    [string]$Error = "",
    [switch]$Quiet
)

$ErrorActionPreference = "SilentlyContinue"

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Test-ArtifactGeneratingCommand {
    param([string]$CommandName)
    
    $artifactCommands = @(
        "gbm.request", "gbm.specify", "gbm.clarify", "gbm.plan", "gbm.tasks",
        "gbm.architecture", "gbm.implement", "gbm.tests", "gbm.review"
    )
    
    return $artifactCommands -contains $CommandName
}

function Get-AutoUploadConfig {
    $ManifestFile = ".gobuildme/manifest.json"
    
    $result = @{
        Enabled = $false
        Bucket = "tools-ai-agents-spec-driven-development-gfm"
    }
    
    if (Test-Path $ManifestFile) {
        try {
            $Manifest = Get-Content $ManifestFile -Raw | ConvertFrom-Json
            if ($Manifest.PSObject.Properties.Name -contains "upload_spec") {
                $result.Enabled = $Manifest.upload_spec.auto_upload -eq $true
                if ($Manifest.upload_spec.s3_bucket) {
                    $result.Bucket = $Manifest.upload_spec.s3_bucket
                }
            }
        } catch {
            # Error reading manifest - keep defaults
        }
    }
    
    return $result
}

function Start-AutoUpload {
    param(
        [string]$FeatureDir,
        [string]$Bucket
    )
    
    $UploadScript = Join-Path $ScriptDir "upload-spec.ps1"
    
    if (Test-Path $UploadScript) {
        # Run upload asynchronously as a background job
        $env:GBM_S3_BUCKET = $Bucket
        Start-Job -ScriptBlock {
            param($Script, $Dir)
            & $Script $Dir -Quiet
        } -ArgumentList $UploadScript, $FeatureDir | Out-Null
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# 1. TELEMETRY HOOK
# ----------------------------------------------------------------------------
if ($env:GBM_SKIP_TELEMETRY -ne "true") {
    $TelemetryScript = Join-Path $ScriptDir "get-telemetry-context.ps1"
    if (Test-Path $TelemetryScript) {
        try {
            # Note: get-telemetry-context.ps1 expects specific parameter names:
            #   -CommandName (not -Command)
            #   -CommandStartTime (not -StartTime)
            #   -ErrorMessage (not -Error)
            $telemetryArgs = @()
            $telemetryArgs += "-TrackComplete"
            if ($Command) { $telemetryArgs += "-CommandName"; $telemetryArgs += $Command }
            if ($Status) { $telemetryArgs += "-Status"; $telemetryArgs += $Status }
            if ($CommandId) { $telemetryArgs += "-CommandId"; $telemetryArgs += $CommandId }
            if ($StartTime) { $telemetryArgs += "-CommandStartTime"; $telemetryArgs += $StartTime }
            if ($Results) { $telemetryArgs += "-Results"; $telemetryArgs += $Results }
            if ($Error) { $telemetryArgs += "-ErrorMessage"; $telemetryArgs += $Error }
            if ($Quiet) { $telemetryArgs += "-Quiet" }

            & $TelemetryScript @telemetryArgs 2>$null
        } catch {
            # Suppress telemetry errors
        }
    }
}

# 2. AUTO-UPLOAD HOOK
# ----------------------------------------------------------------------------
if ($env:GBM_SKIP_AUTO_UPLOAD -ne "true" -and $Status -eq "success") {
    $config = Get-AutoUploadConfig
    $autoUploadEnabled = $config.Enabled
    $uploadBucket = $config.Bucket
    
    # Override with environment variable if set
    if ($env:GBM_AUTO_UPLOAD) {
        $autoUploadEnabled = $env:GBM_AUTO_UPLOAD.ToLower() -eq "true"
    }
    
    if ($autoUploadEnabled) {
        if (Test-ArtifactGeneratingCommand -CommandName $Command) {
            if ($FeatureDir -and (Test-Path $FeatureDir -PathType Container)) {
                Start-AutoUpload -FeatureDir $FeatureDir -Bucket $uploadBucket
            }
        }
    }
}

# 3. FUTURE HOOKS CAN BE ADDED HERE
# ----------------------------------------------------------------------------
# Example: notifications, metrics, cleanup, etc.

exit 0

