# Add domain user as a local administrator
Install-Module -Name ActiveDirectory

Add-LocalGroupMember -Group "Administrators" -Member "officelink\bhubiak"