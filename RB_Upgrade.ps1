$Silent = $args[0]

Function MsgBox($Message, $Type, $Title)
{
   [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
   [Microsoft.VisualBasic.Interaction]::MsgBox($Message, "SystemModal, $Type", $Title)
}

$CurDir = (Split-Path $MyInvocation.Mycommand.Path)

if ($Silent -ne "silent") {
$Prompt = MsgBox "This will stop Host Service and perform automated Reachback Upgrade - Continue?" "YesNo" "Unattended Upgrade"
switch ($Prompt) {
    "No" { EXIT }
}}

#PreUpgrade_Backup
& sqlcmd -E -Q "Restore log Squirrel with Recovery" 2>$null
& sqlcmd -E -Q "Restore log SquirrelCRM with Recovery" 2>$null
$Date = Get-Date -Format "yyyy-MM-dd"

new-item "C:\Agent\upgrade backups\$Date\databasebackups" -type directory -force

Write-Host BACKING UP DATABASES...

& SqlCmd -E -Q "BACKUP DATABASE [Squirrel] TO DISK='C:\Agent\upgrade backups\`"$Date`"\databasebackups\pre-upgrade sqbackup.bak'"

Write-Host ZIPPING UP DATABASES...

Remove-Item "C:\Agent\upgrade backups\$Date\databasebackups\databasebackups.zip" -force -ErrorAction 'silentlycontinue'

& zip -j -r "C:\Agent\upgrade backups\$Date\databasebackups\databasebackups.zip" "C:\Agent\upgrade backups\$Date\databasebackups"

Remove-Item "C:\Agent\upgrade backups\$Date\databasebackups\*.bak" -Force

Write-Host BACKING UP SQUIRREL FILES...

copy-item "C:\\Squirrel\\Browser" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
copy-item "C:\\Squirrel\\Custom" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
copy-item "C:\\Squirrel\\etc" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
copy-item "C:\\Squirrel\\Host" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
copy-item "C:\\Squirrel\\Posdata" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
copy-item "C:\\Squirrel\\Program" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
copy-item "C:\\Squirrel\\tftpboot" "C:\\Agent\\upgrade backups\\$Date\\Squirrel" -force -recurse
new-item "C:\\Agent\\upgrade backups\\$Date\\Squirrel\\X11R6\\lib\\X11\" -type directory -force
copy-item "C:\\Squirrel\\X11R6\\lib\\X11\\XF86Config" "C:\\Agent\\upgrade backups\\$Date\\Squirrel\\X11R6\\lib\\X11\" -force
new-item "$CurDir\\Software\\Browser\\English_Canadian" -type directory -force
copy-item "C:\\Squirrel\\Browser\\English_Canadian\\*rptCustom.htm" "$CurDir\\Software\\Browser\\English_Canadian" -force
copy-item "C:\\Squirrel\\Browser\\English_Canadian\\*Optional.htm" "$CurDir\\Software\\Browser\\English_Canadian" -force

Write-Host ZIPPING UP SQUIRREL FILES...

Remove-Item "C:\Agent\upgrade backups\$Date\Squirrel.zip" -force -ErrorAction 'silentlycontinue'

CD "C:\Agent\upgrade backups\$Date"

& zip -r "Squirrel.zip" "Squirrel" >$null

Remove-Item –path "C:\Agent\upgrade backups\$Date\Squirrel" –recurse -force

CD "$CurDir\Software"
#if ERRORLEVEL 1 goto ERROR2

#Bootptab_Backup
new-item "C:\\Agent" -type directory -force
copy-item "%SQCURDIR%\tftpboot\bootptab*.*" "C:\Agent" -force

#SQL_Rename
#FOR /F "delims= " %%i in ('SQLCMD -E -Q "sp_helpserver" ^| findstr "[0-9]"') do (SET "SQL_CURRENT=%%i")
#IF /I "%SQL_CURRENT%"=="%COMPUTERNAME%" goto RemoteUpgrade
#SQLCMD -E -Q "sp_dropserver '%SQL_CURRENT%'"
#SQLCMD -E -Q "sp_addserver '%COMPUTERNAME%', local"

#RemoteUpgrade
Remove-Item –path "SquirrelSetup.log" -force -ErrorAction 'silentlycontinue'
cmd /c mklink "SquirrelSetup.log" "%TEMP%\Setup Log $Date #001.txt"
#FOR /F "delims=" %%i IN ('dir /b /a /s "%SQCURDIR%" ^| findstr /e "exe"') DO (taskkill /f /im "%%~nxi")
ForEach ($exe in get-ChildItem "$env:SQCURDIR\Squirrel\*.exe") {
	stop-process -name "$exe" -force
}

NET STOP VxAgent
stop-process -name VxAgent.exe -force
stop-process -name mmc.exe -force
NET STOP MSSQLSERVER
stop-process -name sqlservr.exe -force
NET START MSSQLSERVER
Rename-ItemProperty -path "'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'" -name PendingFileRenameOperations -newname PendingFileRenameOperationsBAK -ErrorAction 'silentlycontinue'

#FOR /F "tokens=* usebackq" %%i in (`sqlcmd -d Squirrel -Q "SET NOCOUNT ON; select Name,Address1,Phone from K_Store" -W -h-1`) do set Site=%%i

ECHO WScript.Sleep 90*60*1000		> "%TEMP%\AlertCountdown.vbs"
ECHO Set MyEmail = CreateObject("CDO.Message")		>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Subject="UPGRADE STUCK"	>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.From= "sqcorpservices@gmail.com"	>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.To= "rdavis@squirrelsystems.com"	>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.TextBody="RB Upgrade appears to be stuck at %Site%. Attempt to get a connection into the site to verify status of upgrade. <T1>6044123308</T1>"		>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2			>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserver") = "in-v3.mailjet.com"		>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 587			>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = 1			>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusername") =  "474901cc35fecf00d8fe6368edbe1160"			>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendpassword") =  "7265c3e68a5d59d6e3411a1d8a597576"			>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Configuration.Fields.Update			>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Send			>> "%TEMP%\AlertCountdown.vbs"
ECHO set MyEmail=nothing			>> "%TEMP%\AlertCountdown.vbs"
START /min "Alert Countdown" "%TEMP%\AlertCountdown.vbs"

ECHO @ECHO OFF			> "%TEMP%\UpgradeWatchdog.bat"
ECHO :CHECK			>> "%TEMP%\UpgradeWatchdog.bat"
ECHO TIMEOUT /T 30 /NOBREAK	>> "%TEMP%\UpgradeWatchdog.bat"
ECHO TASKKILL /F /IM NET1.EXE	>> "%TEMP%\UpgradeWatchdog.bat"
ECHO TASKKILL /F /IM LABOUR.EXE	>> "%TEMP%\UpgradeWatchdog.bat"
ECHO TASKKILL /F /IM LABOUR.TMP	>> "%TEMP%\UpgradeWatchdog.bat"
ECHO NET START MSSQLSERVER	>> "%TEMP%\UpgradeWatchdog.bat"
ECHO GOTO CHECK			>> "%TEMP%\UpgradeWatchdog.bat"
ECHO EXIT			>> "%TEMP%\UpgradeWatchdog.bat"
START /min "Upgrade Watchdog" "%TEMP%\UpgradeWatchdog.bat"

FOR /F %%i IN ('dir /b ^| find /i "RemoteUpgrade"') DO (%%i SP- /SILENT /NORESTART /NOCANCEL /CLOSEAPPLICATIONS /NOARCHIVE)

TASKKILL /FI "windowtitle eq  Administrator: Upgrade Watchdog*" /F /T 
TASKKILL /FI "windowtitle eq  Upgrade Watchdog*" /F /T 

:Custom
TIMEOUT /T 5 /NOBREAK >NUL
FOR /F "DELIMS=" %%i IN ('DIR /B /S Custom ^| findstr /e "sql"') DO (SQLCMD -E -d SQUIRREL -i "%%i")
COPY /Y "Custom\*.class" "%SQCURDIR%\Program\Pos\Extended\*.class"

:HTM
COPY /Y "Browser\English_Canadian\*.*" "%SQCURDIR%\Browser\English_Canadian\*.*"

:Program
COPY /Y "Program\*.*" "%SQCURDIR%\Program\*.*"

:Drivers
COPY /Y "Drivers\*.*" "%SQCURDIR%\Program\Drivers\*.*"

:Bootptab_Update
taskkill /f /im "bootpdnt.exe"
taskkill /f /im "tftpdnt.exe"
COPY /Y "C:\Agent\bootptab*.*" "%SQCURDIR%\tftpboot"
net start tftpdnt
net start bootpdnt
SqShutdown -AUTOEXIT
TIMEOUT /T 2 /NOBREAK >NUL 

:END
COPY "+Upgrade_Confirmation_Message.pdf" c:\agent /y

powershell.exe -Command "Rename-ItemProperty -path "'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'" -name PendingFileRenameOperationsBAK -newname PendingFileRenameOperations" >NUL
ECHO @ECHO OFF			> "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cleanup.bat"
ECHO REG COPY "HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinlogonBAK" "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /F >> "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cleanup.bat"
ECHO explorer.exe "c:\agent\+Upgrade_Confirmation_Message.pdf" >> "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cleanup.bat"
ECHO SCHTASKS /delete /tn RB_Upgrade /f >> "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cleanup.bat"
ECHO DEL "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cleanup.bat" >> "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cleanup.bat"
ECHO EXIT >> "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Cleanup.bat"

TIMEOUT /T 2 /NOBREAK >NUL    
shutdown /r /f /t 05

EXIT

:ERROR
call :MsgBox "Reachback Upgrade cancelled" "vbCritical+vbSystemModal" "%TITLE%"
EXIT

:ERROR2
call :MsgBox "ERROR OCCURRED - PLEASE ENSURE FILES HAVE BEEN EXTRACTED" "vbCritical+vbSystemModal" "%TITLE%"
EXIT

