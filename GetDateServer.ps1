$Cred = Get-Credential

Invoke-Command –ComputerName DC01 -Credential  $Cred –ScriptBlock{Get-Date}