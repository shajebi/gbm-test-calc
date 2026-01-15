#!/usr/bin/env pwsh
# Purpose: Common functions for QA commands (architecture integration, etc.)
# Why: Centralizes architecture integration and QA-specific utilities
# How: Provides reusable functions for all QA scripts

# Source the main common.ps1 for repo utilities
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path "$ScriptDir/common.ps1")) {
    Write-Host "Error: common.ps1 not found in $ScriptDir" -ForegroundColor Red
    Write-Host "Please ensure GoBuildMe is properly installed"
    exit 1
}

. "$ScriptDir/common.ps1"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Architecture Integration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Test-AndGenerateArchitecture {
    $archFile = ".gobuildme/docs/technical/architecture/technology-stack.md"

    # Check if architecture docs exist
    if (-not (Test-Path $archFile)) {
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        Write-Host "📐 Architecture documentation not found." -ForegroundColor Cyan
        Write-Host "   Generating architecture for better test generation..."
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        Write-Host ""

        # Run architecture command
        if (Test-Path ".gobuildme/scripts/powershell/analyze-architecture.ps1") {
            $result = & .gobuildme/scripts/powershell/analyze-architecture.ps1
            if ($LASTEXITCODE -ne 0) {
                # Auto-generation failed - show helpful error
                Write-Host ""
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
                Write-Host "❌ Error: Architecture generation failed" -ForegroundColor Red
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
                Write-Host ""
                Write-Host "   QA commands require architecture documentation to:"
                Write-Host "   - Understand your tech stack (language, framework, database)"
                Write-Host "   - Generate appropriate test scaffolds (PHPUnit vs pytest vs Jest)"
                Write-Host "   - Create correct fixture patterns"
                Write-Host "   - Provide accurate test recommendations"
                Write-Host ""
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host "🎯 Action Required: Run /gbm.architecture manually" -ForegroundColor Yellow
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "   This will analyze your codebase and create necessary docs."
                Write-Host "   Then retry the QA command."
                Write-Host ""
                return $false
            }
        } else {
            Write-Host ""
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
            Write-Host "⚠️  Error: Architecture script not found" -ForegroundColor Yellow
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
            Write-Host ""
            Write-Host "   Expected location: .gobuildme/scripts/powershell/analyze-architecture.ps1"
            Write-Host ""
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host "🎯 Action Required: Ensure GoBuildMe is properly installed" -ForegroundColor Yellow
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "   Run: gobuildme init"
            Write-Host ""
            return $false
        }

        Write-Host ""
        Write-Host "✓ Architecture documentation generated" -ForegroundColor Green
        Write-Host ""
        return $true
    }

    # Check if architecture is outdated (>7 days)
    if (Test-Path $archFile) {
        $fileInfo = Get-Item $archFile
        $daysOld = ((Get-Date) - $fileInfo.LastWriteTime).Days

        if ($daysOld -gt 7) {
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            Write-Host "📐 Architecture documentation is $daysOld days old." -ForegroundColor Cyan
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

            # Check if running interactively
            if ([Environment]::UserInteractive) {
                $refresh = Read-Host "   Refresh architecture? [Y/n]"
            } else {
                # Non-interactive (CI/CD) - default to yes
                $refresh = "y"
                Write-Host "   Refresh architecture? [Y/n] y (auto-refresh in CI/CD)"
            }
            Write-Host ""

            if ($refresh -ne "n" -and $refresh -ne "N") {
                Write-Host "Refreshing architecture documentation..."
                Write-Host ""

                if (Test-Path ".gobuildme/scripts/powershell/analyze-architecture.ps1") {
                    & .gobuildme/scripts/powershell/analyze-architecture.ps1
                } else {
                    Write-Host "⚠️  Architecture script not found." -ForegroundColor Yellow
                    return $false
                }

                Write-Host ""
                Write-Host "✓ Architecture documentation refreshed" -ForegroundColor Green
                Write-Host ""
            }
        }
    }

    return $true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Architecture Data Loading
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Get-ArchitectureContext {
    $techStack = ".gobuildme/docs/technical/architecture/technology-stack.md"

    if (-not (Test-Path $techStack)) {
        Write-Host "⚠️  Architecture not found. Using basic detection." -ForegroundColor Yellow
        return $null
    }

    $content = Get-Content $techStack -Raw

    # Extract key information from architecture docs
    $context = @{
        Language = ""
        Framework = ""
        TestFramework = ""
        Database = ""
    }

    if ($content -match "Language:\s*(.+)") {
        $context.Language = $matches[1].Trim()
    }
    if ($content -match "Framework:\s*(.+)") {
        $context.Framework = $matches[1].Trim()
    }
    if ($content -match "Test Framework:\s*(.+)") {
        $context.TestFramework = $matches[1].Trim()
    }
    if ($content -match "Database:\s*(.+)") {
        $context.Database = $matches[1].Trim()
    }

    return $context
}

function Get-IntegrationLandscape {
    $integrationFile = ".gobuildme/docs/technical/architecture/integration-landscape.md"

    if (-not (Test-Path $integrationFile)) {
        return $null
    }

    $content = Get-Content $integrationFile -Raw

    $landscape = @{
        ExternalServices = @()
        ApiType = "REST"
    }

    # Extract external services
    if ($content -match "## External Services([\s\S]*?)(?=##|\z)") {
        $servicesSection = $matches[1]
        $landscape.ExternalServices = $servicesSection -split "`n" |
            Where-Object { $_ -match "^[[:space:]]*-" } |
            ForEach-Object {
                $_ -replace "^[[:space:]]*-[[:space:]]*", "" -replace "\s*\(.*\).*$", ""
            } |
            Where-Object { $_.Trim() -ne "" }
    }

    # Extract API type
    if ($content -match "API.*Type:\s*(.+)") {
        $landscape.ApiType = $matches[1].Trim()
    }

    return $landscape
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Feature Context Loading
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Get-FeatureContext {
    param([string]$Feature = "")

    if ([string]::IsNullOrEmpty($Feature)) {
        $Feature = git rev-parse --abbrev-ref HEAD 2>$null
    }

    # Use Get-FeatureDir for correct path resolution (handles epic--slice)
    $repoRoot = Get-RepoRoot
    $featureDir = Get-FeatureDir -RepoRoot $repoRoot -Branch $Feature

    $context = @{
        Entities = @()
        AcceptanceCriteria = @()
        ArchitectureContext = ""
    }

    # Load data model entities with fallback priority:
    # Priority 1: Feature-specific data-model.md (most detailed, feature-scoped)
    # Priority 2: Global data-architecture.md (comprehensive entity catalog from /gbm.architecture)
    if (Test-Path "$featureDir/data-model.md") {
        $content = Get-Content "$featureDir/data-model.md" -Raw
        $context.Entities = $content -split "`n" |
            Where-Object { $_ -match "^## " } |
            ForEach-Object { $_ -replace "^## ", "" } |
            Where-Object { $_ -ne "Data Model" }
    }
    elseif (Test-Path ".gobuildme/docs/technical/architecture/data-architecture.md") {
        # Fallback to global entity catalog from architecture documentation
        # Extract entities from "## Entity Catalog" section
        $content = Get-Content ".gobuildme/docs/technical/architecture/data-architecture.md" -Raw
        $inEntityCatalog = $false
        $context.Entities = $content -split "`n" | ForEach-Object {
            if ($_ -match "^## Entity Catalog") {
                $inEntityCatalog = $true
            }
            elseif ($_ -match "^## " -and $inEntityCatalog) {
                $inEntityCatalog = $false
            }
            elseif ($inEntityCatalog -and $_ -match "^### ") {
                $_ -replace "^### ", ""
            }
        } | Where-Object { $_ -ne $null -and $_ -ne "" }
    }

    # Load acceptance criteria
    if (Test-Path "$featureDir/spec.md") {
        $content = Get-Content "$featureDir/spec.md" -Raw
        $context.AcceptanceCriteria = $content -split "`n" |
            Where-Object { $_ -match "^[0-9]+\." }
    }

    # Check for feature architecture context
    if (Test-Path "$featureDir/docs/technical/architecture/feature-context.md") {
        $context.ArchitectureContext = "$featureDir/docs/technical/architecture/feature-context.md"
    }

    return $context
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Language Detection
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Get-ProjectLanguage {
    if ((Test-Path "requirements.txt") -or (Test-Path "pyproject.toml")) {
        return "python"
    } elseif (Test-Path "package.json") {
        $content = Get-Content "package.json" -Raw
        if ($content -match "typescript") {
            return "typescript"
        } else {
            return "javascript"
        }
    } elseif (Test-Path "composer.json") {
        return "php"
    } elseif ((Test-Path "pom.xml") -or (Test-Path "build.gradle")) {
        return "java"
    } elseif (Test-Path "go.mod") {
        return "go"
    } elseif (Test-Path "Cargo.toml") {
        return "rust"
    } elseif (Test-Path "Gemfile") {
        return "ruby"
    } elseif (Test-Path "*.csproj") {
        return "csharp"
    } else {
        return "unknown"
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Test Framework Detection (with architecture fallback)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Get-TestFramework {
    # First try architecture
    $archContext = Get-ArchitectureContext
    if ($archContext -and $archContext.TestFramework) {
        return $archContext.TestFramework
    }

    # Fallback to manual detection
    if ((Test-Path "requirements.txt") -or (Test-Path "pyproject.toml")) {
        $hasReq = Test-Path "requirements.txt"
        $hasPyproj = Test-Path "pyproject.toml"

        if (($hasReq -and (Select-String -Path "requirements.txt" -Pattern "pytest" -Quiet)) -or
            ($hasPyproj -and (Select-String -Path "pyproject.toml" -Pattern "pytest" -Quiet))) {
            return "pytest"
        } else {
            return "unittest"
        }
    } elseif (Test-Path "package.json") {
        $content = Get-Content "package.json" -Raw
        if ($content -match "jest") {
            return "jest"
        } elseif ($content -match "vitest") {
            return "vitest"
        } else {
            return "mocha"
        }
    } elseif (Test-Path "composer.json") {
        return "phpunit"
    } elseif ((Test-Path "pom.xml") -or (Test-Path "build.gradle")) {
        return "junit"
    } else {
        return "unknown"
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TODO Scanning
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Find-TestTodos {
    param([string]$TestDir = "tests")

    if (-not (Test-Path $TestDir)) {
        return @()
    }

    # Find all test files with TODO markers
    $files = Get-ChildItem -Path $TestDir -Recurse -Include "*.py","*.js","*.ts","*.php","*.java" |
        Where-Object {
            (Select-String -Path $_.FullName -Pattern "TODO|pytest\.skip|test\.skip|@skip" -Quiet)
        }

    return $files
}

function Get-TodoDetails {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        return @()
    }

    # Extract TODO comments and skip markers with line numbers
    $matches = Select-String -Path $FilePath -Pattern "TODO|pytest\.skip|test\.skip|@skip"
    return $matches
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Persona Loading
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Get-PersonaConfig {
    $personasConfig = ".gobuildme/config/personas.yaml"

    $config = @{
        PersonaId = ""
        PersonaName = ""
        CoverageFloor = ""
        IntegrationCoverageFloor = ""
    }

    # Check if personas config exists
    if (-not (Test-Path $personasConfig)) {
        return $config
    }

    # Try to extract default_persona
    $content = Get-Content $personasConfig -Raw

    if ($content -match "default_persona:\s*(.+)") {
        $personaId = $matches[1].Trim() -replace '"', '' -replace "'", ''

        if ([string]::IsNullOrEmpty($personaId)) {
            return $config
        }

        $config.PersonaId = $personaId
    } else {
        return $config
    }

    # Load persona-specific configuration
    $personaFile = ".gobuildme/personas/$($config.PersonaId).yaml"

    if (-not (Test-Path $personaFile)) {
        Write-Host "⚠️  Persona '$($config.PersonaId)' configured but file not found: $personaFile" -ForegroundColor Yellow
        return $config
    }

    # Extract persona details
    $personaContent = Get-Content $personaFile -Raw

    if ($personaContent -match "name:\s*(.+)") {
        $config.PersonaName = $matches[1].Trim()
    }
    if ($personaContent -match "coverage_floor:\s*(.+)") {
        $config.CoverageFloor = $matches[1].Trim()
    }
    if ($personaContent -match "integration_coverage_floor:\s*(.+)") {
        $config.IntegrationCoverageFloor = $matches[1].Trim()
    }

    return $config
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# QA Configuration Loading
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Get-QaConfig {
    $qaConfig = ".gobuildme/config/qa-config.yaml"

    $config = @{
        GateMode = "advisory"
        CoverageUnit = 85
        CoverageIntegration = 90
        CoverageE2E = 80
        CoverageOverall = 80
        AcTraceabilityMin = 95
        AcManualReview = $true
        TodoMaxPercent = 10
        TodoBlock = $false
    }

    # If no config file, use defaults
    if (-not (Test-Path $qaConfig)) {
        return $config
    }

    # Parse config file
    $content = Get-Content $qaConfig -Raw

    if ($content -match "mode:\s*(.+)") {
        $config.GateMode = $matches[1].Trim() -replace '"', ''
    }
    if ($content -match "unit:\s*(\d+)") {
        $config.CoverageUnit = [int]$matches[1]
    }
    if ($content -match "integration:\s*(\d+)") {
        $config.CoverageIntegration = [int]$matches[1]
    }
    if ($content -match "e2e:\s*(\d+)") {
        $config.CoverageE2E = [int]$matches[1]
    }
    if ($content -match "overall:\s*(\d+)") {
        $config.CoverageOverall = [int]$matches[1]
    }
    if ($content -match "minimum:\s*(\d+)") {
        $config.AcTraceabilityMin = [int]$matches[1]
    }

    return $config
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Coverage Utilities
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Get-CoverageThreshold {
    param([string]$TestType)

    $qaConfig = Get-QaConfig
    $personaConfig = Get-PersonaConfig

    $threshold = 0

    switch ($TestType) {
        "unit" {
            $threshold = $qaConfig.CoverageUnit
        }
        "integration" {
            # Use persona integration floor if set, otherwise use config
            if ($personaConfig.IntegrationCoverageFloor) {
                $threshold = [math]::Round([double]$personaConfig.IntegrationCoverageFloor * 100)
            } else {
                $threshold = $qaConfig.CoverageIntegration
            }
        }
        "e2e" {
            $threshold = $qaConfig.CoverageE2E
        }
        "overall" {
            # Use persona coverage floor if set, otherwise use config
            if ($personaConfig.CoverageFloor) {
                $threshold = [math]::Round([double]$personaConfig.CoverageFloor * 100)
            } else {
                $threshold = $qaConfig.CoverageOverall
            }
        }
        default {
            $threshold = $qaConfig.CoverageOverall
        }
    }

    return $threshold
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Backup and Rollback Utilities
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function New-TestBackup {
    param([string]$Operation)

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $pid = $PID
    $backupDir = ".gobuildme/test-generation-backup/${Operation}_${timestamp}_${pid}"

    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

    $backedUpFiles = @()

    # Backup tests directory if it exists
    if (Test-Path "tests") {
        Copy-Item -Path "tests" -Destination "$backupDir/" -Recurse -ErrorAction SilentlyContinue
        $backedUpFiles += "tests/"
    }

    # Backup root-level test configuration files
    $configFiles = @("conftest.py", "pytest.ini", "jest.config.js", "jest.config.ts",
                     "vitest.config.js", "vitest.config.ts", "phpunit.xml", "pom.xml", "build.gradle")

    foreach ($file in $configFiles) {
        if (Test-Path $file) {
            Copy-Item -Path $file -Destination "$backupDir/" -ErrorAction SilentlyContinue
            $backedUpFiles += $file
        }
    }

    # Backup test scaffolding reports if they exist
    if (Test-Path ".gobuildme/specs/qa-test-scaffolding") {
        New-Item -ItemType Directory -Force -Path "$backupDir/.gobuildme" | Out-Null
        Copy-Item -Path ".gobuildme/specs/qa-test-scaffolding" -Destination "$backupDir/.gobuildme/" -Recurse -ErrorAction SilentlyContinue
        $backedUpFiles += ".gobuildme/specs/qa-test-scaffolding/"
    }

    # Create manifest with backed up files list
    $manifest = @{
        operation = $Operation
        timestamp = $timestamp
        pid = $pid
        backed_up = $backedUpFiles
    } | ConvertTo-Json

    Set-Content -Path "$backupDir/manifest.json" -Value $manifest

    return $backupDir
}

function Restore-TestBackup {
    param([string]$BackupDir)

    if (-not (Test-Path $BackupDir)) {
        Write-Host "✗ Backup not found: $BackupDir" -ForegroundColor Red
        return $false
    }

    # Verify backup integrity
    if (-not (Test-Path "$BackupDir/manifest.json")) {
        Write-Host "⚠️  Backup missing manifest, may be incomplete" -ForegroundColor Yellow
    }

    Write-Host "⚠️  Restoring from backup: $BackupDir" -ForegroundColor Yellow

    # Remove current tests directory
    if (Test-Path "tests") {
        Remove-Item -Path "tests" -Recurse -Force
    }

    # Restore tests from backup
    if (Test-Path "$BackupDir/tests") {
        Copy-Item -Path "$BackupDir/tests" -Destination "." -Recurse
        Write-Host "✓ Restored tests/ directory" -ForegroundColor Green
    }

    # Restore root-level test configuration files
    $configFiles = @("conftest.py", "pytest.ini", "jest.config.js", "jest.config.ts",
                     "vitest.config.js", "vitest.config.ts", "phpunit.xml", "pom.xml", "build.gradle")

    foreach ($file in $configFiles) {
        if (Test-Path "$BackupDir/$file") {
            Copy-Item -Path "$BackupDir/$file" -Destination "."
            Write-Host "✓ Restored $file" -ForegroundColor Green
        }
    }

    # Restore test scaffolding reports
    if (Test-Path "$BackupDir/.gobuildme/specs/qa-test-scaffolding") {
        New-Item -ItemType Directory -Force -Path ".gobuildme" | Out-Null
        Copy-Item -Path "$BackupDir/.gobuildme/specs/qa-test-scaffolding" -Destination ".gobuildme/" -Recurse
        Write-Host "✓ Restored .gobuildme/specs/qa-test-scaffolding/" -ForegroundColor Green
    }

    return $true
}

function Get-LatestBackup {
    $backupBase = ".gobuildme/test-generation-backup"

    if (-not (Test-Path $backupBase)) {
        return ""
    }

    # Find most recent backup
    $latest = Get-ChildItem -Path $backupBase -Directory |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($latest) {
        return $latest.FullName
    }

    return ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Dry-run Utilities
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Test-DryRun {
    return $env:DRY_RUN -eq "true"
}

function Write-DryRunMessage {
    param([string]$Message)

    if (Test-DryRun) {
        Write-Host "[DRY-RUN] $Message" -ForegroundColor Cyan
    }
}

function Invoke-IfNotDryRun {
    param([scriptblock]$ScriptBlock)

    if (Test-DryRun) {
        Write-DryRunMessage "Would execute: $ScriptBlock"
        return $null
    } else {
        return & $ScriptBlock
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Output Formatting
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Write-Section {
    param([string]$Title)

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host $Title
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

# Export functions for use in other scripts
Export-ModuleMember -Function *
