function Set-VSCode {
    <#
    .SYNOPSIS
        Copies VS Code configuration files from the repository to the user's default path.
    #>
    Write-LogTitle "Configuring Visual Studio Code..."

    # Define source and destination paths.
    # VS Code's user settings are typically in %APPDATA%\(Code|Code - Insiders)\User
    $sourceVscodeConfigDir = Join-Path $PSScriptRoot '..' 'vscode' -Resolve
    $destinationVscodeConfigDir = Join-Path $env:APPDATA 'Code - Insiders' 'User'

    # Check if the source directory exists before attempting to copy.
    if (-not (Test-Path -Path $sourceVscodeConfigDir -PathType Container)) {
        Write-LogWarning "Source VS Code configuration directory not found at '$sourceVscodeConfigDir'. Skipping VS Code configuration."
        return
    }

    # Ensure the destination directory exists.
    if (-not (Test-Path -Path $destinationVscodeConfigDir -PathType Container)) {
        Write-LogInfo "Creating VS Code configuration directory: '$destinationVscodeConfigDir'"
        try {
            # Use -Force to create parent directories if they don't exist
            New-Item -ItemType Directory -Path $destinationVscodeConfigDir -Force -ErrorAction Stop | Out-Null
        }
        catch {
            Write-LogError "Failed to create VS Code configuration directory '$destinationVscodeConfigDir': $($_.Exception.Message)"
            return
        }
    }

    Write-LogInfo "Copying VS Code configuration files from '$sourceVscodeConfigDir' to '$destinationVscodeConfigDir'..."
    try {        
        # Use -Force to overwrite existing files in the destination.
        Copy-Item -Path (Join-Path $sourceVscodeConfigDir 'settings.json') -Destination $destinationVscodeConfigDir -Force -ErrorAction Stop
        Copy-Item -Path (Join-Path $sourceVscodeConfigDir 'vscode-custom.css') -Destination $HOME -Force -ErrorAction Stop
        Write-LogInfo "Successfully configured Visual Studio Code."
    }
    catch {
        Write-LogError "Failed to copy VS Code configuration files: $($_.Exception.Message)"
    }
}
