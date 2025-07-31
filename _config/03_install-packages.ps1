Write-LogTitle "Starting batch installation of programs (via winget)..."

try {
    winget import -i (Join-Path $PSScriptRoot 'winget-packages.json') --ignore-unavailable --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-LogError "Failed to import packages. Winget exited with code: $LASTEXITCODE"
    }
}
catch {
    Write-LogError "An error occurred while trying to install ${packageId}: $($_.Exception.Message)"
}
