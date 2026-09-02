# Finds user by Canonical Name aka their logon username

while ($true) {

$Aduser = Read-Host "Enter the username"

(Get-ADUser -Filter "SamAccountName -like '*$Aduser*'" -Properties CanonicalName).CanonicalName 

}