$Cred = Get-Credential

Invoke-Command –ComputerName DC03 -Credential  $Cred –ScriptBlock{Get-GPInheritance -Target 'ou=MyOU,dc=contoso,dc=com'}