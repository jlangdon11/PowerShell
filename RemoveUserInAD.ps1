$Cred = Get-Credential

# Confirms the user exists
Get-ADUser -Identity 'CN=Firstname Lastname,OU=Domain Users,DC=officelink,DC=local'

# Removes the user
Invoke-Command –ComputerName DC03 -Credential  $Cred –ScriptBlock{Remove-ADUser -Identity 'CN=Firstname Lastname,OU=Domain Users,DC=officelink,DC=local' -Confirm:$false}

# Confirm the user is deleted
Get-ADUser -Filter * -SearchBase "OU=Domain Users,DC=officelink,DC=local" | Sort -Property Name | Format-Table DistinguishedName,Name,ObjectClass

# Removing all disbaled accounts
#Search-ADAccount -AccountDisabled | where {$_.ObjectClass -eq 'user'} | Remove-ADUser