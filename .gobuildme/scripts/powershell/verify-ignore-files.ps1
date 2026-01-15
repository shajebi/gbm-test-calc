#!/usr/bin/env pwsh
# verify-ignore-files.ps1 - Verify and create missing ignore files
# This script detects project technology stack and creates appropriate ignore files

$ErrorActionPreference = "Stop"

Write-Host "🔍 Verifying ignore files..." -ForegroundColor Cyan

# Detect project technologies
function Test-NodeJS {
    return (Test-Path "package.json") -or (Test-Path "node_modules")
}

function Test-Python {
    return (Test-Path "requirements.txt") -or (Test-Path "setup.py") -or (Test-Path "pyproject.toml") -or (Test-Path "Pipfile") -or (Get-ChildItem -Filter "*.py" -Recurse -Depth 2 -ErrorAction SilentlyContinue)
}

function Test-Java {
    return (Test-Path "pom.xml") -or (Test-Path "build.gradle") -or (Test-Path "build.gradle.kts") -or (Get-ChildItem -Filter "*.java" -Recurse -Depth 2 -ErrorAction SilentlyContinue)
}

function Test-CSharp {
    return (Get-ChildItem -Filter "*.csproj" -Recurse -Depth 2 -ErrorAction SilentlyContinue) -or (Get-ChildItem -Filter "*.sln" -Recurse -Depth 2 -ErrorAction SilentlyContinue)
}

function Test-Go {
    return (Test-Path "go.mod") -or (Get-ChildItem -Filter "*.go" -Recurse -Depth 2 -ErrorAction SilentlyContinue)
}

function Test-Docker {
    return (Test-Path "Dockerfile") -or (Test-Path "docker-compose.yml") -or (Test-Path "docker-compose.yaml")
}

function Test-Terraform {
    return (Get-ChildItem -Filter "*.tf" -Recurse -Depth 2 -ErrorAction SilentlyContinue)
}

function Test-Helm {
    return (Test-Path "Chart.yaml") -or (Test-Path "charts")
}

# Create .gitignore if missing
function New-GitIgnore {
    if (Test-Path ".gitignore") {
        Write-Host "  ✓ .gitignore exists" -ForegroundColor Green
        return
    }

    Write-Host "  📝 Creating .gitignore..." -ForegroundColor Yellow

    $content = @'
# Operating System Files
.DS_Store
Thumbs.db
*.swp
*.swo
*~

# IDE Files
.vscode/
.idea/
*.iml
.project
.classpath
.settings/

# Environment Files
.env
.env.local
.env.*.local
*.env

# Logs
*.log
logs/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

'@

    # Add Node.js patterns
    if (Test-NodeJS) {
        $content += @'

# Node.js
node_modules/
dist/
build/
.npm
.eslintcache
.yarn/cache
.yarn/unplugged
.yarn/build-state.yml
.yarn/install-state.gz
.pnp.*

'@
    }

    # Add Python patterns
    if (Test-Python) {
        $content += @'

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/
.venv
pip-log.txt
pip-delete-this-directory.txt
.pytest_cache/
.coverage
htmlcov/
*.egg-info/
dist/
build/

'@
    }

    # Add Java patterns
    if (Test-Java) {
        $content += @'

# Java
target/
build/
*.class
.gradle/
.mvn/
*.jar
*.war
*.ear

'@
    }

    # Add C# patterns
    if (Test-CSharp) {
        $content += @'

# C#/.NET
bin/
obj/
*.user
*.suo
*.userprefs
.vs/
packages/
*.nupkg
*.log

'@
    }

    # Add Go patterns
    if (Test-Go) {
        $content += @'

# Go
vendor/
*.exe
*.test
*.out
go.work

'@
    }

    Set-Content -Path ".gitignore" -Value $content -Encoding UTF8
    Write-Host "  ✅ Created .gitignore with appropriate patterns" -ForegroundColor Green
}

# Create .dockerignore if Docker detected
function New-DockerIgnore {
    if (-not (Test-Docker)) {
        return
    }

    if (Test-Path ".dockerignore") {
        Write-Host "  ✓ .dockerignore exists" -ForegroundColor Green
        return
    }

    Write-Host "  📝 Creating .dockerignore..." -ForegroundColor Yellow

    $content = @'
# Git
.git
.gitignore
.gitattributes

# CI/CD
.github/
.gitlab-ci.yml
.travis.yml
.circleci/

# Documentation
README.md
CHANGELOG.md
LICENSE
*.md

# IDE
.vscode/
.idea/
*.iml

# Environment
.env
.env.local
*.env

# Logs
*.log
logs/

'@

    if (Test-NodeJS) {
        $content += @'

# Node.js
node_modules/
npm-debug.log
yarn-error.log
.npm
.yarn/

'@
    }

    if (Test-Python) {
        $content += @'

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
venv/
.venv/
*.egg-info/

'@
    }

    Set-Content -Path ".dockerignore" -Value $content -Encoding UTF8
    Write-Host "  ✅ Created .dockerignore" -ForegroundColor Green
}

# Create .eslintignore if Node.js detected
function New-ESLintIgnore {
    if (-not (Test-NodeJS)) {
        return
    }

    if (Test-Path ".eslintignore") {
        Write-Host "  ✓ .eslintignore exists" -ForegroundColor Green
        return
    }

    # Check for both legacy (.eslintrc*) and flat config (eslint.config.*) formats
    $hasESLintConfig = (Test-Path ".eslintrc.js") -or (Test-Path ".eslintrc.json") -or (Test-Path ".eslintrc.cjs") -or `
                       (Test-Path "eslint.config.js") -or (Test-Path "eslint.config.mjs") -or (Test-Path "eslint.config.cjs")
    if (-not $hasESLintConfig) {
        return
    }

    Write-Host "  📝 Creating .eslintignore..." -ForegroundColor Yellow

    $content = @'
node_modules/
dist/
build/
coverage/
*.min.js
*.bundle.js

'@

    Set-Content -Path ".eslintignore" -Value $content -Encoding UTF8
    Write-Host "  ✅ Created .eslintignore" -ForegroundColor Green
}

# Create .prettierignore if Node.js detected
function New-PrettierIgnore {
    if (-not (Test-NodeJS)) {
        return
    }

    if (Test-Path ".prettierignore") {
        Write-Host "  ✓ .prettierignore exists" -ForegroundColor Green
        return
    }

    if (-not ((Test-Path ".prettierrc") -or (Test-Path ".prettierrc.json") -or (Test-Path "prettier.config.js"))) {
        return
    }

    Write-Host "  📝 Creating .prettierignore..." -ForegroundColor Yellow

    $content = @'
node_modules/
dist/
build/
coverage/
*.min.js
*.bundle.js
package-lock.json
yarn.lock
pnpm-lock.yaml

'@

    Set-Content -Path ".prettierignore" -Value $content -Encoding UTF8
    Write-Host "  ✅ Created .prettierignore" -ForegroundColor Green
}

# Create .npmignore if Node.js package
function New-NpmIgnore {
    if (-not (Test-NodeJS)) {
        return
    }

    if (Test-Path ".npmignore") {
        Write-Host "  ✓ .npmignore exists" -ForegroundColor Green
        return
    }

    # Check if this is a publishable package
    if (Test-Path "package.json") {
        $packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
        if ($packageJson.private -eq $true) {
            return
        }
    } else {
        return
    }

    Write-Host "  📝 Creating .npmignore..." -ForegroundColor Yellow

    $content = @'
# Tests
test/
tests/
*.test.js
*.spec.js
__tests__/
coverage/

# Development
.github/
.vscode/
.idea/
src/
*.ts
tsconfig.json

# Documentation
docs/
*.md
!README.md

# CI/CD
.travis.yml
.gitlab-ci.yml
.circleci/

'@

    Set-Content -Path ".npmignore" -Value $content -Encoding UTF8
    Write-Host "  ✅ Created .npmignore" -ForegroundColor Green
}

# Create .terraformignore if Terraform detected
function New-TerraformIgnore {
    if (-not (Test-Terraform)) {
        return
    }

    if (Test-Path ".terraformignore") {
        Write-Host "  ✓ .terraformignore exists" -ForegroundColor Green
        return
    }

    Write-Host "  📝 Creating .terraformignore..." -ForegroundColor Yellow

    $content = @'
# Git
.git/
.gitignore

# Terraform
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl

# IDE
.vscode/
.idea/

# Documentation
*.md
docs/

'@

    Set-Content -Path ".terraformignore" -Value $content -Encoding UTF8
    Write-Host "  ✅ Created .terraformignore" -ForegroundColor Green
}

# Create .helmignore if Helm detected
function New-HelmIgnore {
    if (-not (Test-Helm)) {
        return
    }

    if (Test-Path ".helmignore") {
        Write-Host "  ✓ .helmignore exists" -ForegroundColor Green
        return
    }

    Write-Host "  📝 Creating .helmignore..." -ForegroundColor Yellow

    $content = @'
# Git
.git/
.gitignore

# CI/CD
.gitlab-ci.yml
.travis.yml
.circleci/

# IDE
.vscode/
.idea/

# Documentation
README.md
NOTES.txt
docs/

'@

    Set-Content -Path ".helmignore" -Value $content -Encoding UTF8
    Write-Host "  ✅ Created .helmignore" -ForegroundColor Green
}

# Main execution
Write-Host ""
Write-Host "Detected technologies:" -ForegroundColor Cyan
if (Test-NodeJS) { Write-Host "  • Node.js/JavaScript" }
if (Test-Python) { Write-Host "  • Python" }
if (Test-Java) { Write-Host "  • Java" }
if (Test-CSharp) { Write-Host "  • C#/.NET" }
if (Test-Go) { Write-Host "  • Go" }
if (Test-Docker) { Write-Host "  • Docker" }
if (Test-Terraform) { Write-Host "  • Terraform" }
if (Test-Helm) { Write-Host "  • Helm" }

Write-Host ""
Write-Host "Verifying ignore files:" -ForegroundColor Cyan

# Create all necessary ignore files
New-GitIgnore
New-DockerIgnore
New-ESLintIgnore
New-PrettierIgnore
New-NpmIgnore
New-TerraformIgnore
New-HelmIgnore

Write-Host ""
Write-Host "✅ Ignore file verification complete" -ForegroundColor Green
