# Returns the expiration date and time of a user's password

Get-ADUser -identity langdonjm –Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" |
Select-Object -Property "Displayname",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}

# Returns the date and time of password last set by a user

Get-ADUser -identity bella -properties passwordlastset | ft Name, passwordlastset