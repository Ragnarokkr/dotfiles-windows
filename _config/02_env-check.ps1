Write-LogTitle "Performing Environment & Prerequisite Checks"

# --- Administrator Check ---
# This script requires administrative privileges to install software.
Write-LogInfo "Checking for administrator privileges..."
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-LogError "Administrator privileges are required to run this script."
    Write-LogError "Please re-run the script in an elevated PowerShell session (Run as Administrator)."
    return 
}
else {
    Write-LogInfo "Administrator privileges confirmed."
}

# --- Required Programs Check ---
$programsToCheck = @(
    "winget"    
)

Write-LogInfo "Checking for required programs like 'winget'..."
$installationStatus = Test-InstalledProgram -Name $programsToCheck

$installationStatus | ForEach-Object {
    if ($_.IsInstalled) {
        Write-LogInfo "Found '$($_.Name)' (Version: $($_.Version))"
    }
    else {
        Write-LogError "Could not find '$($_.Query)'. This is a required program and may need to be installed manually."
    }
}
