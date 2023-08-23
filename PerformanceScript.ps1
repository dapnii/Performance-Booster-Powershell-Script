$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    Exit
}



#----###########ALL VARIABLES#############----#

$ErrorActionPreference = 'silentlycontinue'
$UserTempPath = [System.IO.Path]::Combine($env:TEMP, '*.*')
$TempPaths = @($UserTempPath, "C:\Windows\Temp", "C:\Windows\Prefetch")
$BackgroundApps = Get-Item HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications 
$GlobalUserDisabled = (Get-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications).GlobalUserDisabled
$GetPowerPlan = powercfg /GetActiveScheme 2>$null
$FirefoxVersions = @("*.default-esr", "*.default-release")
$ChromeCache = "C:\Users\$env:USERNAME\AppData\Local\Google\Chrome\User Data\Default\Cache"
$VisualEffectsArray = "AnimateMinMax", "ComboBoxAnimation", "ControlAnimations", "CursorShadow", "DropShadow", "ListBoxSmoothScrolling", "ListviewAlphaSelect", "ListviewShadow", "MenuAnimation", "SelectionFade", "TaskbarAnimations", "DWMAeroPeekEnabled", "DWMEnabled", "DWMSaveThumbnailEnabled", "Themes", "ThumbnailsOrIcon", "TooltipAnimation"



#------##############CODE################------#


foreach ($Path in $TempPaths) {
    Get-ChildItem -Path $Path *.* -Recurse | Remove-Item -Force -Recurse
    Write-Host "Files from $Path have been deleted..."
}

if ($GetPowerPlan -eq "Power Scheme GUID: 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  (High performance)") {
    Write-Host "High performance mode was already enabled..."
}
 else {
    powercfg /s SCHEME_MIN
    Write-Host "High performance mode has been enabled..."
}

if ($GlobalUserDisabled -eq 0 -or $null -eq $GlobalUserDisabled) {
    $BackgroundApps | New-ItemProperty -Name 'GlobalUserDisabled' -Value 1
    Write-Host "Background apps have been disabled..." 
} else {
    Write-Host "Background apps are already disabled..."
}

foreach ($Version in $FirefoxVersions) {
    if (Test-Path C:\Users\$env:USERNAME\AppData\Local\Mozilla\Firefox\Profiles\$Version\cache2) {
        Remove-Item C:\Users\$env:USERNAME\AppData\Local\Mozilla\Firefox\Profiles\$Version\cache2 -Recurse
        Write-Host "Firefox cache cleared..."
        break
    } else {
        Write-Host "Firefox cache folder could not be find..."
        break
    }
}

if (Test-Path $ChromeCache) {
    Remove-Item $ChromeCache -Recurse
    Write-Host "Google Chrome cache cleared..."
} else {
    Write-Host "Google Chrome cache folder could not be find..."
}

Write-Host "Disabling Start Menu Suggestions..."
Get-Item HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager | Set-ItemProperty -Name SystemPaneSuggestionsEnabled -Value 0

Write-Host "Disabling Automatically Installing Suggested Apps..."
Get-Item HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager | Set-ItemProperty -Name SilentInstalledAppsEnabled -Value 0


Write-Host "Applying Custom Performance settings..."
Reg Add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects /v VisualFXSetting /t REG_DWORD /d 3 /f | Out-Null

REG ADD "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012078010000000 /f | Out-Null
REG ADD "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f | Out-Null

foreach ($Option in $VisualEffectsArray) {
    Reg Add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\$Option /v DefaultApplied /t REG_DWORD /d 0 /f | Out-Null
    Write-Host "Disabling $Option"
}

Restart-Service -Name Themes

Read-Host -Prompt "PRESS ENTER TO EXIT..."

