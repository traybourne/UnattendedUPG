@echo off

Powershell.exe -executionpolicy remotesigned -File  %~dp0\Build.ps1
TIMEOUT /T 2 /NOBREAK >NUL 
"C:\Program Files (x86)\NSIS\makensis.exe" %~dp0\Build.nsi