# Validate a feature's slo.yaml against the schema in .gobuildme/templates/config/slo.schema.json
# Usage: .gobuildme/scripts/powershell/slo-lint.ps1 [-Strict] [path-to-slo.yaml]

<#
.SYNOPSIS
    Validate SLO YAML files against schema.

.DESCRIPTION
    Validates a feature's slo.yaml against the schema in .gobuildme/templates/config/slo.schema.json
    Performs basic structure validation of required fields.

.PARAMETER Strict
    Exit with error code if validation fails (default: warnings only)

.PARAMETER SloFile
    Path to slo.yaml file to validate. If not provided, searches for latest in .gobuildme/specs

.EXAMPLE
    .\slo-lint.ps1 -SloFile .gobuildme/specs/my-feature/slo.yaml

.EXAMPLE
    .\slo-lint.ps1 -Strict
#>

[CmdletBinding()]
param(
    [switch]$Strict,
    [string]$SloFile = ""
)

$ErrorActionPreference = "Continue"

function Write-SloInfo {
    param([string]$Message)
    Write-Host "[slo-lint] $Message" -ForegroundColor Cyan
}

function Write-SloError {
    param([string]$Message)
    Write-Host "[slo-lint] $Message" -ForegroundColor Red
}

# Determine repo root
try {
    $RepoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $RepoRoot) {
        $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $RepoRoot = (Resolve-Path "$ScriptDir\..\.." -ErrorAction Stop).Path
    }
} catch {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $RepoRoot = (Resolve-Path "$ScriptDir\..\.." -ErrorAction Stop).Path
}

# Find SLO file if not provided
if (-not $SloFile) {
    $SpecsDir = Join-Path $RepoRoot ".gobuildme\specs"
    if (Test-Path $SpecsDir) {
        $SloFile = Get-ChildItem -Path $SpecsDir -Filter "slo.yaml" -Recurse -Depth 2 -ErrorAction SilentlyContinue | 
                   Select-Object -First 1 -ExpandProperty FullName
    }
}

# Find schema
$Schema = Join-Path $RepoRoot ".gobuildme\templates\config\slo.schema.json"
if (-not (Test-Path $Schema)) {
    $Schema = Join-Path $RepoRoot "templates\config\slo.schema.json"
}

# Validate SLO file exists
if (-not $SloFile -or -not (Test-Path $SloFile)) {
    Write-SloError "No slo.yaml found. Provide path or create one from templates/slo-template.yaml"
    if ($Strict) { exit 1 } else { exit 0 }
}

# Check for required tools
$HasYq = Get-Command yq -ErrorAction SilentlyContinue
$HasPython = Get-Command python -ErrorAction SilentlyContinue
if (-not $HasPython) {
    $HasPython = Get-Command python3 -ErrorAction SilentlyContinue
}

if (-not $HasYq -and -not $HasPython) {
    Write-SloError "Neither yq nor python found. Cannot convert YAML to JSON."
    if ($Strict) { exit 1 } else { exit 0 }
}

# Convert YAML to JSON
try {
    if ($HasYq) {
        $SloJson = yq -o=json $SloFile 2>$null | ConvertFrom-Json
    } else {
        # Use PowerShell's built-in YAML support (PowerShell 7+) or Python fallback
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            # Try using powershell-yaml module if available
            try {
                Import-Module powershell-yaml -ErrorAction Stop
                $SloContent = Get-Content $SloFile -Raw
                $SloJson = ConvertFrom-Yaml $SloContent
            } catch {
                # Fallback to Python
                $PythonCmd = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { "python" }
                $PythonScript = @"
import sys, json, yaml
from pathlib import Path
try:
    data = yaml.safe_load(Path('$SloFile').read_text())
    print(json.dumps(data))
except Exception as e:
    sys.exit(1)
"@
                $JsonOutput = & $PythonCmd -c $PythonScript 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-SloError "Cannot convert YAML to JSON"
                    if ($Strict) { exit 1 } else { exit 0 }
                }
                $SloJson = $JsonOutput | ConvertFrom-Json
            }
        } else {
            # PowerShell 5.x - use Python
            $PythonCmd = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { "python" }
            $PythonScript = @"
import sys, json
try:
    import yaml
except ImportError:
    sys.exit(1)
from pathlib import Path
data = yaml.safe_load(Path('$SloFile').read_text())
print(json.dumps(data))
"@
            $JsonOutput = & $PythonCmd -c $PythonScript 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-SloError "Cannot convert YAML to JSON (PyYAML not installed)"
                if ($Strict) { exit 1 } else { exit 0 }
            }
            $SloJson = $JsonOutput | ConvertFrom-Json
        }
    }
} catch {
    Write-SloError "Failed to parse YAML: $_"
    if ($Strict) { exit 1 } else { exit 0 }
}

# Validate schema exists
if (-not (Test-Path $Schema)) {
    Write-SloError "Schema not found at $Schema; skipping"
    if ($Strict) { exit 1 } else { exit 0 }
}

# Minimal validation (structure checks)
$ValidationErrors = @()

if (-not $SloJson.service) {
    $ValidationErrors += "Missing required field: service"
}

if (-not $SloJson.owner.team) {
    $ValidationErrors += "Missing required field: owner.team"
}

if (-not $SloJson.owner.on_call) {
    $ValidationErrors += "Missing required field: owner.on_call"
}

if (-not $SloJson.slis -or $SloJson.slis.Count -eq 0) {
    $ValidationErrors += "Missing or empty required field: slis"
}

if (-not $SloJson.slos -or $SloJson.slos.Count -eq 0) {
    $ValidationErrors += "Missing or empty required field: slos"
}

if ($ValidationErrors.Count -gt 0) {
    Write-SloError "Validation failed:"
    foreach ($err in $ValidationErrors) {
        Write-SloError "  - $err"
    }
    Write-SloError "Expected: service, owner.team, owner.on_call, slis, slos"
    exit 1
}

Write-SloInfo "OK: $SloFile"
exit 0

