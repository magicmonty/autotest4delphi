unit AutoTestMainUnit;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  ImgList,
  CoolTrayIcon,
  ExtCtrls,
  StdCtrls,
  Menus,
  PassiveViewFramework;

type
  TMainForm = class(TControlledForm)
    Label1: TLabel;
    TestProjectEdit: TEdit;
    Label2: TLabel;
    StartStopButton: TButton;
    SelectTestProjectButton: TButton;
    AddWatchedDirectoryButton: TButton;
    WatchedDirectoryEdit: TEdit;
    PopupMenu1: TPopupMenu;
    MI_Show: TMenuItem;
    MI_Start: TMenuItem;
    MI_Stop: TMenuItem;
    MI_Hide: TMenuItem;
    N1: TMenuItem;
    MI_Quit: TMenuItem;
    TrayIcon: TCoolTrayIcon;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

end.

