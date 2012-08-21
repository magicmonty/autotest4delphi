unit MSBuildCommand;

interface

uses
  Forms,
  xmlintf,

  Windows,
  TUTrayIcon,
  ActiveObjectEngine;

type
  TNotificationIcon = (niSuccess, niError);

  TMSBuildCommand = class(TCommand)
  strict private
    FConfigFile: string;
    FBuildCommand: string;
    FBuildParams: string;
    FTestCommand: string;
    FTestParams: string;

    function LoadConfig: Boolean;
    procedure SetEnvironment(const ANode: IXMLNode);
    function SetBuildCommand(const ANode: IXMLNode): Boolean;
    function SetTestCommand(const ANode: IXMLNode): Boolean;
    function SetCommand(const ANode: IXMLNode; var ACommand, AParams: string): Boolean;
    function ExpandEnvVars(const Str: string): string;
    function ExecAndWait(
      ExecuteFile, ParamString, StartInDirectory: string;
      var AExitCode: DWORD;
      var AErrorCode: Integer;
      var Output: string): Boolean;
  public
    constructor Create(AEngine: TActiveObjectEngine; AConfigFile: string);
    procedure Execute; override;
  end;

implementation

uses
  xmldoc,
  ActiveX,
  Classes,
  Variants,
  SysUtils,
  PrjConst,
  Notification;

constructor TMSBuildCommand.Create(
  AEngine: TActiveObjectEngine;
  AConfigFile: string);
begin
  inherited Create(AEngine);
  FConfigFile := AConfigFile;
end;

procedure TMSBuildCommand.Execute;
var
  path: string;
  exitCode: Cardinal;
  errorCode: Integer;
  balloonTitle: string;
  balloonIcon: TNotificationType;
  output: string;
  text: string;
  tmp: TStringList;
begin
  balloonTitle := 'Change';

  path := ExcludeTrailingPathDelimiter(ExtractFilePath(FConfigFile));

  CoInitialize(nil);
  try
    if LoadConfig then
    begin
      if ExecAndWait(
        FBuildCommand,
        FBuildParams,
        path,
        ExitCode,
        ErrorCode,
        Output
      ) then
      begin
        if (exitCode = 0)
        and (errorCode = 0) then
        begin
          if ExecAndWait(
            FTestCommand,
            FTestParams,
            ExtractFilePath(FTestCommand),
            ExitCode,
            ErrorCode,
            Output
          ) then
          begin
            if (exitCode = 0) and (errorCode = 0) then
            begin
              balloonIcon := ntSuccess;
              balloonTitle := 'Success';
            end
            else
            begin
              balloonIcon := ntFailure;
              balloonTitle := 'Failure';
            end;

            text := output;
          end
          else
          begin
            balloonIcon := ntError;
            balloonTitle := 'Error running tests';
            text := 'Could not run test: ' + Trim(FTestCommand + ' ' + FTestParams);
          end;
        end
        else
        begin
          balloonIcon := ntError;
          balloonTitle := 'Build error';
          text := output;
        end;

      end
      else
      begin
        balloonIcon := ntError;
        balloonTitle := 'Build error';
        text := 'could not run build command: ' + Trim(FBuildCommand + ' ' + FBuildParams);
      end;
    end
    else
    begin
      balloonIcon := ntError;
      balloonTitle := 'Error loading config';
      text := 'Could not load configuration from ' + FConfigFile;
    end;
  finally
    CoUninitialize;
  end;

  if balloonIcon = ntFailure then
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
  else if balloonIcon <> ntError then
    output := EmptyStr;


  ShowNotification(balloonTitle, text, output, balloonIcon);
end;

function TMSBuildCommand.LoadConfig: Boolean;
var
  root, node: IXMLNode;
  xml: IXMLDocument;
begin
  Result := False;

  FBuildCommand := '';
  FBuildParams := '';
  FTestCommand := '';
  FTestParams := '';

  try
    try
      if FileExists(FConfigFile) then
      begin
        xml := LoadXMLDocument(FConfigFile);
        root := xml.DocumentElement;

        if Assigned(root) and (root.NodeName = 'buildrunner') then
        begin
          node := root.ChildNodes.FindNode('environment');
          if Assigned(node) then
            SetEnvironment(node);

          node := root.ChildNodes.FindNode('build');
          if not Assigned(node) or not SetBuildCommand(node) then
            exit;

          node := root.ChildNodes.FindNode('test');
          if not Assigned(node) or not SetTestCommand(node) then
            exit;

          Result := True;
        end;
      end;
    finally
      node := nil;
      root := nil;
      xml := nil;
    end;
  except
    Result := False;
  end;
end;

procedure TMSBuildCommand.SetEnvironment(const ANode: IXMLNode);
var
  envVar: IXMLNode;
  envVarName, envVarValue: string;
  tempValue: string;
begin
  try
    envVar := ANode.ChildNodes.First;
    while Assigned(envVar) do
    begin
      envVarName := envVar.NodeName;
      if Variants.VarIsEmpty(envVar.NodeValue)
      or Variants.VarIsNull(envVar.NodeValue) then
        tempValue := ''
      else
        tempValue := envVar.NodeValue;

      tempValue := StringReplace(tempValue, '%CD%', ExcludeTrailingPathDelimiter(ExtractFilePath(FConfigFile)), [rfReplaceAll, rfIgnoreCase]);
      envVarValue := ExpandEnvVars(tempValue);
      SetEnvironmentVariable(PChar(envVarName), PChar(envVarValue));

      envVar := envVar.NextSibling;
    end;
  finally
    envVar := nil;
  end;
end;

function TMSBuildCommand.SetBuildCommand(const ANode: IXMLNode): Boolean;
begin
  Result := SetCommand(ANode, FBuildCommand, FBuildParams);
end;

function TMSBuildCommand.SetTestCommand(const ANode: IXMLNode): Boolean;
begin
  Result := SetCommand(ANode, FTestCommand, FTestParams);
end;

function TMSBuildCommand.SetCommand(const ANode: IXMLNode; var ACommand, AParams: string): Boolean;
var
  node: IXMLNode;
begin
  Result := False;
  ACommand := '';
  AParams := '';

  node := ANode.ChildNodes.FindNode('command');
  if not Assigned(node) then
    exit;

  if VarIsEmpty(node.NodeValue)
  or VarIsNull(node.NodeValue) then
    exit;

  ACommand := node.NodeValue;
  ACommand := ExpandEnvVars(StringReplace(ACommand, '%CD%', ExcludeTrailingPathDelimiter(ExtractFilePath(FConfigFile)), [rfReplaceAll, rfIgnoreCase]));

  node := ANode.ChildNodes.FindNode('params');
  if Assigned(node)
  and not VarIsEmpty(node.NodeValue)
  and not VarIsNull(node.NodeValue) then
    AParams := node.NodeValue;
  AParams := ExpandEnvVars(StringReplace(AParams, '%CD%', ExcludeTrailingPathDelimiter(ExtractFilePath(FConfigFile)), [rfReplaceAll, rfIgnoreCase]));

  Result := True;
end;

function TMSBuildCommand.ExpandEnvVars(const Str: string): string;
var
  BufSize: Integer; // size of expanded string
begin
  // Get required buffer size
  BufSize := ExpandEnvironmentStrings(PChar(Str), nil, 0);
  if BufSize > 0 then
  begin
    // Read expanded string into result string
    SetLength(Result, BufSize - 1);
    ExpandEnvironmentStrings(PChar(Str), PChar(Result), BufSize);
  end
  else
    // Trying to expand empty string
    Result := '';
end;

function TMSBuildCommand.ExecAndWait(
  ExecuteFile, ParamString, StartInDirectory: string;
  var AExitCode: DWORD;
  var AErrorCode: Integer;
  var Output: string): Boolean;
const
  C_READ_BUFFER = 2400;
var
  processInfo: TProcessInformation;
  startupInfo: TStartupInfoA;
  securityDescriptor: TSecurityDescriptor;
  commandLine: string;
  security: TSecurityAttributes;
  StdOutPipeR, StdOutPipeW: THandle;

  buffer: PByte;
  bytesRead: DWORD;
  avail: DWORD;
  temp: AnsiString;
  Handle: THandle;
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

    InitializeSecurityDescriptor(@securityDescriptor, SECURITY_DESCRIPTOR_REVISION);
    SetSecurityDescriptorDacl(@securityDescriptor, true, nil, false);
    lpSecurityDescriptor := @securityDescriptor;
  end;

  if CreatePipe(StdOutPipeR, StdOutPipeW, @Security, 0) then
  try
    SetHandleInformation(StdOutPipeR, HANDLE_FLAG_INHERIT, 0);
    GetMem(buffer, C_READ_BUFFER);

    try
      commandLine := Format('"%s" %s', [ExecuteFile, ParamString]);

      // Timeout muß bei QVP und PDF als Application auf jeden Fall null sein.
      FillChar(startupInfo, SizeOf(TStartupInfoA), #0);
      FillChar(processInfo, SizeOf(TProcessInformation), #0);

      GetStartupInfoA(startupInfo);
      startupInfo.dwFlags := STARTF_USESTDHANDLES + STARTF_USESHOWWINDOW;
      startupInfo.wShowWindow := SW_HIDE;
      // startupInfo.hStdInput := StdInPipeR;
      startupInfo.hStdOutput := StdOutPipeW;
      startupInfo.hStdError := StdOutPipeW;
      startupInfo.lpTitle := 'msbuild';

      if StartInDirectory = EmptyStr then
        StartInDirectory := ExtractFilePath(ExecuteFile);

      if CreateProcessA(
        nil,
        PAnsiChar(AnsiString(commandLine)),
        nil,
        nil,
        true,
        CREATE_NEW_CONSOLE,
        nil,
        PAnsiChar(AnsiString(StartInDirectory)),
        startupInfo,
        processInfo) then
      begin
        Handle := processInfo.hProcess;
        Result := true;

        while WaitForSingleObject(Handle, 100) = WAIT_TIMEOUT do
        begin
          PeekNamedPipe(StdOutPipeR, nil, 0, nil, @avail, nil);
          if avail > 0 then
          begin
            SetLength(temp, avail);
            ReadFile(StdOutPipeR, temp[1], Avail, bytesRead, nil);
            Output := Output + string(temp);
          end;
        end;

        PeekNamedPipe(StdOutPipeR, nil, 0, nil, @avail, nil);
        if avail > 0 then
        begin
          SetLength(temp, avail);
          ReadFile(StdOutPipeR, temp[1], Avail, bytesRead, nil);
          Output := Output + string(temp);
        end;


        if AErrorCode = 0 then
          GetExitCodeProcess(processInfo.hProcess, AExitCode)
        else
          AExitCode := 0;

        CloseHandle(processInfo.hProcess);
        CloseHandle(processInfo.hThread);
      end
      else
      begin
        Result := false;
        AErrorCode := 2;
      end;
    finally
      FreeMem(buffer);
    end;
  finally
    CloseHandle(StdOutPipeR);
    CloseHandle(StdOutPipeW);
  end;
end;

end.
