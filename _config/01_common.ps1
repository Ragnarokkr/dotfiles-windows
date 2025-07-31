# ---------------------------------------------------------------------------- #
#                               Logging Functions                              #
# ---------------------------------------------------------------------------- #

# Private helper function for consistent log formatting.
function _Write-Log {
    param(
        [string]$Message,
        [string]$Level,
        [string]$ForegroundColor = "White",               
        [string]$BackgroundColor = "Black"
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'    

    # Determine the color for the log level tag itself
    $levelTagColor = switch ($Level.ToUpper()) {        
        'INFO' { 'Cyan' }
        'WARN' { 'Yellow' }
        'ERROR' { 'Red' }
        'NOTE' { 'DarkYellow' }
        default { 'Gray' } # A sensible default for unknown levels
    }

    Write-Host -NoNewline "$timestamp [" -ForegroundColor White -BackgroundColor Black
    Write-Host -NoNewline "$Level" -ForegroundColor $levelTagColor
    Write-Host -NoNewline "] " -ForegroundColor Gray
    Write-Host $Message -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
}

<#
.SYNOPSIS
    Writes a formatted title message to the console for section breaks.
.PARAMETER Message
    The message to display as a title.
#>
function Write-LogTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )    
    _Write-Log -Message " $Message " -Level 'INFO' -ForegroundColor Black -BackgroundColor White
}

<#
.SYNOPSIS
    Writes a formatted informational message to the console.
.PARAMETER Message
    The informational message to display.
#>
function Write-LogInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    _Write-Log -Message $Message -Level 'INFO'
}

<#
.SYNOPSIS
    Writes a formatted warning message to the console.
.PARAMETER Message
    The warning message to display.
#>
function Write-LogWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    _Write-Log -Message $Message -Level 'WARN'
}

<#
.SYNOPSIS
    Writes a formatted error message to the console.
.PARAMETER Message
    The error message to display.
#>
function Write-LogError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    _Write-Log -Message $Message -Level 'ERROR'
}

function Write-LogNote {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    _Write-Log -Message $Message -Level 'NOTE' -ForegroundColor Black -BackgroundColor DarkYellow
}

# ---------------------------------------------------------------------------- #
#                               SYSTEM UTILITIES                               #
# ---------------------------------------------------------------------------- #

# Function to scan common file system paths for a program.
# This is a heuristic approach for programs not found in the registry.
function Search-ProgramInFileSystem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProgramName
    )

    # Define common installation paths where programs might reside.
    # These include standard Program Files, and user-specific AppData locations.
    $commonPaths = @(
        "$env:ProgramFiles",
        "$env:ProgramFiles(x86)",
        "$env:LOCALAPPDATA",
        "$env:APPDATA"
    )

    Write-LogInfo "Scanning common file system paths for '$ProgramName'..."

    foreach ($basePath in $commonPaths) {
        # Check if the base path exists before attempting to list its contents.
        if (Test-Path $basePath) {
            # Search direct subdirectories for names matching the program.
            # -ErrorAction SilentlyContinue prevents errors if permissions are denied or paths are empty.
            Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                # Use -like for a flexible, case-insensitive substring match.
                if ($_.Name -like "*$ProgramName*") {
                    Write-LogInfo "Found potential program directory: $($_.FullName)"
                    # Return a PSCustomObject with relevant details.
                    # Version and Publisher are typically not available from file system scans.
                    return [PSCustomObject]@{
                        DisplayName    = $_.Name
                        Path           = $_.FullName
                        Source         = "File System (Directory Name)"
                        DisplayVersion = $null
                        Publisher      = $null
                    }
                }
            }

            # Search for executables within direct subdirectories that match the program name.
            # This can catch programs installed in differently named folders but with recognizable executables.
            Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $subDir = $_.FullName
                # Look for any .exe file whose base name (name without extension) contains the program name.
                Get-ChildItem -Path $subDir -Filter "*.exe" -File -ErrorAction SilentlyContinue | ForEach-Object {
                    if ($_.BaseName -like "*$ProgramName*" -or $_.Name -like "*$ProgramName*.exe") {
                        Write-LogInfo "Found potential program executable: $($_.FullName)"
                        # Use the executable's base name as the DisplayName.
                        return [PSCustomObject]@{
                            DisplayName    = $_.BaseName
                            Path           = $_.FullName
                            Source         = "File System (Executable)"
                            DisplayVersion = $null
                            Publisher      = $null
                        }
                    }
                }
            }
        }
    }
    # If no program is found after scanning all common paths, return $null.
    return $null
}

# Main function to test for installed programs, now including file system checks.
function Test-InstalledProgram {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0,
            HelpMessage = "The name of the program(s) to check.")]
        [string[]]$Name
    )

    begin {
        # Define standard registry paths where Windows applications register their uninstall information.
        $registryPaths = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', # For 32-bit apps on 64-bit OS
            'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'              # Per-user installations
        )

        Write-LogInfo "Gathering list of installed programs from registry..."
        # Retrieve properties from registry paths.
        # -ErrorAction SilentlyContinue handles cases where a path might not exist (e.g., Wow6432Node on a 32-bit system).
        # We filter for entries with a DisplayName to avoid empty or invalid entries.
        $installedProgramsFromRegistry = Get-ItemProperty -Path $registryPaths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -ne $null -and $_.DisplayName -ne '' } |
        Select-Object DisplayName, DisplayVersion, Publisher
        Write-LogInfo "Found $($installedProgramsFromRegistry.Count) programs in registry."
    }

    process {
        foreach ($programName in $Name) {
            Write-LogInfo "Checking for program: '$programName'"

            $foundProgram = $null
            $source = $null

            # 1. First, attempt to find the program in the Windows Registry.
            # We use -like for a flexible, case-insensitive substring match against DisplayName.
            $foundProgramFromRegistry = $installedProgramsFromRegistry | Where-Object { $_.DisplayName -like "*$programName*" } | Select-Object -First 1

            if ($foundProgramFromRegistry) {
                $foundProgram = $foundProgramFromRegistry
                $source = "Registry"
                Write-LogInfo "Program '$programName' found in registry."
            }
            else {
                Write-LogInfo "Program '$programName' not found in registry. Checking file system..."
                # 2. If not found in the registry, proceed to scan common file system paths.
                $foundProgramFromFileSystem = Search-ProgramInFileSystem -ProgramName $programName

                if ($foundProgramFromFileSystem) {
                    $foundProgram = $foundProgramFromFileSystem
                    # The source will be more specific (e.g., "File System (Directory Name)" or "File System (Executable)").
                    $source = $foundProgramFromFileSystem.Source
                    Write-LogInfo "Program '$programName' found in file system."
                }
                else {
                    Write-LogInfo "Program '$programName' not found in file system."
                }
            }

            # Output the result for the current program query.
            if ($foundProgram) {
                [PSCustomObject]@{
                    Query       = $programName
                    IsInstalled = $true
                    Name        = $foundProgram.DisplayName
                    Version     = $foundProgram.DisplayVersion # Will be $null if found via file system scan
                    Publisher   = $foundProgram.Publisher     # Will be $null if found via file system scan
                    Source      = $source                       # Indicates where the program was found
                }
            }
            else {
                # If the program was not found in either location.
                [PSCustomObject]@{
                    Query       = $programName
                    IsInstalled = $false
                    Name        = $null
                    Version     = $null
                    Publisher   = $null
                    Source      = $null
                }
            }
        }
    }
}
