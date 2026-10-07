#ifndef AppVersion
  #error AppVersion must be supplied by the build script
#endif
#ifndef ExportDir
  #error ExportDir must be supplied by the build script
#endif
#ifndef OutputDir
  #error OutputDir must be supplied by the build script
#endif
#ifndef IconFile
  #error IconFile must be supplied by the build script
#endif

[Setup]
AppId={{D0B92D83-A991-4A70-9873-53EF2C01D5B2}
AppName=Astra 3D Car Game V2
AppVersion={#AppVersion}
AppPublisher=hussnainahmedd
AppPublisherURL=https://github.com/hussnainahmedd/astra-3d-car-game-v2
AppSupportURL=https://github.com/hussnainahmedd/astra-3d-car-game-v2/issues
DefaultDirName={localappdata}\Programs\Astra 3D Car Game V2
DefaultGroupName=Astra 3D Car Game V2
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64os
ArchitecturesInstallIn64BitMode=x64os
OutputDir={#OutputDir}
OutputBaseFilename=Astra-3D-Car-Game-V2-Windows-x64-Setup
SetupIconFile={#IconFile}
UninstallDisplayIcon={app}\Astra-3D-Car-Game-V2.exe
LicenseFile={#ExportDir}\LICENSE.game.txt
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Files]
Source: "{#ExportDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Astra 3D Car Game V2"; Filename: "{app}\Astra-3D-Car-Game-V2.exe"; WorkingDir: "{app}"
Name: "{group}\Uninstall Astra 3D Car Game V2"; Filename: "{uninstallexe}"
Name: "{userdesktop}\Astra 3D Car Game V2"; Filename: "{app}\Astra-3D-Car-Game-V2.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\Astra-3D-Car-Game-V2.exe"; Description: "Play Astra 3D Car Game V2"; Flags: nowait postinstall skipifsilent

; User progress is outside {app}; upgrades and uninstall leave it intact.
