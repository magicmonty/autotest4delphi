unit GrowlNotification;

interface

uses
  Classes;

type
  TNotificationType = (ntError, ntFailure, ntSuccess);

  TGrowlNotification = class
  private
    procedure SendCommand(Command: TStringStream);
    function LoadPNGResource(Id: string; const Stream: TStream): string;
    procedure AddBinaryResource(Source: TMemoryStream; ID: string; Command: TStringStream);
    procedure AddStringToCommand(Line: string; const command: TStringStream);
  public
    procedure RegisterApplication;
    procedure SendNotification(Title, Text: string; NotificationType: TNotificationType);
  end;

  TSendCommand = class(TThread)
  private
    FDataString: AnsiString;
  public
    constructor Create(DataString: AnsiString);
    procedure Execute; override;
  end;
implementation

uses
  Windows,
  SysUtils,
  DecHash,
  DecFmt,
  IdTcpClient,
  PrjConst;

procedure TGrowlNotification.RegisterApplication;
var
  command: TStringStream;
  icon, errorIcon, successIcon: TMemoryStream;
  iconId, errorIconId, successIconId: string;
begin
  icon := TMemoryStream.Create;
  errorIcon := TMemoryStream.Create;
  successIcon := TMemoryStream.Create;
  command := TStringStream.Create('');
  try
    iconId := LoadPNGResource('icon', icon);
    errorIconId := LoadPNGResource('error_icon', errorIcon);
    successIconId := LoadPNGResource('success_icon', successIcon);

    AddStringToCommand('GNTP/1.0 REGISTER NONE', command);
    AddStringToCommand('Application-Name: Autotest4Delphi', command);
    if iconId <> EmptyStr then
      AddStringToCommand('Application-Icon: x-growl-resource://' + iconId, command)
    else
      AddStringToCommand('Application-Icon: ', command);
    AddStringToCommand('Notifications-Count: 3', command);
    AddStringToCommand('', command);
    AddStringToCommand('Notification-Name: success', command);
    AddStringToCommand('Notification-Display-Name: Success', command);
    AddStringToCommand('Notification-Enabled: True', command);
    if successIconId <> EmptyStr then
      AddStringToCommand('Notification-Icon: x-growl-resource://' + successIconId, command);
    AddStringToCommand('', command);
    AddStringToCommand('Notification-Name: error', command);
    AddStringToCommand('Notification-Display-Name: Error', command);
    AddStringToCommand('Notification-Enabled: True', command);
    if ErrorIconId <> EmptyStr then
      AddStringToCommand('Notification-Icon: x-growl-resource://' + errorIconId, command);
    AddStringToCommand('', command);
    AddStringToCommand('Notification-Name: failure', command);
    AddStringToCommand('Notification-Display-Name: Failure', command);
    AddStringToCommand('Notification-Enabled: True', command);
    if ErrorIconId <> EmptyStr then
      AddStringToCommand('Notification-Icon: x-growl-resource://' + errorIconId, command);

    AddBinaryResource(icon, iconId, command);
    AddBinaryResource(successIcon, successIconId, command);
    AddBinaryResource(errorIcon, errorIconId, command);

    AddStringToCommand('', command);
    AddStringToCommand('', command);

    SendCommand(command);
  finally
    FreeAndNil(command);
    FreeAndNil(icon);
    FreeAndNil(errorIcon);
    FreeAndNil(successIcon);
  end;
end;

procedure TGrowlNotification.SendCommand(Command: TStringStream);
begin
  TSendCommand.Create(command.DataString);
end;

procedure TGrowlNotification.SendNotification(Title, Text: string; NotificationType: TNotificationType);
var
  command: TStringStream;
begin
  command := TStringStream.Create('');
  try
    AddStringToCommand('GNTP/1.0 NOTIFY NONE', command);
    AddStringToCommand('Application-Name: Autotest4Delphi', command);
    case NotificationType of
      ntError: AddStringToCommand('Notification-Name: error', command);
      ntFailure: AddStringToCommand('Notification-Name: failure', command);
      ntSuccess: AddStringToCommand('Notification-Name: success', command);
    end;
    AddStringToCommand('Notification-ID: ' + IntToStr(GetTickCount), command);
    AddStringToCommand('Notification-Title: ' + Title, command);
    AddStringToCommand('Notification-Text: ' + Text, command);
    AddStringToCommand('', command);
    AddStringToCommand('', command);

    SendCommand(command);
  finally
    FreeAndNil(command);
  end;
end;

procedure TGrowlNotification.AddBinaryResource(Source: TMemoryStream; ID: string; Command: TStringStream);
begin
  if ID <> EmptyStr then
  begin
    AddStringToCommand('', Command);
    AddStringToCommand('Identifier: ' + ID, Command);
    AddStringToCommand('Length: ' + IntToStr(Source.Size), Command);
    AddStringToCommand('', Command);
    command.CopyFrom(Source, 0);
    AddStringToCommand('', Command);
  end;
end;

procedure TGrowlNotification.AddStringToCommand(Line: string; const command: TStringStream);
begin
  command.WriteString(Line + CRLF);
end;

function TGrowlNotification.LoadPNGResource(Id: string; const Stream: TStream): string;
var
  tmpStream: TResourceStream;
begin
  Result := '';

  if not Assigned(Stream) then
    exit;

  try
    tmpStream := TResourceStream.Create(HInstance, Id, 'PNG');
    try
      Stream.CopyFrom(tmpStream, tmpStream.Size);
      Stream.Seek(0, soFromBeginning);
      if Stream.Size > 0 then
        Result := THash_MD5.CalcStream(Stream, Stream.Size, TFormat_HEXL);
    finally
      FreeAndNil(tmpStream);
    end;
  except
    Result := '';
  end;
end;

{ TSendCommand }

constructor TSendCommand.Create(DataString: AnsiString);
begin
  inherited Create(true);
  FreeOnTerminate := true;
  FDataString := DataString;
  Resume;
end;

procedure TSendCommand.Execute;
var
  client: TIdTCPClient;
begin
  client := TIdTCPClient.Create(nil);
  try
    client.Host := '127.0.0.1';
    client.Port := 23053;
    client.ConnectTimeout := 10;
    client.Connect;
    if client.Connected then
      client.SendCmd(FDataString);
  finally
    try
      client.Disconnect;
    finally
      FreeAndNil(client);
    end;
  end;
end;

end.
