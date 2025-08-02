function Get-UserDocumentsPath {
    <#
    .SYNOPSIS
        Retrieves the path to the current user's Documents folder from the registry.
    #>
    try {
        $userShellFoldersPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        # The 'Personal' value holds the path to the Documents folder.
        $documentsPath = (Get-ItemProperty -Path $userShellFoldersPath -Name "Personal" -ErrorAction Stop).Personal
        # The path from registry might contain environment variables (e.g., %USERPROFILE%), so we must expand them.
        return [System.Environment]::ExpandEnvironmentVariables($documentsPath)
    }
    catch {
        Write-LogError "Failed to retrieve Documents path from registry: $($_.Exception.Message)"
        # Fallback to the well-known default if the registry query fails.
        $fallbackPath = Join-Path $HOME "Documents"
        Write-LogWarning "Falling back to default Documents path: $fallbackPath"
        return $fallbackPath
    }
}

function Decrypt-PowerToysFiles {
    <#
    .SYNOPSIS
        Decrypts .age files from a source directory to a destination directory.
    .PARAMETER SourcePath
        The path to the directory containing the encrypted .age files.
    .PARAMETER DestinationPath
        The path to the temporary directory where decrypted files will be stored.
    .PARAMETER PrivateKeyPath
        The full path to the age private key file.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $true)]
        [string]$PrivateKeyPath
    )

    Write-LogInfo "Decrypting files from '$SourcePath'..."

    $encryptedFiles = Get-ChildItem -Path $SourcePath -Recurse -Filter "*.age"
    $decryptionErrors = 0

    foreach ($file in $encryptedFiles) {
        $relativeFilePath = $file.FullName.Substring($SourcePath.Length + 1)
        $decryptedFilePath = Join-Path $DestinationPath $relativeFilePath.Replace(".age", "")
        
        $decryptedFileDir = Split-Path -Path $decryptedFilePath -Parent
        if (-not (Test-Path -Path $decryptedFileDir -PathType Container)) {
            New-Item -ItemType Directory -Path $decryptedFileDir -Force | Out-Null
        }

        Write-LogInfo "Decrypting: $relativeFilePath"
        try {
            Start-Process -FilePath "age.exe" -ArgumentList "--decrypt", "-i", "`"$PrivateKeyPath`"", "`"$($file.FullName)`"" -RedirectStandardOutput $decryptedFilePath -NoNewWindow -Wait
            if ($LASTEXITCODE -ne 0) {
                Write-LogError "Failed to decrypt file: $relativeFilePath (Exit code: $LASTEXITCODE)"
                $decryptionErrors++
            }
        }
        catch {
            Write-LogError "Exception decrypting '$relativeFilePath': $($_.Exception.Message)"
            $decryptionErrors++
        }
    }
    
    return $decryptionErrors
}

function Backup-PowerToysSettings {
    <#
    .SYNOPSIS
        Backs up PowerToys settings to a specified backup directory.
    #>
    [CmdletBinding()]
    param()

    Write-LogTitle "Configuring PowerToys"

    # Get user's documents path
    $documentsPath = Get-UserDocumentsPath
    if (-not $documentsPath) {
        Write-LogError "Could not determine Documents path. Aborting PowerToys backup."
        return
    }

    # Define paths
    $sourcePowerToysSettingsDir = Join-Path $PSScriptRoot '..' 'powertoys' -Resolve
    $destinationBackupDir = Join-Path $documentsPath 'PowerToys' 'Backup'
    $tempDecryptDir = Join-Path $env:TEMP "PowerToysDecrypt_$(Get-Random)"

    # Check if the source directory exists
    if (-not (Test-Path -Path $sourcePowerToysSettingsDir -PathType Container)) {
        Write-LogWarning "PowerToys settings directory not found at '$sourcePowerToysSettingsDir'. Skipping backup."
        return
    }
    
    # Create necessary directories
    try {
        New-Item -ItemType Directory -Path $destinationBackupDir, $tempDecryptDir -Force -ErrorAction Stop | Out-Null
        Write-LogInfo "Backup directories created."
    }
    catch {
        Write-LogError "Failed to create directories: $($_.Exception.Message). Aborting."
        return
    }

    # Handle encrypted files
    $encryptedFiles = Get-ChildItem -Path $sourcePowerToysSettingsDir -Recurse -Filter "*.age"
    if ($encryptedFiles) {
        $privateKeyPath = Read-Host "Please enter the full path to your age private key file"
        if (-not (Test-Path -Path $privateKeyPath -PathType Leaf)) {
            Write-LogError "The specified private key file does not exist: '$privateKeyPath'. Aborting."
            Remove-Item -Path $tempDecryptDir -Recurse -Force -ErrorAction SilentlyContinue
            return
        }

        $decryptionErrors = Decrypt-PowerToysFiles -SourcePath $sourcePowerToysSettingsDir -DestinationPath $tempDecryptDir -PrivateKeyPath $privateKeyPath
    }

    # Copy files
    Write-LogInfo "Copying files to backup directory '$destinationBackupDir'..."
    try {
        # Copy non-encrypted and decrypted files
        Copy-Item -Path (Join-Path $sourcePowerToysSettingsDir '*') -Destination $destinationBackupDir -Recurse -Force -Exclude "*.age" -ErrorAction Stop
        Copy-Item -Path (Join-Path $tempDecryptDir '*') -Destination $destinationBackupDir -Recurse -Force -ErrorAction Stop
        
        if ($decryptionErrors -gt 0) {
            Write-LogWarning "Backup completed with $decryptionErrors decryption errors."
        }
        else {
            Write-LogInfo "Successfully backed up and decrypted PowerToys settings."
        }
    }
    catch {
        Write-LogError "Failed to copy files to backup directory: $($_.Exception.Message)"
    }
    finally {
        # Clean up temporary directory
        Write-LogInfo "Cleaning up temporary directory '$tempDecryptDir'..."
        Remove-Item -Path $tempDecryptDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}