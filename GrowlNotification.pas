unit GrowlNotification;

interface

type
  TNotificationType = (ntError, ntFailure, ntSuccess);
  
  TGrowlNotification = class
  private
    procedure SendCommand(Command: string);
  public
    procedure RegisterApplication;
    procedure SendNotification(Title, Text: string; NotificationType: TNotificationType);
  end;

implementation

uses
  Windows,
  SysUtils,
  Classes,
  IdTcpClient;
{ TGrowlNotification }

procedure TGrowlNotification.RegisterApplication;
var
  command: TStringList;
  stream: TStringStream;
begin
  command := TStringList.Create;
  try
    command.Add('GNTP/1.0 REGISTER NONE');
    command.Add('Application-Name: Autotest4Delphi');
    command.Add('Application-Icon: http://dunit.sourceforge.net/images/xtao128_new.png');
    command.Add('Notifications-Count: 3');
    command.Add('');
    command.Add('Notification-Name: success');
    command.Add('Notification-Display-Name: Success');
    command.Add('Notification-Enabled: True');
    command.Add('Notification-Icon: http://icons.iconarchive.com/icons/custom-icon-design/pretty-office/128/success-icon.png');
    command.Add('');
    command.Add('Notification-Name: error');
    command.Add('Notification-Display-Name: Error');
    command.Add('Notification-Enabled: True');
    command.Add('Notification-Icon: http://icons.iconarchive.com/icons/iconarchive/red-orb-alphabet/128/Letter-X-icon.png');
    command.Add('');
    command.Add('Notification-Name: failure');
    command.Add('Notification-Display-Name: Failure');
    command.Add('Notification-Enabled: True');
    command.Add('Notification-Icon: http://icons.iconarchive.com/icons/iconarchive/red-orb-alphabet/128/Letter-X-icon.png');
    command.Add('');
    command.Add('');

    SendCommand(command.Text);
  finally
    FreeAndNil(command);
  end;
end;

procedure TGrowlNotification.SendCommand(Command: string);
var
  client: TIdTCPClient;
begin
  client := TIdTCPClient.Create(nil);
  try
    client.Host := '127.0.0.1';
    client.Port := 23053;
    client.Connect;
    client.SendCmd(Command);
  finally
    FreeAndNil(client);
  end;
end;

procedure TGrowlNotification.SendNotification(Title, Text: string; NotificationType: TNotificationType);
var
  command: TStringList;
begin
  command := TStringList.Create;
  try
    command.Add('GNTP/1.0 NOTIFY NONE');
    command.Add('Application-Name: Autotest4Delphi');
    case NotificationType of
      ntError: command.Add('Notification-Name: error');
      ntFailure: command.Add('Notification-Name: failure');
      ntSuccess: command.Add('Notification-Name: success');
    end;
    command.Add('Notification-ID: ' + IntToStr(GetTickCount));
    command.Add('Notification-Title: ' + Title);
    command.Add('Notification-Text: ' + Text);
    command.Add('');
    command.Add('');

    SendCommand(command.Text);
  finally
    FreeAndNil(command);
  end;
end;

end.
