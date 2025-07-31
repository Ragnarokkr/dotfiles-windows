function Set-Wallpapers {
    <#
    .SYNOPSIS
        Copies wallpaper files and configures Windows to use them as a cycling desktop background.
    #>
    Write-LogTitle "Configuring Wallpapers..."

    # Define source and destination paths.
    $sourceWallpapersDir = Join-Path $PSScriptRoot '..' 'wallpapers' -Resolve
    $destinationWallpapersDir = Join-Path $HOME 'Pictures\Wallpapers'

    # Check if the source directory exists before attempting to copy.
    if (-not (Test-Path -Path $sourceWallpapersDir -PathType Container)) {
        Write-LogWarning "Source wallpapers directory not found at '$sourceWallpapersDir'. Skipping wallpaper configuration."
        return
    }

    # Ensure the destination directory exists.
    if (-not (Test-Path -Path $destinationWallpapersDir -PathType Container)) {
        Write-LogInfo "Creating wallpapers directory: '$destinationWallpapersDir'"
        try {
            New-Item -ItemType Directory -Path $destinationWallpapersDir -ErrorAction Stop | Out-Null
        }
        catch {
            Write-LogError "Failed to create wallpapers directory '$destinationWallpapersDir': $($_.Exception.Message)"
            return
        }
    }

    Write-LogInfo "Copying wallpaper files from '$sourceWallpapersDir' to '$destinationWallpapersDir'..."
    try {
        # Use -Recurse to copy all files and subdirectories.
        # Use -Force to overwrite existing files in the destination.
        Copy-Item -Path (Join-Path $sourceWallpapersDir '*.jpg') -Destination $destinationWallpapersDir -Recurse -Force -ErrorAction Stop

        Write-LogInfo "Successfully copied wallpaper files."

        # Configure Windows to use these wallpapers as a cycling desktop background.
        Write-LogInfo "Configuring desktop background slideshow..."

        # Define registry paths and values for the slideshow.
        $slideshowRegPath = "HKCU:\Control Panel\Personalization\Desktop Slideshow"
        $wallpaperRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers"
        $slideshowInterval = 1800000 # 30 minutes in milliseconds.
        $shuffleSlideshow = 1        # 1 for true (shuffle), 0 for false.

        # Ensure the slideshow registry key exists before setting properties on it.
        if (-not (Test-Path $slideshowRegPath)) {
            New-Item -Path $slideshowRegPath -Force -ErrorAction Stop | Out-Null
        }

        # Set the slideshow properties in the registry.
        Set-ItemProperty -Path $slideshowRegPath -Name "ImagesRootPath" -Value $destinationWallpapersDir -Type String -Force -ErrorAction Stop
        Set-ItemProperty -Path $slideshowRegPath -Name "Interval" -Value $slideshowInterval -Type DWord -Force -ErrorAction Stop
        Set-ItemProperty -Path $slideshowRegPath -Name "Shuffle" -Value $shuffleSlideshow -Type DWord -Force -ErrorAction Stop

        # Set the background type to 'Slideshow' (Value 2).
        Set-ItemProperty -Path $wallpaperRegPath -Name "BackgroundType" -Value 2 -Type DWord -Force -ErrorAction Stop

        # To apply the changes immediately, we need to broadcast a system-wide message.
        # This command tells the shell to update its settings, which should refresh the desktop.
        RUNDLL32.EXE USER32.DLL, UpdatePerUserSystemParameters 1, True
        Write-LogInfo "Successfully configured wallpapers and desktop slideshow."
    }
    catch {
        Write-LogError "Failed to configure wallpapers: $($_.Exception.Message)"
    }
}
