# Searches AD Users by OU and formats to show just name and object class and sorts alphabetically

# https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-aduser?view=windowsserver2022-ps

Get-ADUser -Filter * -SearchBase "OU=Domain Users,DC=officelink,DC=local" | Sort -Property Name | Format-Table DistinguishedName,Name,ObjectClass