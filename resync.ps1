<#
.SYNOPSIS
    Resynchronizes dotfiles.
.DESCRIPTION
    This script compares system dotfiles with their repository counterparts
    and updates the repository if the system version is newer.
.NOTES
    - This script is intended to be run from within the dotfiles repository.
#>

# Import common functions for logging
. (Join-Path $PSScriptRoot '_config' '01_common.ps1')
# Import the dotfiles database
. (Join-Path $PSScriptRoot '_config' 'dotfiles-db.ps1')

function Sync-Dotfiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Paths
    )

    Write-LogTitle "Starting dotfiles synchronization..."

    foreach ($path in $Paths) {
        # Expand environment variables in source path (if any)
        $source = [System.Environment]::ExpandEnvironmentVariables($path.systemPath)
        $destination = $path.repoPath

        Write-LogInfo "Checking: Source='$source', Destination='$destination'"

        if (-not (Test-Path $source)) {
            Write-LogWarning "Source path not found. Skipping."
            continue
        }

        $sourceIsDirectory = (Get-Item $source).PSIsContainer

        if ($sourceIsDirectory) {
            # Handle directories
            if (-not (Test-Path $destination)) {
                Write-LogInfo "Destination directory does not exist. Creating and copying..."
                try {
                    Copy-Item -Path $source -Destination $destination -Recurse -Force -ErrorAction Stop
                    Write-LogInfo "Copied source directory to destination."
                }
                catch {
                    Write-LogError "Failed to copy source directory to destination: $($_.Exception.Message)"
                }
            }
            else {
                # Destination directory exists. We will sync contents by comparing file hashes.
                Write-LogInfo "Destination directory exists. Syncing contents by comparing file hashes..."
                try {
                    # 1. Sync files from source to destination
                    $sourceFiles = Get-ChildItem -Path $source -Recurse -File
                    foreach ($sFile in $sourceFiles) {
                        $relativePath = $sFile.FullName.Substring($source.Length)
                        $dFileFullPath = Join-Path -Path $destination -ChildPath $relativePath

                        $updateNeeded = $false
                        if (-not (Test-Path $dFileFullPath)) {
                            Write-LogInfo "New file in source: '$($sFile.Name)'. Copying..."
                            $updateNeeded = $true
                        }
                        else {
                            try {
                                $sourceHash = (Get-FileHash -Path $sFile.FullName -ErrorAction Stop).Hash
                                $destinationHash = (Get-FileHash -Path $dFileFullPath -ErrorAction Stop).Hash
                                if ($sourceHash -ne $destinationHash) {
                                    Write-LogInfo "File content differs for '$($sFile.Name)'. Updating..."
                                    $updateNeeded = $true
                                }
                            }
                            catch {
                                Write-LogError "Failed to compare hashes for '$($sFile.Name)': $($_.Exception.Message)"
                                continue # Skip to next file on hash error
                            }
                        }

                        if ($updateNeeded) {
                            $destDir = Split-Path -Path $dFileFullPath -Parent
                            if (-not (Test-Path $destDir)) {
                                New-Item -ItemType Directory -Path $destDir -Force -ErrorAction Stop | Out-Null
                            }
                            Copy-Item -Path $sFile.FullName -Destination $dFileFullPath -Force -ErrorAction Stop
                        }
                    }
                    
                    Write-LogInfo "Directory sync completed for '$destination'."
                }
                catch {
                    # Catch errors from Get-ChildItem, Remove-Item, etc.
                    Write-LogError "An error occurred during directory synchronization for '$destination': $($_.Exception.Message)"
                }
            }
        }
        else {
            # Handle files
            $sourceFile = Get-Item $source
            $updateNeeded = $false

            if (-not (Test-Path $destination)) {
                Write-LogInfo "Destination file does not exist. Copying..."
                $updateNeeded = $true
            }
            elseif ((Test-Path $destination) -and (Get-Item $destination).PSIsContainer) {
                Write-LogWarning "Destination is a directory, but source is a file. Skipping."
                continue
            }
            else {
                $destinationFile = Get-Item $destination
                try {
                    $sourceHash = (Get-FileHash -Path $sourceFile.FullName -ErrorAction Stop).Hash
                    $destinationHash = (Get-FileHash -Path $destinationFile.FullName -ErrorAction Stop).Hash

                    if ($sourceHash -ne $destinationHash) {
                        Write-LogInfo "Source file content differs from destination. Updating..."
                        $updateNeeded = $true
                    }
                    else {
                        Write-LogInfo "Destination file is up-to-date (same content hash). Skipping."
                    }
                }
                catch {
                    Write-LogError "Failed to compare file hashes for '$($sourceFile.FullName)' and '$($destinationFile.FullName)': $($_.Exception.Message)"
                    continue
                }
            }

            if ($updateNeeded) {
                try {
                    # Ensure destination directory exists for the file
                    $destDir = Split-Path -Path $destination -Parent
                    if (-not (Test-Path $destDir)) {
                        New-Item -ItemType Directory -Path $destDir -Force -ErrorAction Stop | Out-Null
                    }
                    Copy-Item -Path $sourceFile.FullName -Destination $destination -Force -ErrorAction Stop
                    Write-LogInfo "Copied source file to destination."
                }
                catch {
                    Write-LogError "Failed to copy source file to destination: $($_.Exception.Message)"
                }
            }
        }
    }

    Write-LogInfo "Dotfiles synchronization finished."
}

Sync-Dotfiles -Paths $dotfilesDb