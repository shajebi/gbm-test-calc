#!/usr/bin/env pwsh
# fact-check.ps1 - Extract fact-checking context from project
# This script outputs JSON with paths needed for fact-checking workflow

param(
    [switch]$Json,
    [string]$FeatureDir,
    [string]$SourceFile,
    [string]$PersonaId
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Get-Item "$ScriptDir/../..").FullName

# Determine feature directory
$ActualFeatureDir = ""
if ($FeatureDir) {
    $ActualFeatureDir = $FeatureDir
} else {
    $SpecsDir = Join-Path $ProjectRoot ".gobuildme/specs"
    if (Test-Path $SpecsDir) {
        $ActualFeatureDir = Get-ChildItem -Path $SpecsDir -Directory -ErrorAction SilentlyContinue |
                           Sort-Object LastWriteTime -Descending |
                           Select-Object -First 1 -ExpandProperty FullName
        if (-not $ActualFeatureDir) {
            $ActualFeatureDir = ""
        }
    }
}

# Determine source file
$ActualSourceFile = ""
if ($SourceFile) {
    $ActualSourceFile = $SourceFile
} elseif ($ActualFeatureDir) {
    $CommonFiles = @("research.md", "architecture.md", "prd.md", "security-audit.md", "test-plan.md")
    foreach ($file in $CommonFiles) {
        $filePath = Join-Path $ActualFeatureDir $file
        if (Test-Path $filePath) {
            $ActualSourceFile = $filePath
            break
        }
    }
}

# Determine persona ID
$ActualPersonaId = ""
if ($PersonaId) {
    $ActualPersonaId = $PersonaId
} else {
    $PersonasYaml = Join-Path $ProjectRoot ".gobuildme/config/personas.yaml"
    if (Test-Path $PersonasYaml) {
        $content = Get-Content $PersonasYaml -Raw -ErrorAction SilentlyContinue
        if ($content -match 'default_persona:\s*"?([^"\s]+)"?') {
            $ActualPersonaId = $Matches[1]
        }
    }
}

# Constitution path
$ConstitutionPath = Join-Path $ProjectRoot ".gobuildme/memory/constitution.md"

# Output
if ($Json) {
    $output = @{
        feature_dir = $ActualFeatureDir
        source_file = $ActualSourceFile
        persona_id = $ActualPersonaId
        constitution_path = $ConstitutionPath
        project_root = $ProjectRoot
    } | ConvertTo-Json -Compress
    Write-Output $output
} else {
    Write-Output "FEATURE_DIR=$ActualFeatureDir"
    Write-Output "SOURCE_FILE=$ActualSourceFile"
    Write-Output "PERSONA_ID=$ActualPersonaId"
    Write-Output "CONSTITUTION_PATH=$ConstitutionPath"
    Write-Output "PROJECT_ROOT=$ProjectRoot"
}
