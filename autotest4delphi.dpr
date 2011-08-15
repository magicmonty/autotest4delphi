program autotest4delphi;

uses
  Forms,
  AutoTestMainUnit in 'AutoTestMainUnit.pas' {MainForm},
  ActiveObjectEngine in 'ActiveObjectEngine.pas',
  DirWatcher in 'DirWatcher.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Autotest for Delphi';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
