# Shows the list of running process on a computer

Get-Process

<# Shows the list of running process on a computer
This also shows the ID of the process as well as the Path it is located
#> 

Get-Process | Format-Table -Wrap -AutoSize -Property Name,Id,Path


# Filters out process

Get-Process -Name *chrome* | Format-Table -Wrap -AutoSize -Property Name,Id,Path


# Groups by company


Get-Process | Format-Table -Wrap -AutoSize -Property Name,Id,Path -GroupBy Company
