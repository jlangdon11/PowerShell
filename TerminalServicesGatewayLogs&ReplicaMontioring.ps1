$Cred = Get-Credential

Invoke-Command –ComputerName HV01 -Credential  $Cred –ScriptBlock{Get-VM -ComputerName HV01 | Format-Table -Property VMName, State, Status, ReplicationHealth, ReplicationMode, Path, ComputerName}

Invoke-Command –ComputerName HV02 -Credential  $Cred –ScriptBlock{Get-VM -ComputerName HV02 | Format-Table -Property VMName, State, Status, ReplicationHealth, ReplicationMode, Path, ComputerName}

$StartTime = (Get-Date).AddDays(-4)
Get-WinEvent -ComputerName RDS01 -Credential $Cred -FilterHashtable @{
  Logname='Microsoft-Windows-TerminalServices-Gateway/Operational'
  StartTime=$StartTime
} | format-table -auto -wrap
Pause