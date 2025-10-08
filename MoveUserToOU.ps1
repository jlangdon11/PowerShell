# Search for user
Get-ADUser -Filter "GivenName -like 'j*'"
 
# Specify the user's identity (e.g., username, distinguished name, or SID)
$user = Get-ADUser -Identity "username"

# Specify the target OU's distinguished name
$targetOU = "OU=OUName,DC=domain,DC=com"

# Move the user to the target OU
Move-ADObject -Identity $user -TargetPath $targetOU
