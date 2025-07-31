function Set-Helix {
    <#
    .SYNOPSIS
        Copies Helix configuration files from the repository to the default Helix config path.
    #>
    Write-LogTitle "Configuring Helix Editor..."

    # Define source and destination paths.
    # Helix's default config directory is typically ~/.config/helix on Windows (which resolves to $env:USERPROFILE\.config\helix)
    $sourceHelixConfigDir = Join-Path $PSScriptRoot '..' 'helix' -Resolve
    $destinationHelixConfigDir = Join-Path $env:APPDATA 'helix'

    # Check if the source directory exists before attempting to copy.
    if (-not (Test-Path -Path $sourceHelixConfigDir -PathType Container)) {
        Write-LogWarning "Source Helix configuration directory not found at '$sourceHelixConfigDir'. Skipping Helix configuration."
        return
    }

    # Ensure the destination directory exists.
    if (-not (Test-Path -Path $destinationHelixConfigDir -PathType Container)) {
        Write-LogInfo "Creating Helix configuration directory: '$destinationHelixConfigDir'"
        try {
            New-Item -ItemType Directory -Path $destinationHelixConfigDir -ErrorAction Stop | Out-Null
        }
        catch {
            Write-LogError "Failed to create Helix configuration directory '$destinationHelixConfigDir': $($_.Exception.Message)"
            return
        }
    }

    Write-LogInfo "Copying Helix configuration files from '$sourceHelixConfigDir' to '$destinationHelixConfigDir'..."
    try {
        # Use -Recurse to copy all files and subdirectories.
        # Use -Force to overwrite existing files in the destination.
        Copy-Item -Path (Join-Path $sourceHelixConfigDir '*') -Destination $destinationHelixConfigDir -Recurse -Force -ErrorAction Stop
        Write-LogInfo "Successfully configured Helix editor."
    }
    catch {
        Write-LogError "Failed to copy Helix configuration files: $($_.Exception.Message)"
    }
}
