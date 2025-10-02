# For Outlook

New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\Outlook\Security" -Name "DisallowSMIMEExternalContent" -Value 0 -PropertyType DWord