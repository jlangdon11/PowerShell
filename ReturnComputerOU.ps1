# Tries to find a match with the name like the DT or LT number that was entered

while ($true) {

$Adcomputer = Read-Host "Enter a DT or LT number"

(Get-ADComputer -Filter "Name -like '*$Adcomputer*'" -Properties CanonicalName).CanonicalName

}