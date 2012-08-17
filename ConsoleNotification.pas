unit ConsoleNotification;

interface

uses
  Notification;

type
  TConsoleNotification = class(TInterfacedObject, INotification)
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
  Windows;

procedure TConsoleNotification.ShowNotification(
  const Title: string;
  const Text: string;
  const ConsoleOutput: string;
  const NotificationType: TNotificationType);
var
  outputHandle: Cardinal;
  originalAttributes: Word;
  newAttributes: Word;
  screenBufferInfo: CONSOLE_SCREEN_BUFFER_INFO;
begin
  try
    outputHandle := GetStdHandle(STD_OUTPUT_HANDLE);

    GetConsoleScreenBufferInfo(outputHandle, screenBufferInfo);
    originalAttributes := screenBufferInfo.wAttributes;

    newAttributes := originalAttributes
                     and not FOREGROUND_INTENSITY
                     and not FOREGROUND_RED
                     and not FOREGROUND_GREEN
                     and not FOREGROUND_BLUE;

    if NotificationType = ntSuccess then
      newAttributes := newAttributes or FOREGROUND_GREEN or FOREGROUND_INTENSITY
    else
      newAttributes := newAttributes or FOREGROUND_RED or FOREGROUND_INTENSITY;

    if originalAttributes and BACKGROUND_INTENSITY > 0 then
      newAttributes := newAttributes and not FOREGROUND_INTENSITY;

    SetConsoleTextAttribute(outputHandle, newAttributes);
    Writeln(outputHandle, Text);
    if Trim(ConsoleOutput) <> EmptyStr then
    begin
      Writeln(outputHandle);
      Writeln(outputHandle, ConsoleOutput);
    end;

    SetConsoleTextAttribute(outputHandle, originalAttributes);
  except
  end;
end;

end.
