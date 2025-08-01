function Install-NerdFonts {
    <#
    .SYNOPSIS
        Downloads, unpacks, and installs Nerd Fonts (JetBrains Mono).
    #>
    Write-LogTitle "Configuring Nerd Fonts..."

    # Define font details
    $fontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    $zipFileName = "JetBrainsMono.zip"
    $zipDownloadPath = Join-Path $env:TEMP $zipFileName
    $fontUnpackPath = Join-Path $env:TEMP "NerdFonts-JetBrainsMono"

    # Prerequisite: Check for an unpacker executable in PATH. Prefer NanaZip.
    $unpackerPath = Get-Command NanaZipC.exe -ErrorAction SilentlyContinue
    if (-not $unpackerPath) {
        Write-LogWarning "NanaZip (NanaZipC.exe) not found in PATH. Checking for 7-Zip..."
        $unpackerPath = Get-Command 7z.exe -ErrorAction SilentlyContinue
        if (-not $unpackerPath) {
            Write-LogWarning "7-Zip (7z.exe) also not found in PATH. It is required to unpack the font archive."
            Write-LogWarning "Skipping Nerd Font installation."
            return
        }
    }

    try {
        # 1. Download the font archive
        Write-LogInfo "Downloading Nerd Fonts from '$fontZipUrl'..."
        Invoke-WebRequest -Uri $fontZipUrl -OutFile $zipDownloadPath -UseBasicParsing -ErrorAction Stop

        # 2. Unpack the archive
        if (Test-Path $fontUnpackPath) {
            Write-LogInfo "Removing existing temporary font directory: $fontUnpackPath"
            Remove-Item -Path $fontUnpackPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Path $fontUnpackPath -ErrorAction Stop | Out-Null

        Write-LogInfo "Unpacking '$zipDownloadPath' to '$fontUnpackPath'..."
        $arguments = "x `"$zipDownloadPath`" -o`"$fontUnpackPath`" -y"
        $process = Start-Process -FilePath $unpackerPath.Source -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop

        if ($process.ExitCode -ne 0) {
            Write-LogError "Failed to unpack '$zipDownloadPath' with exit code $($process.ExitCode)."
            throw "Font extraction failed."
        }
        Write-LogInfo "Successfully unpacked fonts."

        # 3. Install the fonts
        $fontFiles = Get-ChildItem -Path $fontUnpackPath -Recurse -Include "*.otf", "*.ttf"
        if ($fontFiles.Count -eq 0) {
            Write-LogWarning "No font files (.otf, .ttf) found in the unpacked directory. Skipping installation."
            return
        }

        Write-LogInfo "Checking and installing up to $($fontFiles.Count) font files..."
        $shell = New-Object -ComObject Shell.Application
        $fontsFolder = $shell.Namespace(0x14) # 0x14 is the CSIDL for the Fonts folder
        $systemFontsPath = Join-Path $env:windir 'Fonts'
        $installedCount = 0

        foreach ($fontFile in $fontFiles) {
            $destinationFontPath = Join-Path $systemFontsPath $fontFile.Name
            if (Test-Path -Path $destinationFontPath -PathType Leaf) {
                # Font already exists, skip it.
                continue
            }
            # The CopyHere method is asynchronous. Use flags for a silent install (4=No progress, 16=Yes to all).
            $fontsFolder.CopyHere($fontFile.FullName, 20)
            $installedCount++
        }

        if ($installedCount -gt 0) {
            Write-LogInfo "Issued installation for $installedCount new font(s). Waiting for async operations to complete..."
            Start-Sleep -Seconds 15 # Give Windows time to process the font installations before cleanup.
            Write-LogInfo "Font installation process completed."
        }
        else {
            Write-LogInfo "All fonts were already installed. No new fonts were added."
        }
        Write-LogNote "Nerd Fonts should now be available. A reboot may be required for them to appear in all applications."
    }
    catch {
        Write-LogError "Failed to install Nerd Fonts: $($_.Exception.Message)"
    }
    finally {
        # Clean up the downloaded and extracted files.
        if (Test-Path $zipDownloadPath) {
            Write-LogInfo "Cleaning up downloaded font archive..."
            Remove-Item -Path $zipDownloadPath -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $fontUnpackPath) {
            Write-LogInfo "Cleaning up temporary font files from '$fontUnpackPath'..."
            Remove-Item -Path $fontUnpackPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
