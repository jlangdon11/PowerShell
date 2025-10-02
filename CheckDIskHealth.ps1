$Cred = Get-Credential

Invoke-Command –ComputerName HV01 -Credential  $Cred –ScriptBlock{Get-PhysicalDisk | Select-Object HealthStatus}

Invoke-Command –ComputerName HV02 -Credential  $Cred –ScriptBlock{Get-PhysicalDisk | Select-Object HealthStatus}

Pause