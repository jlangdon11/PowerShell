# https://learn.microsoft.com/en-us/powershell/module/hyper-v/suspend-vmreplication?view=windowsserver2025-ps 

$Cred = Get-Credential

Invoke-Command –ComputerName HV01 -Credential  $Cred –ScriptBlock{Suspend-VMReplication DB01}

Pause