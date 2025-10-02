# Shows all disabled user within Active Directory as well as when they were last modified

$Cred = Get-Credential

Invoke-Command –ComputerName DC03 -Credential  $Cred –ScriptBlock{Get-ADUser -Filter {Enabled -eq $false} -Properties Modified | select samaccountname,Modified}