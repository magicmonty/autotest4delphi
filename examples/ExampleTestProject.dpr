program MDS4DvTests;
{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  Forms,
  SysUtils,
  TestFramework,
  TestModules,
  GUITestRunner;
  
const
  SwitchChars = ['-','/'];

var
  ConfigFile : string;
  OutputFile : string = DEFAULT_FILENAME;

procedure LoadTests(const FileMask : string);
var
  srec : TSearchRec;
begin
  if FindFirst(FileMask, faAnyFile, srec) = 0 then
    repeat
      RegisterModuleTests(srec.Name);
      WriteLn('Loaded module ' + srec.Name);
    until FindNext(srec) <> 0;
  FindClose(srec);
end;

procedure ProcessCommandLine;
var
  i : Integer;
  s : string;
begin
  for i := 1 to ParamCount do begin
    s := ParamStr(i);
    if not (s[1] in SwitchChars) then
      LoadTests(s)
    else begin
      if CompareText(Copy(s, 2, 2), 'c=') = 0 then
        ConfigFile := Copy(s, 4, Length(s))
      else
      if CompareText(Copy(s, 2, 2), 'o=') = 0 then
        OutputFile := Copy(s, 4, Length(s));
    end;
  end;
end;

begin
  if IsConsole then
  begin
    try
      WriteLn('DUnit Console');
      ProcessCommandLine;
      if ConfigFile <> '' then begin
        RegisteredTests.LoadConfiguration(ConfigFile, False, True);
        WriteLn('Loaded config file ' + ConfigFile);
      end;
      WriteLn('Writing output to ' + OutputFile);
      WriteLn('Running ' + IntToStr(RegisteredTests.CountEnabledTestCases) + ' of ' + IntToStr(RegisteredTests.CountTestCases) + ' test cases');
      if not XMLTestRunner.RunRegisteredTests(OutputFile).WasSuccessful then
        Halt(1);
    except
      on e:Exception do
        Writeln(Format('%s: %s', [e.ClassName, e.Message]));
    end;
  end
  else
    GUITestRunner.RunRegisteredTests;
end.

