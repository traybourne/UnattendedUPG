:::::::::::::::::::::::::::::::::::::::::::::::::::
::            UNATTENDED RB INSTALL              ::
:::::::::::::::::::::::::::::::::::::::::::::::::::


@ECHO OFF

SET "TITLE=UNATTENDED RB INSTALL"
@TITLE %TITLE%
COLOR 1F

IF /I "%1" == "silent" goto PreUpgrade_Backup

call :MsgBox "This will stop Host Service and perform automated Reachback Upgrade - Continue?" "vbInformation+vbYesNo+vbSystemModal" "%TITLE%"
    if errorlevel 7 (
        echo NO
	GOTO ERROR
    ) else if errorlevel 6 (
        echo YES
    )

:PreUpgrade_Backup
sqlcmd -E -Q "Restore log Squirrel with Recovery" >NUL
sqlcmd -E -Q "Restore log SquirrelCRM with Recovery" >NUL
for /f "usebackq" %%i in (`PowerShell $date ^= Get-Date^; $date ^= $date.AddDays^(0^)^; $date.ToString^('yyyy-MM-dd'^)`) do set date=%%i

mkdir "C:\Agent\upgrade backups\%date%\databasebackups"

cls
echo BACKING UP DATABASES...

SqlCmd -E -S %computername% -Q "BACKUP DATABASE [Squirrel] TO DISK='C:\Agent\upgrade backups\%date%\databasebackups\pre-upgrade sqbackup.bak'"

cls
echo ZIPPING UP DATABASES...

if exist "C:\Agent\upgrade backups\%date%\databasebackups\databasebackups.zip" del "C:\Agent\upgrade backups\%date%\databasebackups\databasebackups.zip"

zip -j -r "C:\Agent\upgrade backups\%date%\databasebackups\databasebackups.zip" "C:\Agent\upgrade backups\%date%\databasebackups"

del "C:\Agent\upgrade backups\%date%\databasebackups\*.bak"

cls
echo BACKING UP SQUIRREL FILES...

xcopy /Y /E C:\Squirrel\Browser\*.* "C:\Agent\upgrade backups\%date%\Squirrel\Browser\" >NUL
xcopy /Y /E C:\Squirrel\Custom\*.* "C:\Agent\upgrade backups\%date%\Squirrel\Custom\" >NUL
xcopy /Y /E C:\Squirrel\etc\*.* "C:\Agent\upgrade backups\%date%\Squirrel\etc\" >NUL
xcopy /Y /E C:\Squirrel\Host\*.* "C:\Agent\upgrade backups\%date%\Squirrel\Host\" >NUL
xcopy /Y /E C:\Squirrel\Posdata\*.* "C:\Agent\upgrade backups\%date%\Squirrel\Posdata\" >NUL
xcopy /Y /E C:\Squirrel\Program\*.* "C:\Agent\upgrade backups\%date%\Squirrel\Program\" >NUL
xcopy /Y /E C:\Squirrel\tftpboot\*.* "C:\Agent\upgrade backups\%date%\Squirrel\tftpboot\" >NUL
xcopy /Y /E C:\Squirrel\X11R6\lib\X11\XF86Config "C:\Agent\upgrade backups\%date%\Squirrel\X11R6\lib\X11\" >NUL
copy C:\Squirrel\Browser\English_Canadian\*rptCustom.htm "%~dp0\Browser\English_Canadian\*rptCustom.htm" >NUL
copy C:\Squirrel\Browser\English_Canadian\*Optional.htm "%~dp0\Browser\English_Canadian\*Optional.htm" >NUL

cls
echo ZIPPING UP SQUIRREL FILES...

if exist "C:\Agent\upgrade backups\%date%\Squirrel.zip" del "C:\Agent\upgrade backups\%date%\Squirrel.zip"

cd /d "C:\Agent\upgrade backups\%date%\"
zip -r Squirrel.zip Squirrel >NUL

rmdir "C:\Agent\upgrade backups\%date%\Squirrel" /s /q

cls

CD /D "%~dp0\SOFTWARE"

if ERRORLEVEL 1 goto ERROR2

:Bootptab_Backup
mkdir "C:\Agent"
COPY /Y "%SQCURDIR%\tftpboot\bootptab*.*" "C:\Agent"

:SQL_Rename
FOR /F "delims= " %%i in ('SQLCMD -E -Q "sp_helpserver" ^| findstr "[0-9]"') do (SET "SQL_CURRENT=%%i")
IF /I "%SQL_CURRENT%"=="%COMPUTERNAME%" goto RemoteUpgrade
SQLCMD -E -Q "sp_dropserver '%SQL_CURRENT%'"
SQLCMD -E -Q "sp_addserver '%COMPUTERNAME%', local"

:RemoteUpgrade
FOR /F "delims=" %%i IN ('dir /b /a /s "%SQCURDIR%" ^| findstr /e "exe"') DO (taskkill /f /im "%%~nxi")

NET STOP VxAgent /yes
TASKKILL /F /T /FI "SERVICES eq VxAgent"
TASKKILL /F /IM mmc.exe
NET STOP MSSQLSERVER /yes
TASKKILL /F /T /FI "SERVICES eq MSSQLSERVER"
NET START MSSQLSERVER
powershell.exe -Command "Rename-ItemProperty -path "'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'" -name PendingFileRenameOperations -newname PendingFileRenameOperationsBAK" >NUL

FOR /F "tokens=* usebackq" %%i in (`sqlcmd -d Squirrel -Q "SET NOCOUNT ON; select Name,Address1,Phone from K_Store" -W -h-1`) do set Site=%%i

ECHO WScript.Sleep 90*60*1000		> "%TEMP%\AlertCountdown.vbs"
ECHO Set MyEmail = CreateObject("CDO.Message")		>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Subject="UPGRADE STUCK"	>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.From="sqcorpservices@gmail.com"	>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.To="rdavis@squirrelsystems.com"	>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.TextBody="RB Upgrade appears to be stuck at %Site%. Attempt to get a connection into the site to verify status of upgrade. <T1>6044123308</T1>"		>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2			>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserver") = "in-v3.mailjet.com"		>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 587			>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = 1			>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusername") = "474901cc35fecf00d8fe6368edbe1160"			>> "%TEMP%\AlertCountdown.vbs"
ECHO MyEmail.Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendpassword") = "438a427b7f9a73cecd35cb82b52cc5b2"			>> "%TEMP%\AlertCountdown.vbs"
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

if exist "%~dp0\SquirrelSetup.log" del "%~dp0\SquirrelSetup.log"
mklink "%~dp0\SquirrelSetup.log" "%TEMP%\Setup Log %Date% #001.txt"
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

:MsgBox prompt type title
    setlocal enableextensions
    set "tempFile=%temp%\%~nx0.%random%%random%%random%vbs.tmp"
    >"%tempFile%" echo(WScript.Quit msgBox("%~1",%~2,"%~3") & cscript //nologo //e:vbscript "%tempFile%"
    set "exitCode=%errorlevel%" & del "%tempFile%" >nul 2>nul
    endlocal & exit /b %exitCode%
