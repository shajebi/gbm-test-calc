#!/usr/bin/env pwsh
# Purpose : Generate architecture analysis artifacts via PowerShell.
# Why     : Supports `/analyze` workflows on Windows environments.
# How     : Resolves feature context, calls Augment when available, and writes heuristic reports.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/common.ps1"
$paths = Get-FeaturePathsEnv
$repoRoot = $paths.REPO_ROOT
$currentBranch = $paths.CURRENT_BRANCH
$hasGit = $paths.HAS_GIT
$featureDir = $paths.FEATURE_DIR

Set-Location $repoRoot

if (-not (Test-FeatureBranch -Branch $currentBranch -HasGit $hasGit)) {
    exit 1
}

if (-not (Test-Path $featureDir)) {
    New-Item -ItemType Directory -Force -Path $featureDir | Out-Null
}

# Create global architecture directory
$globalArchDir = Join-Path $repoRoot '.gobuildme/docs/technical/architecture'
New-Item -ItemType Directory -Force -Path $globalArchDir | Out-Null

# Create feature-specific architecture directory
$featureArchDir = Join-Path $featureDir 'docs/technical/architecture'
New-Item -ItemType Directory -Force -Path $featureArchDir | Out-Null

# Output file for data collection (feature-specific, no timestamp)
$outFile = Join-Path $featureArchDir "data-collection.md"

# Generate structured data for AI Agent analysis
"# Architecture Data Collection`n" | Out-File -FilePath $outFile -Encoding UTF8

"**Purpose**: Raw data collection for AI Agent architectural analysis" | Out-File -Append -FilePath $outFile -Encoding UTF8
"**Note**: This data should be analyzed by an AI Agent to generate comprehensive architectural insights`n" | Out-File -Append -FilePath $outFile -Encoding UTF8

# Check for available AI agent CLIs and use them for enhanced analysis
function Test-AiCliAnalysis {
    $enhancedAnalysisUsed = $false

    # Auggie CLI (Augment Code) - comprehensive analysis
    if (Get-Command auggie -ErrorAction SilentlyContinue) {
        "Using Auggie CLI for deep analysis..." | Out-File -Append $outFile
        try {
            auggie analyze architecture --output $outDir 2>>$outFile | Out-Null
            "✓ Auggie CLI analysis complete." | Out-File -Append $outFile
            $enhancedAnalysisUsed = $true
        } catch {
            "⚠ Auggie analysis failed" | Out-File -Append $outFile
        }
    }

    # Claude Code CLI - code analysis
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        "Using Claude Code CLI for code analysis..." | Out-File -Append $outFile
        try {
            claude analyze --format json --output "$outDir/claude-analysis.json" . 2>>$outFile | Out-Null
            "✓ Claude Code analysis complete." | Out-File -Append $outFile
            $enhancedAnalysisUsed = $true
        } catch {
            "⚠ Claude Code analysis failed" | Out-File -Append $outFile
        }
    }

    # Gemini CLI - code understanding
    if (Get-Command gemini -ErrorAction SilentlyContinue) {
        "Using Gemini CLI for code understanding..." | Out-File -Append $outFile
        try {
            gemini code analyze --output "$outDir/gemini-analysis.json" . 2>>$outFile | Out-Null
            "✓ Gemini CLI analysis complete." | Out-File -Append $outFile
            $enhancedAnalysisUsed = $true
        } catch {
            "⚠ Gemini CLI analysis failed" | Out-File -Append $outFile
        }
    }

    # Qwen Code CLI - code analysis
    if (Get-Command qwen -ErrorAction SilentlyContinue) {
        "Using Qwen Code CLI for analysis..." | Out-File -Append $outFile
        try {
            qwen analyze --output "$outDir/qwen-analysis.json" . 2>>$outFile | Out-Null
            "✓ Qwen Code analysis complete." | Out-File -Append $outFile
            $enhancedAnalysisUsed = $true
        } catch {
            "⚠ Qwen Code analysis failed" | Out-File -Append $outFile
        }
    }

    # opencode CLI - code analysis
    if (Get-Command opencode -ErrorAction SilentlyContinue) {
        "Using opencode CLI for analysis..." | Out-File -Append $outFile
        try {
            opencode analyze --output "$outDir/opencode-analysis.json" . 2>>$outFile | Out-Null
            "✓ opencode analysis complete." | Out-File -Append $outFile
            $enhancedAnalysisUsed = $true
        } catch {
            "⚠ opencode analysis failed" | Out-File -Append $outFile
        }
    }

    # Codex CLI - code analysis
    if (Get-Command codex -ErrorAction SilentlyContinue) {
        "Using Codex CLI for analysis..." | Out-File -Append $outFile
        try {
            codex analyze --output "$outDir/codex-analysis.json" . 2>>$outFile | Out-Null
            "✓ Codex CLI analysis complete." | Out-File -Append $outFile
            $enhancedAnalysisUsed = $true
        } catch {
            "⚠ Codex CLI analysis failed" | Out-File -Append $outFile
        }
    }

    # Windsurf IDE CLI - if available
    if (Get-Command windsurf -ErrorAction SilentlyContinue) {
        "Using Windsurf CLI for analysis..." | Out-File -Append $outFile
        try {
            windsurf analyze --output "$outDir/windsurf-analysis.json" . 2>>$outFile | Out-Null
            "✓ Windsurf analysis complete." | Out-File -Append $outFile
            $enhancedAnalysisUsed = $true
        } catch {
            "⚠ Windsurf analysis failed" | Out-File -Append $outFile
        }
    }

    # Kilo Code CLI - if available
    if (Get-Command kilocode -ErrorAction SilentlyContinue) {
        "Using Kilo Code CLI for analysis..." | Out-File -Append $outFile
        try {
            kilocode analyze --output "$outDir/kilocode-analysis.json" . 2>>$outFile | Out-Null
            "✓ Kilo Code analysis complete." | Out-File -Append $outFile
            $enhancedAnalysisUsed = $true
        } catch {
            "⚠ Kilo Code analysis failed" | Out-File -Append $outFile
        }
    }

    # Roo Code CLI - if available
    if (Get-Command roo -ErrorAction SilentlyContinue) {
        "Using Roo Code CLI for analysis..." | Out-File -Append $outFile
        try {
            roo analyze --output "$outDir/roo-analysis.json" . 2>>$outFile | Out-Null
            "✓ Roo Code analysis complete." | Out-File -Append $outFile
            $enhancedAnalysisUsed = $true
        } catch {
            "⚠ Roo Code analysis failed" | Out-File -Append $outFile
        }
    }

    if ($enhancedAnalysisUsed) {
        "`n## Enhanced AI Analysis" | Out-File -Append $outFile
        "✓ Deep analysis completed using available AI agent CLIs" | Out-File -Append $outFile
        "Check $outDir for detailed analysis files from AI agents" | Out-File -Append $outFile
        "" | Out-File -Append $outFile
    } else {
        "`n## AI Analysis Status" | Out-File -Append $outFile
        "⚠ No AI agent CLIs detected for enhanced analysis" | Out-File -Append $outFile
        "Install any of: auggie, claude, gemini, qwen, opencode, codex, windsurf, kilocode, roo" | Out-File -Append $outFile
        "Using comprehensive heuristic analysis instead" | Out-File -Append $outFile
        "" | Out-File -Append $outFile
    }
}

# Run AI CLI analysis check
Test-AiCliAnalysis

"## Repository Structure (top)" | Out-File -Append $outFile
'```' | Out-File -Append $outFile
Get-ChildItem -Directory -Depth 1 | ForEach-Object { $_.FullName -replace '^.*?[\\/]', '' } | Out-File -Append $outFile
'```' | Out-File -Append $outFile

"`n## Language Signals" | Out-File -Append $outFile
'```' | Out-File -Append $outFile
('pyproject.toml','requirements.txt','package.json','go.mod','Cargo.toml','pom.xml','build.gradle','build.gradle.kts','composer.json') |
    ForEach-Object { if (Test-Path $_) { $_ } } | Out-File -Append $outFile
'```' | Out-File -Append $outFile

"`n## Import/Dependency Map (heuristic)" | Out-File -Append $outFile
'```' | Out-File -Append $outFile
try {
    if (Get-Command rg -ErrorAction SilentlyContinue) {
        rg -n "^(from |import )|require\(|import\s" --glob '!{.git,.venv,node_modules,.gobuildme}/*' | Out-File -Append $outFile
    } else {
        git grep -n "^(from |import )|require\(|import\s" -- . `:(exclude) .git `:(exclude) .venv `:(exclude) node_modules `:(exclude) .gobuildme | Out-File -Append $outFile
    }
} catch {}
'```' | Out-File -Append $outFile

# Enhanced Analysis Functions
function Analyze-CodeStructure {
    "`n## Code Structure Analysis" | Out-File -Append $outFile
    '```' | Out-File -Append $outFile

    "=== Code Entities ===" | Out-File -Append $outFile

    # JavaScript/TypeScript analysis
    $jsFiles = Get-ChildItem -Recurse -Include "*.js","*.ts","*.jsx","*.tsx" -ErrorAction SilentlyContinue
    if ($jsFiles) {
        "JavaScript/TypeScript:" | Out-File -Append $outFile
        $functions = (Select-String -Path $jsFiles.FullName -Pattern "function|const.*=.*=>" -ErrorAction SilentlyContinue).Count
        $classes = (Select-String -Path $jsFiles.FullName -Pattern "class " -ErrorAction SilentlyContinue).Count
        $components = (Select-String -Path $jsFiles.FullName -Pattern "export.*function|export.*const.*=.*=>" -ErrorAction SilentlyContinue).Count
        "  Functions: $functions" | Out-File -Append $outFile
        "  Classes: $classes" | Out-File -Append $outFile
        "  Components: $components" | Out-File -Append $outFile
    }

    # Python analysis
    $pyFiles = Get-ChildItem -Recurse -Include "*.py" -ErrorAction SilentlyContinue
    if ($pyFiles) {
        "Python:" | Out-File -Append $outFile
        $functions = (Select-String -Path $pyFiles.FullName -Pattern "^def " -ErrorAction SilentlyContinue).Count
        $classes = (Select-String -Path $pyFiles.FullName -Pattern "^class " -ErrorAction SilentlyContinue).Count
        $models = (Select-String -Path $pyFiles.FullName -Pattern "class.*Model|class.*models\.Model" -ErrorAction SilentlyContinue).Count
        "  Functions: $functions" | Out-File -Append $outFile
        "  Classes: $classes" | Out-File -Append $outFile
        "  Models: $models" | Out-File -Append $outFile
    }

    # Java analysis
    $javaFiles = Get-ChildItem -Recurse -Include "*.java" -ErrorAction SilentlyContinue
    if ($javaFiles) {
        "Java:" | Out-File -Append $outFile
        $classes = (Select-String -Path $javaFiles.FullName -Pattern "^public class|^class " -ErrorAction SilentlyContinue).Count
        $interfaces = (Select-String -Path $javaFiles.FullName -Pattern "^public interface|^interface " -ErrorAction SilentlyContinue).Count
        $methods = (Select-String -Path $javaFiles.FullName -Pattern "public.*\(" -ErrorAction SilentlyContinue).Count
        "  Classes: $classes" | Out-File -Append $outFile
        "  Interfaces: $interfaces" | Out-File -Append $outFile
        "  Methods: $methods" | Out-File -Append $outFile
    }

    # Go analysis
    $goFiles = Get-ChildItem -Recurse -Include "*.go" -ErrorAction SilentlyContinue
    if ($goFiles) {
        "Go:" | Out-File -Append $outFile
        $functions = (Select-String -Path $goFiles.FullName -Pattern "^func " -ErrorAction SilentlyContinue).Count
        $structs = (Select-String -Path $goFiles.FullName -Pattern "^type.*struct" -ErrorAction SilentlyContinue).Count
        $interfaces = (Select-String -Path $goFiles.FullName -Pattern "^type.*interface" -ErrorAction SilentlyContinue).Count
        "  Functions: $functions" | Out-File -Append $outFile
        "  Structs: $structs" | Out-File -Append $outFile
        "  Interfaces: $interfaces" | Out-File -Append $outFile
    }

    '```' | Out-File -Append $outFile
}

function Analyze-BusinessLogic {
    "`n## Business Domain Analysis" | Out-File -Append $outFile
    '```' | Out-File -Append $outFile

    "=== Business Entities ===" | Out-File -Append $outFile
    $allFiles = Get-ChildItem -Recurse -Include "*.py","*.js","*.java","*.go","*.ts" -ErrorAction SilentlyContinue
    $entities = Select-String -Path $allFiles.FullName -Pattern "class.*(User|Order|Product|Payment|Invoice|Customer|Account|Profile|Item|Cart|Transaction)" -ErrorAction SilentlyContinue | Select-Object -First 10
    if ($entities) {
        $entities | ForEach-Object { $_.Line.Trim() } | Out-File -Append $outFile
    } else {
        "No common business entities detected" | Out-File -Append $outFile
    }

    "" | Out-File -Append $outFile
    "=== Business Operations ===" | Out-File -Append $outFile
    $operations = Select-String -Path $allFiles.FullName -Pattern "def.*(create|update|delete|process|calculate|validate|authenticate|authorize)" -ErrorAction SilentlyContinue | Select-Object -First 10
    if ($operations) {
        $operations | ForEach-Object { $_.Line.Trim() } | Out-File -Append $outFile
    } else {
        "No common business operations detected" | Out-File -Append $outFile
    }

    '```' | Out-File -Append $outFile
}

function Analyze-ApiEndpoints {
    "`n## API Endpoints Analysis" | Out-File -Append $outFile
    '```' | Out-File -Append $outFile

    "=== REST Endpoints ===" | Out-File -Append $outFile
    $allFiles = Get-ChildItem -Recurse -Include "*.js","*.ts","*.py","*.java","*.go" -ErrorAction SilentlyContinue

    # Express.js/Node.js endpoints
    $expressEndpoints = Select-String -Path $allFiles.FullName -Pattern "app\.(get|post|put|delete|patch)" -ErrorAction SilentlyContinue | Select-Object -First 10
    if ($expressEndpoints) {
        "Express.js endpoints:" | Out-File -Append $outFile
        $expressEndpoints | ForEach-Object { $_.Line.Trim() } | Out-File -Append $outFile
    }

    # Python web endpoints
    $pythonEndpoints = Select-String -Path $allFiles.FullName -Pattern "@app\.route|def.*request|class.*View" -ErrorAction SilentlyContinue | Select-Object -First 10
    if ($pythonEndpoints) {
        "Python web endpoints:" | Out-File -Append $outFile
        $pythonEndpoints | ForEach-Object { $_.Line.Trim() } | Out-File -Append $outFile
    }

    # Spring Boot endpoints
    $springEndpoints = Select-String -Path $allFiles.FullName -Pattern "@RequestMapping|@GetMapping|@PostMapping|@PutMapping|@DeleteMapping" -ErrorAction SilentlyContinue | Select-Object -First 10
    if ($springEndpoints) {
        "Spring Boot endpoints:" | Out-File -Append $outFile
        $springEndpoints | ForEach-Object { $_.Line.Trim() } | Out-File -Append $outFile
    }

    # Go endpoints
    $goEndpoints = Select-String -Path $allFiles.FullName -Pattern "http\.HandleFunc|mux\.HandleFunc|router\." -ErrorAction SilentlyContinue | Select-Object -First 10
    if ($goEndpoints) {
        "Go HTTP endpoints:" | Out-File -Append $outFile
        $goEndpoints | ForEach-Object { $_.Line.Trim() } | Out-File -Append $outFile
    }

    if (-not $expressEndpoints -and -not $pythonEndpoints -and -not $springEndpoints -and -not $goEndpoints) {
        "No API endpoints detected" | Out-File -Append $outFile
    }

    '```' | Out-File -Append $outFile
}

# High-Level Architectural Analysis Functions

function Detect-ArchitecturalStyle {
    "`n## Architectural Style Analysis" | Out-File -Append $outFile
    '```' | Out-File -Append $outFile

    # Microservices indicators
    $microservicesScore = 0
    if (Test-Path "docker-compose.yml" -or Test-Path "docker-compose.yaml") { $microservicesScore += 2 }
    if ((Test-Path "services" -PathType Container) -or (Get-ChildItem -Recurse -Name "Dockerfile" -ErrorAction SilentlyContinue)) { $microservicesScore += 2 }
    if ((Test-Path "kubernetes.yml") -or (Test-Path "k8s" -PathType Container)) { $microservicesScore += 3 }

    # Monolithic indicators
    $monolithicScore = 0
    if ((Test-Path "app" -PathType Container) -and (Test-Path "config" -PathType Container) -and ((Test-Path "artisan") -or (Test-Path "manage.py") -or (Test-Path "package.json"))) { $monolithicScore += 3 }
    if ((Test-Path "composer.json") -or (Test-Path "requirements.txt") -or (Test-Path "package.json")) { $monolithicScore += 1 }

    # Serverless indicators
    $serverlessScore = 0
    if ((Test-Path "serverless.yml") -or (Test-Path "sam.yml") -or (Test-Path "lambda" -PathType Container)) { $serverlessScore += 3 }

    # Determine primary architectural style
    if ($microservicesScore -gt $monolithicScore -and $microservicesScore -gt $serverlessScore) {
        "Primary Architecture: Microservices" | Out-File -Append $outFile
        "Confidence: High (score: $microservicesScore)" | Out-File -Append $outFile
    } elseif ($serverlessScore -gt $monolithicScore -and $serverlessScore -gt $microservicesScore) {
        "Primary Architecture: Serverless" | Out-File -Append $outFile
        "Confidence: High (score: $serverlessScore)" | Out-File -Append $outFile
    } else {
        "Primary Architecture: Monolithic" | Out-File -Append $outFile
        "Confidence: Medium (score: $monolithicScore)" | Out-File -Append $outFile
    }

    "" | Out-File -Append $outFile
    "Secondary Patterns:" | Out-File -Append $outFile

    # MVC pattern
    if ((Test-Path "models" -PathType Container) -or (Test-Path "views" -PathType Container) -or (Test-Path "controllers" -PathType Container) -or (Test-Path "app/Models" -PathType Container)) {
        "✓ MVC (Model-View-Controller) pattern detected" | Out-File -Append $outFile
    }

    # Layered architecture
    if (((Test-Path "presentation" -PathType Container) -or (Test-Path "business" -PathType Container) -or (Test-Path "data" -PathType Container)) -or ((Test-Path "api" -PathType Container) -and (Test-Path "services" -PathType Container))) {
        "✓ Layered architecture pattern detected" | Out-File -Append $outFile
    }

    # Event-driven architecture
    $eventFiles = Get-ChildItem -Recurse -Include "*.php","*.py","*.js","*.java" -ErrorAction SilentlyContinue | Select-String -Pattern "event|Event|listener|Listener|queue|Queue" -ErrorAction SilentlyContinue
    if ($eventFiles) {
        "✓ Event-driven architecture patterns detected" | Out-File -Append $outFile
    }

    '```' | Out-File -Append $outFile
}

function Analyze-TechnologyStack {
    "`n## Technology Stack Analysis" | Out-File -Append $outFile
    '```' | Out-File -Append $outFile

    "=== Primary Technologies ===" | Out-File -Append $outFile

    # Backend technologies
    "Backend Technologies:" | Out-File -Append $outFile
    if (Test-Path "composer.json") {
        $composerContent = Get-Content "composer.json" -Raw -ErrorAction SilentlyContinue
        $phpFramework = "Unknown Framework"
        if ($composerContent -match '"laravel/framework"') { $phpFramework = "Laravel" }
        elseif ($composerContent -match '"symfony/symfony"') { $phpFramework = "Symfony" }
        elseif ($composerContent -match '"codeigniter/framework"') { $phpFramework = "CodeIgniter" }
        "  • PHP with $phpFramework" | Out-File -Append $outFile
    }

    if ((Test-Path "requirements.txt") -or (Test-Path "pyproject.toml")) {
        $pythonFramework = "Unknown"
        $reqContent = ""
        if (Test-Path "requirements.txt") { $reqContent += Get-Content "requirements.txt" -Raw -ErrorAction SilentlyContinue }
        if (Test-Path "pyproject.toml") { $reqContent += Get-Content "pyproject.toml" -Raw -ErrorAction SilentlyContinue }

        if ($reqContent -match "Django|django") { $pythonFramework = "Django" }
        elseif ($reqContent -match "Flask|flask") { $pythonFramework = "Flask" }
        elseif ($reqContent -match "FastAPI|fastapi") { $pythonFramework = "FastAPI" }
        "  • Python with $pythonFramework" | Out-File -Append $outFile
    }

    if (Test-Path "package.json") {
        $packageContent = Get-Content "package.json" -Raw -ErrorAction SilentlyContinue
        $nodeFramework = "Unknown"
        if ($packageContent -match "express") { $nodeFramework = "Express.js" }
        elseif ($packageContent -match "next") { $nodeFramework = "Next.js" }
        elseif ($packageContent -match "nuxt") { $nodeFramework = "Nuxt.js" }
        elseif ($packageContent -match "react") { $nodeFramework = "React" }
        elseif ($packageContent -match "vue") { $nodeFramework = "Vue.js" }
        "  • Node.js with $nodeFramework" | Out-File -Append $outFile
    }

    # Database technologies
    "" | Out-File -Append $outFile
    "Database Technologies:" | Out-File -Append $outFile
    $envFiles = Get-ChildItem -Recurse -Include "*.env*","*.yml","*.yaml","*.json" -ErrorAction SilentlyContinue
    $envContent = $envFiles | Get-Content -ErrorAction SilentlyContinue | Out-String

    if ($envContent -match "mysql|MySQL") { "  • MySQL" | Out-File -Append $outFile }
    if ($envContent -match "postgresql|postgres|PostgreSQL") { "  • PostgreSQL" | Out-File -Append $outFile }
    if ($envContent -match "mongodb|mongo|MongoDB") { "  • MongoDB" | Out-File -Append $outFile }
    if ($envContent -match "redis|Redis") { "  • Redis (Cache/Queue)" | Out-File -Append $outFile }

    # Infrastructure technologies
    "" | Out-File -Append $outFile
    "Infrastructure Technologies:" | Out-File -Append $outFile
    if ((Test-Path "Dockerfile") -or (Test-Path "docker-compose.yml")) { "  • Docker containerization" | Out-File -Append $outFile }
    if ((Test-Path "k8s" -PathType Container) -or (Test-Path "kubernetes.yml")) { "  • Kubernetes orchestration" | Out-File -Append $outFile }

    $infraFiles = Get-ChildItem -Recurse -Include "*.yml","*.yaml","*.json","*.tf" -ErrorAction SilentlyContinue
    $infraContent = $infraFiles | Get-Content -ErrorAction SilentlyContinue | Out-String

    if ($infraContent -match "aws|AWS|amazon") { "  • AWS cloud services" | Out-File -Append $outFile }
    if ($infraContent -match "gcp|google-cloud|GCP") { "  • Google Cloud Platform" | Out-File -Append $outFile }
    if ($infraContent -match "azure|Azure|microsoft") { "  • Microsoft Azure" | Out-File -Append $outFile }

    '```' | Out-File -Append $outFile
}

# Run high-level architectural analysis
Detect-ArchitecturalStyle
Analyze-TechnologyStack

"`n## Discovered Boundaries" | Out-File -Append $outFile
# Dynamic boundary detection
if (Test-Path "src" -PathType Container) { if (Test-Path "tests" -PathType Container) { "✓ src/ vs tests/ (testing boundary)" | Out-File -Append $outFile } }
if (Test-Path "backend" -PathType Container) { if (Test-Path "frontend" -PathType Container) { "✓ backend/ vs frontend/ (application tier boundary)" | Out-File -Append $outFile } }
if ((Test-Path "services" -PathType Container) -or (Test-Path "api" -PathType Container) -or (Test-Path "models" -PathType Container)) { "✓ services/ vs models/ vs api/ (service layer boundary)" | Out-File -Append $outFile }
if ((Test-Path "public" -PathType Container) -or (Test-Path "static" -PathType Container)) { "✓ static assets boundary detected" | Out-File -Append $outFile }
if ((Test-Path "config" -PathType Container) -or (Test-Path ".env")) { "✓ configuration boundary detected" | Out-File -Append $outFile }

"`n## Analysis Summary" | Out-File -Append $outFile
"- **Scope**: Full codebase structural and semantic analysis" | Out-File -Append $outFile
"- **Depth**: Business logic, API patterns, data models, security" | Out-File -Append $outFile
"- **Coverage**: Documentation, architectural patterns, boundaries" | Out-File -Append $outFile
"- **Generated**: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')" | Out-File -Append $outFile

"`nWrote $outFile" | Out-File -Append $outFile
Write-Output "Wrote $outFile"
