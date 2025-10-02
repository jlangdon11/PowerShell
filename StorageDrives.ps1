# Listing all the drives on a computer, their size, and free space

Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"