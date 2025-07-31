# Imports required scripts
. (Join-Path $PSScriptRoot '_config' '01_common.ps1')
. (Join-Path $PSScriptRoot '_config' '02_env-check.ps1')
. (Join-Path $PSScriptRoot '_config' '03_install-packages.ps1')
. (Join-Path $PSScriptRoot '_config' '04_install-programs.ps1')
. (Join-Path $PSScriptRoot '_config' '05_dotfiles-setup.ps1')

Write-LogInfo "DONE! Restart your system for changes to take effect."