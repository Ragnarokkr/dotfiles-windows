function Set-PowerShell {
    <#
    .SYNOPSIS
        Copies the PowerShell profile from the repository to the default user profile path.
    #>
    Write-LogTitle "Configuring PowerShell Profile..."

    # Define source and destination paths.
    # The default PowerShell profile path is usually $PROFILE.CurrentUserAllHosts
    $sourceProfile = Join-Path $PSScriptRoot '..' 'powershell' 'profile.ps1' -Resolve
    $destinationProfileDir = Split-Path -Path $PROFILE.CurrentUserAllHosts -Parent
    $destinationProfile = $PROFILE.CurrentUserAllHosts

    # Check if the source file exists before attempting to copy.
    if (-not (Test-Path -Path $sourceProfile -PathType Leaf)) {
        Write-LogWarning "Source PowerShell profile not found at '$sourceProfile'. Skipping PowerShell profile configuration."
        return
    }

    # Ensure the destination directory exists.
    if (-not (Test-Path -Path $destinationProfileDir -PathType Container)) {
        Write-LogInfo "Creating PowerShell profile directory: '$destinationProfileDir'"
        try {
            New-Item -ItemType Directory -Path $destinationProfileDir -ErrorAction Stop | Out-Null
        }
        catch {
            Write-LogError "Failed to create PowerShell profile directory '$destinationProfileDir': $($_.Exception.Message)"
            return
        }
    }

    Write-LogInfo "Copying PowerShell profile to '$destinationProfile'..."
    try {
        # Use -Force to overwrite an existing profile in the destination.
        Copy-Item -Path $sourceProfile -Destination $destinationProfile -Force -ErrorAction Stop
        Write-LogInfo "Successfully configured PowerShell profile."
    }
    catch {
        Write-LogError "Failed to copy PowerShell profile: $($_.Exception.Message)"
    }
}