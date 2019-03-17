@echo off

:START
Powershell.exe -executionpolicy remotesigned -File  SetSchedUpgrade.ps1
if "%ERRORLEVEL%" gtr "0" goto ERROR1
goto FIN

:FIN
del /F /Q Autologon.exe
del /F /Q EULA.reg
del /F /Q SetSchedUpgrade.ps1
(goto) 2>nul & del /F /Q "%~f0"

:ERROR1
cls
echo Please wait...
C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -executionpolicy remotesigned -File  SetSchedUpgrade.ps1
if "%ERRORLEVEL%" gtr "0" goto ERROR2
goto FIN

:ERROR2
call :MsgBox "Powershell not found. Check the PATH variable" "vbCritical+vbSystemModal" "%TITLE%"
EXIT

:MsgBox prompt type title
    setlocal enableextensions
    set "tempFile=%temp%\%~nx0.%random%%random%%random%vbs.tmp"
    >"%tempFile%" echo(WScript.Quit msgBox("%~1",%~2,"%~3") & cscript //nologo //e:vbscript "%tempFile%"
    set "exitCode=%errorlevel%" & del "%tempFile%" >nul 2>nul
    endlocal & exit /b %exitCode%