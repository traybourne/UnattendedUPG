@echo off
ECHO [Version] > %TEMP%\SetSchedUpgrade.SED
ECHO Class=IEXPRESS >> %TEMP%\SetSchedUpgrade.SED
ECHO SEDVersion=3 >> %TEMP%\SetSchedUpgrade.SED
ECHO [Options] >> %TEMP%\SetSchedUpgrade.SED
ECHO PackagePurpose=InstallApp >> %TEMP%\SetSchedUpgrade.SED
ECHO ShowInstallProgramWindow=0 >> %TEMP%\SetSchedUpgrade.SED
ECHO HideExtractAnimation=0 >> %TEMP%\SetSchedUpgrade.SED
ECHO UseLongFileName=1 >> %TEMP%\SetSchedUpgrade.SED
ECHO InsideCompressed=0 >> %TEMP%\SetSchedUpgrade.SED
ECHO CAB_FixedSize=0 >> %TEMP%\SetSchedUpgrade.SED
ECHO CAB_ResvCodeSigning=0 >> %TEMP%\SetSchedUpgrade.SED
ECHO RebootMode=N >> %TEMP%\SetSchedUpgrade.SED
ECHO InstallPrompt=%%InstallPrompt%% >> %TEMP%\SetSchedUpgrade.SED
ECHO DisplayLicense=%%DisplayLicense%% >> %TEMP%\SetSchedUpgrade.SED
ECHO FinishMessage=%%FinishMessage%% >> %TEMP%\SetSchedUpgrade.SED
ECHO TargetName=%%TargetName%% >> %TEMP%\SetSchedUpgrade.SED
ECHO FriendlyName=%%FriendlyName%% >> %TEMP%\SetSchedUpgrade.SED
ECHO AppLaunched=%%AppLaunched%% >> %TEMP%\SetSchedUpgrade.SED
ECHO PostInstallCmd=%%PostInstallCmd%% >> %TEMP%\SetSchedUpgrade.SED
ECHO AdminQuietInstCmd=%%AdminQuietInstCmd%% >> %TEMP%\SetSchedUpgrade.SED
ECHO UserQuietInstCmd=%%UserQuietInstCmd%% >> %TEMP%\SetSchedUpgrade.SED
ECHO SourceFiles=SourceFiles >> %TEMP%\SetSchedUpgrade.SED
ECHO [Strings] >> %TEMP%\SetSchedUpgrade.SED
ECHO InstallPrompt= >> %TEMP%\SetSchedUpgrade.SED
ECHO DisplayLicense= >> %TEMP%\SetSchedUpgrade.SED
ECHO FinishMessage= >> %TEMP%\SetSchedUpgrade.SED
ECHO TargetName=%~dp0\SetSchedUpgrade.exe >> %TEMP%\SetSchedUpgrade.SED
ECHO FriendlyName=Unattended Upgrade >> %TEMP%\SetSchedUpgrade.SED
ECHO AppLaunched=cmd /c Launch.bat >> %TEMP%\SetSchedUpgrade.SED
ECHO PostInstallCmd=^<None^> >> %TEMP%\SetSchedUpgrade.SED
ECHO AdminQuietInstCmd= >> %TEMP%\SetSchedUpgrade.SED
ECHO UserQuietInstCmd= >> %TEMP%\SetSchedUpgrade.SED
ECHO FILE0="Autologon.exe" >> %TEMP%\SetSchedUpgrade.SED
ECHO FILE1="EULA.reg" >> %TEMP%\SetSchedUpgrade.SED
ECHO FILE2="Launch.bat" >> %TEMP%\SetSchedUpgrade.SED
ECHO FILE3="SetSchedUpgrade.ps1" >> %TEMP%\SetSchedUpgrade.SED
ECHO [SourceFiles] >> %TEMP%\SetSchedUpgrade.SED
ECHO SourceFiles0=%~dp0\ >> %TEMP%\SetSchedUpgrade.SED
ECHO [SourceFiles0] >> %TEMP%\SetSchedUpgrade.SED
ECHO %%FILE0%%= >> %TEMP%\SetSchedUpgrade.SED
ECHO %%FILE1%%= >> %TEMP%\SetSchedUpgrade.SED
ECHO %%FILE2%%= >> %TEMP%\SetSchedUpgrade.SED
ECHO %%FILE3%%= >> %TEMP%\SetSchedUpgrade.SED

C:\Windows\SysWOW64\iexpress.exe /n /q /m %TEMP%\SetSchedUpgrade.SED