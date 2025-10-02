$Cred = Get-Credential

Invoke-Command –ComputerName DC03 -Credential  $Cred –ScriptBlock{Get-ADComputer -Filter * -SearchBase "OU=Customer Service,OU=Domain Computers,DC=officelink,DC=local"}