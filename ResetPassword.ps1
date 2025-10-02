Connect-Graph -Scopes User.ReadWrite.All

$userUPN="<user account sign in name, such as belindan@contoso.com>"
$newPassword="<new password>"
$secPassword = ConvertTo-SecureString $newPassword -AsPlainText -Force
Update-MgUser -UserId $userUPN -PasswordProfile @{ ForceChangePasswordNextSignIn = $false; Password = $newPassword }