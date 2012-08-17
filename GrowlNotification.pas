unit GrowlNotification;

interface

uses
  Notification;

type
  TGrowlNotification = class(TInterfacedObject, INotification)
  public
    procedure ShowNotification(
      const Title: string;
      const Text: string;
      const ConsoleOutput: string;
      const NotificationType: TNotificationType
    );
  end;

implementation

uses
  SysUtils,
  PrjConst,
  GrowlNotifier;


procedure TGrowlNotification.ShowNotification(
  const Title: string;
  const Text: string;
  const ConsoleOutput: string;
  const NotificationType: TNotificationType);
var
  notifier: TGrowlNotifier;
begin
  try
    notifier := TGrowlNotifier.Create;
    try
      notifier.SendNotification(
        Title,
        Trim(StringReplace(Text, CRLF, LF, [rfReplaceAll])),
        NotificationType
      );
    finally
      FreeAndNil(notifier);
    end;
  except
  end;
end;

end.
