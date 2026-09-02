# Returns user details like their Canonical Name and if they are locked out

while ($true) {

$Aduser = Read-Host "Enter the username"

Get-ADUser -Filter "SamAccountName -like '*$Aduser*'" -Properties CanonicalName, LockedOut

}

<#if (LockedOut = true){
    Unlock-ADAccount

    Get-ADUser -Filter "SamAccountName -like '*$Aduser*'" -Properties CanonicalName, LockedOut
}#>
