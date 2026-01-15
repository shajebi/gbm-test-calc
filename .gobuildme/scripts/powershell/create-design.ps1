#!/usr/bin/env pwsh
# Purpose : Bootstrap design documents for a feature using PowerShell.
# Why     : Ensures design intent lives beside specs regardless of shell preference.
# How     : Resolves the feature directory, copies the design template, and reports the output path.

[CmdletBinding()]
param([string]$Feature)
$ErrorActionPreference = 'Stop'

try { $repoRoot = (git rev-parse --show-toplevel) } catch { $repoRoot = (Get-Location).Path }
Set-Location $repoRoot

$branch = try { git rev-parse --abbrev-ref HEAD } catch { 'feature' }
$slug = ($Feature; if (-not $Feature) { $branch }) -join ''
$slug = $slug.ToLower() -replace '[^a-z0-9]','-' -replace '-{2,}','-' -replace '^-','' -replace '-$',''

$dir = Join-Path 'specs' $slug
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$file = Join-Path $dir 'design.md'

$tpl = 'templates/design-template.md'
if (Test-Path $tpl) { Copy-Item $tpl $file -Force } else { '# Design Document' | Set-Content -Path $file -Encoding UTF8 }
Write-Host "DESIGN: $file"

