$Cred = Get-Credential

Invoke-Command –ComputerName DC03 -Credential  $Cred –ScriptBlock{Set-ADAccountPassword -Identity 'CN=Paul Schoellman,OU=Sales Managers,OU=Domain Users,DC=Officelink,DC=local' -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "Exp!red033125" -Force)}