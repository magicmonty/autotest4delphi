unit TestCommand;

interface

uses
  Forms,
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
    procedure ShowNotification(Title, Text, ConsoleOutput: String; Icon: TNotificationType);
  public
    constructor Create(Engine: TActiveObjectEngine; TestProject: string; DCC32Path: string);
    procedure Execute;
    function ExecAndWait(ExecuteFile, ParamString, StartInDirectory: AnsiString; var AExitCode: DWORD; var AErrorCode: Integer; var Output: string): Boolean;
  end;

implementation

uses
  Classes,
  SysUtils,
  PrjConst;

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
  balloonTitle: string;
  balloonIcon: TNotificationType;
  output: string;
  text: string;
  tmp: TStringList;
begin
  balloonTitle := 'Change';

  path := ExtractFilePath(FTestProject);
  if path[Length(path)] = '\' then
    SetLength(path, Length(path) - 1);

  if not DirectoryExists(path + '\bin') then
    CreateDir(path + '\bin');
  
  if not DirectoryExists(path + '\dcu') then
    CreateDir(path + '\dcu');

  params := Format('-CC -DCONSOLE_TESTRUNNER;TEST;AUTOTEST -E"%0:s\bin" -N0"%0:s\dcu" -Q "%1:s"', [path, FTestProject]);
  ExecAndWait(FDCC32Path, params, path, exitCode, errorCode, output);
  if (exitCode = 0)
  and (errorCode = 0) then
  begin
    command := Format('%s\bin\%s', [path, StringReplace(ExtractFileName(FTestProject), '.dpr', '.exe', [rfReplaceAll, rfIgnoreCase])]);
    params := '';
    ExecAndWait(command, params, path, exitCode, errorCode, output);
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
  end;

  text := output;
  
  if balloonIcon = ntError then
    text := balloonTitle
  else if balloonIcon = ntFailure then
  begin
    tmp := TStringList.Create;
    try
      tmp.Text := output;
      if tmp.Count > 0 then
      begin
        text := tmp.Strings[0];
        tmp.Delete(0);
        output := tmp.Text;
      end
      else
        text := balloonTitle;
    finally
      FreeAndNil(tmp);
    end;
  end
  else
    output := EmptyStr;


  ShowNotification(balloonTitle, text, output, balloonIcon);
end;

procedure TTestCommand.ShowNotification(Title, Text, ConsoleOutput: String; Icon: TNotificationType);
var
  notifier: TGrowlNotification;
begin
  notifier := TGrowlNotification.Create;
  try
    try
      try
        if Icon = ntSuccess then
          SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_GREEN)
        else
          SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED);

        Writeln(Text);
        if Trim(ConsoleOutput) <> EmptyStr then
        begin
          Writeln;
          Writeln(ConsoleOutput);
        end;

        SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE);
      except
      end;

      notifier.SendNotification(Title, Trim(StringReplace(Text, CRLF, LF, [rfReplaceAll])), icon);
    except
    end;
  finally
    FreeAndNil(notifier);
  end;
end;

function TTestCommand.ExecAndWait(ExecuteFile, ParamString, StartInDirectory: AnsiString; var AExitCode: DWORD; var AErrorCode: Integer; var Output: string): Boolean;
const
  C_READ_BUFFER = 2400;
var
  processInfo: TProcessInformation;
  startupInfo: TStartupInfo;
  commandLine: AnsiString;
  security: TSecurityAttributes;
  readPipe, writePipe: THandle;
  buffer: PChar;
  appRunning: DWORD;
  bytesRead: DWORD;
begin
  Result := true;
  Output := EmptyStr;
  AExitCode := 0;
  AErrorCode := 0;

  if ExecuteFile[1] = '"' then
    Delete(ExecuteFile, 1, 1);

  if ExecuteFile[Length(ExecuteFile)] = '"' then
    Delete(ExecuteFile, Length(ExecuteFile), 1);

  with security do
  begin
    nLength := SizeOf(TSecurityAttributes);
    bInheritHandle := true;
    lpSecurityDescriptor := nil;
  end;

  if CreatePipe(readPipe, writePipe, @security, 0) then
  begin
    buffer := AllocMem(C_READ_BUFFER + 1);

    // Timeout muﬂ bei QVP und PDF als Application auf jeden Fall null sein.
    FillChar(startupInfo, SizeOf(TStartupInfo), 0);
    startupInfo.cb := SizeOf(TStartupInfo);
    startupInfo.hStdInput := readPipe;
    startupInfo.hStdOutput := writePipe;
    startupInfo.hStdError := writePipe;
    startupInfo.dwFlags := STARTF_USESTDHANDLES + STARTF_USESHOWWINDOW;
    startupInfo.wShowWindow := SW_HIDE;
    commandLine := Format('"%s" %s', [ExecuteFile, ParamString]);

    if StartInDirectory = EmptyStr then
      StartInDirectory := ExtractFilePath(ExecuteFile);

    if CreateProcess(nil,
      PChar(commandLine),
      @security,
      @security,
      true,
      NORMAL_PRIORITY_CLASS,
      nil,
      PChar(StartInDirectory),
      startupInfo,
      processInfo) then
    begin
      Result := true;

      repeat
        appRunning := WaitForSingleObject(processInfo.hProcess, 100);
        Application.ProcessMessages;
      until (appRunning <> WAIT_TIMEOUT);

      repeat
        bytesRead := 0;
        ReadFile(readPipe, buffer[0], C_READ_BUFFER, bytesRead, nil);
        buffer[bytesRead] := #0;
        OemToAnsi(buffer, buffer);
        Output := Output + string(buffer);
      until bytesRead < C_READ_BUFFER;

      FreeMem(buffer);

      if AErrorCode = 0 then
        GetExitCodeProcess(processInfo.hProcess, AExitCode)
      else
        AExitCode := 0;

      CloseHandle(processInfo.hProcess);
      CloseHandle(processInfo.hThread);
      CloseHandle(readPipe);
      CloseHandle(writePipe);
    end
    else
    begin
      Result := false;
      AErrorCode := 2;
    end;
  end;
end;

end.
