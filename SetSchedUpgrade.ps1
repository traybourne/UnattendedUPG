Function MsgBox($Message, $Title)
{
   [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
   [Microsoft.VisualBasic.Interaction]::MsgBox($Message, "SystemModal,Critical", $Title)
}

$UpgradePath = ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.bat')
$DatePrompt = {
try{
$SchedDate  = Read-Host -Prompt 'Enter the DATE you would like to schedule the upgrade for (e.g. 04/24/2018)'

$culture = [Globalization.CultureInfo]::InvariantCulture

if ($SchedDate -match '^\w\w\/\w\w\/\w\w\w\w$') {
    $pattern = 'MM\/dd\/yyyy'
}

[DateTime]::ParseExact($SchedDate, $pattern, $culture)
}catch {
        MsgBox "Date entered was invalid, try again" "Unattended Upgrade"
        & $DatePrompt
        }
Clear-Host
& $TimePrompt
}

$TimePrompt = {
try{
$SchedTime  = Read-Host -Prompt 'Enter the TIME you would like to schedule the upgrade for in 24 hour format (e.g. 03:00:00)'

$culture = [Globalization.CultureInfo]::InvariantCulture

if ($SchedTime -match '^\w\w\:\w\w\:\w\w$') {
    $pattern = 'hh\:mm\:ss'
}

[DateTime]::ParseExact($SchedTime, $pattern, $culture)
}catch {
        MsgBox "Time entered was invalid, try again" "Unattended Upgrade"
        & $TimePrompt
        }
REG COPY "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" "HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinlogonBAK" /F
REG IMPORT EULA.reg
Clear-Host
MsgBox "Please enter the Windows password in the next prompt and press Enable to allow unattended reboot for the upgrade" "Unattended Upgrade"
Start-Process -FilePath "Autologon.exe" -Wait
schtasks /create /tn "RB_Upgrade" /tr "'$UpgradePath' silent" /SC ONCE /SD $SchedDate /ST $SchedTime /ru system
EXIT
}

if ((Get-WMIObject Win32_Logicaldisk -filter "deviceid='C:'").FreeSpace -gt 10GB){
& $DatePrompt
} else {
MsgBox "Hard Drive is too full, please free at least 10GB before scheduling upgrade" "Unattended Upgrade"
Exit
}
