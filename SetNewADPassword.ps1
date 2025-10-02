# Sets a new password for a specified user

# https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-adaccountpassword?view=windowsserver2022-ps

Set-ADAccountPassword -Identity 'CN=Name,OU=Customer Service,OU=Domain Users,DC=officelink,DC=local' -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "NewPasswordHere" -Force)