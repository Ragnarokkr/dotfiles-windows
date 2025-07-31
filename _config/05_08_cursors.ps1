function Set-Cursors {
    <#
    .SYNOPSIS
        Unpacks and installs a custom cursor theme using an INF file.
        Ref: https://www.deviantart.com/cworldmaster/art/coolCursorCombov2-930861793
    #>
    Write-LogTitle "Configuring Cursors..."

    # Define paths for the cursor archive and temporary extraction location.
    # Assumes the .rar file is in a 'cursors' directory at the repo root.
    $sourceCursorsRar = Join-Path $PSScriptRoot '..' 'cursors' 'coolcursorcombov2_by_cworldmaster_dfe7lk1.rar' -Resolve
    $tempUnpackPath = Join-Path $env:TEMP "Cursors"
    
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


    # Check if the source archive exists.
    if (-not (Test-Path -Path $sourceCursorsRar -PathType Leaf)) {
        Write-LogWarning "Source cursor archive not found at '$sourceCursorsRar'. Skipping cursor configuration."
        return
    }

    try {
        # Ensure the temporary directory is clean before extraction.
        if (Test-Path $tempUnpackPath) {
            Write-LogInfo "Removing existing temporary cursor directory: $tempUnpackPath"
            Remove-Item -Path $tempUnpackPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Path $tempUnpackPath -ErrorAction Stop | Out-Null

        # Unpack the archive using 7-Zip.
        Write-LogInfo "Unpacking '$sourceCursorsRar' to '$tempUnpackPath'..."
        $arguments = "x `"$sourceCursorsRar`" -o`"$tempUnpackPath`" -y"
        $process = Start-Process -FilePath $unpackerPath.Source -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop

        if ($process.ExitCode -ne 0) {
            Write-LogError "Failed to unpack '$sourceCursorsRar' with exit code $($process.ExitCode)."
            # This will be caught by the main catch block.
            throw "Extraction failed."
        }
        Write-LogInfo "Successfully unpacked cursors."

        # Install the cursors using the provided .inf file.
        $infPath = Join-Path $tempUnpackPath 'coolCursorCombo\windows_11_cursors_concept_v2_by_jepricreations_densjkc\light\cursor\Install.inf'
        if (-not (Test-Path -Path $infPath -PathType Leaf)) {
            Write-LogError "Cursor installation file 'Install.inf' not found at the expected path: '$infPath'."
            throw "Install.inf not found after extraction."
        }

        Write-LogInfo "Installing cursors using '$infPath'..."
        # This command invokes the setup API to install from an INF file.
        Start-Process -FilePath "rundll32.exe" -ArgumentList "setupapi,InstallHinfSection DefaultInstall 132 `"$infPath`"" -Wait -PassThru -ErrorAction Stop

        Write-LogInfo "Cursor installation command executed successfully."
        Write-LogNote "To apply the new cursors, go to Settings > Bluetooth & devices > Mouse > Additional mouse settings > Pointers tab and select the new scheme."
    }
    catch {
        Write-LogError "Failed to configure cursors: $($_.Exception.Message)"
    }
    finally {
        # Clean up the temporary directory.
        if (Test-Path $tempUnpackPath) {
            Write-LogInfo "Cleaning up temporary cursor files from '$tempUnpackPath'..."
            Remove-Item -Path $tempUnpackPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
