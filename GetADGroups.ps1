$Cred = Get-Credential

Invoke-Command –ComputerName DC03 -Credential  $Cred –ScriptBlock{Get-ADGroup -filter * | select Name, DistinguishedName}

Pause