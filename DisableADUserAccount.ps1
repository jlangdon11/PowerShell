# Disabling a AD user account

# https://learn.microsoft.com/en-us/powershell/module/activedirectory/disable-adaccount?view=windowsserver2022-ps

$Cred = Get-Credential

Invoke-Command –ComputerName DC03 -Credential  $Cred –ScriptBlock{Disable-ADAccount -Identity 'CN=Paul Schoellman,OU=Sales Managers,OU=Domain Users,DC=officelink,DC=local'}

