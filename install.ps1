<#
.SYNOPSIS
    Installer for dotfiles.
.DESCRIPTION
    This script clones a dotfiles repository into %APPDATA%\dotfiles
    and then executes a setup script from within that repository.
.NOTES
    - Requires Git to be installed and available in the system's PATH.
    - You may need to adjust your PowerShell execution policy to run this script.
      To run without changing the policy permanently, open PowerShell and use:
      powershell -ExecutionPolicy Bypass -File .\install.ps1
#>

$RepoUrl = "https://github.com/Ragnarokkr/dotfiles-windows.git"
$SetupScript = "setup.ps1"

# The destination directory for the dotfiles repository.
$dotfilesDir = Join-Path $env:APPDATA "dotfiles"

function Search-Git {
    Write-Host "Checking for Git..."
    $gitExists = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitExists) {
        Write-Error "Git is not installed or not in your PATH. Please install Git and try again."
        Write-Host "You can download Git from: https://git-scm.com/downloads"
        return 1
    }
    Write-Host "Git found." -ForegroundColor Green
}

function Get-Repo {
    if (Test-Path $dotfilesDir) {
        Write-Warning "Existing dotfiles directory found at '$dotfilesDir'."
        try {
            $choice = Read-Host "Do you want to remove it and perform a fresh clone? (y/n)"
            if ($choice.ToLower() -ne 'y') {
                Write-Host "Installation aborted by user."
                return 
            }
        }
        catch {
            # Catches Ctrl+C during Read-Host
            Write-Host "`nInstallation aborted by user."
            return
        }

        Write-Host "Removing existing directory..."
        try {
            Remove-Item -Path $dotfilesDir -Recurse -Force -ErrorAction Stop
            Write-Host "Existing directory removed." -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to remove existing directory: $_"
            return 1
        }
    }

    Write-Host "Cloning repository from '$RepoUrl' into '$dotfilesDir'..."
    try {
        # Using --depth 1 for a shallow clone, which is faster for setup.
        git clone $RepoUrl $dotfilesDir --depth 1
        if ($LASTEXITCODE -ne 0) {
            # Manually check exit code as git might not throw a terminating error
            throw "Git clone failed. Please check the repository URL and your network connection."
        }
        Write-Host "Repository cloned successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to clone repository: $_"
        return 1
    }
}

function Invoke-Setup {
    $setupScriptPath = Join-Path $dotfilesDir $SetupScript

    if (-not (Test-Path $setupScriptPath)) {
        Write-Warning "Setup script '$SetupScript' not found in the repository at '$setupScriptPath'."
        Write-Host "Cloning complete, but no setup was run."
        return
    }

    Write-Host "Executing setup script: '$setupScriptPath'..."
    try {
        # Change to the dotfiles directory so the setup script runs with the correct working directory
        Push-Location $dotfilesDir
        # Execute the script. Using -ErrorAction Stop to catch terminating errors.
        & $setupScriptPath -ErrorAction Stop
        Pop-Location
        Write-Host "Setup script executed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "The setup script failed to execute: $_"
        # Ensure we pop the location even on failure
        if ((Get-Location).Path -ne (Get-Location -Stack).Path) {
            Pop-Location
        }
        return 1
    }
}

# ---------------------------------------------------------------------------- #
#                                Main Execution                                #
# ---------------------------------------------------------------------------- #

Search-Git
Get-Repo
Invoke-Setup

[System.Environment]::SetEnvironmentVariable('DOTFILES_PATH', $dotfilesDir, [System.EnvironmentVariableTarget]::User)
Write-Host "Your dotfiles repo is stored at: DOTFILES_PATH=$dotfilesDir"
Write-Host "To update, cd into it and run: git fetch --prune origin && git merge origin/master"