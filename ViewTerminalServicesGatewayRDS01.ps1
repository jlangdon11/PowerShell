# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent?view=powershell-5.1
# -1 shows all logs from today's date
# -7 would show 7 days worth of logs
$Cred = Get-Credential
$StartTime = (Get-Date).AddDays(-1)
Get-WinEvent -ComputerName RDS01 -Credential $Cred -FilterHashtable @{
  Logname='Microsoft-Windows-TerminalServices-Gateway/Operational'
  StartTime=$StartTime
} | format-table -auto -wrap
pause