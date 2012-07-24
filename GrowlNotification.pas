unit GrowlNotification;

interface

uses
  SysUtils,
  Classes;

type
  TNotificationType = (ntError, ntFailure, ntSuccess, ntNotify);

  TGrowlNotification = class
  private
    procedure SendCommand(Command: TBytesStream; const Wait: Boolean = False);
    function LoadPNGResource(Id: string; const Stream: TStream): string;
    procedure AddBinaryResource(Source: TMemoryStream; ID: string; Command: TBytesStream);
    procedure AddStringToCommand(Line: string; const command: TBytesStream);
    procedure AddEndOfRequest(command: TBytesStream);
  public
    procedure RegisterApplication;
    procedure SendNotification(Title, Text: string; NotificationType: TNotificationType);
  end;

  TSendCommand = class(TThread)
  private
    FData: TBytes;
  public
    constructor Create(Data: TBytes);
    procedure Execute; override;
  end;

const
  RESOURCE_BASE_URL = 'https://github.com/magicmonty/autotest4delphi/raw/master/resources/';
implementation

uses
  Windows,
  pngImage,
  DecHash,
  DecFmt,
  IdTcpClient,
  PrjConst;

procedure TGrowlNotification.RegisterApplication;
var
  command: TBytesStream;
  icon, errorIcon, successIcon: TMemoryStream;
  iconId, errorIconId, successIconId: string;
begin
  icon := TMemoryStream.Create;
  errorIcon := TMemoryStream.Create;
  successIcon := TMemoryStream.Create;
  command := TBytesStream.Create;
  command.Size := 0;
  try
    iconId := LoadPNGResource('icon', icon);
    errorIconId := LoadPNGResource('error_icon', errorIcon);
    successIconId := LoadPNGResource('success_icon', successIcon);

    AddStringToCommand('GNTP/1.0 REGISTER NONE', command);
    AddStringToCommand('Application-Name: Autotest4Delphi', command);
    if iconId <> '' then
      AddStringToCommand('Application-Icon: x-growl-resource://' + iconId, command)
    else
      AddStringToCommand('Application-Icon: ' + RESOURCE_BASE_URL + 'icon.png', command);

    AddStringToCommand('Notifications-Count: 4', command);
    AddStringToCommand('', command);
    AddStringToCommand('Notification-Name: success', command);
    AddStringToCommand('Notification-Display-Name: Success', command);
    AddStringToCommand('Notification-Enabled: True', command);
    if successIconId <> '' then
      AddStringToCommand('Notification-Icon: x-growl-resource://' + successIconId, command)
    else
      AddStringToCommand('Notification-Icon: ' + RESOURCE_BASE_URL + 'success_icon.png', command);
    AddStringToCommand('', command);
    AddStringToCommand('Notification-Name: error', command);
    AddStringToCommand('Notification-Display-Name: Error', command);
    AddStringToCommand('Notification-Enabled: True', command);
    if ErrorIconId <> '' then
      AddStringToCommand('Notification-Icon: x-growl-resource://' + errorIconId, command)
    else
      AddStringToCommand('Notification-Icon: ' + RESOURCE_BASE_URL + 'error_icon.png', command);
    AddStringToCommand('', command);
    AddStringToCommand('Notification-Name: failure', command);
    AddStringToCommand('Notification-Display-Name: Failure', command);
    AddStringToCommand('Notification-Enabled: True', command);
    if ErrorIconId <> '' then
      AddStringToCommand('Notification-Icon: x-growl-resource://' + errorIconId, command)
    else
      AddStringToCommand('Notification-Icon: ' + RESOURCE_BASE_URL + 'error_icon.png', command);
    AddStringToCommand('', command);
    AddStringToCommand('Notification-Name: notify', command);
    AddStringToCommand('Notification-Display-Name: Notify', command);
    AddStringToCommand('Notification-Enabled: True', command);
    if ErrorIconId <> '' then
      AddStringToCommand('Notification-Icon: x-growl-resource://' + iconId, command)
    else
      AddStringToCommand('Notification-Icon: ' + RESOURCE_BASE_URL + 'icon.png', command);

    AddBinaryResource(icon, iconId, command);
    AddBinaryResource(successIcon, successIconId, command);
    AddBinaryResource(errorIcon, errorIconId, command);

    AddEndOfRequest(command);

    SendCommand(command, true);
  finally
    FreeAndNil(command);
    FreeAndNil(icon);
    FreeAndNil(errorIcon);
    FreeAndNil(successIcon);
  end;
end;

procedure TGrowlNotification.SendCommand(Command: TBytesStream; const Wait: Boolean = False);
var
  cmd: TSendCommand;
begin
  if Wait then
  begin
    cmd := TSendCommand.Create(Command.Bytes);
    cmd.WaitFor;
  end
  else
    TSendCommand.Create(command.Bytes);

end;

procedure TGrowlNotification.SendNotification(Title, Text: string; NotificationType: TNotificationType);
var
  command: TBytesStream;
begin
  command := TBytesStream.Create();
  try
    AddStringToCommand('GNTP/1.0 NOTIFY NONE', command);
    AddStringToCommand('Application-Name: Autotest4Delphi', command);
    case NotificationType of
      ntError:
        begin
          AddStringToCommand('Notification-Name: error', command);
          AddStringToCommand('Notification-Priority: 2', command);
        end;
      ntFailure:
        begin
          AddStringToCommand('Notification-Name: failure', command);
          AddStringToCommand('Notification-Priority: 1', command);
        end;
      ntSuccess:
        begin
          AddStringToCommand('Notification-Name: success', command);
          AddStringToCommand('Notification-Priority: -1', command);
        end;
      ntNotify:
        begin
          AddStringToCommand('Notification-Name: notify', command);
          AddStringToCommand('Notification-Priority: 0', command);
        end;
    end;
    AddStringToCommand('Notification-ID: ' + IntToStr(GetTickCount), command);
    AddStringToCommand('Notification-Title: ' + Title, command);
    AddStringToCommand('Notification-Text: ' + Text, command);

    AddEndOfRequest(command);

    SendCommand(command);
  finally
    FreeAndNil(command);
  end;
end;

procedure TGrowlNotification.AddEndOfRequest(command: TBytesStream);
begin
  AddStringToCommand('', command);
  AddStringToCommand('', command);
end;

procedure TGrowlNotification.AddBinaryResource(Source: TMemoryStream; ID: string; Command: TBytesStream);
var
  streamSize: Int64;
begin
  if (ID <> '') and (Source.Size > 0) then
  begin
    AddStringToCommand('', Command);
    AddStringToCommand('Identifier: ' + ID, Command);
    AddStringToCommand('Length: ' + IntToStr(Source.Size), Command);
    AddStringToCommand('', Command);
    streamSize := Command.Size;
    Command.CopyFrom(Source, 0);
    Command.Size := streamSize + Source.Size;
    AddStringToCommand('', Command);
  end;
end;

procedure TGrowlNotification.AddStringToCommand(Line: string; const command: TBytesStream);
var
  tmp: PAnsiChar;
  bufferSize: Cardinal;
  streamSize: Int64;
  bytesWritten: Int64;
begin
  bufferSize := Length(AnsiString(Line) + #13#10);
  tmp := PAnsiChar(AnsiString(Line + #13#10));
  streamSize := command.Size;
  bytesWritten := command.Write(tmp^, bufferSize);
  command.Size := streamSize + bytesWritten;
end;

function TGrowlNotification.LoadPNGResource(Id: string; const Stream: TStream): string;
var
  png: TPngImage;
begin
  Result := '';

  if not Assigned(Stream) then
    exit;

  png := TPngImage.Create;
  try
    png.LoadFromResourceName(HInstance, Id);
    Stream.Size := 0;
    png.SaveToStream(Stream);

    Stream.Seek(0, soFromBeginning);
    if Stream.Size > 0 then
      Result := string(THash_MD5.CalcStream(Stream, Stream.Size, TFormat_HEXL));
    Stream.Seek(0, soFromBeginning);
  finally
    png.Free;
  end;
end;

{ TSendCommand }

constructor TSendCommand.Create(Data: TBytes);
begin
  inherited Create(true);
  FreeOnTerminate := true;
  FData := Data;
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
    client.ConnectTimeout := 100;
    client.Connect;
    if client.Connected then
      client.Socket.Write(FData);
  finally
    try
      client.Disconnect;
    finally
      FreeAndNil(client);
    end;
  end;
end;

end.
