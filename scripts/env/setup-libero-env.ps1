param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
)

if (-not $env:LIBERO_PROJECT_ROOT) { $env:LIBERO_PROJECT_ROOT = Join-Path $RepoRoot "bsp/libero" }
if (-not $env:LIBERO_DESIGN_SCRIPTS) { $env:LIBERO_DESIGN_SCRIPTS = $env:LIBERO_PROJECT_ROOT }
if (-not $env:HSS_PAYLOAD_GEN) { $env:HSS_PAYLOAD_GEN = Join-Path $RepoRoot "zephyr/zephyr/blobs/payload-generator" }

Write-Host "[Libero/HSS env]"
Write-Host "  LIBERO_PROJECT_ROOT=$($env:LIBERO_PROJECT_ROOT)"
Write-Host "  LIBERO_DESIGN_SCRIPTS=$($env:LIBERO_DESIGN_SCRIPTS)"
Write-Host "  HSS_PAYLOAD_GEN=$($env:HSS_PAYLOAD_GEN)"

if (-not (Get-Command libero -ErrorAction SilentlyContinue) -and -not (Get-Command "libero-socexport" -ErrorAction SilentlyContinue)) {
    Write-Warning "Add the Libero SoC installation directory to PATH before running automation."
}
