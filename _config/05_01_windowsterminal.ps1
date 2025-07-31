function Set-WindowsTerminal {
    <#
    .SYNOPSIS
        Downloads a color scheme and adds it to the Windows Terminal settings.
    #>
    Write-LogTitle "Configuring Windows Terminal..."

    # Define the color scheme details
    $schemeUrl = "https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/windowsterminal/MaterialDark.json"
    $schemeName = "MaterialDark"    
    $settingsJsonPath = Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json"

    if (-not (Test-Path $settingsJsonPath -PathType Leaf)) {
        Write-LogWarning "Windows Terminal settings.json not found at '$settingsJsonPath'. A default one may be created on first launch. Skipping configuration."
        return
    }

    $backupPath = "$settingsJsonPath.bak"
    try {
        # Download the color scheme
        Write-LogInfo "Downloading '$schemeName' color scheme from '$schemeUrl'..."
        $schemeObject = Invoke-WebRequest -Uri $schemeUrl -UseBasicParsing -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop

        # Read and parse the existing settings file
        Write-LogInfo "Reading Windows Terminal settings from '$settingsJsonPath'..."
        $settings = Get-Content -Path $settingsJsonPath -Raw | ConvertFrom-Json -ErrorAction Stop

        # Ensure the 'schemes' property exists and is an array
        if (-not $settings.PSObject.Properties.Name.Contains('schemes')) {
            Write-LogInfo "No 'schemes' array found in settings.json. Creating it."
            $settings | Add-Member -MemberType NoteProperty -Name 'schemes' -Value @()
        }

        # Check if the scheme already exists by name
        $schemeExists = $settings.schemes | Where-Object { $_.name -eq $schemeName }
        if ($schemeExists) {
            Write-LogInfo "Color scheme '$schemeName' already exists in settings.json. Skipping."
            return
        }

        # Add the new scheme to the array
        Write-LogInfo "Adding '$schemeName' to schemes..."
        $settings.schemes += $schemeObject

        # Convert back to JSON and save. Use a sufficient depth.
        $updatedSettingsJson = $settings | ConvertTo-Json -Depth 10
        
        Write-LogInfo "Saving updated settings to '$settingsJsonPath'..."
        Copy-Item -Path $settingsJsonPath -Destination $backupPath -Force -ErrorAction Stop
        Write-LogInfo "Backup of original settings created at '$backupPath'"

        Set-Content -Path $settingsJsonPath -Value $updatedSettingsJson -Encoding UTF8 -ErrorAction Stop

        Write-LogInfo "Successfully configured Windows Terminal with '$schemeName' color scheme."
    }
    catch {
        Write-LogError "Failed to configure Windows Terminal: $($_.Exception.Message)"
        if (Test-Path $backupPath) {
            Write-LogWarning "Attempting to restore settings.json from backup..."
            Copy-Item -Path $backupPath -Destination $settingsJsonPath -Force -ErrorAction Stop
        }
    }
}