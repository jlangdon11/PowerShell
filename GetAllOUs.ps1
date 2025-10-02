# Gets a list of OUs and formats just name and distinguished name and sorts it alphabetically

$Cred = Get-Credential

Invoke-Command –ComputerName DC03 -Credential  $Cred –ScriptBlock{Get-ADOrganizationalUnit -Filter * | Select Name, DistinguishedName | Sort -Property Name}