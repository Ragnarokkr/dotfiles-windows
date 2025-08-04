$dotfilesDb = @(
    @{ 
        id         = 'git'; 
        repoPath   = (Join-Path $PSScriptRoot '..' 'git' '.gitattributes' -Resolve); 
        systemPath = (Join-Path $HOME '.gitattributes'); 
    },
    @{ 
        id         = 'git'; 
        repoPath   = (Join-Path $PSScriptRoot '..' 'git' '.gitignore' -Resolve); 
        systemPath = (Join-Path $HOME '.gitignore'); 
    },
    @{ 
        id         = 'git'; 
        repoPath   = (Join-Path $PSScriptRoot '..' 'git' '.gitmessage.txt' -Resolve); 
        systemPath = (Join-Path $HOME '.gitmessage.txt'); 
    },
    @{ 
        id         = 'helix'; 
        repoPath   = (Join-Path $PSScriptRoot '..' 'helix' -Resolve); 
        systemPath = (Join-Path $env:APPDATA 'helix'); 
    },
    @{ 
        id         = 'ohmyposh'; 
        repoPath   = (Join-Path $PSScriptRoot '..' 'oh-my-posh' 'atomic-custom.omp.json' -Resolve); 
        systemPath = (Join-Path $env:LOCALAPPDATA 'oh-my-posh' 'themes' 'atomic-custom.omp.json'); 
    },
    @{ 
        id         = 'powershell'; 
        repoPath   = (Join-Path $PSScriptRoot '..' 'powershell' 'profile.ps1' -Resolve); 
        systemPath = $PROFILE.CurrentUserAllHosts; 
    },
    @{ 
        id         = 'vscode'; 
        repoPath   = (Join-Path $PSScriptRoot '..' 'vscode' 'settings.json' -Resolve); 
        systemPath = (Join-Path $env:APPDATA 'Code - Insiders' 'User' 'settings.json'); 
    },
    @{ 
        id         = 'vscode'; 
        repoPath   = (Join-Path $PSScriptRoot '..' 'vscode' 'vscode-custom.css' -Resolve); 
        systemPath = (Join-Path $HOME 'vscode-custom.css'); 
    }
)