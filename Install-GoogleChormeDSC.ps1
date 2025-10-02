
<#
.Synopsis
   Powershell DSC script to install google chrome exe file on any machine
.DESCRIPTION
   Powershell DSC script to install google chrome exe file on any machine
.NOTES    
    Name: Install-GoogleChormeDSC.ps1
    Author: Deepak Vishwakarma
    Email : Deepitpro@outlook.com
    Version: 0.1 
    DateCreated: 04 Nov 2017
#>

Configuration InstallGoogleChrome
{

Import-DscResource –ModuleName 'PSDesiredStateConfiguration'

Node Localhost
    {
        #Google Chorme
         Package Chrome
         {
         Ensure = 'Present'
         Name = 'Google Chrome'
         Path = '\\fs01\\Software Applications (Client and Server)\Google Chrome\ChromeSetup.exe' #update the file with the google chrome exe file localtion
         ProductId = ''
         Arguments = '/silent /install'
        }
    }
}
        


InstallGoogleChorme -OutputPath C:\

Start-DscConfiguration -Path c:\ -Wait -Verbose -Force
