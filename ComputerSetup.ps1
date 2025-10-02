# For everyone

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

function Check-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# -----------------------------------------------------------------------------
#<$computerName = Read-Host 'Enter New Computer Name'
#Write-Host "Renaming this computer to: " $computerName  -ForegroundColor Yellow
#Rename-Computer -NewName $computerName>
# -----------------------------------------------------------------------------
#Add-computer –domainname officelink.local
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Disable Sleep on AC Power..." -ForegroundColor Green
Write-Host "------------------------------------" -ForegroundColor Green
Powercfg /Change monitor-timeout-ac 20
Powercfg /Change standby-timeout-ac 0
# -----------------------------------------------------------------------------
#Write-Host ""
#Write-Host "Add 'This PC' Desktop Icon..." -ForegroundColor Green
#Write-Host "------------------------------------" -ForegroundColor Green
#$thisPCIconRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
#$thisPCRegValname = "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" 
#$item = Get-ItemProperty -Path $thisPCIconRegPath -Name $thisPCRegValname -ErrorAction SilentlyContinue 
#if ($item) { 
 #   Set-ItemProperty  -Path $thisPCIconRegPath -name $thisPCRegValname -Value 0  
#} 
#else { 
 #   New-ItemProperty -Path $thisPCIconRegPath -Name $thisPCRegValname -Value 0 -PropertyType DWORD | Out-Null  
#} 
# -----------------------------------------------------------------------------
#Write-Host ""
#Write-Host "Removing Edge Desktop Icon..." -ForegroundColor Green
#Write-Host "------------------------------------" -ForegroundColor Green
#$edgeLink = $env:USERPROFILE + "\Desktop\Microsoft Edge.lnk"
#Remove-Item $edgeLink
# -----------------------------------------------------------------------------
# To list all appx packages:
Get-AppxPackage | Format-Table -Property Name,Version,PackageFullName
Write-Host "Removing UWP Rubbish..." -ForegroundColor Green
Write-Host "------------------------------------" -ForegroundColor Green
$uwpRubbishApps = @(
    "Microsoft.Messaging",
    "king.com.CandyCrushSaga",
    "Microsoft.BingNews",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.People",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.YourPhone",
    "Fitbit.FitbitCoach",
    "4DF9E0F8.Netflix",
    "Disney.37853FC22V2CE",
    "Microsoft.XboxGameCallableUI",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.XboxGameOverlay",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.GetHelp")

foreach ($uwp in $uwpRubbishApps) {
    Get-AppxPackage -Name $uwp | Remove-AppxPackage
}
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Enable Remote Desktop..." -ForegroundColor Green
Write-Host "------------------------------------" -ForegroundColor Green
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\" -Name "fDenyTSConnections" -Value 0
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\" -Name "UserAuthentication" -Value 1
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

if (Check-Command -cmdname 'choco') {
    Write-Host "Choco is already installed, skip installation."
}
else {
    Write-Host ""
    Write-Host "Installing Chocolate for Windows..." -ForegroundColor Green
    Write-Host "------------------------------------" -ForegroundColor Green
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

Write-Host ""
Write-Host "Installing Applications..." -ForegroundColor Green
Write-Host "------------------------------------" -ForegroundColor Green
#Write-Host "[WARN] Made in China: some software like Google Chrome require the true Internet first" -ForegroundColor Yellow

<#if (Check-Command -cmdname 'git') {
    Write-Host "Git is already installed, checking new version..."
    choco update git -y
}
else {
    Write-Host ""
    Write-Host "Installing Git for Windows..." -ForegroundColor Green
    choco install git -y
}

if (Check-Command -cmdname 'node') {
    Write-Host "Node.js is already installed, checking new version..."
    choco update nodejs -y
}
else {
    Write-Host ""
    Write-Host "Installing Node.js..." -ForegroundColor Green
    choco install nodejs -y
}#>

#choco install 7zip.install -y
#choco install googlechrome -y
#choco install firefox -y
choco install vlc -y
#choco install office365business --params "'/productid:O365ProPlusRetail /updates:TRUE'" -y

#Write-Host "------------------------------------" -ForegroundColor Green
#Read-Host -Prompt "Setup is done, restart is needed, press [ENTER] to restart computer."
#Restart-Computer