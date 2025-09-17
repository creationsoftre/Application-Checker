<###############################
Title: Application Checker
Author: TW
Original: 2022_04_15
Last Updated: 2022_04_15
	

Overview:
- Checks to see if an application is installed or not
###############################>

# Show an Open File Dialog and return the file selected by the user.
function Read-OpenFileDialog([string]$WindowTitle, [string]$InitialDirectory, [string]$Filter = "All files (*.*)|*.*", [switch]$AllowMultiSelect)
{  
    Add-Type -AssemblyName System.Windows.Forms

    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog

    $openFileDialog.Title = $WindowTitle

    if ($InitialDirectory) 
    { 
        $openFileDialog.InitialDirectory = $InitialDirectory 
    }

    $openFileDialog.Filter = $Filter
    if ($AllowMultiSelect) 
    { 
        $openFileDialog.MultiSelect = $true 
    }

    $openFileDialog.ShowHelp = $true 
    $null = $openFileDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))

    if ($AllowMultiSelect) 
    { 
        return $openFileDialog.Filenames 
    } 
    else 
    { 
        return $openFileDialog.Filename 
    }
}

#Selecting a server list file for contents to be read
$serverList = Read-OpenFileDialog -WindowTitle "Select your Server List" -InitialDirectory 'c:\temp' -Filter "Text files (*.txt)|*.txt"
if (![string]::IsNullOrEmpty($serverList)) 
{ 
    Write-Host "You selected the file: $serverList" 
}
else
{ 
    "You did not select a file.";break 
}


#reading servers in server lis
$servers = @(Get-content $serverList)

#User Credntials
$cred = "$env:USERDOMAIN\$env:USERNAME"

$userCredentials = Get-Credential -UserName $cred  -message 'Enter credentials for Elevated Account'

#Create new PowerShell Session on each Server in server list
$sessions = New-PSSession -ComputerName $servers -Credential $userCredentials

#Perform the folllowing steps on each server
Invoke-Command -Session $sessions {

    $application = "PowerShell 7-x64"
    $get_application = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -eq $application} | select Name, Version
        if($get_application){
            Write-Host " $($env:computername) - " -NoNewline
            Write-Host "Application: $get_application is installed."  -ForegroundColor Green
        }else{
            Write-Host " $($env:computername) - " -NoNewline
            Write-Host "Application: $application is not installed."  -ForegroundColor red
        }
}

Get-PSSession | Remove-PSSession





