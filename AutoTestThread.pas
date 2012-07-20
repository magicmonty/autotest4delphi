unit AutoTestThread;

interface

uses
  Classes,
  ActiveObjectEngine,
  DirWatcher;

type
  TAutoTestThread = class(TThread)
  private
    FTestEngine: TActiveObjectEngine;
    FDirWatcher: TDirectoryMonitor;
    FTestProject: string;
    FDirectoryToWatch: string;
    FDCC32ExePath: string;
    FUseBuildXML: Boolean;
    FBuildXMLFilePath: string;

    procedure FDirWatcherOnDirectoryChange(
      Sender: TObject;
      Action: TDirectoryAction;
      FileName: string);
  public
    property DirectoryToWatch: string read FDirectoryToWatch write FDirectoryToWatch;
    property TestProject: string read FTestProject write FTestProject;
    property DCC32ExePath: string read FDCC32ExePath write FDCC32ExePath;
    property UseBuildXML: Boolean read FUseBuildXML write FUseBuildXML;
    property BuildXMLFilePath: string read FBuildXMLFilePath write FBuildXMLFilePath;

    constructor Create;
    destructor Destroy; override;
    procedure Execute; override;
  end;

implementation

uses
  SysUtils,
  MSBuildCommand,
  TestCommand;

constructor TAutoTestThread.Create;
begin
  inherited Create(true);
  FreeOnTerminate := true;

  FDirectoryToWatch := '';
  FTestProject := '';
  FDCC32ExePath := '';
  FUseBuildXML := False;
  FBuildXMLFilePath := '';

  FTestEngine := TActiveObjectEngine.Create;
  FDirWatcher := TDirectoryMonitor.Create;
end;

destructor TAutoTestThread.Destroy;
begin
  FDirWatcher.OnDirectoryChange := nil;
  FDirWatcher.Stop;
  FreeAndNil(FDirWatcher);

  FTestEngine.Stop;
  FreeAndNil(FTestEngine);
  
  inherited Destroy;
end;

procedure TAutoTestThread.Execute;
begin
  FDirWatcher.WatchSubFolders := true;
  FDirWatcher.DirectoryToWatch := FDirectoryToWatch;
  FDirWatcher.Options := [awChangeLastWrite, awChangeCreation];
  FDirWatcher.OnDirectoryChange := FDirWatcherOnDirectoryChange;
  FDirWatcher.Start;

  if FUseBuildXML and FileExists(FBuildXMLFilePath) then
    FTestEngine.AddCommand(TMSBuildCommand.Create(FTestEngine, FBuildXMLFilePath))
  else
    FTestEngine.AddCommand(TTestCommand.Create(FTestEngine, FTestProject, FDCC32ExePath));
  FTestEngine.Run;

  while not Terminated do
    Sleep(100);
end;

procedure TAutoTestThread.FDirWatcherOnDirectoryChange(Sender: TObject; Action: TDirectoryAction; FileName: string);
var
  extension: string;
begin
  extension := ExtractFileExt(FileName);
  if (Action = daFileAdded)
    or (Action = daFileModified)
    and (
    (extension = '.pas')
    or (extension = '.inc')
    or (LowerCase(FDirWatcher.DirectoryToWatch + '\' + FileName) = LowerCase(FTestProject))
    ) then
  begin
    if FTestEngine.Stopped or (not FTestEngine.Running and not FTestEngine.Executing) then
    begin
      if FUseBuildXML and FileExists(FBuildXMLFilePath) then
        FTestEngine.AddCommand(TMSBuildCommand.Create(FTestEngine, FBuildXMLFilePath))
      else
        FTestEngine.AddCommand(TTestCommand.Create(FTestEngine, FTestProject, FDCC32ExePath));

      if not FTestEngine.Running or FTestEngine.Stopped then
        FTestEngine.Run;
    end;
  end;
end;

end.
