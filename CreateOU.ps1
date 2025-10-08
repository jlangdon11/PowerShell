$newOU = Read-Host "Enter in the name of the new OU"

New-ADOrganizationalUnit -Name $newOU -Path "OU=Domain Users,DC=officelink,DC=local"

# Confirms the OU was created
Get-ADOrganizationalUnit -Filter 'name -like "NameOfNewOU*"'
