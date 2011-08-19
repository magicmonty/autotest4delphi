program autotest4delphi;

{$R 'resources\resources.res' 'resources\resources.rc'}

uses
  Forms,
  ActiveObjectEngine in 'ActiveObjectEngine.pas',
  DirWatcher in 'DirWatcher.pas',
  TestCommand in 'TestCommand.pas',
  Elements in 'PassiveView\Elements.pas',
  PassiveViewFramework in 'PassiveView\PassiveViewFramework.pas',
  WinView in 'PassiveView\WinView.pas',
  AutoTestMainUnit in 'views\AutoTestMainUnit.pas' {MainForm},
  AutoTestMainController in 'controllers\AutoTestMainController.pas',
  GrowlNotification in 'GrowlNotification.pas',
  PrjConst in 'PrjConst.pas';

{$R *.res}

var
  MainController : IController;

  begin
  Application.Initialize;
  Application.Title := 'Autotest for Delphi';
  Application.Run;
  
  MainController := TMainFormController.Create;
  MainController.View := TMainForm.Create(Application);
  MainController.Start;
  WaitForView(MainController.View);
  MainController.Stop;
end.
