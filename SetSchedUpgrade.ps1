﻿$CurDir = (Split-Path $MyInvocation.Mycommand.Path)
Function MsgBox($Message, $Type, $Title)
{
   [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
   [Microsoft.VisualBasic.Interaction]::MsgBox($Message, "SystemModal, $Type", $Title)
}

Function InputBox($Message, $Title)
{
   [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
   [Microsoft.VisualBasic.Interaction]::InputBox($Message, $Title)
}

$UpgradePath = "$CurDir\RB_Upgrade.ps1"
$LogPath = "$CurDir\RB_Upgrade.log"
$DatePrompt = {
if (!(Test-Path "$CurDir\Software\*RemoteUpgrade*.exe")) {
	MsgBox "Remote Upgrade file not found! please ensure the Software folder with the Remote Upgrade file is in the same folder as this exe" "Critical" "UnattendedUPG Build"
	Exit
}

try{
$SchedDate = InputBox "Enter the DATE you would like to schedule the upgrade for (e.g. 04/24/2018)" "Unattended Upgrade"
if (!$SchedDate) { Exit }
$culture = [Globalization.CultureInfo]::InvariantCulture

if ($SchedDate -match '^\w\w\/\w\w\/\w\w\w\w$') {
    $pattern = 'MM\/dd\/yyyy'
}

[DateTime]::ParseExact($SchedDate, $pattern, $culture)
}catch {
        MsgBox "Date entered was invalid, try again" "Critical" "Unattended Upgrade"
        & $DatePrompt
        }
Clear-Host
& $TimePrompt
}

$TimePrompt = {
try{
$SchedTime  = InputBox "Enter the TIME you would like to schedule the upgrade for in 24 hour format (e.g. 03:00)" "Unattended Upgrade"
if (!$SchedTime) { Exit }
if ($SchedTime -match '^\w\w\:\w\w$') {
    $pattern = 'HH\:mm'
}

[DateTime]::ParseExact($SchedTime, $pattern, $culture)
}catch {
        MsgBox "Time entered was invalid, try again" "Critical" "Unattended Upgrade"
        & $TimePrompt
        }
Clear-Host
Start-Sleep 2
if (!(Test-Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\WinlogonBAK")) {
Copy-Item -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\WinlogonBAK" -Force
}
MsgBox "Please enter the Windows username and password in the next prompt and press Enable to allow unattended reboot for the upgrade" "Information" "Unattended Upgrade"
Start-Process -FilePath "Autologon.exe" -ArgumentList "/accepteula" -Wait
$Format = (((((([System.Globalization.DateTimeFormatInfo]::CurrentInfo.ShortDatePattern) -replace 'M+/', 'MM/') -replace 'd+/', 'dd/') -replace 'MMM', 'MM') -replace '-yy+', '-yyyy') -replace '/yy+', '/yyyy') -replace 'yy+-', 'yyyy-'
$ParseDate = [DateTime]::Parse($SchedDate, $Culture)
schtasks /create /tn "RB_Upgrade" /tr "'Powershell.exe' -executionpolicy remotesigned -File '$UpgradePath' silent" /SC ONCE /SD (get-date $ParseDate -format $Format) /ST $SchedTime /ru SYSTEM /rl HIGHEST
MsgBox "Task Scheduler will now launch, please confirm task was created successfully" "Information" "Unattended Upgrade"
Start-Process -FilePath "taskschd.msc"
EXIT
}

if ((Get-WMIObject Win32_Logicaldisk -filter "deviceid='C:'").FreeSpace -gt 10GB){
& $DatePrompt
} else {
MsgBox "Hard Drive is too full, please free at least 10GB before scheduling upgrade" "Critical" "Unattended Upgrade"
Exit
}
