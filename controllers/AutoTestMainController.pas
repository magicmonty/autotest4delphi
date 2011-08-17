unit AutoTestMainController;

interface

uses
  Dialogs,
  Menus,
  DirWatcher,
  ActiveObjectEngine,
  PassiveViewFramework;

type
  TMainFormController = class(TController)
  private
    FCount: Integer;
    FDirWatcher: TDirectoryMonitor;
    FTestEngine: TActiveObjectEngine;

    FStartStopButton: IViewElement;
    FSelectTestProjectButton: IViewElement;
    FAddWatchedDirectoryButton: IViewElement;
    FTestProjectEdit: IEditElement;
    FWatchedDirectoryEdit: IEditElement;

    FStartMenuItem: IMenuItemElement;
    FStopMenuItem: IMenuItemElement;
    FShowMenuItem: IMenuItemElement;
    FHideMenuItem: IMenuItemElement;
    FQuitMenuItem: IMenuItemElement;

    procedure SelectTestProjectButtonClick;
    procedure AddWatchedDirectoryButtonClick;
    procedure StartButtonClick;
    procedure StopButtonClick;
    procedure QuitMenuItemClick;
    procedure ShowMenuItemClick;
    procedure HideMenuItemClick;

    procedure FDirWatcherOnDirectoryChange(Sender: TObject; Action: TDirectoryAction; FileName: AnsiString);
    procedure TrayIconDblClick;
    procedure StopWatching;
  public
    procedure ObserveViewElements; override;

    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

uses
  Registry,
  Windows,
  FileCtrl,
  SysUtils,
  CoolTrayIcon,
  TestCommand,
  GrowlNotification;

constructor TMainFormController.Create;
var
  notifier: TGrowlNotification;
begin
  inherited Create;

  notifier := TGrowlNotification.Create;
  try
    try
      notifier.RegisterApplication;
    except
    end;
  finally
    FreeAndNil(notifier);
  end;

  FDirWatcher := TDirectoryMonitor.Create;
end;

destructor TMainFormController.Destroy;
begin
  FDirWatcher.OnDirectoryChange := nil;
  FDirWatcher.Stop;
  FreeAndNil(FDirWatcher);

  inherited Destroy;
end;

procedure TMainFormController.StopWatching;
begin
  FDirWatcher.Stop;
  if Assigned(FTestEngine) then
    FTestEngine.Stop;
end;

procedure TMainFormController.ObserveViewElements;
var
  reg: TRegistry;
begin
  FStartStopButton := View.GetViewElement('StartStopButton');
  FStartStopButton.SetControlMethod(StartButtonClick);
  FSelectTestProjectButton := View.GetViewElement('SelectTestProjectButton');
  FSelectTestProjectButton.SetControlMethod(SelectTestProjectButtonClick);
  FAddWatchedDirectoryButton := View.GetViewElement('AddWatchedDirectoryButton');
  FAddWatchedDirectoryButton.SetControlMethod(AddWatchedDirectoryButtonClick);
  FTestProjectEdit := View.GetViewElement('TestProjectEdit').AsEdit;
  FWatchedDirectoryEdit := View.GetViewElement('WatchedDirectoryEdit').AsEdit;

  FStartMenuItem := View.GetComponent('MI_Start').AsMenuItem;
  FStartMenuItem.SetControlMethod(StartButtonClick);
  FStopMenuItem := View.GetComponent('MI_Stop').AsMenuItem;
  FStopMenuItem.SetControlMethod(StopButtonClick);
  FQuitMenuItem := View.GetComponent('MI_Quit').AsMenuItem;
  FQuitMenuItem.SetControlMethod(QuitMenuItemClick);
  FShowMenuItem := View.GetComponent('MI_Show').AsMenuItem;
  FShowMenuItem.SetControlMethod(ShowMenuItemClick);
  FHideMenuItem := View.GetComponent('MI_Hide').AsMenuItem;
  FHideMenuItem.SetControlMethod(HideMenuItemClick);

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.OpenKey('Software\Pagansoft\Autotest4Delphi', true);
    FTestProjectEdit.AsString := reg.ReadString('Testproject');
    FWatchedDirectoryEdit.AsString := reg.ReadString('WatchedDirectory');
  finally
    FreeAndNil(reg);
  end;
end;

procedure TMainFormController.QuitMenuItemClick;
begin
  StopWatching;
  View.Close;
end;

procedure TMainFormController.AddWatchedDirectoryButtonClick;
var
  dir: string;
begin
  if SelectDirectory('Add directory to watch for changes', '', dir) then
  begin
    if dir[Length(dir)] = '\' then
      SetLength(dir, Length(dir) - 1);

    FWatchedDirectoryEdit.AsString := dir;
  end;
end;

procedure TMainFormController.SelectTestProjectButtonClick;
var
  openDialog: TOpenDialog;
  path: string;
begin
  openDialog := TOpenDialog.Create(nil);
  try
    openDialog.DefaultExt := '.dpr';
    openDialog.Filter := '*.dpr|*.dpr';
    openDialog.FilterIndex := 1;
    openDialog.Title := 'Select Test project';
    if openDialog.Execute then
    begin
      FTestProjectEdit.AsString := openDialog.FileName;

      path := ExtractFilePath(openDialog.FileName);
      if path[Length(path)] = '\' then
        path := Copy(path, 1, Length(path) - 1);

      FWatchedDirectoryEdit.AsString := path;
    end;
  finally
    FreeAndNil(openDialog);
  end;
end;

procedure TMainFormController.StartButtonClick;
var
  reg: TRegistry;
begin
  FCount := 0;
  if FileExists(FTestProjectEdit.AsString)
  and DirectoryExists(FWatchedDirectoryEdit.AsString) then
  begin
    reg := TRegistry.Create;
    try
      reg.RootKey := HKEY_CURRENT_USER;
      reg.OpenKey('Software\Pagansoft\Autotest4Delphi', true);
      reg.WriteString('Testproject', FTestProjectEdit.AsString);
      reg.WriteString('WatchedDirectory', FWatchedDirectoryEdit.AsString);
    finally
      FreeAndNil(reg);
    end;

    FAddWatchedDirectoryButton.Disable;
    FSelectTestProjectButton.Disable;
    FTestProjectEdit.Disable;
    FWatchedDirectoryEdit.Disable;
    FStartStopButton.AsButton.AsString := 'Stop';
    FStartStopButton.SetControlMethod(StopButtonClick);
    
    FStartMenuItem.Disable;
    FStopMenuItem.Enable;

    HideMenuItemClick;

    TrayIconDblClick;

    FTestEngine := TActiveObjectEngine.Create;

    FDirWatcher.WatchSubFolders := true;
    FDirWatcher.DirectoryToWatch := FWatchedDirectoryEdit.AsString;
    FDirWatcher.Options := [awChangeLastWrite, awChangeCreation];
    FDirWatcher.OnDirectoryChange := FDirWatcherOnDirectoryChange;
    FDirWatcher.Start;
  end;
end;

procedure TMainFormController.StopButtonClick;
begin
  FAddWatchedDirectoryButton.Enable;
  FSelectTestProjectButton.Enable;
  FTestProjectEdit.Enable;
  FWatchedDirectoryEdit.Enable;
  FStartStopButton.AsButton.AsString := 'Start';
  FStartStopButton.SetControlMethod(StartButtonClick);
  FStartMenuItem.Enable;
  FStopMenuItem.Disable;

  StopWatching;

  ShowMenuItemClick;
end;

procedure TMainFormController.FDirWatcherOnDirectoryChange(Sender: TObject; Action: TDirectoryAction; FileName: AnsiString);
var
  extension: string;
begin
  extension := ExtractFileExt(FileName);
  if (Action = daFileAdded)
    or (Action = daFileModified)
    and (
    (extension = '.pas')
    or (extension = '.inc')
    or (LowerCase(FDirWatcher.DirectoryToWatch + '\' + FileName) = LowerCase(FTestProjectEdit.AsString))
    ) then
  begin
    if FTestEngine.Stopped or (not FTestEngine.Running and not FTestEngine.Executing) then
    begin
      Inc(FCount);
      FTestEngine.AddCommand(TTestCommand.Create(FTestEngine, FTestProjectEdit.AsString, FCount));
      if not FTestEngine.Running or FTestEngine.Stopped then
        FTestEngine.Run;
    end;
  end;
end;

procedure TMainFormController.ShowMenuItemClick;
begin
  View.Normalize;
  View.Show;
  FShowMenuItem.Disable;
  FHideMenuItem.Enable;
end;

procedure TMainFormController.HideMenuItemClick;
begin
  View.Hide;
  View.Minimize;
  FShowMenuItem.Enable;
  FHideMenuItem.Disable;
end;

procedure TMainFormController.TrayIconDblClick;
begin
  if View.IsVisible then
  begin
    // View.Show;
    FShowMenuItem.Disable;
    FHideMenuItem.Enable;
  end
  else
  begin
    // View.Hide;
    FShowMenuItem.Enable;
    FHideMenuItem.Disable;
  end;
end;

end.
