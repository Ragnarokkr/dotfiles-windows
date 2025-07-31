# --- Configuration ---
# Define the path to the JSON file containing the list of programs to install.
# The JSON file should be an array of objects, each with:
#   - Name: The name of the program (for logging/display).
#   - Url: The direct download URL for the installer.
#   - FileName: The name to save the installer as locally (e.g., "chrome_setup.exe").
#   - InstallArgs: Arguments for silent installation.
#                  Common silent install arguments:
#                  - MSI: /qn /norestart (for .msi files)
#                  - EXE: /S, /silent, /quiet, /q (check program documentation for exact args)
#                  - If no silent args are known, leave as "" or omit the property.
#   - InstallerType: "msi" or "exe" (used to determine default silent args if not specified)
$ProgramsJsonPath = Join-Path $PSScriptRoot "program-installers.json"

# Check if the programs JSON file exists.
if (-not (Test-Path -Path $ProgramsJsonPath -PathType Leaf)) {
    Write-LogError "Programs definition file not found at '$ProgramsJsonPath'."
    Write-LogError "Please create a 'program-installers.json' file in the same directory as the script."
    # Using 'return' so it can be dot-sourced without terminating the parent shell.
    return
}

# Read and parse the programs from the JSON file.
try {
    $ProgramsToInstall = Get-Content -Path $ProgramsJsonPath -Raw | ConvertFrom-Json -ErrorAction Stop
}
catch {
    Write-LogError "Failed to read or parse '$ProgramsJsonPath': $($_.Exception.Message)"
    return
}

# Define the directory where installers will be downloaded
$DownloadPath = "$env:TEMP\ProgramInstallers"

# --- Functions ---

function New-DownloadDirectory {
    <#
    .SYNOPSIS
        Creates the specified download directory if it doesn't exist.
    .PARAMETER Path
        The full path to the directory to create.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        Write-LogInfo "Creating download directory: $Path"
        try {
            New-Item -ItemType Directory -Path $Path -ErrorAction Stop | Out-Null
        }
        catch {
            Write-LogError "Failed to create directory '$Path': $($_.Exception.Message)"
            exit 1
        }
    }
}

function Download-Installer {
    <#
    .SYNOPSIS
        Downloads an installer from a given URL to a specified local path.
    .PARAMETER Url
        The URL of the installer to download.
    .PARAMETER DestinationPath
        The full local path where the installer should be saved.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    Write-LogInfo "Attempting to download '$Url' to '$DestinationPath'..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile $DestinationPath -UseBasicParsing -ErrorAction Stop
        Write-LogInfo "Successfully downloaded installer."
        return $true
    }
    catch {
        Write-LogError "Failed to download installer from '$Url': $($_.Exception.Message)"
        return $false
    }
}

function Install-Program {
    <#
    .SYNOPSIS
        Executes an installer with specified arguments.
    .PARAMETER InstallerPath
        The full local path to the installer executable or MSI.
    .PARAMETER Arguments
        Any command-line arguments for silent installation.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$InstallerPath,

        [string]$Arguments = ""
    )

    Write-LogInfo "Attempting to install '$InstallerPath' with arguments: '$Arguments'..."
    try {
        # Start-Process is used for non-blocking execution and to pass arguments correctly.
        # -Wait ensures the script waits for the installer to finish before proceeding.
        # -PassThru captures the process object to check ExitCode.
        $process = Start-Process -FilePath $InstallerPath -ArgumentList $Arguments -Wait -PassThru -ErrorAction Stop
        
        if ($process.ExitCode -eq 0) {
            Write-LogInfo "Successfully installed '$InstallerPath'."
            return $true
        }
        else {
            Write-LogWarning "Installer for '$InstallerPath' exited with code: $($process.ExitCode). This might indicate a non-successful installation or a reboot pending."
            return $false
        }
    }
    catch {
        Write-LogError "Failed to execute installer '$InstallerPath': $($_.Exception.Message)"
        return $false
    }
}

# --- Main Script Logic ---

Write-LogTitle "Starting batch installation of programs (via installers)..."

# Ensure the download directory exists
New-DownloadDirectory -Path $DownloadPath

# Loop through each program in the array and attempt to install it
foreach ($Program in $ProgramsToInstall) {
    Write-LogInfo "Processing $($Program.Name)"

    $InstallerFileName = $Program.FileName
    $InstallerUrl = $Program.Url
    $InstallerLocalPath = Join-Path -Path $DownloadPath -ChildPath $InstallerFileName
    $InstallArguments = $Program.InstallArgs

    # If InstallArgs is not specified, try to use a default based on InstallerType
    if ([string]::IsNullOrEmpty($InstallArguments)) {
        if ($Program.InstallerType -eq "msi") {
            $InstallArguments = "/qn /norestart"
            Write-LogInfo "Using default MSI silent arguments: '$InstallArguments'"
        }
        elseif ($Program.InstallerType -eq "exe") {
            $InstallArguments = "/S" # Common for many EXEs, but verify for specific programs
            Write-LogInfo "Using default EXE silent arguments: '$InstallArguments'"
        }
        else {
            Write-LogWarning "No silent install arguments specified for $($Program.Name) and no default could be determined. Installation might require user interaction."
        }
    }

    # 1. Download the installer
    if (Download-Installer -Url $InstallerUrl -DestinationPath $InstallerLocalPath) {
        # 2. Install the program
        Install-Program -InstallerPath $InstallerLocalPath -Arguments $InstallArguments
    }
    else {
        Write-LogError "Skipping installation of $($Program.Name) due to download failure."
    }
}

Write-LogInfo "Cleaning up downloaded installers from $DownloadPath..."
Remove-Item -Path $DownloadPath -Recurse -Force -ErrorAction SilentlyContinue
Write-LogInfo "Cleanup complete."
