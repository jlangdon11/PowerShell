# List all installed apps on a computer

Get-AppxPackage

# Filter out installed app on a computer

Get-AppxPackage | Where-Object {$_.Name -like "*fox*"}

Pause