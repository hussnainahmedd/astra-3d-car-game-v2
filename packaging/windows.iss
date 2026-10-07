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
AppName=RoadShift
AppVersion={#AppVersion}
AppPublisher=hussnainahmedd
AppPublisherURL=https://github.com/hussnainahmedd/astra-3d-car-game-v2
AppSupportURL=https://github.com/hussnainahmedd/astra-3d-car-game-v2/issues
DefaultDirName={localappdata}\Programs\RoadShift
DefaultGroupName=RoadShift
UsePreviousGroup=no
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64os
ArchitecturesInstallIn64BitMode=x64os
OutputDir={#OutputDir}
OutputBaseFilename=RoadShift-Setup-Windows-x64
SetupIconFile={#IconFile}
UninstallDisplayIcon={app}\RoadShift.exe
LicenseFile={#ExportDir}\LICENSE.game.txt
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Files]
Source: "{#ExportDir}\RoadShift.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ExportDir}\RoadShift.pck"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ExportDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#ExportDir}\LICENSE.game.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ExportDir}\LICENSE.godot.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ExportDir}\COPYRIGHT.godot.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ExportDir}\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ExportDir}\PLAYING.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ExportDir}\BUILD_INFO.json"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\RoadShift"; Filename: "{app}\RoadShift.exe"; WorkingDir: "{app}"
Name: "{group}\Uninstall RoadShift"; Filename: "{uninstallexe}"
Name: "{userdesktop}\RoadShift"; Filename: "{app}\RoadShift.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\RoadShift.exe"; Description: "Play RoadShift"; Flags: nowait postinstall skipifsilent

; User progress is outside {app}; upgrades and uninstall leave it intact.
