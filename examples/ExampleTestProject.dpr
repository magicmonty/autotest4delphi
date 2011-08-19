program ExampleTestProject;
{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  Forms,
  SysUtils,
  TestFramework,
  TestModules,
  GUITestRunner,
  XmlTestRunner in 'XmlTestRunner.pas';

var
  OutputFile : string = DEFAULT_FILENAME;

var
  testResult: TTestResult;
  testFailure: TTestFailure;
  i: Integer;
  runCount, warningCount, failureCount, errorCount: Integer;
  tmp: string;

begin
  if IsConsole then
  begin
    try
      testResult := XMLTestRunner.RunRegisteredTests(OutputFile);

      try
        runCount := testResult.RunCount;
      except
        runCount := 0;
      end;

      try
        warningCount := testResult.WarningCount;
      except
        warningCount := 0;
      end;

      try
        if not testResult.WasSuccessful then
          failureCount := testResult.FailureCount
        else
          failureCount := 0;
      except
        failureCount := 0;
      end;

      try
        if not testResult.WasSuccessful then
          errorCount := testResult.ErrorCount
        else
          errorCount := 0;
      except
        errorCount := 0;
      end;

      WriteLn('Run: ' + IntToStr(runCount) + ' / Warnings: ' + IntToStr(warningCount) + ' / Failures: ' + IntToStr(failureCount) + ' / Errors: ' + IntToStr(errorCount) );
      if failureCount > 0 then
      begin
        Writeln('Failures:');
        for i := 0 to failureCount - 1 do
        begin
          testFailure := testResult.Failures[i];
          tmp := testFailure.FailedTest.Name;
          if Trim(testFailure.LocationInfo) <> EmptyStr then
            tmp := tmp + ' (' + testFailure.LocationInfo + ')';
          tmp := tmp + ': ' + testFailure.ThrownExceptionMessage;

          Writeln(tmp);
        end;
      end;

      if errorCount > 0 then
      begin
        Writeln('Errors:');
        for i := 0 to errorCount - 1 do
        begin
          testFailure := testResult.Errors[i];
          tmp := testFailure.FailedTest.Name;
          if Trim(testFailure.LocationInfo) <> EmptyStr then
            tmp := tmp + ' (' + testFailure.LocationInfo + ')';
          tmp := tmp + ': ' + testFailure.ThrownExceptionMessage;

          Writeln(tmp);
        end;
      end;

      if not testResult.WasSuccessful then
        Halt(1);
    except
      on e:Exception do
        Writeln(Format('%s: %s', [e.ClassName, e.Message]));
    end;
  end
  else
    GUITestRunner.RunRegisteredTests;
end.

