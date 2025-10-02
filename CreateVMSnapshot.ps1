# Creates a Snapshot of a VM

# https://learn.microsoft.com/en-us/powershell/module/hyper-v/checkpoint-vm?view=windowsserver2022-ps

Get-VM $VMName -ComputerName HV01 | Checkpoint-VM