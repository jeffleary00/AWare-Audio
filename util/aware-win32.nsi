; example1.nsi
;
; This script is perhaps one of the simplest NSIs you can make. All of the
; optional settings are left to their default settings. The installer simply 
; prompts the user asking them where to install, and drops a copy of example1.nsi
; there. 

;--------------------------------

; The name of the installer
Name "aware-win32"

; The file to write
OutFile "aware-win32.exe"

; The default installation directory
InstallDir $PROGRAMFILES\AWare Audio

; Request application privileges for Windows Vista
RequestExecutionLevel user

;--------------------------------

; Pages

Page directory
Page instfiles

;--------------------------------

; The stuff to install
Section "" ;No components page, name is not important

  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put file there
  File example1.nsi
  
SectionEnd ; end the section


;--------------------------------

; Uninstaller

UninstallText "This will uninstall AWare Audio. Hit next to continue."
Section "Uninstall"

  Delete "$INSTDIR\AWare.exe"
  Delete "$INSTDIR\AWARELIB.EXE"
  Delete "$SMPROGRAMS\AWare Audio\*.*"
  RMDir "$SMPROGRAMS\AWare Audio"
  
  MessageBox MB_YESNO|MB_ICONQUESTION "Would you like to remove the directory $INSTDIR\cpdest?" IDNO NoDelete
    Delete "$INSTDIR\cpdest\*.*"
    RMDir "$INSTDIR\cpdest" ; skipped if no
  NoDelete:
  
  RMDir "$INSTDIR\MyProjectFamily\MyProject"
  RMDir "$INSTDIR\MyProjectFamily"
  RMDir "$INSTDIR"

  IfFileExists "$INSTDIR" 0 NoErrorMsg
    MessageBox MB_OK "Note: $INSTDIR could not be removed!" IDOK 0 ; skipped if file doesn't exist
  NoErrorMsg:

SectionEnd