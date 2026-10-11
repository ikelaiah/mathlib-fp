program SpectralPlanRunner;

{$mode objfpc}{$H+}{$J-}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes,
  consoletestrunner,
  TestSpectralPlans;

type
  TSpectralPlanRunner = class(TTestRunner)
  end;

var
  Application: TSpectralPlanRunner;

begin
  Application := TSpectralPlanRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'mathlib-fp spectral plan tests';
    Application.Run;
  finally
    Application.Free;
  end;
end.
