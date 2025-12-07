param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
)

if (-not $env:ZEPHYR_WORKSPACE) { $env:ZEPHYR_WORKSPACE = Join-Path $RepoRoot "zephyr" }
if (-not $env:ZEPHYR_BASE) { $env:ZEPHYR_BASE = Join-Path $env:ZEPHYR_WORKSPACE "zephyr" }
if (-not $env:WEST_CONFIG) { $env:WEST_CONFIG = Join-Path $env:ZEPHYR_WORKSPACE "west.yml" }

Write-Host "[Zephyr AMP env]"
Write-Host "  ZEPHYR_WORKSPACE=$($env:ZEPHYR_WORKSPACE)"
Write-Host "  ZEPHYR_BASE=$($env:ZEPHYR_BASE)"
Write-Host "  WEST_CONFIG=$($env:WEST_CONFIG)"

if (-not (Test-Path (Join-Path $env:ZEPHYR_WORKSPACE ".west"))) {
    Write-Warning "Run 'cd $($env:ZEPHYR_WORKSPACE); west init -l .; west update' to bootstrap the workspace."
}
