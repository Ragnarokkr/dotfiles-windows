function Set-Git {
    <#
    .SYNOPSIS
        Copies the .gitconfig file from the repository to the user's home directory.
    #>
    Write-LogTitle "Configuring Git..."

    # Define source and destination paths.
    $sourceGitConfig = Join-Path $PSScriptRoot '..' 'git' -Resolve    
    $destinationGitConfig = $HOME
    
    # Check if the source file exists before attempting to copy.
    if (-not (Test-Path -Path $sourceGitConfig)) {
        Write-LogWarning "Source '$sourceGitConfig' not found. Skipping Git configuration."
        return
    }

    Write-LogInfo "Copying .gitconfig to '$destinationGitConfig'..."
    try {
        # Use -Force to overwrite an existing .gitconfig in the destination.
        Copy-Item -Path (Join-Path $sourceGitConfig '*') -Destination $destinationGitConfig -Recurse -Force -ErrorAction Stop
        # Configuring system-dependent Git settings.
        git config --global commit.template (Join-Path $HOME ".gitmessage.txt")
        git config --global core.attributesFile (Join-Path $HOME ".gitattributes")
        git config --global core.excludesFile (Join-Path $HOME ".gitignore")        
        git config --global gpg.program (Join-Path ${env:ProgramFiles(x86)} "GnuPG" "bin" "gpg.exe")
        git config --global user.email "$env:GIT_EMAIL"
        git config --global user.name "$env:GIT_NAME"
        git config --global user.signingKey "$env:GIT_SIGNING_KEY"
        # Configuring Git Credential Manager.
        & (Join-Path $env:LOCALAPPDATA "Programs" "Git Credential Manager" "git-credential-manager.exe") configure

        Write-LogNote "Remember to import your public/private GPG keys."
        Write-LogInfo "Successfully configured Git."
    }
    catch {
        Write-LogError "Failed to configure Git: $($_.Exception.Message)"
    }
}
