unit Elements;

interface

uses Classes, Menus, PassiveViewFramework, Controls;

type
  TBaseComponentElement = class(TInterfacedObject, ITypedComponentElement)
  private
    FComponent: TComponentCracker;
    FControlMethod: TControlMethod;
  protected
    property Component: TComponentCracker read FComponent;
    function GetAsString : string; virtual;
    procedure SetAsString(const Value : string); virtual;
  public
    procedure Enable; virtual;
    procedure Disable; virtual;
    procedure Show; virtual;
    procedure Hide; virtual;

    constructor Create(AComponent: TComponent); virtual;
    destructor Destroy; override;
    function AsString : string;
    procedure SetControlMethod(ControlMethod: TControlMethod); virtual;
    procedure InternalOnClick(Sender: TObject);
  end;

  TBaseElement = class(TInterfacedObject, ITypedViewElement)
  private
    FControl : TControlCracker;
  protected
    property Control : TControlCracker read FControl;
    function GetAsString : string; virtual;
    procedure SetAsString(const Value : string); virtual;
  public
    procedure Enable;
    procedure Disable;
    procedure Show;
    procedure Hide;
    
    constructor Create(AControl : TControl); virtual;
    destructor Destroy; override;
    function AsString : string;
  end;

  TEditElement = class(TBaseElement, IEditElement)
  protected
    function GetAsString : string; override;
    procedure SetAsString(const Value : string); override;
  end;

  TButtonElement = class(TBaseElement, IButtonElement)
  protected
    function GetAsString : string; override;
    procedure SetAsString(const Value : string); override;
  end;

  TListElement = class(TBaseElement, IListElement)
  protected
    procedure ControlAddItem(const Item : string);
    procedure ControlDeleteItem(Index : Integer);
    function GetAsString : string; override;
    procedure SetAsString(const Value : string); override;
  public
    procedure AddItem(const Item : string);
    procedure DeleteItem(Index : Integer);
  end;

  TMenuItemElement = class(TBaseComponentElement, IMenuItemElement)
  public
    procedure Enable; override;
    procedure Disable; override;
    procedure Show; override;
    procedure Hide; override;
    function GetAsString : string; override;
    procedure SetAsString(const Value : string); override;
    procedure SetControlMethod(ControlMethod: TControlMethod); override;
  end;

implementation

uses SysUtils, StdCtrls;

{ TBaseElement }

constructor TBaseElement.Create(AControl: TControl);
begin
  FControl := TControlCracker(AControl);
end;

destructor TBaseElement.Destroy;
begin
  FControl := nil;
  inherited Destroy;
end;

procedure TBaseElement.Disable;
begin
  FControl.Enabled := false;
end;

procedure TBaseElement.Enable;
begin
  FControl.Enabled := true;
end;

function TBaseElement.GetAsString: string;
begin
  Result := '';
end;

procedure TBaseElement.Hide;
begin
  FControl.Visible := true;
end;

procedure TBaseElement.SetAsString(const Value: string);
begin
end;

procedure TBaseElement.Show;
begin
  FControl.Visible := false;
end;

function TBaseElement.AsString: string;
begin
  Result := GetAsString;
end;

{ TEditElement }

function TEditElement.GetAsString: string;
begin
  Result := '';
  if FControl.InheritsFrom(TCustomEdit) then
    Result := TCustomEdit(FControl).Text;
end;

procedure TEditElement.SetAsString(const Value: string);
begin
  if FControl.InheritsFrom(TCustomEdit) then
    TCustomEdit(FControl).Text := Value;
end;

{ TListElement }

procedure TListElement.AddItem(const Item: string);
begin
  ControlAddItem(Item);
end;

procedure TListElement.ControlAddItem(const Item: string);
begin
  if FControl.InheritsFrom(TCustomListBox) then
    TCustomListBox(FControl).Items.Add(Item);
end;

procedure TListElement.ControlDeleteItem(Index: Integer);
begin
  if FControl.InheritsFrom(TCustomListBox) then
    TCustomListBox(FControl).Items.Delete(Index);
end;

procedure TListElement.DeleteItem(Index: Integer);
begin
  ControlDeleteItem(Index);
end;

function TListElement.GetAsString: string;
begin
  if FControl.InheritsFrom(TCustomListBox) then begin
    Result := '"' + StringReplace(TCustomListBox(FControl).Items.Text, #13#10, '","', [rfReplaceAll]);
    Result := Copy(Result, 1, Length(Result) - 2);
  end;
end;

procedure TListElement.SetAsString(const Value: string);
begin
  if FControl.InheritsFrom(TCustomListBox) then
    TCustomListBox(FControl).Items.CommaText := Value;
end;

{ TButtonElement }

function TButtonElement.GetAsString: string;
begin
  Result := '';
  if FControl.InheritsFrom(TButton) then
    Result := TButton(FControl).Caption;
end;

procedure TButtonElement.SetAsString(const Value: string);
begin
  if FControl.InheritsFrom(TButton) then
    TButton(FControl).Caption := Value;
end;

{ TMenuItemElement }

procedure TMenuItemElement.Disable;
begin
  if FComponent.InheritsFrom(TMenuItem) then
    TMenuItem(FComponent).Enabled := false;
end;

procedure TMenuItemElement.Enable;
begin
  if FComponent.InheritsFrom(TMenuItem) then
    TMenuItem(FComponent).Enabled := true;
end;

function TMenuItemElement.GetAsString: string;
begin
  Result := '';

  if FComponent.InheritsFrom(TMenuItem) then
    Result := TMenuItem(FComponent).Caption;
end;

procedure TMenuItemElement.Hide;
begin
  if FComponent.InheritsFrom(TMenuItem) then
    TMenuItem(FComponent).Visible := false;
end;

procedure TMenuItemElement.SetAsString(const Value: string);
begin
  if FComponent.InheritsFrom(TMenuItem) then
    TMenuItem(FComponent).Caption := Value;
end;

procedure TMenuItemElement.SetControlMethod(ControlMethod: TControlMethod);
begin
  inherited SetControlMethod(ControlMethod);

  if FComponent.InheritsFrom(TMenuItem) then
  begin
    if Assigned(ControlMethod) then
      TMenuItem(FComponent).OnClick := InternalOnClick
    else
      TMenuItem(FComponent).OnClick := nil;
  end;
end;

procedure TMenuItemElement.Show;
begin
  if FComponent.InheritsFrom(TMenuItem) then
    TMenuItem(FComponent).Visible := true;
end;

{ TBaseComponentElement }

function TBaseComponentElement.AsString: string;
begin
  Result := GetAsString;
end;

constructor TBaseComponentElement.Create(AComponent: TComponent);
begin
  FComponent := TComponentCracker(AComponent);
end;

destructor TBaseComponentElement.Destroy;
begin
  FComponent := nil;
  inherited Destroy;
end;

procedure TBaseComponentElement.Disable;
begin

end;

procedure TBaseComponentElement.Enable;
begin

end;

function TBaseComponentElement.GetAsString: string;
begin
  Result := '';
end;

procedure TBaseComponentElement.Hide;
begin

end;

procedure TBaseComponentElement.InternalOnClick(Sender: TObject);
begin
  if Assigned(FControlMethod) then
    FControlMethod;
end;

procedure TBaseComponentElement.SetAsString(const Value: string);
begin

end;

procedure TBaseComponentElement.SetControlMethod(ControlMethod: TControlMethod);
begin
  FControlMethod := ControlMethod;
end;

procedure TBaseComponentElement.Show;
begin

end;

end.
