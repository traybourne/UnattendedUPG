$Silent = $args[0]
$CurDir = (Split-Path $MyInvocation.Mycommand.Path)
$Site = & sqlcmd -d Squirrel -Q "SET NOCOUNT ON; select Name,Address1,Phone from K_Store" -W -h-1
$Cancel = {
MsgBox "Reachback Upgrade cancelled" "Critical" "Unattended Upgrade"
EXIT
}
$FAIL = {
$Alert = @"
WScript.Sleep 10*1000
Set MyEmail = CreateObject("CDO.Message")
MyEmail.Subject="UPGRADE FAILED"
MyEmail.From=
MyEmail.To=
MyEmail.TextBody="RB Upgrade appears to have failed at $Site, log files are attached. Attempt to get a connection into the site to verify status of upgrade. <T1>6044123308</T1>"
MyEmail.AddAttachment "$CurDir\RB_Upgrade.log"
MyEmail.AddAttachment "$CurDir\RB_UpgradeTrace.log"
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
Start-Sleep -s 2
Start-Process -FilePath "$env:TEMP\Alert.vbs"
EXIT
}

Remove-Item "$CurDir\RB_UpgradeTrace.log" -Force -ErrorAction 'silentlycontinue'
$Script = {
Function MsgBox($Message, $Type, $Title)
{
   [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
   [Microsoft.VisualBasic.Interaction]::MsgBox($Message, "SystemModal, $Type", $Title)
}

if ($Silent -ne "silent") {
$Prompt = MsgBox "This will stop Host Service and perform automated Reachback Upgrade - Continue?" "YesNo" "Unattended Upgrade"
switch ($Prompt) {
    "No" { & $Cancel }
}}

#PreUpgrade_Backup
& sqlcmd -E -Q "Restore log Squirrel with Recovery" >$null
& sqlcmd -E -Q "Restore log SquirrelCRM with Recovery" >$null
$Date = Get-Date -Format "yyyy-MM-dd"

New-Item "C:\Agent\upgrade backups\$Date\databasebackups" -type directory -force

Write-Output "BACKING UP DATABASES..."

& SqlCmd -E -Q "BACKUP DATABASE [Squirrel] TO DISK='C:\Agent\upgrade backups\$Date\databasebackups\pre-upgrade sqbackup.bak'"

Write-Output "ZIPPING UP DATABASES..."

Remove-Item "C:\Agent\upgrade backups\$Date\databasebackups\databasebackups.zip" -Force -ErrorAction 'silentlycontinue'

& zip -j -r "C:\Agent\upgrade backups\$Date\databasebackups\databasebackups.zip" "C:\Agent\upgrade backups\$Date\databasebackups"

Remove-Item "C:\Agent\upgrade backups\$Date\databasebackups\*.bak" -Force

Write-Output "BACKING UP SQUIRREL FILES..."

Copy-Item "C:\\Squirrel\\Browser" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
Copy-Item "C:\\Squirrel\\Custom" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse -ErrorAction 'silentlycontinue'
Copy-Item "C:\\Squirrel\\etc" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
Copy-Item "C:\\Squirrel\\Host" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse -ErrorAction 'silentlycontinue'
Copy-Item "C:\\Squirrel\\Posdata" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
Copy-Item "C:\\Squirrel\\Program" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
Copy-Item "C:\\Squirrel\\tftpboot" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
New-Item "C:\\Agent\\upgrade backups\\$Date\\Squirrel\\X11R6\\lib\\X11\" -type directory -force
Copy-Item "C:\\Squirrel\\X11R6\\lib\\X11\\XF86Config" "C:\\Agent\\upgrade backups\\$Date\\Squirrel\\X11R6\\lib\\X11\" -force
New-Item "$CurDir\\Software\\Browser\\English_Canadian" -type directory -force
Copy-Item "C:\\Squirrel\\Browser\\English_Canadian\\*rptCustom.htm" "$CurDir\\Software\\Browser\\English_Canadian" -force
Copy-Item "C:\\Squirrel\\Browser\\English_Canadian\\*Optional.htm" "$CurDir\\Software\\Browser\\English_Canadian" -force

Write-Output "ZIPPING UP SQUIRREL FILES..."

Remove-Item "C:\Agent\upgrade backups\$Date\Squirrel.zip" -force -ErrorAction 'silentlycontinue'

CD "C:\Agent\upgrade backups\$Date"

& zip -r "Squirrel.zip" "Squirrel" >$null

Remove-Item "C:\Agent\upgrade backups\$Date\Squirrel" -recurse -force

if (-not (Test-Path "$CurDir\Software\*RemoteUpgrade*.exe")) { & $FAIL }
CD "$CurDir\Software"

#Bootptab_Backup
New-Item "C:\\Agent" -type directory -force
Copy-Item "$env:SQCURDIR\tftpboot\bootptab*.*" "C:\Agent" -force

#SQL_Rename
Write-Output "CHECKING IF SQL NAME MATCHES PC NAME..."
$SQL_CURRENT = & sqlcmd -E -Q "SET NOCOUNT ON; select @@SERVERNAME" -W -h-1
if ($SQL_CURRENT -ne $env:COMPUTERNAME) {
& SQLCMD -E -Q "sp_dropserver '$SQL_CURRENT'"
& SQLCMD -E -Q "sp_addserver '$env:COMPUTERNAME', local"
}

#RemoteUpgrade
Remove-Item "$CurDir\SquirrelSetup.log" -force -ErrorAction 'silentlycontinue'
cmd /c mklink "$CurDir\SquirrelSetup.log" "$env:TEMP\Setup Log $Date #001.txt"

Write-Output "KILLING ALL SQUIRREL PROCESSES..."
ForEach ($exe in get-ChildItem "$env:SQCURDIR\Program" -Filter *.exe) {
	$name = [io.path]::GetFileNameWithoutExtension("$exe")
	Stop-Process -Name "$name" -Force -ErrorAction 'silentlycontinue'
}

NET STOP VxAgent /yes
Stop-Process -Name "VxAgent" -Force -ErrorAction 'silentlycontinue'
Stop-Process -Name "java" -Force -ErrorAction 'silentlycontinue'
Stop-Process -Name "javaw" -Force -ErrorAction 'silentlycontinue'
Stop-Process -Name "mmc" -Force -ErrorAction 'silentlycontinue'
NET STOP MSSQLSERVER /yes
Stop-Process -Name "sqlservr" -Force -ErrorAction 'silentlycontinue' sqlservr.exe
NET START MSSQLSERVER
Rename-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -name PendingFileRenameOperations -newname PendingFileRenameOperationsBAK -ErrorAction 'silentlycontinue'

$AlertCountdown = @"
WScript.Sleep 90*60*1000
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set MyEmail = CreateObject("CDO.Message")
objFSO.CopyFile "$CurDir\RB_Upgrade.log", "$CurDir\_RB_Upgrade.log"
objFSO.CopyFile "$CurDir\RB_UpgradeTrace.log", "$CurDir\_RB_UpgradeTrace.log"
MyEmail.Subject="UPGRADE STUCK"
MyEmail.From=
MyEmail.To=
MyEmail.TextBody="RB Upgrade appears to be stuck at $Site, log files are attached. Attempt to get a connection into the site to verify status of upgrade. <T1>6044123308</T1>"
MyEmail.AddAttachment "$CurDir\_RB_Upgrade.log"
MyEmail.AddAttachment "$CurDir\_RB_UpgradeTrace.log"
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

Write-Output "RUNNING REMOTE UPGRADE..."
$p = Start-Process -passthru "$CurDir\Software\*RemoteUpgrade*.exe" -ArgumentList "/SILENT /NORESTART /NOCANCEL /CLOSEAPPLICATIONS /NOARCHIVE"
$p.WaitForExit()

#TASKKILL /FI "windowtitle eq  Administrator: Upgrade Watchdog*" /F /T 
#TASKKILL /FI "windowtitle eq  Upgrade Watchdog*" /F /T 

#Custom
Write-Output "INSTALLING ANY CUSTOM PIECES AND OPTIONAL MODULES FOUND..."
Start-Sleep -s 5
ForEach ($sql in get-ChildItem "Custom\*.sql") {
	& SQLCMD -E -d SQUIRREL -i "$sql"
}
Copy-Item "Custom\*.class" "$env:SQCURDIR\Program\Pos\Extended" -force

#HTM
Copy-Item "Browser\English_Canadian\*" "$env:SQCURDIR\Browser\English_Canadian" -force

#Program
Copy-Item "Program\*" "$env:SQCURDIR\Program" -force -recurse

#Drivers
Copy-Item "Drivers\*" "$env:SQCURDIR\Program\Drivers" -force

#Bootptab_Update
Stop-Process -Name "bootpdnt" -Force -ErrorAction 'silentlycontinue'
Stop-Process -Name "tftpdnt" -Force -ErrorAction 'silentlycontinue'
Copy-Item "C:\Agent\bootptab*" "$env:SQCURDIR\tftpboot" -force
net start tftpdnt
net start bootpdnt
Start-Process -FilePath "SqShutdown.exe" -ArgumentList "-AUTOEXIT"
Start-Sleep -s 3

#END
Write-Output "CREATING CLEANUP SCRIPT AND REBOOTING PC..."
Copy-Item "+Upgrade_Confirmation_Message.pdf" "c:\agent" -force

Rename-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -name PendingFileRenameOperationsBAK -newname PendingFileRenameOperations -ErrorAction 'silentlycontinue'
$Cleanup = @"
@ECHO OFF
REG COPY "HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinlogonBAK" "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /F
REG DELETE "HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinlogonBAK" /F
explorer.exe "c:\agent\+Upgrade_Confirmation_Message.pdf"
SCHTASKS /delete /tn RB_Upgrade /f
DEL "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cleanup.bat"
EXIT
"@
$Cleanup | Set-Content "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cleanup.bat" -Encoding ASCII

Start-Sleep -s 2

Start-Process -FilePath "shutdown.exe" -ArgumentList "/r /f /t 05"

EXIT
}

Trace-Command ParameterBinding {& $Script 2>&1 > "$CurDir\RB_Upgrade.log"} -PSHost -FilePath "$CurDir\RB_UpgradeTrace.log" -Option ExecutionFlow
