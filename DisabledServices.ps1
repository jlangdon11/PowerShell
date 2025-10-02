Get-Service | Select Name

$DisableServices = @(

    "BDESVC",
    "vmicguestinterface"
    "vmicheartbeat"
    "vmickvpexchange"
    "vmicrdv"
    "vmicshutdown"
    "vmictimesync"
    "vmicvmsession"
    "vmicvss"
    "SCardSvr"
    "ScDeviceEnum"
    "SCPolicySvc"
    "XblAuthManager"
    "XblGameSave"
    "XboxGipSvc"
    "XboxNetApiSvc")

foreach ($ds in $DisableServices) {
    Get-Service -Name $ds | Set-Service -StartupType Disabled
}