#----###########ALL VARIABLES#############----#

$ErrorActionPreference = 'silentlycontinue'
$UserTempPath = [System.IO.Path]::Combine($env:TEMP, '*.*')
$TempPaths = @($UserTempPath, "C:\Windows\Temp", "C:\Windows\Prefetch")
$BackgroundApps = Get-Item HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications 
$GlobalUserDisabled = (Get-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications).GlobalUserDisabled
$GetPowerPlan = powercfg /GetActiveScheme
$FirefoxVersions = @("*.default-esr", "*.default-release")
$ChromeCache = "C:\Users\$env:USERNAME\AppData\Local\Google\Chrome\User Data\Default\Cache"


#------##############CODE################------#


foreach ($Path in $TempPaths) {
    Get-ChildItem -Path $Path *.* -Recurse | Remove-Item -Force -Recurse
    Write-Output "Files from $Path have been deleted..."
}

if ($GetPowerPlan -eq "Power Scheme GUID: 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  (High performance)") {
    Write-Output "High performance mode was already enabled..."
}
 else {
    powercfg /s SCHEME_MIN
    Write-Output "High performance has been enabled..."
}

if ($GlobalUserDisabled -eq 0 -or $GlobalUserDisabled -eq $null) {
    $BackgroundApps | New-ItemProperty -Name 'GlobalUserDisabled' -Value 1
    Write-Output "Background apps have been disabled..." 
} else {
    Write-Output "Background apps are already disabled..."
}

foreach ($Version in $FirefoxVersions) {
    if (Test-Path C:\Users\$env:USERNAME\AppData\Local\Mozilla\Firefox\Profiles\$Version\cache2) {
        Remove-Item C:\Users\$env:USERNAME\AppData\Local\Mozilla\Firefox\Profiles\$Version\cache2 -Recurse
        Write-Output "Firefox cache cleared..."
        break
    } else {
        Write-Output "Firefox cache folder could not be find..."
        break
    }
}

if (Test-Path $ChromeCache) {
    Remove-Item $ChromeCache -Recurse
    Write-Output "Google Chrome cache cleared..."
} else {
    Write-Output "Google Chrome cache folder could not be find..."
}

Read-Host -Prompt "PRESS ENTER TO EXIT..."