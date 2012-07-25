unit SampleTest;

interface

uses
  Generics.Collections,
  TestFramework,
  Classes;

type
  TIntegerList = TList<Integer>;

  TAdder = class
    FSummands: TIntegerList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddSummand(const ASummand: Integer);
    function Sum: Integer;
    procedure Reset;
  end;

  TestTAdder = class(TTestCase)
  strict private
    FAdder: TAdder;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure WhenNoSummand_SumShouldBe_0;
    procedure WhenOnlyOneSummand_SumShouldBe_TheSummand;
    procedure TheSumOf_2_And_2_ShouldBe_4;
    procedure TheSumOf_40_And_2_ShouldBe_42;
    procedure TheSumOf_10_5_5_20_And_2_ShouldBe_42;
  end;

implementation

procedure TestTAdder.SetUp;
begin
  FAdder := TAdder.Create;
end;

procedure TestTAdder.TearDown;
begin
  FAdder.Free;
  FAdder := nil;
end;

procedure TestTAdder.TheSumOf_10_5_5_20_And_2_ShouldBe_42;
begin
  FAdder.AddSummand(10);
  FAdder.AddSummand(5);
  FAdder.AddSummand(5);
  FAdder.AddSummand(20);
  FAdder.AddSummand(2);
  CheckEquals(42, FAdder.Sum);
end;

procedure TestTAdder.TheSumOf_2_And_2_ShouldBe_4;
begin
  FAdder.AddSummand(2);
  FAdder.AddSummand(2);
  CheckEquals(4, FAdder.Sum);
end;

procedure TestTAdder.TheSumOf_40_And_2_ShouldBe_42;
begin
  FAdder.AddSummand(40);
  FAdder.AddSummand(2);
  CheckEquals(42, FAdder.Sum);
end;

procedure TestTAdder.WhenNoSummand_SumShouldBe_0;
begin
  CheckEquals(0, FAdder.Sum);
end;

procedure TestTAdder.WhenOnlyOneSummand_SumShouldBe_TheSummand;
const
  TEST_VECTOR: array [0..4] of Integer = (0, 1, 42, 100, 1000);
var
  i: Integer;
begin
  for i := 0 to Length(TEST_VECTOR) - 1 do
  begin
    FAdder.Reset;
    FAdder.AddSummand(TEST_VECTOR[i]);
    CheckEquals(TEST_VECTOR[i], FAdder.Sum);
  end;
end;

{$region 'TAdder'}
function TAdder.Sum: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FSummands.Count - 1 do
    Inc(Result, FSummands[I]);
end;

procedure TAdder.AddSummand(const ASummand: Integer);
begin
  FSummands.Add(ASummand);
end;

constructor TAdder.Create;
begin
  FSummands := TIntegerList.Create;
end;

destructor TAdder.Destroy;
begin
  FSummands.Free;
  inherited;
end;

procedure TAdder.Reset;
begin
  FSummands.Clear;
end;

initialization
  RegisterTest('', TestTAdder.Suite);
end.


