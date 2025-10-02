# Resume VM Replication

# https://learn.microsoft.com/en-us/powershell/module/hyper-v/resume-vmreplication?view=windowsserver2022-ps

$Cred = Get-Credential

Invoke-Command –ComputerName HV01 -Credential  $Cred –ScriptBlock{Resume-VMReplication DB01}

Pause