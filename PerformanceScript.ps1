# Window Size #
[console]::WindowWidth=100
[console]::WindowHeight=30
[console]::BufferWidth = [console]::WindowWidth

# Checks if script is ran as admin #

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    Exit
}


# Errors are not outputed #
$ErrorActionPreference = 'silentlycontinue'

# Saves HKEY_USERS under HKU:
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null

# Clears temporary files in %temp%, temp, prefetch folders #
$TempPaths = "C:\Users\*\AppData\Local\Temp", "C:\Windows\Temp", "C:\Windows\Prefetch"
foreach ($Path in $TempPaths) {
    Get-ChildItem -Path $Path *.* -Recurse | Remove-Item -Force -Recurse
    Write-Host "Deleting Files From $Path..."
}


# Checks if high performance mode is enabled and if not enables it #
$GetPowerPlan = powercfg /GetActiveScheme 2>$null
if ($GetPowerPlan -eq "Power Scheme GUID: 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  (High performance)") {
    Write-Host "High performance mode was already enabled..."
}
 else {
    powercfg /s SCHEME_MIN
    Write-Host "Enabling High Performance Mode..."
}


# Check if background apps are disabled and disables them if not true #
Write-Host "Disabling background apps..."

$baseKeyPath = "HKU:\"
$subKeys = Get-ChildItem -Path $baseKeyPath
foreach ($subKey in $subKeys) {
    $registryPath = Join-Path -Path $subKey.PSPath -ChildPath "Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    if (Test-Path -Path $registryPath) {
        Set-ItemProperty -Path $registryPath -Name "GlobalUserDisabled" -Value 1
    }
}


# Checks what version of firefox user has and clear proper cache folder #
$FirefoxVersions = @("*.default-esr", "*.default-release")
foreach ($Version in $FirefoxVersions) {
    if (Test-Path C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\$Version\cache2) {
        Remove-Item C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\$Version\cache2 -Recurse
        Write-Host "Clearing Firefox Cache..."
        break
    } else {
        Write-Host "Firefox Cache Folder Could Not Be Find..."
        break
    }
}


# Clears Google Chrome cache #
$ChromeCache = "C:\Users\*\AppData\Local\Google\Chrome\User Data\Default\Cache"
if (Test-Path $ChromeCache) {
    Remove-Item $ChromeCache -Recurse
    Write-Host "Clearing Google Chrome Cache..."
} else {
    Write-Host "Google Chrome Cache Folder Could Not Be Find..."
}


# Disables DiagTrack Service #
Write-Host "Disabling Diagnostic Data Tracking Service..."
Set-Service -Name DiagTrack -StartupType Disabled; Stop-Service -Name DiagTrack

# Disables Offline Files #
Write-Host "Disabling Offline Files..."
Set-Service -Name CscService -StartupType Disabled; Stop-Service -Name CscService


# Loop designed to loop through each user in HKEY_USERS and do specified things below #
$VisualEffectsArray = "AnimateMinMax", "ComboBoxAnimation", "ControlAnimations", "CursorShadow", "ListBoxSmoothScrolling", "ListviewAlphaSelect", "ListviewShadow", "MenuAnimation", "TaskbarAnimations", "DWMAeroPeekEnabled", "DWMEnabled", "DWMSaveThumbnailEnabled", "Themes", "TooltipAnimation"
$userProfiles = Get-ChildItem -Path "Registry::HKEY_USERS"
foreach ($profile in $userProfiles) {

    $profileSID = $profile.PSChildName

    Write-Host "Enabling Custom Performance Settings for HKEY_USERS\$profileSID"
    reg add "HKEY_USERS\$profileSID\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f | Out-Null

    Write-Host "Customizing Prefrence Mask Settings for HKEY_USERS\$profileSID"
    reg add "HKEY_USERS\$profileSID\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012078010000000 /f | Out-Null

    Write-Host "Disabling Windows Metrics for HKEY_USERS\$profileSID"
    reg add "HKEY_USERS\$profileSID\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f | Out-Null

    Write-Host "Disabling Transparency Effects for HKEY_USERS\$profileSID"
    reg add "HKEY_USERS\$profileSID\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f | Out-Null

    Write-Host "Disabling Automatically Installing Suggested Apps..."
    reg add "HKEY_USERS\$profileSID\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f | Out-Null

    Write-Host "Disabling Start Menu Suggestions..."
    reg add "HKEY_USERS\$profileSID\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f | Out-Null

# System Properties --> Advanced --> Performance Settings --> Custom Settings for best performance and look #
    foreach ($Option in $VisualEffectsArray) {
        Write-Host "Disabling $Option ..."
        reg add "HKEY_USERS\$profileSID\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\$Option" /v DefaultApplied /t REG_DWORD /d 0 /f | Out-Null
    }
}

Restart-Service -Name Themes


Read-Host -Prompt "PRESS ENTER TO EXIT..."
