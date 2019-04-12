;--------------------------------
!include x64.nsh

; The name of the installer
Name "UnattendedUPG"

; The file to write
OutFile "SetSchedUpgrade.exe"

; The default installation directory
InstallDir $EXEDIR

Icon .\Icon.ico

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
;InstallDirRegKey HKLM "Software\NSIS_Example2" "Install_Dir"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

SilentInstall silent

; The stuff to install
Section "Execute"

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR

File .\Autologon.exe
File .\Launch.bat
File .\SetSchedUpgrade.ps1
File .\RB_Upgrade.ps1
  
${If} ${RunningX64}
Exec '"C:\Windows\sysnative\cmd.exe" /c "$INSTDIR\Launch.bat"'
${Else}
Exec '"$INSTDIR\Launch.bat"'
${EndIf}  
  
SectionEnd