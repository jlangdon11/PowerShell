# Adding a user in Active Directory

$Cred = Get-Credential

Invoke-Command –ComputerName DC03 -Credential  $Cred –ScriptBlock{New-ADUser -Name "Firstname Lastname" -GivenName "Firstname" -Surname "Lastname" -SamAccountName "FirstIntialLastname" -Path "OU=Domain Users,DC=officelink,DC=local" -AccountPassword(Read-Host -AsSecureString "password") -Enabled $true}
