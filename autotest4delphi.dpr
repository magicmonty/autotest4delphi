program autotest4delphi;

{$R 'resources.res' 'resources\resources.rc'}
{$R 'ExeIcon.res' 'ExeIcon.rc'}
{$R 'VersionInfo.res' 'VersionInfo.rc'}
{$APPTYPE Console}

uses
  Classes,
  SysUtils,
  Windows,
  IniFiles,
  ActiveObjectEngine in 'ActiveObjectEngine.pas',
  DirWatcher in 'DirWatcher.pas',
  TestCommand in 'TestCommand.pas',
  GrowlNotifier in 'GrowlNotifier.pas',
  PrjConst in 'PrjConst.pas',
  AutoTestThread in 'AutoTestThread.pas',
  MSBuildCommand in 'MSBuildCommand.pas',
  Notification in 'Notification.pas',
  GrowlNotification in 'GrowlNotification.pas',
  ConsoleNotification in 'ConsoleNotification.pas',
  ComposedNotification in 'ComposedNotification.pas';

var
  // MainController : IController;
  FAutoTestThread: TAutoTestThread;
  FTestProject: string;
  FDirectoryToWatch: string;
  FDCC32ExePath: string;
  FUseBuildXML: Boolean;
  FBuildXMLFilePath: string;
  FTerminate: Boolean;
  LoadResult: Byte;
  FCurrentDir: string;

const
  C_INI_NAME = 'autotest.ini';
  C_INI_SECTION = 'autotest';

function GetCurrentDirectory: string;
begin
  if FCurrentDir = EmptyStr then
  begin
    if (ParamCount = 1) then
      FCurrentDir := Trim(ExtractFilePath(ParamStr(1)));

    if FCurrentDir = EmptyStr then
      FCurrentDir := Trim(ExtractFilePath(ParamStr(0)));
  end;

  Result := FCurrentDir;
end;

function console_handler( dwCtrlType: DWORD ): BOOL; stdcall;
begin
  // Avoid terminating with Ctrl+C
  if dwCtrlType in [CTRL_C_EVENT, CTRL_CLOSE_EVENT] then
  begin
    Writeln('Closing application...');
    FAutoTestThread.Terminate;
    FTerminate := true;
    result := TRUE;
    SetConsoleCtrlHandler(@console_handler, false);
  end
  else
    result := FALSE;
end;

function ExpandEnvString(const APath: string): string;
var
  bufferSize: Cardinal;
begin
  Result := APath;
  bufferSize := ExpandEnvironmentStrings(PChar(APath), nil, 0);
  if bufferSize > 0 then
  begin
    SetLength(Result, bufferSize - 1);
    ExpandEnvironmentStrings(PChar(APath), PChar(Result), bufferSize);
  end;

  Result := StringReplace(
    Result,
    '%CD%',
    ExcludeTrailingPathDelimiter(GetCurrentDirectory),
    [rfReplaceAll, rfIgnoreCase]
  );
end;

function LoadIni: Byte;
var
  ini: TMemInifile;
  iniFileName: string;
begin
  iniFileName := EmptyStr;
  FCurrentDir := EmptyStr;

  if (ParamCount = 1) then
    iniFileName := ExpandEnvString(ParamStr(1))
  else
    iniFileName := C_INI_NAME;


  if FileExists(iniFileName) then
  begin
    try
      ini := TMemIniFile.Create(iniFileName);
      if ini.SectionExists(C_INI_SECTION) then
      begin
        FUseBuildXML := False;
        if ini.ValueExists(C_INI_SECTION, 'UseBuildXML') then
          FUseBuildXML := ini.ReadBool(C_INI_SECTION, 'UseBuildXML', False);

        if FUseBuildXML then
        begin
          FBuildXMLFilePath := '';
          if ini.ValueExists(C_INI_SECTION, 'BuildXMLPath') then
            FBuildXMLFilePath := ExpandEnvString(ini.ReadString(C_INI_SECTION, 'BuildXMLPath', ''));

          if FileExists(FBuildXMLFilePath) then
            Result := 0
          else
          begin
            Result := 10;
            FUseBuildXML := False;
          end;
        end;

        if not FUseBuildXML then
        begin
          if ini.ValueExists(C_INI_SECTION, 'TestProject') then
          begin
            FTestProject := ExpandEnvString(ini.ReadString(C_INI_SECTION, 'TestProject', EmptyStr));
            if FileExists(FTestProject) then
            begin
              if ini.ValueExists(C_INI_SECTION, 'DirectoryToWatch') then
              begin
                FDirectoryToWatch := ExpandEnvString(ini.ReadString(C_INI_SECTION, 'DirectoryToWatch', EmptyStr));
                if DirectoryExists(FDirectoryToWatch) then
                begin
                  if ini.ValueExists(C_INI_SECTION, 'DCC32Exe') then
                  begin
                    FDCC32ExePath := ExpandEnvString(ini.ReadString(C_INI_SECTION, 'DCC32Exe', EmptyStr));
                    if FileExists(FDCC32ExePath) then
                    begin
                      if (LowerCase(ExtractFileName(FDCC32ExePath)) = 'dcc32.exe') then
                        Result := 0
                      else
                        Result := 9;
                    end
                    else
                      Result := 8;
                  end
                  else
                    Result := 7;
                end
                else
                  Result := 6;
              end
              else
                Result := 5;
            end
            else
              Result := 4;
          end
          else
            Result := 3;
        end
        else
        begin
          if ini.ValueExists(C_INI_SECTION, 'DirectoryToWatch') then
          begin
            FDirectoryToWatch := ExpandEnvString(ini.ReadString(C_INI_SECTION, 'DirectoryToWatch', EmptyStr));
            if DirectoryExists(FDirectoryToWatch) then
              Result := 0
            else
              Result := 6;
          end
          else
            Result := 5;
        end;
      end
      else
        Result := 2;
    finally
      FreeAndNil(ini);
    end;
  end
  else
    Result := 1;
end;

procedure GrowlNotify(const AMessage: string);
var
  growl: TGrowlNotifier;
begin
  try
    growl := TGrowlNotifier.Create;
    try
      growl.SendNotification('Autotest4Delphi', AMessage, ntNotify);
    finally
      FreeAndNil(growl);
    end;
  except
  end;
end;

var
  registered: Boolean;
  growl: TGrowlNotifier;

begin
  registered := False;
  try
    growl := TGrowlNotifier.Create;
    try
      try
        growl.RegisterApplication;
        registered := True;
      except
        registered := True;
      end;
    finally
      FreeAndNil(growl);
    end;
  except
  end;

  if registered then
    GrowlNotify('Autotest4Delphi running');

  LoadResult := LoadIni;

  case LoadResult of
    1: Writeln('autotest.ini not found!');
    2: Writeln('Error parsing autotest.ini: Section [autotest] not found!');
    3: Writeln('Error parsing autotest.ini: no TestProject in Section [autotest]!');
    4: Writeln(Format('TestProject "%s" not found!', [FTestProject]));
    5: Writeln('Error parsing autotest.ini: no DirectoryToWatch in Section [autotest]!');
    6: Writeln(Format('Directory "%s" not found!', [FDirectoryToWatch]));
    7: Writeln('Error parsing autotest.ini: no DCC32Exe in Section [autotest]!');
    8: Writeln(Format('DCC32.exe "%s" not found!', [FDCC32ExePath]));
    9: Writeln(Format('"%s" is not a dcc32.exe!', [FDCC32ExePath]));
   10: Writeln(Format('Could not find build.xml (%s)!', [FBuildXMLFilePath]));
  else
    SetConsoleCtrlHandler(@console_handler, true);
    FTerminate := false;

    FAutoTestThread := TAutoTestThread.Create(
      TComposedNotification.Create
        .AddNotifier(TConsoleNotification.Create)
        .AddNotifier(TGrowlNotification.Create)
      );
    FAutoTestThread.DirectoryToWatch := FDirectoryToWatch;
    FAutoTestThread.TestProject := FTestProject;
    FAutoTestThread.DCC32ExePath := FDCC32ExePath;
    FAutoTestThread.UseBuildXML := FUseBuildXML;
    FAutoTestThread.BuildXMLFilePath := FBuildXMLFilePath;
    FAutoTestThread.Resume;

    while not FTerminate do
      CheckSynchronize(10);
  end;

  GrowlNotify('Autotest4Delphi closing');
  Sleep(1000);
end.
