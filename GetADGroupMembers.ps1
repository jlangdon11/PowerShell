# Show all members of an AD group, just swap Identity value for any group in AD

# https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-adgroupmember?view=windowsserver2022-ps

$Cred = Get-Credential

Invoke-Command –ComputerName DC03 -Credential  $Cred –ScriptBlock{Get-ADGroupMember -Identity "Executive" | select Name, DistinguishedName | Sort -Property Name }