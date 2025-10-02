$Cred = Get-Credential

Invoke-Command –ComputerName HV01 -Credential  $Cred –ScriptBlock{Get-VM -ComputerName HV01 | Format-Table -Property VMName, State, Status, ReplicationHealth, ReplicationMode, Path, ComputerName}

Invoke-Command –ComputerName HV02 -Credential  $Cred –ScriptBlock{Get-VM -ComputerName HV02 | Format-Table -Property VMName, State, Status, ReplicationHealth, ReplicationMode, Path, ComputerName}