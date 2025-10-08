# Moves computer to new OU and then verifies that it was indeed moved

$Cred = Get-Credential


Invoke-Command –ComputerName DC03 -Credential  $Cred –ScriptBlock{et-ADComputer mmaggard25 | Move-ADObject -TargetPath 'ou=Customer Service,ou=Domain Computers,dc=officelink,dc=local'; Get-ADComputer -Filter * -SearchBase "ou=Customer Service,ou=Domain Computers,dc=officelink,dc=local"}
