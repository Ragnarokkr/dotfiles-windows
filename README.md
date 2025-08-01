# Dotfiles (Windows)

Welcome to my personal dotfiles repository, tailored for Windows 11. While this configuration reflects my own preferences and workflows, you’re welcome to explore, adapt, or fork it if you find any parts useful.

## Features

This configuration installs and sets up a suite of tools to enhance the Windows environment:

- **Shell**  
  PowerShell with a customized prompt via [Oh My Posh](https://ohmyposh.dev/).
- **Terminal**  
  Custom Windows Terminal [Material-inspired](https://github.com/mbadolato/iTerm2-Color-Schemes/blob/master/windowsterminal/MaterialDark.json) color scheme.
- **Development**  
  Git, Helix (text editor), VSCode Insider, D, Go, Node.js, Deno, and more.
  For a complete list of packages, see the [packages](_config/winget-packages.json) and [programs](_config/program-installers.json) scripts.
- **Customization**
  - Various wallpapers I liked from the internet.
  - A customized [Numix-inspired](https://www.deviantart.com/cworldmaster/art/coolCursorCombov2-930861793) cursors theme.
  - [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip) for terminal and code editors.

## Prerequisites

- Windows 10 or 11.
- Windows Terminal installed.
- PowerShell 7.5+ installed.
- `git` installed.

## Installation

Follow these steps carefully to ensure a smooth setup.

### 1. Configure Environment Variables

Before running the installer, export the following variables in your shell session so Git and Gemini CLI can be properly configured:

```powershell
$GIT_NAME="Your Name"
$GIT_EMAIL="your.email@example.com"
$GIT_SIGNING_KEY="YourGpgKeyId"
$GEMINI_API_KEY="YourGeminiApiKey"
```

> To persist these settings across sessions, add those exports to a file that’s sourced by your shell at startup. For example, you could create a file named `$env:HOME/private.ps1`:
>
> ```powershell
> [System.Environment]::SetEnvironmentVariable("GIT_NAME", "Your Name", [System.EnvironmentVariableTarget]::User)
> [System.Environment]::SetEnvironmentVariable("GIT_EMAIL", "your.email@example.com", [System.EnvironmentVariableTarget]::User)
> [System.Environment]::SetEnvironmentVariable("GIT_SIGNING_KEY", "YourGpgKeyId", [System.EnvironmentVariableTarget]::User)
> [System.Environment]::SetEnvironmentVariable("GEMINI_API_KEY", "YourGeminiApiKey", [System.EnvironmentVariableTarget]::User)
> ```
>
> Then source it from your main shell startup file:
>
> ```shell
> . $env:HOME/private.ps1
> ```
>
> ⚠️ **Security warning:** Do not commit or otherwise version-control `$env:HOME/private.ps1` (or whatever file you choose). It contains sensitive credentials that should remain private.

### 2. Run the Installer

Execute the following command to download and run the installer script:

```powershell
irm https://raw.githubusercontent.com/Ragnarokkr/dotfiles-windows/refs/heads/master/install.ps1 | iex
```

The script will guide you through the remaining setup steps. Once complete, restart your terminal to load the new configuration. Enjoy your new environment!
