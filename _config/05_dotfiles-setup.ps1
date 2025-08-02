. (Join-Path $PSScriptRoot '05_01_windowsterminal.ps1')
. (Join-Path $PSScriptRoot '05_02_ohmyposh.ps1')
. (Join-Path $PSScriptRoot '05_03_powershell.ps1')
. (Join-Path $PSScriptRoot '05_04_helix.ps1')
. (Join-Path $PSScriptRoot '05_05_vscode.ps1')
. (Join-Path $PSScriptRoot '05_06_git.ps1')
. (Join-Path $PSScriptRoot '05_07_wallpapers.ps1')
. (Join-Path $PSScriptRoot '05_08_cursors.ps1')
. (Join-Path $PSScriptRoot '05_09_nerdfonts.ps1')
. (Join-Path $PSScriptRoot '05_10_powertoys.ps1')

# ---------------------------------------------------------------------------- #
#                                     MAIN                                     #
# ---------------------------------------------------------------------------- #

Set-WindowsTerminal
Set-OhMyPosh
Set-PowerShell
Set-Helix
Set-VSCode
Set-Git
Set-Wallpapers
Set-Cursors
Install-NerdFonts
Backup-PowerToysSettings