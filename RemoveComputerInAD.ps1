$Cred = Get-Credential

Invoke-Command –ComputerName DC03 -Credential  $Cred –ScriptBlock{Remove-ADComputer -Identity "bhubiak-surface"}

