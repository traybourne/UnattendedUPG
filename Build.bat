@echo off
ECHO [Version] > SetSchedUpgrade.SED
ECHO Class=IEXPRESS >> SetSchedUpgrade.SED
ECHO SEDVersion=3 >> SetSchedUpgrade.SED
ECHO [Options] >> SetSchedUpgrade.SED
ECHO PackagePurpose=InstallApp >> SetSchedUpgrade.SED
ECHO ShowInstallProgramWindow=0 >> SetSchedUpgrade.SED
ECHO HideExtractAnimation=0 >> SetSchedUpgrade.SED
ECHO UseLongFileName=1 >> SetSchedUpgrade.SED
ECHO InsideCompressed=0 >> SetSchedUpgrade.SED
ECHO CAB_FixedSize=0 >> SetSchedUpgrade.SED
ECHO CAB_ResvCodeSigning=0 >> SetSchedUpgrade.SED
ECHO RebootMode=N >> SetSchedUpgrade.SED
ECHO InstallPrompt=%%InstallPrompt%% >> SetSchedUpgrade.SED
ECHO DisplayLicense=%%DisplayLicense%% >> SetSchedUpgrade.SED
ECHO FinishMessage=%%FinishMessage%% >> SetSchedUpgrade.SED
ECHO TargetName=%%TargetName%% >> SetSchedUpgrade.SED
ECHO FriendlyName=%%FriendlyName%% >> SetSchedUpgrade.SED
ECHO AppLaunched=%%AppLaunched%% >> SetSchedUpgrade.SED
ECHO PostInstallCmd=%%PostInstallCmd%% >> SetSchedUpgrade.SED
ECHO AdminQuietInstCmd=%%AdminQuietInstCmd%% >> SetSchedUpgrade.SED
ECHO UserQuietInstCmd=%%UserQuietInstCmd%% >> SetSchedUpgrade.SED
ECHO SourceFiles=SourceFiles >> SetSchedUpgrade.SED
ECHO [Strings] >> SetSchedUpgrade.SED
ECHO InstallPrompt= >> SetSchedUpgrade.SED
ECHO DisplayLicense= >> SetSchedUpgrade.SED
ECHO FinishMessage= >> SetSchedUpgrade.SED
ECHO TargetName=C:\Users\%USERNAME%\Documents\GitHub\UnattendedUPG\SetSchedUpgrade.exe >> SetSchedUpgrade.SED
ECHO FriendlyName=Unattended Upgrade >> SetSchedUpgrade.SED
ECHO AppLaunched=cmd /c Launch.bat >> SetSchedUpgrade.SED
ECHO PostInstallCmd=^<None^> >> SetSchedUpgrade.SED
ECHO AdminQuietInstCmd= >> SetSchedUpgrade.SED
ECHO UserQuietInstCmd= >> SetSchedUpgrade.SED
ECHO FILE0="Autologon.exe" >> SetSchedUpgrade.SED
ECHO FILE1="EULA.reg" >> SetSchedUpgrade.SED
ECHO FILE2="Launch.bat" >> SetSchedUpgrade.SED
ECHO FILE3="SetSchedUpgrade.ps1" >> SetSchedUpgrade.SED
ECHO [SourceFiles] >> SetSchedUpgrade.SED
ECHO SourceFiles0=C:\Users\%USERNAME%\Documents\GitHub\UnattendedUPG\ >> SetSchedUpgrade.SED
ECHO [SourceFiles0] >> SetSchedUpgrade.SED
ECHO %%FILE0%%= >> SetSchedUpgrade.SED
ECHO %%FILE1%%= >> SetSchedUpgrade.SED
ECHO %%FILE2%%= >> SetSchedUpgrade.SED
ECHO %%FILE3%%= >> SetSchedUpgrade.SED

C:\Windows\SysWOW64\iexpress.exe /n /q /m SetSchedUpgrade.SED