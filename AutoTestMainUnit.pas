unit AutoTestMainUnit;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  ImgList,
  CoolTrayIcon,
  ExtCtrls,
  StdCtrls,
  DirWatcher,
  ActiveObjectEngine, Menus;

type
  TTestCommand = class(TInterfacedObject, ICommand)
  private
    FEngine: TActiveObjectEngine;
    FTestProject: string;
    FTrayIcon: TTrayIcon;
    FCount: Integer;
  public
    constructor Create(Engine: TActiveObjectEngine; TestProject: string; TrayIcon: TTrayIcon; Count: Integer);
    procedure Execute;
    function ExecAndWait(ExecuteFile, ParamString, StartInDirectory: AnsiString; var AExitCode: DWORD; var AErrorCode: Integer): Boolean;
  end;

  TMainForm = class(TForm)
    StateImages: TImageList;
    Label1: TLabel;
    TestProjectEdit: TEdit;
    Label2: TLabel;
    StartStopButton: TButton;
    TrayIcon: TTrayIcon;
    OpenDialog: TOpenDialog;
    SelectTestProjectButton: TButton;
    AddWatchedDirectoryButton: TButton;
    WatchedDirectoryEdit: TEdit;
    PopupMenu1: TPopupMenu;
    Show1: TMenuItem;
    start1: TMenuItem;
    Stop1: TMenuItem;
    Hide1: TMenuItem;
    N1: TMenuItem;
    Quit1: TMenuItem;
    procedure SelectTestProjectButtonClick(Sender: TObject);
    procedure AddWatchedDirectoryButtonClick(Sender: TObject);
    procedure StartButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Quit1Click(Sender: TObject);
  private
    FCount: Integer;
    FDirWatcher: TDirectoryMonitor;
    FTestEngine: TActiveObjectEngine;

    { Private-Deklarationen }
    procedure FDirWatcherOnDirectoryChange(Sender: TObject; Action: TDirectoryAction; FileName: AnsiString);
  public
    { Public-Deklarationen }
  end;

var
  MainForm: TMainForm;

implementation

uses
  Registry,
  FileCtrl;

{$R *.dfm}

procedure TMainForm.AddWatchedDirectoryButtonClick(Sender: TObject);
var
  dir: string;
begin
  if SelectDirectory('Add directory to watch for changes', '', dir) then
  begin
    if dir[Length(dir)] = '\' then
      SetLength(dir, Length(dir) - 1);

    WatchedDirectoryEdit.Text := dir;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  reg: TRegistry;
begin
  FDirWatcher := TDirectoryMonitor.Create;

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.OpenKey('Software\Pagansoft\Autotest4Delphi', true);
    TestProjectEdit.Text := reg.ReadString('Testproject');
    WatchedDirectoryEdit.Text := reg.ReadString('WatchedDirectory');
  finally
    FreeAndNil(reg);
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FDirWatcher.OnDirectoryChange := nil;
  FDirWatcher.Stop;
  FreeAndNil(FDirWatcher);
end;

procedure TMainForm.Quit1Click(Sender: TObject);
begin
  StopButtonClick(nil);
  Close;
end;

procedure TMainForm.SelectTestProjectButtonClick(Sender: TObject);
begin
  OpenDialog.DefaultExt := '.dpr';
  OpenDialog.Filter := '*.dpr|*.dpr';
  OpenDialog.FilterIndex := 1;
  OpenDialog.Title := 'Select Test project';
  if OpenDialog.Execute then
  begin
    TestProjectEdit.Text := OpenDialog.FileName;
    WatchedDirectoryEdit.Text := ExtractFilePath(OpenDialog.FileName);
    if WatchedDirectoryEdit.Text[Length(WatchedDirectoryEdit.Text)] = '\' then
      WatchedDirectoryEdit.Text := Copy(WatchedDirectoryEdit.Text, 1, Length(WatchedDirectoryEdit.Text) - 1);
  end;
end;

procedure TMainForm.StartButtonClick(Sender: TObject);
var
  reg: TRegistry;
begin
  if FileExists(TestProjectEdit.Text)
  and DirectoryExists(WatchedDirectoryEdit.Text) then
  begin
    reg := TRegistry.Create;
    try
      reg.RootKey := HKEY_CURRENT_USER;
      reg.OpenKey('Software\Pagansoft\Autotest4Delphi', true);
      reg.WriteString('Testproject', TestProjectEdit.Text);
      reg.WriteString('WatchedDirectory', WatchedDirectoryEdit.Text);
    finally
      FreeAndNil(reg);
    end;
    FCount := 0;
    AddWatchedDirectoryButton.Enabled := false;
    SelectTestProjectButton.Enabled := false;
    TestProjectEdit.Enabled := false;
    WatchedDirectoryEdit.Enabled := false;
    StartStopButton.Caption := 'Stop';
    StartStopButton.OnClick := StopButtonClick;
    start1.Enabled := false;
    Stop1.Enabled := true;

    TrayIconDblClick(nil);

    FTestEngine := TActiveObjectEngine.Create;

    FDirWatcher.WatchSubFolders := true;
    FDirWatcher.DirectoryToWatch := WatchedDirectoryEdit.Text;
    FDirWatcher.Options := [awChangeLastWrite, awChangeCreation];
    FDirWatcher.OnDirectoryChange := FDirWatcherOnDirectoryChange;
    FDirWatcher.Start;
  end;
end;

procedure TMainForm.StopButtonClick(Sender: TObject);
begin
  AddWatchedDirectoryButton.Enabled := true;
  SelectTestProjectButton.Enabled := true;
  TestProjectEdit.Enabled := true;
  WatchedDirectoryEdit.Enabled := true;
  StartStopButton.Caption := 'Start';
  StartStopButton.OnClick := StartButtonClick;
  start1.Enabled := true;
  Stop1.Enabled := false;
  FDirWatcher.Stop;
  FTestEngine.Stop;
end;

procedure TMainForm.TrayIconDblClick(Sender: TObject);
begin
  if Self.WindowState = wsMinimized then
  begin
    Self.Show;
    Self.WindowState := wsNormal;
    Show1.Enabled := false;
    Hide1.Enabled := true;
  end
  else
  begin
    Self.WindowState := wsMinimized;
    Self.Hide;
    Show1.Enabled := true;
    Hide1.Enabled := false;
  end;
end;

procedure TMainForm.FDirWatcherOnDirectoryChange(Sender: TObject; Action: TDirectoryAction; FileName: AnsiString);
var
  extension: string;
begin
  extension := ExtractFileExt(FileName);
  if (Action = daFileAdded)
    or (Action = daFileModified)
    and (
    (extension = '.pas')
    or (extension = '.inc')
    or (LowerCase(FDirWatcher.DirectoryToWatch + '\' + FileName) = LowerCase(TestProjectEdit.Text))
    ) then
  begin
    if FTestEngine.Stopped or (not FTestEngine.Running and not FTestEngine.Executing) then
    begin
      Inc(FCount);
      FTestEngine.AddCommand(TTestCommand.Create(FTestEngine, TestProjectEdit.Text, TrayIcon, FCount));
      if not FTestEngine.Running or FTestEngine.Stopped then
        FTestEngine.Run;
    end;
  end;
end;

{ TTestCommand }

constructor TTestCommand.Create(Engine: TActiveObjectEngine; TestProject: string; TrayIcon: TTrayIcon; Count: Integer);
begin
  inherited Create;
  FEngine := Engine;
  FTestProject := TestProject;
  FTrayIcon := TrayIcon;
  FCount := Count;
end;

procedure TTestCommand.Execute;
var
  command, params, path: string;
  exitCode: Cardinal;
  errorCode: Integer;
begin
  FTrayIcon.BalloonTitle := 'Change ' + IntToStr(FCount);
  FTrayIcon.BalloonHint := FTestProject;

  path := ExtractFilePath(FTestProject);
  if path[Length(path)] = '\' then
    SetLength(path, Length(path) - 1);

  command := 'C:\Program Files (x86)\Borland\BDS\4.0\bin\dcc32.exe';
  params := Format('-CC -DCONSOLE_TESTRUNNER -E%0:s\bin -N0%0:s\dcu -Q %1:s', [path, FTestProject]);
  ExecAndWait(command, params, path, exitCode, errorCode);
  if (exitCode = 0)
  and (errorCode = 0) then
  begin
    command := Format('%s\bin\%s', [path, StringReplace(ExtractFileName(FTestProject), '.dpr', '.exe', [rfReplaceAll, rfIgnoreCase])]);
    params := '';
    ExecAndWait(command, params, path, exitCode, errorCode);
    if (exitCode = 0)
    and (errorCode = 0) then
    begin
      FTrayIcon.BalloonFlags := bfInfo;
      FTrayIcon.IconIndex := 1;
      FTrayIcon.BalloonTitle := 'Success';
    end
    else
    begin
      FTrayIcon.BalloonFlags := bfError;
      FTrayIcon.IconIndex := 2;
      FTrayIcon.BalloonTitle := 'Failure';
    end;
  end
  else
  begin
    FTrayIcon.BalloonFlags := bfError;
    FTrayIcon.IconIndex := 2;
    FTrayIcon.BalloonTitle := 'Build error';
    FTrayIcon.BalloonHint := 'Error building test project';
  end;

  FTrayIcon.ShowBalloonHint;
end;

function TTestCommand.ExecAndWait(ExecuteFile, ParamString, StartInDirectory: AnsiString; var AExitCode: DWORD; var AErrorCode: Integer): Boolean;
var
  processInfo: TProcessInformation;
  startupInfo: TStartupInfo;
  commandLine: AnsiString;
begin
  AExitCode := 0;
  AErrorCode := 0;

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

