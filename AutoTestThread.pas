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

    procedure FDirWatcherOnDirectoryChange(Sender: TObject; Action: TDirectoryAction; FileName: AnsiString);
  public
    constructor Create(DirectoryToWatch, TestProject, DCC32ExePath: string);
    destructor Destroy; override;
    procedure Execute; override;
  end;

implementation

uses
  SysUtils,
  TestCommand;

constructor TAutoTestThread.Create(DirectoryToWatch, TestProject, DCC32ExePath: string);
begin
  inherited Create(true);
  FreeOnTerminate := true;

  FDirectoryToWatch := DirectoryToWatch;
  FTestProject := TestProject;
  FDCC32ExePath := DCC32ExePath;

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

  while not Terminated do
    Sleep(100);
end;

procedure TAutoTestThread.FDirWatcherOnDirectoryChange(Sender: TObject; Action: TDirectoryAction; FileName: AnsiString);
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
      FTestEngine.AddCommand(TTestCommand.Create(FTestEngine, FTestProject, FDCC32ExePath));
      if not FTestEngine.Running or FTestEngine.Stopped then
        FTestEngine.Run;
    end;
  end;
end;

end.
