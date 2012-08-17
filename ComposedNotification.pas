unit ComposedNotification;

interface

uses
  Generics.Collections,
  Notification;

type
  TComposedNotification = class(TInterfacedObject, INotification)
  strict private
    FNotifications: TList<INotification>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ShowNotification(
      const Title: string;
      const Text: string;
      const ConsoleOutput: string;
      const NotificationType: TNotificationType
    );

    function AddNotifier(const ANotifier: INotification): TComposedNotification;
  end;

implementation

{ TComposedNotification }

constructor TComposedNotification.Create;
begin
  inherited Create;
  FNotifications := TList<INotification>.Create;
end;

destructor TComposedNotification.Destroy;
begin
  FNotifications.Free;
  inherited;
end;

function TComposedNotification.AddNotifier(const ANotifier: INotification): TComposedNotification;
begin
  FNotifications.Add(ANotifier);
  Result := Self;
end;

procedure TComposedNotification.ShowNotification(
  const Title: string;
  const Text: string;
  const ConsoleOutput: string;
  const NotificationType: TNotificationType);
var
  CurrentNotification: INotification;
begin
  for CurrentNotification in FNotifications do
    CurrentNotification.ShowNotification(Title, Text, ConsoleOutput, NotificationType);
end;

end.
