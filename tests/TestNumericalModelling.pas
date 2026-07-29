unit TestNumericalModelling;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testutils, testregistry,
  MathBase.SharedTypes, MathBase.Iteration,
  NumericsLib.Differentiation, NumericsLib.Interpolation,
  NumericsLib.Modelling, OptimizationLib.Optimization,
  OptimizationLib.Convex;

type
  TTestNumericalModelling = class(TTestCase)
  published
    procedure TestDerivativePathsAndBadDerivative;
    procedure TestInterpolationFamilies;
    procedure TestSurfacesAndScatteredData;
    procedure TestAdaptiveAndImproperIntegration;
    procedure TestLinearAndNonlinearFits;
    procedure TestVectorRoot;
    procedure TestAdaptiveVectorODEAndEvent;
    procedure TestQuadraticProgram;
    procedure TestSecondOrderConeProgram;
    procedure TestDeterministicSamplingAndReentrantOptimization;
    procedure TestIterationStatusNames;
  end;

implementation

function SmoothObjective(const X:TDoubleArray):Double;
begin Result:=Sin(X[0])+Sqr(X[1]); end;
function SmoothGradient(const X:TDoubleArray):TDoubleArray;
begin Result:=TDoubleArray.Create(Cos(X[0]),2*X[1]); end;
function BadGradient(const X:TDoubleArray):TDoubleArray;
begin Result:=TDoubleArray.Create(0,0); end;
function DualObjective(const X:TDualArray):TDual;
begin Result:=DualSin(X[0])+X[1]*X[1]; end;
function IntegrandSin(X:Double):Double;
begin Result:=Sin(X); end;
function IntegrandGaussian(X:Double):Double;
begin Result:=Exp(-X*X); end;
function UnitSquareIntegrand(const X:TDoubleArray):Double;
begin Result:=X[0]+X[1]; end;
function NonlinearResidual(const P:TDoubleArray):TDoubleArray;
begin
  Result:=TDoubleArray.Create(P[0]+P[1]-3,P[0]+2*P[1]-5,
    P[0]+3*P[1]-7);
end;
function NonlinearJacobian(const P:TDoubleArray):TModelMatrix;
begin
  SetLength(Result,3);
  Result[0]:=TDoubleArray.Create(1,1);
  Result[1]:=TDoubleArray.Create(1,2);
  Result[2]:=TDoubleArray.Create(1,3);
end;
function EquationSystem(const X:TDoubleArray):TDoubleArray;
begin Result:=TDoubleArray.Create(X[0]*X[0]-2,X[1]-3); end;
function EquationJacobian(const X:TDoubleArray):TModelMatrix;
begin
  SetLength(Result,2);
  Result[0]:=TDoubleArray.Create(2*X[0],0);
  Result[1]:=TDoubleArray.Create(0,1);
end;
function ExpODE(T:Double;const Y:TDoubleArray):TDoubleArray;
begin Result:=TDoubleArray.Create(Y[0]); end;
function EventAtTwo(T:Double;const Y:TDoubleArray):Double;
begin Result:=Y[0]-2; end;

threadvar
  ReentryDepth:Integer;

function InnerMaximum(const X:TDoubleArray):Double;
begin Result:=-Sqr(X[0]-2); end;

function ReentrantMaximum(const X:TDoubleArray):Double;
var Inner:TOptResult;
begin
  if ReentryDepth=0 then
  begin
    ReentryDepth:=1;
    try
      Inner:=TOptimizationKit.Maximize(@InnerMaximum,TDoubleArray.Create(0));
      if Abs(Inner.X[0]-2)>1E-3 then
        raise Exception.Create('nested optimizer returned a bad result');
    finally
      ReentryDepth:=0;
    end;
  end;
  Result:=-Sqr(X[0]-1);
end;

procedure AssertNear(Test:TTestCase;Expected,Actual,Tol:Double;
  const Msg:String);
begin
  Test.AssertTrue(Format('%s expected %.12g, got %.12g',[Msg,Expected,Actual]),
    Abs(Expected-Actual)<=Tol);
end;

procedure TTestNumericalModelling.TestDerivativePathsAndBadDerivative;
var N,A:TDoubleArray; C:TDerivativeCheckResult;
begin
  N:=TDifferentiationKit.Gradient(@SmoothObjective,TDoubleArray.Create(0.4,-2));
  A:=TDifferentiationKit.AutoGradient(@DualObjective,TDoubleArray.Create(0.4,-2));
  AssertNear(Self,Cos(0.4),N[0],1E-7,'numerical gradient');
  AssertNear(Self,N[0],A[0],1E-7,'automatic gradient');
  AssertNear(Self,-4,A[1],1E-12,'dual quadratic derivative');
  C:=TDifferentiationKit.CheckGradient(@SmoothObjective,@SmoothGradient,
    TDoubleArray.Create(0.4,-2));
  AssertTrue('correct gradient passes',C.Passed);
  C:=TDifferentiationKit.CheckGradient(@SmoothObjective,@BadGradient,
    TDoubleArray.Create(0.4,-2));
  AssertFalse('bad gradient is discoverable',C.Passed);
  AssertTrue('bad gradient names a variable',C.WorstIndex>=0);
end;

procedure TTestNumericalModelling.TestInterpolationFamilies;
var B:TBarycentricInterpolator; P,A:TCubicInterpolator;
  R:TRationalInterpolationResult;
begin
  B:=TBarycentricInterpolator.Build(TDoubleArray.Create(0,1,2),
    TDoubleArray.Create(0,1,4));
  AssertNear(Self,2.25,B.Evaluate(1.5),1E-12,'barycentric quadratic');
  R:=TInterpolationKit.Rational(TDoubleArray.Create(0,1,2),
    TDoubleArray.Create(1,0.5,1/3),1.5);
  AssertEquals('rational status',Ord(isConverged),Ord(R.Status));
  AssertNear(Self,0.4,R.Value,1E-12,'rational reciprocal');
  P:=TCubicInterpolator.BuildPchip(TDoubleArray.Create(0,1,2,3),
    TDoubleArray.Create(0,1,1.5,2));
  AssertTrue('PCHIP stays monotone',(P.Evaluate(1.5)>=1) and
    (P.Evaluate(1.5)<=1.5));
  AssertNear(Self,P.Evaluate(1.2),(P.Antiderivative(1.2+1E-5)-
    P.Antiderivative(1.2))/1E-5,2E-5,'antiderivative change');
  A:=TCubicInterpolator.BuildAkima(TDoubleArray.Create(0,1,2,3,4),
    TDoubleArray.Create(0,1,4,9,16));
  AssertNear(Self,4,A.Evaluate(2),1E-12,'Akima knot');
end;

procedure TTestNumericalModelling.TestSurfacesAndScatteredData;
var G:TGridSurface; V:TInterpolationMatrix; R:TScatteredInterpolator;
begin
  SetLength(V,2); V[0]:=TDoubleArray.Create(0,1);
  V[1]:=TDoubleArray.Create(1,2);
  G:=TGridSurface.Build(TDoubleArray.Create(0,1),TDoubleArray.Create(0,1),V);
  AssertNear(Self,1,G.Bilinear(0.25,0.75),1E-12,'bilinear plane');
  AssertNear(Self,1,G.Bicubic(0.25,0.75),1E-12,'bicubic plane');
  AssertNear(Self,2,TInterpolationKit.InverseDistance(
    TDoubleArray.Create(0,1),TDoubleArray.Create(0,0),
    TDoubleArray.Create(2,4),0,0),1E-12,'IDW exact point');
  R:=TScatteredInterpolator.BuildRBF(TDoubleArray.Create(0,1,0),
    TDoubleArray.Create(0,0,1),TDoubleArray.Create(1,2,3),1);
  AssertNear(Self,2,R.Evaluate(1,0),1E-9,'RBF exact point');
end;

procedure TTestNumericalModelling.TestAdaptiveAndImproperIntegration;
var R:TIntegrationResult;
begin
  R:=TModellingKit.IntegrateAdaptive(@IntegrandSin,0,Pi);
  AssertEquals('adaptive status',Ord(isConverged),Ord(R.Status));
  AssertNear(Self,2,R.Value,1E-10,'adaptive sine');
  R:=TModellingKit.IntegrateImproper(@IntegrandGaussian,-Infinity,Infinity,
    1E-8,1E-7,2000);
  AssertTrue('improper usable',R.Status in [isConverged,isAcceptableLimit]);
  AssertNear(Self,Sqrt(Pi),R.Value,2E-7,'Gaussian improper integral');
end;

procedure TTestNumericalModelling.TestLinearAndNonlinearFits;
var R:TFitResult; O:TNonlinearFitOptions;
begin
  R:=TModellingKit.FitPolynomial(TDoubleArray.Create(0,1,2,3),
    TDoubleArray.Create(1,3,5,7),1,[]);
  AssertEquals('fit rank',2,R.Rank);
  AssertNear(Self,1,R.Parameters[0],1E-10,'fit intercept');
  AssertNear(Self,2,R.Parameters[1],1E-10,'fit slope');
  O:=TNonlinearFitOptions.Defaults; O.CheckDerivative:=True;
  R:=TModellingKit.FitNonlinear(@NonlinearResidual,@NonlinearJacobian,
    TDoubleArray.Create(0,0),O);
  AssertEquals('LM status',Ord(isConverged),Ord(R.Status));
  AssertNear(Self,1,R.Parameters[0],1E-6,'LM p0');
  AssertNear(Self,2,R.Parameters[1],1E-6,'LM p1');
end;

procedure TTestNumericalModelling.TestVectorRoot;
var R:TVectorRootResult;
begin
  R:=TModellingKit.SolveSystem(@EquationSystem,@EquationJacobian,
    TDoubleArray.Create(1,0));
  AssertEquals('system status',Ord(isConverged),Ord(R.Status));
  AssertNear(Self,Sqrt(2),R.X[0],1E-9,'system root x');
  AssertNear(Self,3,R.X[1],1E-10,'system root y');
end;

procedure TTestNumericalModelling.TestAdaptiveVectorODEAndEvent;
var O:TAdaptiveODEOptions; S:TAdaptiveODESolution; Y:TDoubleArray;
begin
  O:=TAdaptiveODEOptions.Defaults; O.Event:=@EventAtTwo;
  S:=TModellingKit.SolveODE(@ExpODE,0,TDoubleArray.Create(1),2,O);
  AssertEquals('ODE status',Ord(isConverged),Ord(S.Status));
  AssertTrue('event found',S.EventFound);
  AssertNear(Self,Ln(2),S.EventTime,2E-5,'event time');
  Y:=S.Evaluate(0.5);
  AssertNear(Self,Exp(0.5),Y[0],2E-6,'dense ODE output');
end;

procedure TTestNumericalModelling.TestQuadraticProgram;
var M:TQuadraticProgram; O:TConvexOptions; R:TConvexResult;
begin
  SetLength(M.Q,2); M.Q[0]:=TDoubleArray.Create(2,0);
  M.Q[1]:=TDoubleArray.Create(0,2);
  M.C:=TDoubleArray.Create(-4,2);
  SetLength(M.InequalityA,1); M.InequalityA[0]:=TDoubleArray.Create(1,1);
  M.InequalityB:=TDoubleArray.Create(2);
  M.LowerBounds:=TDoubleArray.Create(-10,-10);
  M.UpperBounds:=TDoubleArray.Create(10,10);
  O:=TConvexOptions.Defaults;
  R:=TConvexOptimizationKit.SolveQuadraticProgram(M,O);
  AssertTrue('QP usable',R.Status in [isConverged,isAcceptableLimit]);
  AssertNear(Self,2,R.X[0],2E-5,'QP x');
  AssertNear(Self,-1,R.X[1],2E-5,'QP y');
  AssertTrue('QP feasible',R.Feasibility<=O.FeasibilityTolerance);
end;

procedure TTestNumericalModelling.TestSecondOrderConeProgram;
var C:TDoubleArray; Cones:TSecondOrderCones; O:TConvexOptions; R:TConvexResult;
begin
  C:=TDoubleArray.Create(-1); SetLength(Cones,1);
  SetLength(Cones[0].A,1); Cones[0].A[0]:=TDoubleArray.Create(1);
  Cones[0].B:=TDoubleArray.Create(0); Cones[0].D:=TDoubleArray.Create(0);
  Cones[0].E:=1;
  O:=TConvexOptions.Defaults; O.InitialX:=TDoubleArray.Create(0);
  O.AbsoluteTolerance:=1E-6; O.RelativeTolerance:=1E-6;
  R:=TConvexOptimizationKit.SolveSecondOrderConeProgram(C,Cones,O);
  AssertTrue('SOCP usable',R.Status in [isConverged,isAcceptableLimit]);
  AssertNear(Self,1,R.X[0],2E-3,'SOCP optimum');
  AssertTrue('SOCP feasible',R.Feasibility<=1E-8);
end;

procedure TTestNumericalModelling.TestDeterministicSamplingAndReentrantOptimization;
var A,B:TIntegrationResult; R:TOptResult;
begin
  A:=TModellingKit.IntegrateQuasiMonteCarlo(@UnitSquareIntegrand,
    TDoubleArray.Create(0,0),TDoubleArray.Create(1,1),256,17);
  B:=TModellingKit.IntegrateQuasiMonteCarlo(@UnitSquareIntegrand,
    TDoubleArray.Create(0,0),TDoubleArray.Create(1,1),256,17);
  AssertNear(Self,A.Value,B.Value,0,'seeded QMC reproducibility');
  R:=TOptimizationKit.Maximize(@ReentrantMaximum,TDoubleArray.Create(0),
    0.5,1E-7,1000);
  AssertNear(Self,1,R.X[0],1E-3,'nested optimizer reentrancy');
end;

procedure TTestNumericalModelling.TestIterationStatusNames;
begin
  AssertEquals('status name','numerical breakdown',
    IterationStatusName(isNumericalBreakdown));
  AssertEquals('limit name','iteration limit',
    IterationStatusName(isIterationLimit));
end;

initialization
  RegisterTest(TTestNumericalModelling);

end.
