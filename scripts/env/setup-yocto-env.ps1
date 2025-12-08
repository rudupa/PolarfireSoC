param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
)

$TemplateConf = Join-Path $RepoRoot "yocto/conf/templates"
$env:TEMPLATECONF = $TemplateConf
if (-not $env:MACHINE) { $env:MACHINE = "mpfs-disco-kit" }
if (-not $env:DISTRO) { $env:DISTRO = "polarfire-amp" }

Write-Host "[Yocto AMP env]"
Write-Host "  TEMPLATECONF=$TemplateConf"
Write-Host "  MACHINE=$($env:MACHINE)"
Write-Host "  DISTRO=$($env:DISTRO)"
