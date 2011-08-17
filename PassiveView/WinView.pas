unit WinView;

interface

uses PassiveViewFramework;

procedure WaitForView(AView : IView);

implementation

uses Windows, SysUtils, Forms;

procedure WaitForView(AView : IView);
var
  Event : THandle;
begin
  Event := CreateEvent(nil, True, False, PAnsiChar(IntToStr(hInstance)));
  while True do begin
    WaitForSingleObject(Event, 20);
    Application.ProcessMessages;
    if AView.IsClosed then
      Break;
  end;
  CloseHandle(Event);
end;

end.
