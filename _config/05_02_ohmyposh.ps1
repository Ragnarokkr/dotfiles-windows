function Set-OhMyPosh {
    <#
    .SYNOPSIS
        Copies custom Oh My Posh themes from the repository to the user's Oh My Posh themes directory.
    #>
    Write-LogTitle "Configuring Oh My Posh..."

    # Define source and destination paths.
    # The source is expected to be a directory named 'oh-my-posh' at the root of the repository.
    $sourceOmpConfigDir = Join-Path $PSScriptRoot '..' 'oh-my-posh' -Resolve
    # Oh My Posh's default themes directory for current user is typically %LOCALAPPDATA%\oh-my-posh\themes
    $destinationOmpThemesDir = Join-Path $env:LOCALAPPDATA 'oh-my-posh' 'themes'

    # Check if the source directory exists before attempting to copy.
    if (-not (Test-Path -Path $sourceOmpConfigDir -PathType Container)) {
        Write-LogWarning "Source Oh My Posh configuration directory not found at '$sourceOmpConfigDir'."
        Write-LogWarning "Skipping Oh My Posh theme configuration. Create an 'oh-my-posh' directory in the repo root with your '*.omp.json' themes."
        return
    }

    # Ensure the destination directory exists.
    if (-not (Test-Path -Path $destinationOmpThemesDir -PathType Container)) {
        Write-LogInfo "Creating Oh My Posh themes directory: '$destinationOmpThemesDir'"
        try {
            # Use -Force to create parent directories if they don't exist.
            New-Item -ItemType Directory -Path $destinationOmpThemesDir -Force -ErrorAction Stop | Out-Null
        }
        catch {
            Write-LogError "Failed to create Oh My Posh themes directory '$destinationOmpThemesDir': $($_.Exception.Message)"
            return
        }
    }

    Write-LogInfo "Copying Oh My Posh themes from '$sourceOmpConfigDir' to '$destinationOmpThemesDir'..."
    try {
        # Use -Force to overwrite existing files in the destination. We only copy .omp.json files.
        $themeFiles = Get-ChildItem -Path $sourceOmpConfigDir -Filter '*.omp.json' -ErrorAction SilentlyContinue
        if ($themeFiles.Count -eq 0) {
            Write-LogWarning "No '*.omp.json' theme files found in '$sourceOmpConfigDir'. Nothing to copy."
            return
        }

        Copy-Item -Path $themeFiles.FullName -Destination $destinationOmpThemesDir -Force -ErrorAction Stop
        Write-LogInfo "Successfully copied $($themeFiles.Count) Oh My Posh theme(s)."
        Write-LogNote "Remember to update your PowerShell profile to use one of the copied themes."
    }
    catch {
        Write-LogError "Failed to copy Oh My Posh configuration files: $($_.Exception.Message)"
    }
}