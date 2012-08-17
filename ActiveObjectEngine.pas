unit ActiveObjectEngine;

interface

uses
  Forms,
  StdCtrls,
  Notification,
  GrowlNotifier,
  Classes;

type
  ICommand = interface
  ['{D2FCD7B7-7263-4F67-8783-048E5AB31AD0}']
    procedure SetNotification(const ANotification: INotification);
    procedure Execute;
  end;

  TActiveObjectEngine = class
  private
    FCommands: TInterfaceList;
    FStop: Boolean;
    FExecuting: Boolean;
    FRunning: Boolean;
    FNotification: INotification;
  public
    property Stopped: Boolean read FStop write FStop;

    property Executing: Boolean read FExecuting;
    property Running: Boolean read FRunning;

    constructor Create(const ANotification: INotification);
    destructor Destroy; override;

    procedure AddCommand(ACommand: ICommand);
    procedure Stop;
    procedure Run;
  end;

  TCommand = class(TInterfacedObject, ICommand)
  strict private
    FNotification: INotification;
    FEngine: TActiveObjectEngine;
  protected
    property Engine: TActiveObjectEngine read FEngine;
    procedure ShowNotification(
      const ATitle: string;
      const AText: string;
      const AConsoleOutput: string;
      const ANotificationType: TNotificationType); virtual;
  public
    constructor Create(const AEngine: TActiveObjectEngine);

    procedure SetNotification(const ANotification: INotification); virtual;
    procedure Execute; virtual; abstract;
  end;

  TSleepCommand = class(TCommand)
  strict private
    FWakeupCommand: ICommand;
    FSleepTime: Int64;
    FStartTime: Int64;
    FStarted: Boolean;
  public
    constructor Create(
      AEngine: TActiveObjectEngine;
      ASleepTimeInMilliseconds: Longint;
      AWakeupCommand: ICommand);
    procedure Execute; override;
  end;

  TStopCommand = class(TCommand)
  public
    procedure Execute; override;
  end;

  TLoopCommand = class(TCommand)
  public
    procedure Execute; override;
  end;

implementation

uses
  Windows,
  DateUtils,
  SysUtils,
  PrjConst;

constructor TActiveObjectEngine.Create(const ANotification: INotification);
begin
  inherited Create;
  FStop := false;
  FCommands := TInterfaceList.Create;
  FNotification := ANotification;
end;

destructor TActiveObjectEngine.Destroy;
begin
  FreeAndNil(FCommands);
  inherited Destroy;
end;

procedure TActiveObjectEngine.AddCommand(ACommand: ICommand);
begin
  FCommands.Add(ACommand);
end;

procedure TActiveObjectEngine.Run;
var
  command: ICommand;
begin
  FStop := false;

  while FCommands.Count > 0 do
  begin
    FRunning := true;
    command := FCommands.Items[0] as ICommand;
    command.SetNotification(FNotification);
    FCommands.Delete(0);
    FExecuting := true;
    try
      command.Execute;
    finally
      Sleep(1);
      Application.ProcessMessages;
      FExecuting := false;
    end;
  end;

  FRunning := false;
end;

procedure TActiveObjectEngine.Stop;
begin
  AddCommand(TStopCommand.Create(self));
end;

{ TSleepCommand }

constructor TSleepCommand.Create(
  AEngine: TActiveObjectEngine;
  ASleepTimeInMilliseconds: Integer;
  AWakeupCommand: ICommand);
begin
  inherited Create(Engine);
  FSleepTime := ASleepTimeInMilliseconds;
  FStarted := false;
  FStartTime := 0;
  FWakeupCommand := AWakeupCommand;
end;

procedure TSleepCommand.Execute;
var
  currentTime, elapsedTime: Int64;
begin
  currentTime := DateTimeToUnix(Now) * 1000;
  if not FStarted then
  begin
    FStarted := true;
    FStartTime := currentTime;
    Engine.AddCommand(Self);
  end
  else
  begin
    if not Engine.Stopped then
    begin
      elapsedTime := currentTime - FStartTime;
      if (elapsedTime < FSleepTime) then
        Engine.AddCommand(Self)
      else
        Engine.AddCommand(FWakeupCommand);
    end;
  end;
  Sleep(1);
  Application.ProcessMessages;
end;

{ TStopCommand }

procedure TStopCommand.Execute;
begin
  Engine.Stopped := true;
end;


{ TLoopCommand }

procedure TLoopCommand.Execute;
begin
  if not Engine.Stopped then
  begin
    Sleep(100);
    Engine.AddCommand(Self)
  end;
end;

{ TCommand }

constructor TCommand.Create(const AEngine: TActiveObjectEngine);
begin
  inherited Create;
  FEngine := AEngine;
  FNotification := nil;
end;

procedure TCommand.SetNotification(const ANotification: INotification);
begin
  FNotification := ANotification;
end;

procedure TCommand.ShowNotification(
  const ATitle: string;
  const AText: string;
  const AConsoleOutput: string;
  const ANotificationType: TNotificationType);
begin
  if Assigned(FNotification) then
    FNotification.ShowNotification(
      ATitle,
      AText,
      AConsoleOutput,
      ANotificationType
    );
end;

end.
