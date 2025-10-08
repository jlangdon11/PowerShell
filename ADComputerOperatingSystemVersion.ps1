$Cred = Get-Credential

Invoke-Command -ComputerName  -Credential $Cred -ScriptBlock {Get-ADComputer -Filter * -Property OperatingSystem,OperatingSystemVersion | Format-Table Name,OperatingSystem,OperatingSystemVersion}
