unit ActiveObjectEngine;

interface

uses
  Forms,
  StdCtrls,
  Classes;

type
  ICommand = interface
  ['{D2FCD7B7-7263-4F67-8783-048E5AB31AD0}']
    procedure Execute;
  end;

  TCommand = class(TInterfacedObject, ICommand)
  public
    procedure Execute; virtual; abstract;
  end;

  TActiveObjectEngine = class
  private
    FCommands: TInterfaceList;
    FStop: Boolean;
    FExecuting: Boolean;
    FRunning: Boolean;
  public
    property Stopped: Boolean read FStop write FStop;

    property Executing: Boolean read FExecuting;
    property Running: Boolean read FRunning;

    constructor Create;
    destructor Destroy; override;

    procedure AddCommand(Command: ICommand);
    procedure Stop;
    procedure Run;
  end;

  TSleepCommand = class(TInterfacedObject, ICommand)
  private
    FWakeupCommand: ICommand;
    FEngine: TActiveObjectEngine;
    FSleepTime: Int64;
    FStartTime: Int64;
    FStarted: Boolean;
  public
    constructor Create(Milliseconds: Longint; Engine: TActiveObjectEngine; WakeupCommand: ICommand);
    procedure Execute;
  end;

  TStopCommand = class(TInterfacedObject, ICommand)
  private
    FEngine: TActiveObjectEngine;
  public
    constructor Create(Engine: TActiveObjectEngine);
    procedure Execute;
  end;

  TLoopCommand = class(TInterfacedObject, ICommand)
  private
    FEngine: TActiveObjectEngine;
  public
    constructor Create(Engine: TActiveObjectEngine);
    procedure Execute;
  end;

implementation

uses
  DateUtils,
  SysUtils;

constructor TActiveObjectEngine.Create;
begin
  inherited Create;
  FStop := false;
  FCommands := TInterfaceList.Create;
end;

destructor TActiveObjectEngine.Destroy;
begin
  FreeAndNil(FCommands);
  inherited Destroy;
end;

procedure TActiveObjectEngine.AddCommand(Command: ICommand);
begin
  FCommands.Add(Command);
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

constructor TSleepCommand.Create(Milliseconds: Integer; Engine: TActiveObjectEngine; WakeupCommand: ICommand);
begin
  FSleepTime := Milliseconds;
  FStarted := false;
  FStartTime := 0;
  FEngine := Engine;
  FWakeupCommand := WakeupCommand;
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
    FEngine.AddCommand(Self);
  end
  else
  begin
    if not FEngine.Stopped then
    begin
      elapsedTime := currentTime - FStartTime;
      if (elapsedTime < FSleepTime) then
        FEngine.AddCommand(Self)
      else
        FEngine.AddCommand(FWakeupCommand);
    end;
  end;
  Sleep(1);
  Application.ProcessMessages;
end;

{ TStopCommand }

constructor TStopCommand.Create(Engine: TActiveObjectEngine);
begin
  inherited Create;
  FEngine := Engine;
end;

procedure TStopCommand.Execute;
begin
  FEngine.Stopped := true;
end;


{ TLoopCommand }

constructor TLoopCommand.Create(Engine: TActiveObjectEngine);
begin
  inherited Create;
  FEngine := Engine;
end;

procedure TLoopCommand.Execute;
begin
  if not FEngine.Stopped then
  begin
    Sleep(100);
    FEngine.AddCommand(Self)
  end;
end;

end.
