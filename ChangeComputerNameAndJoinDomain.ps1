# Changes computer name and joins it to the doamin

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

function Check-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# -----------------------------------------------------------------------------
<$computerName = Read-Host 'Enter New Computer Name'
Write-Host "Renaming this computer to: " $computerName  -ForegroundColor Yellow
Rename-Computer -NewName $computerName>
# -----------------------------------------------------------------------------
Add-computer –domainname officelink.local

Write-Host "------------------------------------" -ForegroundColor Green
Read-Host -Prompt "Setup is done, restart is needed, press [ENTER] to restart computer."
Restart-Computer