unit Notification;

interface

type
  TNotificationType = (ntError, ntFailure, ntSuccess, ntNotify);

  INotification = interface
    ['{3CE07271-5821-477E-9B5A-7AB2E1413B3F}']
    procedure ShowNotification(
      const Title: string;
      const Text: string;
      const ConsoleOutput: string;
      const NotificationType: TNotificationType
    );
  end;

implementation

end.
