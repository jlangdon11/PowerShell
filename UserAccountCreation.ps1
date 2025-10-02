# Creates user account within Microsoft 365

# Must connect to Microsoft Graph

$PasswordProfile = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphPasswordProfile
$PasswordProfile.Password = "3Rv0y1q39/chsy"
New-MgUser -DisplayName "John Doe" -GivenName "John" -Surname "Doe" -UserPrincipalName johnd@contoso.onmicrosoft.com -UsageLocation "US" -MailNickname "johnd" -PasswordProfile $PasswordProfile -AccountEnabled $true