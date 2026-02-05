# PowerShell Profile Configuration
# Enhanced terminal with auto-fill, history, aliases, and functions

# ============ Oh My Posh Initialization ============
# Initialize Oh My Posh with Montys theme
$scoop = $env:SCOOP
if (-not $scoop) { $scoop = "$env:USERPROFILE\scoop" }
$omp = "$scoop\apps\oh-my-posh\current\oh-my-posh.exe"

if (Test-Path $omp) {
    & $omp init pwsh --config "$scoop\apps\oh-my-posh\current\themes\montys.omp.json" | Out-String | Invoke-Expression
} else {
    Write-Host "Oh My Posh not found at $omp" -ForegroundColor Red
}

# ============ FiraCode Nerd Font Auto-Installation ============
# Install the included FiraCode Nerd Font automatically
$fontPath = Join-Path $PSScriptRoot "FiraCodeNerdFont-Medium.ttf"
$fontInstalledMarker = "$env:TEMP\.firacode_nerd_installed"

if ((Test-Path $fontPath) -and (-not (Test-Path $fontInstalledMarker))) {
    # Check if font is already installed
    $fontFileName = Split-Path $fontPath -Leaf
    $installedFontPath = Join-Path $env:WINDIR "Fonts\$fontFileName"
    
    if (-not (Test-Path $installedFontPath)) {
        try {
            # Install font silently
            $fontsFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
            $fontsFolder.CopyHere($fontPath, 0x10 + 0x4)
        } catch {
            # Silently fail if installation doesn't work
        }
    }
    
    # Create marker file to skip check on future runs
    New-Item -ItemType File -Path $fontInstalledMarker -Force | Out-Null
}

# Auto-configure VS Code terminal to use FiraCode Nerd Font
$settingsPath = "$env:APPDATA\Code\User\settings.json"
if (Test-Path $settingsPath) {
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        
        # Set FiraCode Nerd Font if not already configured
        if ($settings.'terminal.integrated.fontFamily' -ne "FiraCode Nerd Font") {
            $settings | Add-Member -MemberType NoteProperty -Name "terminal.integrated.fontFamily" -Value "FiraCode Nerd Font" -Force
            $settings | ConvertTo-Json -Depth 100 | Set-Content $settingsPath
        }
    } catch {
        # Silently fail if VS Code settings can't be updated
    }
}

# ============ PSReadLine Configuration ============
# Enable PSReadLine features for better terminal experience
$PSReadLineOptions = @{
    HistorySearchCursorMovesToEnd = $true
    AddToHistoryHandler           = {
        param([string]$line)
        # Don't add to history if it's the same as the last command
        $LastHistoryItem = Get-History -Count 1 -ErrorAction SilentlyContinue
        if ($LastHistoryItem.CommandLine -ne $line) {
            return $true
        }
        return $false
    }
}

Set-PSReadLineOption @PSReadLineOptions

# ============ PSReadLine Predictive IntelliSense ============
# Enable auto suggestions based on command history (requires PSReadLine 2.1.0+)
try {
    Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
    Set-PSReadLineOption -PredictionViewStyle InlineView -ErrorAction Stop
} catch {
    # Silently skip if PSReadLine version doesn't support predictions
}

# ============ PSReadLine Key Bindings ============
# Tab for auto-complete (menu-based)
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Ctrl+R for reverse history search
Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
Set-PSReadLineKeyHandler -Key Ctrl+s -Function ForwardSearchHistory

# Ctrl+l to clear the screen
Set-PSReadLineKeyHandler -Key Ctrl+l -Function ClearScreen

# Alt+F for ForwardWord
Set-PSReadLineKeyHandler -Key Alt+f -Function ForwardWord

# Alt+B for BackwardWord
Set-PSReadLineKeyHandler -Key Alt+b -Function BackwardWord

# ============ Useful Aliases ============
New-Alias -Name ll -Value Get-ChildItem -Force -ErrorAction SilentlyContinue
New-Alias -Name la -Value Get-ChildItem -Force -ErrorAction SilentlyContinue
New-Alias -Name c -Value Clear-Host -Force -ErrorAction SilentlyContinue
New-Alias -Name touch -Value New-Item -Force -ErrorAction SilentlyContinue
New-Alias -Name grep -Value Select-String -Force -ErrorAction SilentlyContinue
New-Alias -Name which -Value Get-Command -Force -ErrorAction SilentlyContinue

# ============ Custom Functions ============

# List files with color coding
function ll {
    Get-ChildItem -Path $args -Force | Format-Table -AutoSize
}

# Go up directories quickly
function .. {
    Set-Location ..
}

function ... {
    Set-Location ../..
}

function .... {
    Set-Location ../../..
}

# Create directory and enter it
function mkcd {
    param([string]$Name)
    New-Item -ItemType Directory -Name $Name -Force | Out-Null
    Set-Location -Path $Name
}

# Open current directory in explorer
function explore {
    Invoke-Item .
}

# Get public IP address
function Get-PublicIP {
    (Invoke-WebRequest -Uri 'https://api.ipify.org?format=json' -UseBasicParsing | ConvertFrom-Json).ip
}

# Find file by name
function Find-File {
    param([string]$Name)
    Get-ChildItem -Recurse -Filter "*$Name*" -ErrorAction SilentlyContinue
}

# Search content in files
function Find-InFiles {
    param(
        [string]$Pattern,
        [string]$Path = '.'
    )
    Select-String -Path "$Path\*" -Pattern $Pattern -Recurse
}

# List processes by memory usage
function Get-MemoryProcesses {
    Get-Process | Sort-Object -Property WS -Descending | Select-Object -First 10 Name, @{Label="Memory(MB)"; Expression={[math]::Round($_.WS/1MB, 2)}}
}

# Quick git status
function gs {
    git status
}

function gaa {
    git add .
}

function gc {
    git commit -m $args
}

function gp {
    git push
}

# ============ Prompt Customization ============
# Prompt is now handled by Oh My Posh with Montys theme
# Commenting out the custom prompt function

<# Custom prompt (disabled - using Oh My Posh instead)
function prompt {
    $GitBranch = ""
    $GitStatus = ""
    
    # Check if we're in a git repository
    if (Test-Path .git) {
        $GitBranch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($GitBranch) {
            $GitStatus = " ($GitBranch)"
        }
    }
    
    $CurrentDirectory = Split-Path -Leaf -Path (Get-Location)
    
    # Color-coded prompt
    Write-Host "$CurrentDirectory" -ForegroundColor Cyan -NoNewline
    Write-Host "$GitStatus" -ForegroundColor Yellow -NoNewline
    Write-Host "> " -ForegroundColor Green -NoNewline
    return " "
}
#>

# ============ Initialization Messages ============
# Uncomment below to see startup messages
# Write-Host "PowerShell Profile Loaded!" -ForegroundColor Green
# Write-Host "Oh My Posh (Montys Theme) Enabled!" -ForegroundColor Cyan
# Write-Host "Useful commands: ll, mkcd, explore, Find-File, Get-PublicIP" -ForegroundColor Gray

