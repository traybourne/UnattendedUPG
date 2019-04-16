@echo off

Powershell.exe -executionpolicy remotesigned -File  %~dp0\Build.ps1
if "%ERRORLEVEL%" gtr "0" goto Fin
TIMEOUT /T 2 /NOBREAK >NUL 
"C:\Program Files (x86)\NSIS\makensis.exe" %~dp0\Build.nsi
:Fin
Exit