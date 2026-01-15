#!/usr/bin/env pwsh
<#!
.SYNOPSIS
Scaffold OpenTelemetry + Coralogix observability files into a target repo (non-destructive)

.PARAMETER Repo
Target repository path

.PARAMETER WithCI
Install observability CI workflow into .github/workflows if missing

.EXAMPLE
./scaffold-observability.ps1 -Repo C:\src\my-service -WithCI
#>
param(
  [Parameter(Mandatory=$true)][string]$Repo,
  [switch]$WithCI
)

# Resolve script repo root (for templates)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
try {
  $SrcRoot = (git -C $ScriptDir rev-parse --show-toplevel 2>$null)
  if (-not $SrcRoot) { throw }
} catch {
  $SrcRoot = (Resolve-Path (Join-Path $ScriptDir '../../..')).Path
}

# Template paths (prefer packaged .gobuildme/templates, fallback to templates/)
$TplCollector = Join-Path $SrcRoot '.gobuildme/templates/observability/otel-collector.yaml'
if (-not (Test-Path $TplCollector)) { $TplCollector = Join-Path $SrcRoot 'templates/observability/otel-collector.yaml' }
$TplCI = Join-Path $SrcRoot '.gobuildme/templates/github-workflows/observability-ci.yml'
if (-not (Test-Path $TplCI)) { $TplCI = Join-Path $SrcRoot 'templates/github-workflows/observability-ci.yml' }

if (-not (Test-Path $Repo)) { Write-Error "Target repo not found: $Repo"; exit 1 }
if (-not (Test-Path $TplCollector)) { Write-Error "Collector template not found under .gobuildme/templates or templates"; exit 1 }

# Create directory structure
$ObsDir = Join-Path $Repo '.gobuildme/observability'
New-Item -ItemType Directory -Force -Path (Join-Path $ObsDir 'collector') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $ObsDir 'instrumentation') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $ObsDir 'alerts') | Out-Null

# Copy collector template (non-destructive)
$CollectorDst = Join-Path $ObsDir 'collector/otel-collector.yaml'
if (Test-Path $CollectorDst) {
  Write-Host "⚠️  Collector config already exists, skipping: $CollectorDst"
} else {
  Copy-Item -LiteralPath $TplCollector -Destination $CollectorDst -Force
  Write-Host "✓ Created: $CollectorDst"
}

# ENV_VARS.md (create if missing)
$EnvDoc = Join-Path $ObsDir 'ENV_VARS.md'
if (-not (Test-Path $EnvDoc)) {
$envText = @'
# Observability Environment Variables

This document lists environment variables required for OpenTelemetry and Coralogix integration.

## Coralogix (required)
- `CORALOGIX_PRIVATE_KEY` — Coralogix API key (secret, per environment)
- `CORALOGIX_DOMAIN` — US region domain (e.g., `cx498.coralogix.com`)
- `CORALOGIX_APP` — Application name (environment: `production`, `staging`, `dev`, `lab`, `ops`)
- `CORALOGIX_SUBSYSTEM` — Subsystem name (service/domain identifier, lowercase)

## OpenTelemetry (application → Collector)
- `OTEL_EXPORTER_OTLP_ENDPOINT` — Collector endpoint (e.g., `http://otel-collector:4317`)
- `OTEL_RESOURCE_ATTRIBUTES` — Comma-separated attributes:
  - `service.name=<service-name>`
  - `deployment.environment=<env>`
  - `cx.application.name=<app-name>`
  - `cx.subsystem.name=<subsystem-name>`
  - Optional: `service.namespace`, `team`, `owner`, `cost_center`

## PagerDuty (optional)
- `PAGERDUTY_INTEGRATION_KEY_<SERVICE>` — PagerDuty events integration key
- `PAGERDUTY_USER_API_KEY` — For MCP (prefer read-only)
- `PAGERDUTY_API_HOST` — Custom PD API host (if applicable)

## Naming conventions
- **Application** (environment): `production`, `staging`, `dev`, `lab`, `ops` (lowercase)
- **Subsystem** (service/domain): lowercase; no env suffix; RUM subsystem is `cx_rum`

## Examples

### Kubernetes
```yaml
env:
  - name: CORALOGIX_PRIVATE_KEY
    valueFrom:
      secretKeyRef:
        name: coralogix-secrets
        key: private-key
  - name: CORALOGIX_DOMAIN
    value: "cx498.coralogix.com"
  - name: CORALOGIX_APP
    value: "production"
  - name: CORALOGIX_SUBSYSTEM
    value: "payment-processor"
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://otel-collector:4317"
  - name: OTEL_RESOURCE_ATTRIBUTES
    value: "service.name=payment-processor,deployment.environment=production,cx.application.name=production,cx.subsystem.name=payment-processor,team=payments"
```

### ECS Task Definition
```json
{
  "environment": [
    {"name": "CORALOGIX_DOMAIN", "value": "cx498.coralogix.com"},
    {"name": "CORALOGIX_APP", "value": "production"},
    {"name": "CORALOGIX_SUBSYSTEM", "value": "apiv2-svc"},
    {"name": "OTEL_EXPORTER_OTLP_ENDPOINT", "value": "http://localhost:4317"}
  ],
  "secrets": [
    {"name": "CORALOGIX_PRIVATE_KEY", "valueFrom": "arn:aws:secretsmanager:..."}
  ]
}
```

## Security notes
- Never commit secrets to VCS; use a secret store (AWS Secrets Manager, Vault, GitHub Actions secrets)
- Rotate `CORALOGIX_PRIVATE_KEY` regularly; scope access minimally
'@
  Set-Content -LiteralPath $EnvDoc -Value $envText -Encoding utf8
  Write-Host "✓ Created: $EnvDoc"
} else {
  Write-Host "⚠️  Exists, skipping: $EnvDoc"
}

# Instrumentation README
$InstReadme = Join-Path $ObsDir 'instrumentation/README.md'
if (-not (Test-Path $InstReadme)) {
$instText = @'
# Instrumentation Examples

Use the language-specific guidance in docs/coralogix.md.

Covered runtimes:
- Java (auto-instrumentation)
- Node.js (SDK + auto-instrumentations)
- Python (opentelemetry-instrument)
- Go (SDK)
- PHP (extension + SDK)
- NGINX (OTel module)
- AWS Lambda (Coralogix layer)

## Local testing
```powershell
$Env:CORALOGIX_PRIVATE_KEY = 'your-key'
$Env:CORALOGIX_DOMAIN = 'cx498.coralogix.com'
$Env:CORALOGIX_APP = 'dev'
$Env:CORALOGIX_SUBSYSTEM = 'local-test'

otelcol --config .gobuildme/observability/collector/otel-collector.yaml

$Env:OTEL_EXPORTER_OTLP_ENDPOINT = 'http://localhost:4317'
$Env:OTEL_RESOURCE_ATTRIBUTES = 'service.name=my-service,deployment.environment=dev,cx.application.name=dev,cx.subsystem.name=my-service'
# run your app
'@
  Set-Content -LiteralPath $InstReadme -Value $instText -Encoding utf8
  Write-Host "✓ Created: $InstReadme"
} else {
  Write-Host "⚠️  Exists, skipping: $InstReadme"
}

# Alerts README
$AlertsReadme = Join-Path $ObsDir 'alerts/README.md'
if (-not (Test-Path $AlertsReadme)) {
$alertsText = @'
# Alert Definitions (Coralogix → PagerDuty)

## Migration checklist
1) Export priority New Relic alerts
2) Recreate in Coralogix (error rate, 5xx ratio, p95/p99 latency, saturation)
3) Configure PagerDuty integration keys per service
4) Test in staging before production

## PagerDuty mapping
- `page` → P1 severity
- `warn` → P2 severity
- Consider Event Orchestration for dedupe/enrichment

## SLO burn-rate alerts
- Use multi-window policies (e.g., 1h + 6h) where applicable
'@
  Set-Content -LiteralPath $AlertsReadme -Value $alertsText -Encoding utf8
  Write-Host "✓ Created: $AlertsReadme"
} else {
  Write-Host "⚠️  Exists, skipping: $AlertsReadme"
}

# Optional: install CI workflow
if ($WithCI) {
  if (Test-Path $TplCI) {
    $ciDir = Join-Path $Repo '.github/workflows'
    New-Item -ItemType Directory -Force -Path $ciDir | Out-Null
    $ciDst = Join-Path $ciDir 'observability-ci.yml'
    if (Test-Path $ciDst) {
      Write-Host "⚠️  CI workflow already exists, skipping: $ciDst"
    } else {
      Copy-Item -LiteralPath $TplCI -Destination $ciDst -Force
      Write-Host "✓ Installed CI workflow: $ciDst"
    }
  } else {
    Write-Host "⚠️  CI template not found under templates/github-workflows, skipping"
  }
}

# Summary
Write-Host
Write-Host ('' * 0) | Out-Null  # no-op; reserve for future formatting
Write-Host ('
') | Out-Null    # no-op
Write-Host ('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
Write-Host "✓ Observability scaffolding complete for: $Repo"
Write-Host
Write-Host "Next steps:"
Write-Host "  1) Review: $ObsDir/ENV_VARS.md"
Write-Host "  2) Configure: $ObsDir/collector/otel-collector.yaml"
Write-Host "  3) Instrument your application (see docs/coralogix.md)"
Write-Host "  4) Validate: .gobuildme/scripts/powershell/observability-sanity.ps1 -Repo $Repo"

