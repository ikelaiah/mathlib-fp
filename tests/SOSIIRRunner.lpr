program SOSIIRRunner;

{$mode objfpc}{$H+}{$J-}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  consoletestrunner, TestSOSIIR;

type
  TSOSIIRConsoleRunner = class(TTestRunner)
  end;

var
  Application: TSOSIIRConsoleRunner;

begin
  Application := TSOSIIRConsoleRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'SOS IIR Test Runner';
  Application.Run;
  Application.Free;
end.
