# Queries all computers located within a specified OU

$Cred = Get-Credential
 
Invoke-Command –ComputerName DC03 -Credential  $Cred –ScriptBlock{Import-Module activedirectory; Get-ADComputer -Filter * -SearchBase "ou=Engineering,ou=Domain Computers,dc=officelink,dc=local"}

Pause