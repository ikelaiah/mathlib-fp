{$mode objfpc}{$H+}
program fpmake;

uses
  fpmkunit;

var
  P: TPackage;

begin
  with Installer do
  begin
    P := AddPackage('mathlib-fp');
    P.Version := '1.2.0';
    P.Author := 'ikelaiah and mathlib-fp contributors';
    P.License := 'MIT';
    P.HomepageURL := 'https://github.com/ikelaiah/mathlib-fp';
    P.Description := 'Mathematics and engineering libraries for Free Pascal';
    P.Dependencies.Add('rtl-objpas');
    P.Dependencies.Add('rtl-generics');
    P.UnitPath.Add('src');
    P.Options.Add('-MObjFPC');
    P.Options.Add('-Sh');
    P.Options.Add('-FcUTF8');

    P.Targets.AddUnit('src/MathBase.MathConstants.pas');
    P.Targets.AddUnit('src/MathBase.SharedTypes.pas');
    P.Targets.AddUnit('src/MathBase.Precision.pas');
    P.Targets.AddUnit('src/MathBase.Trigonometry.pas');
    P.Targets.AddUnit('src/AlgebraLib.Matrices.pas');
    P.Targets.AddUnit('src/AlgebraLib.Vectors.pas');
    P.Targets.AddUnit('src/AlgebraLib.Determinants.pas');
    P.Targets.AddUnit('src/FinanceLib.Interest.pas');
    P.Targets.AddUnit('src/FinanceLib.Bonds.pas');
    P.Targets.AddUnit('src/FinanceLib.NPV.pas');
    P.Targets.AddUnit('src/StatsLib.Stats.pas');
    P.Targets.AddUnit('src/EngineeringLib.Common.pas');
    P.Targets.AddUnit('src/EngineeringLib.FluidDynamics.pas');
    P.Targets.AddUnit('src/EngineeringLib.Thermodynamics.pas');
    P.Targets.AddUnit('src/EngineeringLib.Signal.pas');
    P.Targets.AddUnit('src/EngineeringLib.UnitConversion.pas');
    P.Targets.AddUnit('src/EngineeringLib.Velocity.pas');
    P.Targets.AddUnit('src/EngineeringLib.Pressure.pas');
    P.Targets.AddUnit('src/NumericsLib.Numerics.pas');
    P.Targets.AddUnit('src/ProbabilityLib.Distributions.pas');
    P.Targets.AddUnit('src/CombinatoricsLib.Combinatorics.pas');
    P.Targets.AddUnit('src/OptimizationLib.Optimization.pas');
    P.Targets.AddUnit('src/TimeSeriesLib.TimeSeries.pas');
    P.Targets.AddUnit('src/MLLib.MachineLearning.pas');
    P.Targets.AddUnit('src/GeometryLib.Geometry.pas');

    Run;
  end;
end.
