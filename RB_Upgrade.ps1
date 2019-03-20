$Silent = $args[0]
$CurDir = (Split-Path $MyInvocation.Mycommand.Path)
$ERROR = {
MsgBox "Reachback Upgrade cancelled" "Critical" "Unattended Upgrade"
EXIT
}
$ERROR2 = {
$Alert = @"
Set MyEmail = CreateObject("CDO.Message")
MyEmail.Subject="UPGRADE FAILED"
MyEmail.From=
MyEmail.To=
MyEmail.TextBody="RB Upgrade appears to have failed at $Site. Attempt to get a connection into the site to verify status of upgrade. <T1>6044123308</T1>"
MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2
MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserver") = "in-v3.mailjet.com"
MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 587
MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = 1
MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusername") =
MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendpassword") =
MyEmail.Configuration.Fields.Update
MyEmail.Send
set MyEmail=nothing
"@
$Alert | Set-Content "$env:TEMP\Alert.vbs" -Encoding ASCII
Start-Process -FilePath "$env:TEMP\Alert.vbs" -WindowStyle Hidden
Start-Sleep -s 10
EXIT
}

$Script = {
Function MsgBox($Message, $Type, $Title)
{
   [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
   [Microsoft.VisualBasic.Interaction]::MsgBox($Message, "SystemModal, $Type", $Title)
}

if ($Silent -ne "silent") {
$Prompt = MsgBox "This will stop Host Service and perform automated Reachback Upgrade - Continue?" "YesNo" "Unattended Upgrade"
switch ($Prompt) {
    "No" { & $ERROR }
}}

#PreUpgrade_Backup
& sqlcmd -E -Q "Restore log Squirrel with Recovery" >$null
& sqlcmd -E -Q "Restore log SquirrelCRM with Recovery" >$null
$Date = Get-Date -Format "yyyy-MM-dd"

new-item "C:\Agent\upgrade backups\$Date\databasebackups" -type directory -force

Write-Output "BACKING UP DATABASES..."

& SqlCmd -E -Q "BACKUP DATABASE [Squirrel] TO DISK='C:\Agent\upgrade backups\$Date\databasebackups\pre-upgrade sqbackup.bak'"

Write-Output "ZIPPING UP DATABASES..."

Remove-Item "C:\Agent\upgrade backups\$Date\databasebackups\databasebackups.zip" -force -ErrorAction 'silentlycontinue'

& zip -j -r "C:\Agent\upgrade backups\$Date\databasebackups\databasebackups.zip" "C:\Agent\upgrade backups\$Date\databasebackups"

Remove-Item "C:\Agent\upgrade backups\$Date\databasebackups\*.bak" -Force

Write-Output "BACKING UP SQUIRREL FILES..."

copy-item "C:\\Squirrel\\Browser" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
copy-item "C:\\Squirrel\\Custom" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse -ErrorAction 'silentlycontinue'
copy-item "C:\\Squirrel\\etc" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
copy-item "C:\\Squirrel\\Host" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse -ErrorAction 'silentlycontinue'
copy-item "C:\\Squirrel\\Posdata" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
copy-item "C:\\Squirrel\\Program" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
copy-item "C:\\Squirrel\\tftpboot" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
new-item "C:\\Agent\\upgrade backups\\$Date\\Squirrel\\X11R6\\lib\\X11\" -type directory -force
copy-item "C:\\Squirrel\\X11R6\\lib\\X11\\XF86Config" "C:\\Agent\\upgrade backups\\$Date\\Squirrel\\X11R6\\lib\\X11\" -force
new-item "$CurDir\\Software\\Browser\\English_Canadian" -type directory -force
copy-item "C:\\Squirrel\\Browser\\English_Canadian\\*rptCustom.htm" "$CurDir\\Software\\Browser\\English_Canadian" -force
copy-item "C:\\Squirrel\\Browser\\English_Canadian\\*Optional.htm" "$CurDir\\Software\\Browser\\English_Canadian" -force

Write-Output "ZIPPING UP SQUIRREL FILES..."

Remove-Item "C:\Agent\upgrade backups\$Date\Squirrel.zip" -force -ErrorAction 'silentlycontinue'

CD "C:\Agent\upgrade backups\$Date"

& zip -r "Squirrel.zip" "Squirrel" >$null

Remove-Item "C:\Agent\upgrade backups\$Date\Squirrel" -recurse -force

CD "$CurDir\Software"
#if ERRORLEVEL 1 goto ERROR2

#Bootptab_Backup
new-item "C:\\Agent" -type directory -force
copy-item "$env:SQCURDIR\tftpboot\bootptab*.*" "C:\Agent" -force

#SQL_Rename
$SQL_CURRENT = & sqlcmd -E -Q "SET NOCOUNT ON; select @@SERVERNAME" -W -h-1
if ($SQL_CURRENT -ne $env:COMPUTERNAME) {
& SQLCMD -E -Q "sp_dropserver '$SQL_CURRENT'"
& SQLCMD -E -Q "sp_addserver '$env:COMPUTERNAME', local"
}

#RemoteUpgrade
Remove-Item "$CurDir\SquirrelSetup.log" -force -ErrorAction 'silentlycontinue'
cmd /c mklink "$CurDir\SquirrelSetup.log" "$env:TEMP\Setup Log $Date #001.txt"

ForEach ($exe in get-ChildItem "$env:SQCURDIR\Program\*.exe") {
	stop-process -name "$exe" -force -ErrorAction 'silentlycontinue'
}

NET STOP VxAgent /yes
taskkill /f /im VxAgent.exe
taskkill /f /im mmc.exe
NET STOP MSSQLSERVER /yes
taskkill /f /im sqlservr.exe
NET START MSSQLSERVER
Rename-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -name PendingFileRenameOperations -newname PendingFileRenameOperationsBAK -ErrorAction 'silentlycontinue'

$Site = & sqlcmd -d Squirrel -Q "SET NOCOUNT ON; select Name,Address1,Phone from K_Store" -W -h-1

$AlertCountdown = @"
WScript.Sleep 90*60*1000
Set MyEmail = CreateObject("CDO.Message")
MyEmail.Subject="UPGRADE STUCK"
MyEmail.From=
MyEmail.To=
MyEmail.TextBody="RB Upgrade appears to be stuck at $Site. Attempt to get a connection into the site to verify status of upgrade. <T1>6044123308</T1>"
MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2
MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserver") = "in-v3.mailjet.com"
MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 587
MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = 1
MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusername") =
MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendpassword") =
MyEmail.Configuration.Fields.Update
MyEmail.Send
set MyEmail=nothing
"@
$AlertCountdown | Set-Content "$env:TEMP\AlertCountdown.vbs" -Encoding ASCII
Start-Process -FilePath "$env:TEMP\AlertCountdown.vbs" -WindowStyle Hidden

$UpgradeWatchdog = @"
@ECHO OFF
:CHECK
TIMEOUT /T 30 /NOBREAK
TASKKILL /F /IM NET1.EXE
TASKKILL /F /IM LABOUR.EXE
TASKKILL /F /IM LABOUR.TMP
NET START MSSQLSERVER
GOTO CHECK
EXIT
"@
$UpgradeWatchdog | Set-Content "$env:TEMP\UpgradeWatchdog.bat" -Encoding ASCII
Start-Process -FilePath "$env:TEMP\UpgradeWatchdog.bat" -WindowStyle Hidden

Start-Process -FilePath "$CurDir\Software\*RemoteUpgrade*.exe" -ArgumentList "/SILENT /NORESTART /NOCANCEL /CLOSEAPPLICATIONS /NOARCHIVE" -Wait

#TASKKILL /FI "windowtitle eq  Administrator: Upgrade Watchdog*" /F /T 
#TASKKILL /FI "windowtitle eq  Upgrade Watchdog*" /F /T 

#Custom
Start-Sleep -s 5
ForEach ($sql in get-ChildItem "Custom\*.sql") {
	& SQLCMD -E -d SQUIRREL -i "$sql"
}
copy-item "Custom\*.class" "$env:SQCURDIR\Program\Pos\Extended" -force

#HTM
copy-item "Browser\English_Canadian\*" "$env:SQCURDIR\Browser\English_Canadian" -force

#Program
copy-item "Program\*" "$env:SQCURDIR\Program" -force -recurse

#Drivers
copy-item "Drivers\*" "$env:SQCURDIR\Program\Drivers" -force

#Bootptab_Update
stop-process -name "bootpdnt.exe" -force -ErrorAction 'silentlycontinue'
stop-process -name "tftpdnt.exe" -force -ErrorAction 'silentlycontinue'
copy-item "C:\Agent\bootptab*" "$env:SQCURDIR\tftpboot" -force
net start tftpdnt
net start bootpdnt
& SqShutdown -AUTOEXIT
Start-Sleep -s 2

#END
copy-item "+Upgrade_Confirmation_Message.pdf" "c:\agent" -force

Rename-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -name PendingFileRenameOperationsBAK -newname PendingFileRenameOperations -ErrorAction 'silentlycontinue'
$Cleanup = @"
@ECHO OFF
REG COPY "HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinlogonBAK" "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /F
explorer.exe "c:\agent\+Upgrade_Confirmation_Message.pdf"
SCHTASKS /delete /tn RB_Upgrade /f
DEL "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cleanup.bat"
EXIT
"@
$Cleanup | Set-Content "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cleanup.bat" -Encoding ASCII

Start-Sleep -s 2  
& shutdown /r /f /t 05

EXIT


}
& $Script | Out-file "$CurDir\RB_Upgrade.log" -Encoding ASCII