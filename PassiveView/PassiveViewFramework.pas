unit PassiveViewFramework;

interface

uses Menus, Classes, Controls, Forms;

type
  IController = interface;

  TControlMethod = procedure of object;

  ITypedViewElement = interface
  ['{D4637A5E-6A75-45F3-BC68-EF12854B1914}']
    procedure Enable;
    procedure Disable;
    procedure Show;
    procedure Hide;
    function GetAsString : string;
    procedure SetAsString(const Value : string);
    property AsString : string read GetAsString write SetAsString;
  end;

  IListElement = interface(ITypedViewElement)
  ['{D863607D-7BBB-46A7-A8DA-88B8C9A03CE2}']
    procedure AddItem(const Item : string);
    procedure DeleteItem(Index : Integer);
  end;

  ITypedComponentElement = interface
  ['{6B50A0B8-E75A-4A53-B44D-3F9780EF178D}']
    procedure Enable;
    procedure Disable;
    procedure Show;
    procedure Hide;
    
    function GetAsString : string;
    procedure SetAsString(const Value : string);
    property AsString : string read GetAsString write SetAsString;
    procedure SetControlMethod(ControlMethod : TControlMethod);
  end;
  
  IMenuItemElement  = interface(ITypedComponentElement)
  ['{E924CE82-A77F-47B5-9DA7-F3E9666BEE71}']
  end;

  IEditElement = interface(ITypedViewElement)
  ['{9F5349C2-2774-4315-B746-521D8897CE84}']
  end;

  IButtonElement = interface(ITypedViewElement)
  ['{9F5349C2-2774-4315-B746-521D8897CE84}']
  end;

  IElement = interface
  ['{E63F7EC9-85B6-4553-8154-122CDB967531}']
    procedure Activate;
    procedure Enable;
    procedure Disable;
    procedure Show;
    procedure Hide;

    procedure SetControlMethod(ControlMethod : TControlMethod);
    function AsMenuItem: IMenuItemElement;
  end;

  IViewElement = interface
  ['{852C6874-90E7-434D-9EB3-1F3B21A17FBE}']
    procedure Activate;
    procedure Enable;
    procedure Disable;
    procedure Show;
    procedure Hide;

    procedure SetControlMethod(ControlMethod : TControlMethod);
    function AsList : IListElement;
    function AsEdit : IEditElement;
    function AsButton : IButtonElement;
  end;

  IView = interface
  ['{D5C5C86D-0B08-4A49-883C-B2C4A37F5FA4}']
    function GetViewElement(const ID : string) : IViewElement;
    function GetComponent(const Id: string): IElement;
    procedure Show;
    procedure Hide;
    procedure Close;

    procedure Minimize;
    procedure Normalize;
    function IsMinimized: Boolean;
    function IsVisible: Boolean;
    function IsClosed: Boolean;
  end;

  IController = interface
  ['{2C35BE17-07FB-4304-BEC8-36FD087FE253}']
    function GetView : IView;
    procedure SetView(Value : IView);
    property View : IView read GetView write SetView;
    procedure ObserveViewElements;
    procedure Start;
    procedure Stop;
  end;

  TBaseComponentElement = class(TInterfacedObject, IElement)
  private
    FControlMethod: TControlMethod;
  protected
    function GetAsMenuItem : IMenuItemElement; virtual;
  public
    procedure Activate; virtual;
    procedure Enable; virtual;
    procedure Disable; virtual;
    procedure Show; virtual;
    procedure Hide; virtual; 
    procedure SetControlMethod(ControlMethod : TControlMethod); dynamic;
    function AsMenuItem: IMenuItemElement;
  end;

  TBaseViewElement = class(TInterfacedObject, IViewElement)
  private
    FControlMethod: TControlMethod;
  protected
    function GetAsList : IListElement; virtual;
    function GetAsEdit : IEditElement; virtual;
    function GetAsButton : IButtonElement; virtual;
  public
    procedure Activate; virtual;
    procedure Enable; virtual;
    procedure Disable; virtual;
    procedure Show; virtual;
    procedure Hide; virtual;
    procedure SetControlMethod(ControlMethod : TControlMethod); dynamic;
    function AsList : IListElement;
    function AsEdit : IEditElement;
    function AsButton : IButtonElement;
  end;


  TNullView = class(TInterfacedObject, IView)
  protected
    function GetViewElement(const ID : string) : IViewElement;
    function GetComponent(const Id: string): IElement;
    procedure Show;
    procedure Hide;
    procedure Close;
    function IsVisible : Boolean;
    function IsClosed: Boolean;

    procedure Minimize;
    procedure Normalize;
    function IsMinimized: Boolean;
  end;

  TController = class(TInterfacedObject, IController)
  private
    FView : IView;
    function GetView : IView;
    procedure SetView(Value : IView);
  protected
    property View : IView read GetView write SetView;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ObserveViewElements; virtual;
    procedure Start; virtual;
    procedure Stop; virtual;
  end;

  TComponentCracker = class(TComponent);
  TControlCracker = class(TControl);

  TGuiAdaptor = class(TBaseViewElement)
  private
    FControl : TControlCracker;
    procedure InternalOnClick(Sender : TObject);
  protected
    property Control : TControlCracker read FControl;
    procedure InitializeControl; virtual;
    function GetAsList : IListElement; override;
    function GetAsEdit : IEditElement; override;
    function GetAsButton : IButtonElement; override;
  public
    procedure Enable; override;
    procedure Disable; override;
    procedure Show; override;
    procedure Hide; override;

    constructor Create(AControl : TControl); virtual;
    destructor Destroy; override;
  end;

  TNonGuiAdaptor = class(TBaseComponentElement)
  private
    FComponent : TComponentCracker;
  protected
    property Component : TComponentCracker read FComponent;
    function GetAsMenuItem : IMenuItemElement; override;
  public
    constructor Create(AComponent : TComponent); virtual;
    destructor Destroy; override;
  end;
  
  TControlledForm = class(TForm, IView)
  private
    FIsClosed: Boolean;
  protected
    function GetViewElement(const Id : string) : IViewElement; virtual;
    function GetComponent(const Id: string): IElement;
    function IsVisible : Boolean; virtual;
    function IsClosed: Boolean; virtual;

    procedure Minimize;
    procedure Normalize;
    function IsMinimized: Boolean;
    procedure DoCreate; override;
    procedure DoClose(var Action: TCloseAction); override;
  end;

implementation

uses Elements;

{ TController }

constructor TController.Create;
begin
  FView := TNullView.Create;
end;

destructor TController.Destroy;
begin
  FView := nil;
  inherited;
end;

function TController.GetView: IView;
begin
  Result := FView;
end;

procedure TController.ObserveViewElements;
begin
end;

procedure TController.SetView(Value: IView);
begin
  FView := nil;
  FView := Value;
  if not Assigned(FView) then
    FView := TNullView.Create;
end;

procedure TController.Start;
begin
  ObserveViewElements;
  View.Show;  
end;

procedure TController.Stop;
begin
  View.Close;
end;

{ TNullView }

procedure TNullView.Close;
begin
end;

function TNullView.GetViewElement(const ID: string): IViewElement;
begin
  Result := TBaseViewElement.Create;
end;

procedure TNullView.Hide;
begin

end;

function TNullView.GetComponent(const ID: string): IElement;
begin
  Result := TBaseComponentElement.Create;
end;

function TNullView.IsClosed: Boolean;
begin
  Result := true;
end;

function TNullView.IsMinimized: Boolean;
begin
  Result := false;
end;

function TNullView.IsVisible: Boolean;
begin
  Result := False;
end;

procedure TNullView.Minimize;
begin

end;

procedure TNullView.Normalize;
begin

end;

procedure TNullView.Show;
begin
end;

{ TBaseViewElement }

procedure TBaseViewElement.Activate;
begin
  if Assigned(FControlMethod) then
    FControlMethod;
end;

function TBaseViewElement.AsEdit: IEditElement;
begin
  Result := GetAsEdit;
end;

function TBaseViewElement.AsButton: IButtonElement;
begin
  Result := GetAsButton;
end;

function TBaseViewElement.AsList: IListElement;
begin
  Result := GetAsList;
end;

procedure TBaseViewElement.Disable;
begin
  
end;

procedure TBaseViewElement.Enable;
begin

end;

function TBaseViewElement.GetAsEdit: IEditElement;
begin
  Result := nil;
end;

function TBaseViewElement.GetAsButton: IButtonElement;
begin
  Result := nil;
end;

function TBaseViewElement.GetAsList: IListElement;
begin
  Result := nil;
end;

procedure TBaseViewElement.Hide;
begin

end;

procedure TBaseViewElement.SetControlMethod(ControlMethod: TControlMethod);
begin
  FControlMethod := ControlMethod;
end;

procedure TBaseViewElement.Show;
begin

end;

{ TGuiDecorator }

constructor TGuiAdaptor.Create(AControl: TControl);
begin
  inherited Create;
  FControl := TControlCracker(AControl);
  InitializeControl;
end;

destructor TGuiAdaptor.Destroy;
begin
  FControl := nil;
  inherited;
end;

procedure TGuiAdaptor.Disable;
begin
  FControl.Enabled := false;
end;

procedure TGuiAdaptor.Enable;
begin
  FControl.Enabled := true;
end;

function TGuiAdaptor.GetAsEdit: IEditElement;
begin
  Result := TEditElement.Create(Control);
end;

function TGuiAdaptor.GetAsList: IListElement;
begin
  Result := TListElement.Create(Control);
end;

procedure TGuiAdaptor.Hide;
begin
  FControl.Visible := false;
end;

function TGuiAdaptor.GetAsButton: IButtonElement;
begin
  Result := TButtonElement.Create(Control);
end;

procedure TGuiAdaptor.InitializeControl;
begin
  FControl.OnClick := InternalOnClick;
end;

procedure TGuiAdaptor.InternalOnClick(Sender: TObject);
begin
  Activate;
end;

procedure TGuiAdaptor.Show;
begin
  FControl.Visible := true;
end;

{ TControlledForm }

function TControlledForm.GetViewElement(const Id: string): IViewElement;
var
  Control: TControl;
begin
  Control := FindChildControl(Id);
  if Assigned(Control) then
    Result := TGuiAdaptor.Create(Control)
  else
    Result := TBaseViewElement.Create;
end;

procedure TControlledForm.DoClose(var Action: TCloseAction);
begin
  inherited DoClose(Action);
  if Action in [caHide, caFree] then
    FIsClosed := true;
end;

procedure TControlledForm.DoCreate;
begin
  inherited;
  FIsClosed := false;
end;

function TControlledForm.GetComponent(const Id: string): IElement;
var
  Component: TComponent;
begin
  Component := Self.FindComponent(Id);
  if Assigned(Component) then
  begin
    Result := TNonGuiAdaptor.Create(Component)
  end
  else
    Result := TBaseComponentElement.Create;
end;

function TControlledForm.IsClosed: Boolean;
begin
  Result := FIsClosed;
end;

function TControlledForm.IsMinimized: Boolean;
begin
  Result := WindowState = wsMinimized;
end;

function TControlledForm.IsVisible: Boolean;
begin
  Result := Visible = True;
end;

procedure TControlledForm.Minimize;
begin
  WindowState := wsMinimized;
end;

procedure TControlledForm.Normalize;
begin
  WindowState := wsNormal;
end;

procedure TBaseComponentElement.Activate;
begin
  if Assigned(FControlMethod) then
    FControlMethod;
end;

function TBaseComponentElement.AsMenuItem: IMenuItemElement;
begin
  Result := GetAsMenuItem;
end;

procedure TBaseComponentElement.Disable;
begin

end;

procedure TBaseComponentElement.Enable;
begin

end;

function TBaseComponentElement.GetAsMenuItem: IMenuItemElement;
begin
  Result := nil;
end;

procedure TBaseComponentElement.Hide;
begin

end;

procedure TBaseComponentElement.SetControlMethod(ControlMethod: TControlMethod);
begin
  FControlMethod := ControlMethod;
end;

procedure TBaseComponentElement.Show;
begin

end;

{ TNonGuiAdaptor }

constructor TNonGuiAdaptor.Create(AComponent: TComponent);
begin
  inherited Create;
  FComponent := TComponentCracker(AComponent);
end;

destructor TNonGuiAdaptor.Destroy;
begin
  FComponent := nil;
  inherited;
end;

function TNonGuiAdaptor.GetAsMenuItem: IMenuItemElement;
begin
  Result := TMenuItemElement.Create(Component);
end;

end.
