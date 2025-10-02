# Adding aliases to a user in Office 365 via a csv file

# Must connect to Exchange online first

$ListFile = import-csv '.\\AliasList.csv' 
$Mailbox = 'UserToModify@organization.com'
foreach ($AliasToAdd in $ListFile){
    Set-Mailbox $Mailbox -EmailAddresses @{add=$AliasToAdd.alias}
    Write-Host "$($AliasToAdd.alias) added"
}


# Add email alias to user in Office 365
Set-Mailbox mailboxName -EmailAddresses @{Add='alias@yourdomain.com'}

# Remove email alias from a user in Office 365
Set-Mailbox MailboxName -EmailAddresses @{Remove=’alias@somedomain.co.uk’}