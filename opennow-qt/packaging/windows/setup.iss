; First-install copier for the portable Stillforce tree.
; This is not the updater. It does not write a Windows Installer
; ProductCode, UpgradeCode, or InstallLocation.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef Arch
  #define Arch "x64"
#endif
#ifndef Payload
  #error Compile with /DPayload pointing at the portable ZIP layout
#endif
#ifndef DestinationConflictMessage
  #error Compile with /DDestinationConflictMessage from locales/en.json
#endif

#define AppName "Stillforce"
#define AppExeName "Stillforce.exe"
#define AppPublisher "Stillforce"

[Setup]
AppId={{CE212346-55BF-504D-94C8-A8C6BF6C68F2}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={localappdata}\Stillforce
DisableDirPage=no
AppendDefaultDirName=yes
AllowRootDirectory=no
UsePreviousAppDir=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputBaseFilename=Stillforce-setup
OutputDir=output
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed={#Arch}
ArchitecturesInstallIn64BitMode={#Arch}
UninstallDisplayIcon={app}\bin\{#AppExeName}
SetupIconFile=..\icons\OpenNOW.ico
LicenseFile=..\..\..\LICENSE
ChangesAssociations=no
ChangesEnvironment=no
CloseApplications=yes
UsedUserAreasWarning=no

[Files]
Source: "{#Payload}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\bin\{#AppExeName}"; WorkingDir: "{app}\bin"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\bin\{#AppExeName}"; WorkingDir: "{app}\bin"; Tasks: desktopicon

[Run]
Filename: "{app}\bin\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: dirifempty; Name: "{app}\bin"
Type: dirifempty; Name: "{app}\plugins"
Type: dirifempty; Name: "{app}\qml"
Type: dirifempty; Name: "{app}\share"
Type: dirifempty; Name: "{app}\translations"
Type: dirifempty; Name: "{app}"

[Code]
function DestinationError(Directory: String): String;
begin
  Result := '';
  if FileExists(AddBackslash(Directory) + 'bin\{#AppExeName}') then
    exit;
  if DirExists(AddBackslash(Directory) + 'bin') or
     DirExists(AddBackslash(Directory) + 'plugins') or
     DirExists(AddBackslash(Directory) + 'qml') or
     DirExists(AddBackslash(Directory) + 'share') or
     DirExists(AddBackslash(Directory) + 'translations') then
    Result := '{#DestinationConflictMessage}';
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  Error: String;
begin
  Result := True;
  if (CurPageID <> wpSelectDir) or WizardSilent then
    exit;
  Error := DestinationError(WizardDirValue);
  Result := Error = '';
  if not Result then
    MsgBox(Error, mbError, MB_OK);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := DestinationError(ExpandConstant('{app}'));
end;
