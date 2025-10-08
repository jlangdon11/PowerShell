$Cred = Get-Credential

$session = New-PSSession -ComputerName "ComputerName" -Credential $Cred

Enter-PSSession -Session $session

Exit-PSSession

Remove-PSSession -Session $session
