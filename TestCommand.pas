unit TestCommand;

interface

uses
  GrowlNotification,
  Windows,
  CoolTrayIcon,
  ActiveObjectEngine;

type
  TNotificationIcon = (niSuccess, niError);

  TTestCommand = class(TInterfacedObject, ICommand)
  private
    FEngine: TActiveObjectEngine;
    FTestProject: string;
    FDCC32Path: string;
    procedure ShowNotification(Title, Text: String; Icon: TNotificationType);
  public
    constructor Create(Engine: TActiveObjectEngine; TestProject: string; DCC32Path: string);
    procedure Execute;
    function ExecAndWait(ExecuteFile, ParamString, StartInDirectory: AnsiString; var AExitCode: DWORD; var AErrorCode: Integer): Boolean;
  end;

implementation

uses
  SysUtils;

constructor TTestCommand.Create(Engine: TActiveObjectEngine; TestProject: string; DCC32Path: string);
begin
  inherited Create;
  FEngine := Engine;
  FTestProject := TestProject;
  FDCC32Path := DCC32Path;
end;

procedure TTestCommand.Execute;
var
  command, params, path: string;
  exitCode: Cardinal;
  errorCode: Integer;
  balloonTitle, balloonHint: string;
  balloonIcon: TNotificationType;
begin
  balloonTitle := 'Change';
  balloonHint := FTestProject;

  path := ExtractFilePath(FTestProject);
  if path[Length(path)] = '\' then
    SetLength(path, Length(path) - 1);

  if not DirectoryExists(path + '\bin') then
    CreateDir(path + '\bin');
  
  if not DirectoryExists(path + '\dcu') then
    CreateDir(path + '\dcu');

  params := Format('-CC -DCONSOLE_TESTRUNNER;TEST;AUTOTEST -E%0:s\bin -N0%0:s\dcu -Q %1:s', [path, FTestProject]);
  ExecAndWait(FDCC32Path, params, path, exitCode, errorCode);
  if (exitCode = 0)
  and (errorCode = 0) then
  begin
    command := Format('%s\bin\%s', [path, StringReplace(ExtractFileName(FTestProject), '.dpr', '.exe', [rfReplaceAll, rfIgnoreCase])]);
    params := '';
    ExecAndWait(command, params, path, exitCode, errorCode);
    if (exitCode = 0)
    and (errorCode = 0) then
    begin
      balloonIcon := ntSuccess;
      balloonTitle := 'Success';
    end
    else
    begin
      balloonIcon := ntFailure;
      balloonTitle := 'Failure';
    end;
  end
  else
  begin
    balloonIcon := ntError;
    balloonTitle := 'Build error';
    balloonHint := 'Error building test project';
  end;

  ShowNotification(balloonTitle, balloonHint, balloonIcon);
end;

procedure TTestCommand.ShowNotification(Title, Text: String; Icon: TNotificationType);
var
  notifier: TGrowlNotification;
begin
  notifier := TGrowlNotification.Create;
  try
    try
      notifier.SendNotification(Title, Text, icon);
    except
    end;
  finally
    FreeAndNil(notifier);
  end;
end;

function TTestCommand.ExecAndWait(ExecuteFile, ParamString, StartInDirectory: AnsiString; var AExitCode: DWORD; var AErrorCode: Integer): Boolean;
var
  processInfo: TProcessInformation;
  startupInfo: TStartupInfo;
  commandLine: AnsiString;
begin
  AExitCode := 0;
  AErrorCode := 0;

  if ExecuteFile[1] = '"' then
    Delete(ExecuteFile, 1, 1);

  if ExecuteFile[Length(ExecuteFile)] = '"' then
    Delete(ExecuteFile, Length(ExecuteFile), 1);


  // Timeout muﬂ bei QVP und PDF als Application auf jeden Fall null sein.
  FillChar(startupInfo, SizeOf(TStartupInfo), 0);
  startupInfo.cb := SizeOf(TStartupInfo);
  startupInfo.dwFlags := STARTF_USESHOWWINDOW;
  startupInfo.wShowWindow := SW_HIDE;
  commandLine := Format('"%s" %s', [ExecuteFile, ParamString]);

  if StartInDirectory = EmptyStr then
    StartInDirectory := ExtractFilePath(ExecuteFile);

  if CreateProcess(nil,
    PChar(commandLine),
    nil,
    nil,
    false,
    NORMAL_PRIORITY_CLASS,
    nil,
    PChar(StartInDirectory),
    startupInfo,
    processInfo) then
  begin
    Result := true;

    if WaitForSingleObject(processInfo.hProcess, 120 * 1000) = WAIT_FAILED then
      AErrorCode := 1;

    if AErrorCode = 0 then
      GetExitCodeProcess(processInfo.hProcess, AExitCode)
    else
      AExitCode := 0;

    CloseHandle(processInfo.hProcess);
  end
  else
  begin
    Result := false;
    AErrorCode := 2;
  end;
end;

end.
