unit TestNumericalModelling;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testutils, testregistry,
  MathBase.SharedTypes, MathBase.Iteration, MathBase.Complex, MathBase.Random,
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
    procedure TestPolynomialRoots;
    procedure TestAdaptiveVectorODEAndEvent;
    procedure TestQuadraticProgram;
    procedure TestQuadraticProgramOutcomes;
    procedure TestSecondOrderConeProgram;
    procedure TestDeterministicSamplingAndReentrantOptimization;
    procedure TestIterationStatusNames;
    procedure TestQualificationEdgeCases;
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
function ComplexObjective(const X:TComplexArray):TComplex;
begin Result:=CSin(X[0])+X[1]*X[1]; end;
function SmoothVector(const X:TDoubleArray):TDoubleArray;
begin
  Result:=TDoubleArray.Create(Sin(X[0])+Sqr(X[1]),X[0]*X[1]);
end;
function SmoothVectorDual(const X:TDualArray):TDualArray;
begin
  Result:=TDualArray.Create(DualSin(X[0])+X[1]*X[1],X[0]*X[1]);
end;
function SmoothJacobian(const X:TDoubleArray):TDoubleMatrix;
begin
  SetLength(Result,2);
  Result[0]:=TDoubleArray.Create(Cos(X[0]),2*X[1]);
  Result[1]:=TDoubleArray.Create(X[1],X[0]);
end;
function BadJacobian(const X:TDoubleArray):TDoubleMatrix;
begin
  SetLength(Result,2);
  Result[0]:=TDoubleArray.Create(0,0);
  Result[1]:=TDoubleArray.Create(0,0);
end;
function IntegrandSin(X:Double):Double;
begin Result:=Sin(X); end;
function IntegrandGaussian(X:Double):Double;
begin Result:=Exp(-X*X); end;
function DiscontinuousIntegrand(X:Double):Double;
begin if X<0.5 then Result:=1 else Result:=2; end;
function UnitSquareIntegrand(const X:TDoubleArray):Double;
begin Result:=X[0]+X[1]; end;
function NonFiniteIntegrand(const X:TDoubleArray):Double;
begin Result:=NaN; end;
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
function NonlinearResidualDual(const P:TDualArray):TDualArray;
begin
  Result:=TDualArray.Create(P[0]+P[1]-3,P[0]+2*P[1]-5,
    P[0]+3*P[1]-7);
end;
function BadScaleResidual(const P:TDoubleArray):TDoubleArray;
begin
  Result:=TDoubleArray.Create(1E6*(P[0]-2),1E-6*(P[1]+3));
end;
function OutlierResidual(const P:TDoubleArray):TDoubleArray;
begin Result:=TDoubleArray.Create(P[0]-1,P[0]-1,P[0]-20); end;
function SingleTargetResidual(const P:TDoubleArray):TDoubleArray;
begin Result:=TDoubleArray.Create(P[0]-5,P[0]-5,P[0]-5); end;
function RankDeficientResidual(const P:TDoubleArray):TDoubleArray;
begin
  Result:=TDoubleArray.Create(P[0]+P[1]-1,2*(P[0]+P[1]-1),
    3*(P[0]+P[1]-1));
end;
function EquationSystem(const X:TDoubleArray):TDoubleArray;
begin Result:=TDoubleArray.Create(X[0]*X[0]-2,X[1]-3); end;
function EquationJacobian(const X:TDoubleArray):TModelMatrix;
begin
  SetLength(Result,2);
  Result[0]:=TDoubleArray.Create(2*X[0],0);
  Result[1]:=TDoubleArray.Create(0,1);
end;
function EquationSystemDual(const X:TDualArray):TDualArray;
begin
  Result:=TDualArray.Create(X[0]*X[0]-2,X[1]-3);
end;
function ExpODE(T:Double;const Y:TDoubleArray):TDoubleArray;
begin Result:=TDoubleArray.Create(Y[0]); end;
function TwoScaleODE(T:Double;const Y:TDoubleArray):TDoubleArray;
begin Result:=TDoubleArray.Create(Y[0],-2*Y[1]); end;
function EventAtTwo(T:Double;const Y:TDoubleArray):Double;
begin Result:=Y[0]-2; end;

threadvar
  ReentryDepth:Integer;
  IntegrationReentryDepth:Integer;

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
var
  N,A,Z:TDoubleArray;
  J:TDoubleMatrix;
  C:TDerivativeCheckResult;
  JC:TJacobianCheckResult;
begin
  N:=TDifferentiationKit.Gradient(@SmoothObjective,TDoubleArray.Create(0.4,-2));
  A:=TDifferentiationKit.AutoGradient(@DualObjective,TDoubleArray.Create(0.4,-2));
  Z:=TDifferentiationKit.ComplexStepGradient(@ComplexObjective,
    TDoubleArray.Create(0.4,-2));
  AssertNear(Self,Cos(0.4),N[0],1E-7,'numerical gradient');
  AssertNear(Self,N[0],A[0],1E-7,'automatic gradient');
  AssertNear(Self,Cos(0.4),Z[0],1E-13,'complex-step gradient');
  AssertNear(Self,-4,Z[1],1E-13,'complex-step quadratic derivative');
  AssertNear(Self,-4,A[1],1E-12,'dual quadratic derivative');
  J:=TDifferentiationKit.AutoJacobian(@SmoothVectorDual,
    TDoubleArray.Create(0.4,-2));
  AssertNear(Self,Cos(0.4),J[0][0],1E-12,'automatic Jacobian row 0');
  AssertNear(Self,-2,J[1][0],1E-12,'automatic Jacobian row 1');
  AssertNear(Self,0.4,J[1][1],1E-12,'automatic Jacobian column 1');
  C:=TDifferentiationKit.CheckGradient(@SmoothObjective,@SmoothGradient,
    TDoubleArray.Create(0.4,-2));
  AssertTrue('correct gradient passes',C.Passed);
  C:=TDifferentiationKit.CheckGradient(@SmoothObjective,@BadGradient,
    TDoubleArray.Create(0.4,-2));
  AssertFalse('bad gradient is discoverable',C.Passed);
  AssertTrue('bad gradient names a variable',C.WorstIndex>=0);
  JC:=TDifferentiationKit.CheckJacobian(@SmoothVector,@SmoothJacobian,
    TDoubleArray.Create(0.4,-2));
  AssertTrue('correct Jacobian passes',JC.Passed);
  JC:=TDifferentiationKit.CheckJacobian(@SmoothVector,@BadJacobian,
    TDoubleArray.Create(0.4,-2));
  AssertFalse('bad Jacobian is discoverable',JC.Passed);
  AssertTrue('bad Jacobian names a row',JC.WorstRow>=0);
  AssertTrue('bad Jacobian names a column',JC.WorstColumn>=0);
end;

function ReentrantIntegrand(X:Double):Double;
var Inner:TIntegrationResult;
begin
  if IntegrationReentryDepth=0 then
  begin
    IntegrationReentryDepth:=1;
    try
      Inner:=TModellingKit.IntegrateAdaptive(@IntegrandSin,0,Pi);
      if Abs(Inner.Value-2)>1E-8 then
        raise Exception.Create('nested integral returned a bad result');
    finally
      IntegrationReentryDepth:=0;
    end;
  end;
  Result:=X*X;
end;

function CancelAfterTwo(Iteration,Evaluations:Integer;
  Measure:Double):Boolean;
begin Result:=Iteration<2; end;

procedure TTestNumericalModelling.TestInterpolationFamilies;
var B:TBarycentricInterpolator; P,A:TCubicInterpolator;
  S:TCubicSplineInterpolator; R:TRationalInterpolationResult;
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
  S:=TCubicSplineInterpolator.Build(TDoubleArray.Create(0,1,2,3),
    TDoubleArray.Create(0,1,8,27),sbClamped,0,27);
  AssertNear(Self,3.375,S.Evaluate(1.5),1E-12,'clamped cubic spline');
  AssertNear(Self,6.75,S.Derivative(1.5),1E-11,
    'clamped spline derivative');
  AssertNear(Self,9,S.SecondDerivative(1.5),1E-10,
    'clamped spline second derivative');
  AssertNear(Self,20.25,S.Integrate(0,3),1E-11,
    'clamped spline integral');
  S:=TCubicSplineInterpolator.Build(TDoubleArray.Create(0,1,2,3),
    TDoubleArray.Create(0,1,8,27),sbNotAKnot);
  AssertNear(Self,3.375,S.Evaluate(1.5),1E-11,
    'not-a-knot cubic reproduction');
  S:=TCubicSplineInterpolator.Build(TDoubleArray.Create(0,1,2),
    TDoubleArray.Create(1,3,5),sbNatural);
  AssertNear(Self,4,S.Evaluate(1.5),1E-12,'natural linear spline');
  AssertNear(Self,0,S.SecondDerivative(0),1E-12,
    'natural left boundary');
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
var R:TFitResult; S:TSplineFitResult; O:TNonlinearFitOptions;
begin
  R:=TModellingKit.FitPolynomial(TDoubleArray.Create(0,1,2,3),
    TDoubleArray.Create(1,3,5,7),1,[]);
  AssertEquals('fit rank',2,R.Rank);
  AssertNear(Self,1,R.Parameters[0],1E-10,'fit intercept');
  AssertNear(Self,2,R.Parameters[1],1E-10,'fit slope');
  R:=TModellingKit.FitPolynomial(TDoubleArray.Create(0,1,2,3),
    TDoubleArray.Create(1,3,5,7),1,TDoubleArray.Create(1,2,3,4));
  AssertNear(Self,1,R.Parameters[0],1E-10,'weighted fit intercept');
  AssertNear(Self,2,R.Parameters[1],1E-10,'weighted fit slope');
  R:=TModellingKit.FitPolynomial(TDoubleArray.Create(1,1,1,1),
    TDoubleArray.Create(2,2,2,2),1,[]);
  AssertEquals('rank-deficient fit rank',1,R.Rank);
  AssertEquals('rank-deficient covariance omitted',0,Length(R.Covariance));
  S:=TModellingKit.FitSplineBasis(
    TDoubleArray.Create(0,1,2,3,4,5,6),
    TDoubleArray.Create(1,3,5,7,9.5,15,26.5),
    TDoubleArray.Create(3),[]);
  AssertEquals('spline basis full rank',5,S.Fit.Rank);
  AssertNear(Self,15,S.Evaluate(5),1E-9,'spline regression value');
  O:=TNonlinearFitOptions.Defaults; O.CheckDerivative:=True;
  R:=TModellingKit.FitNonlinear(@NonlinearResidual,@NonlinearJacobian,
    TDoubleArray.Create(0,0),O);
  AssertEquals('LM status',Ord(isConverged),Ord(R.Status));
  AssertNear(Self,1,R.Parameters[0],1E-6,'LM p0');
  AssertNear(Self,2,R.Parameters[1],1E-6,'LM p1');
  R:=TModellingKit.FitNonlinearAuto(@NonlinearResidualDual,
    TDoubleArray.Create(0,0),O);
  AssertEquals('AD LM status',Ord(isConverged),Ord(R.Status));
  AssertNear(Self,1,R.Parameters[0],1E-6,'AD LM p0');
  AssertNear(Self,2,R.Parameters[1],1E-6,'AD LM p1');
end;

procedure TTestNumericalModelling.TestVectorRoot;
var R:TVectorRootResult;
begin
  R:=TModellingKit.SolveSystem(@EquationSystem,@EquationJacobian,
    TDoubleArray.Create(1,0));
  AssertEquals('system status',Ord(isConverged),Ord(R.Status));
  AssertNear(Self,Sqrt(2),R.X[0],1E-9,'system root x');
  AssertNear(Self,3,R.X[1],1E-10,'system root y');
  R:=TModellingKit.SolveSystemAuto(@EquationSystemDual,
    TDoubleArray.Create(1,0));
  AssertEquals('AD system status',Ord(isConverged),Ord(R.Status));
  AssertNear(Self,Sqrt(2),R.X[0],1E-9,'AD system root x');
  AssertNear(Self,3,R.X[1],1E-10,'AD system root y');
end;

procedure TTestNumericalModelling.TestPolynomialRoots;
var
  R:TPolynomialRootResult;
  I:Integer;
begin
  R:=TModellingKit.SolvePolynomial(TDoubleArray.Create(1,0,1));
  AssertEquals('quadratic status',Ord(isConverged),Ord(R.Status));
  AssertEquals('quadratic returns every root',2,Length(R.Roots));
  for I:=0 to High(R.Roots) do
  begin
    AssertNear(Self,0,R.Roots[I].Re,1E-9,'quadratic root real part');
    AssertNear(Self,1,Abs(R.Roots[I].Im),1E-9,
      'quadratic root imaginary magnitude');
    AssertTrue('quadratic residual',R.Residuals[I]<=1E-10);
  end;
  R:=TModellingKit.SolvePolynomial(TDoubleArray.Create(-6,11,-6,1));
  AssertEquals('cubic status',Ord(isConverged),Ord(R.Status));
  AssertEquals('cubic root count',3,Length(R.Roots));
  AssertNear(Self,1,R.Roots[0].Re,1E-8,'cubic first root');
  AssertNear(Self,2,R.Roots[1].Re,1E-8,'cubic second root');
  AssertNear(Self,3,R.Roots[2].Re,1E-8,'cubic third root');
  R:=TModellingKit.SolvePolynomial(TDoubleArray.Create(-8,4));
  AssertEquals('linear status',Ord(isConverged),Ord(R.Status));
  AssertNear(Self,2,R.Roots[0].Re,0,'linear root');
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
  AssertEquals('QP best point dimension',2,Length(R.BestX));
  AssertNear(Self,R.Objective,R.BestObjective,1E-10,'QP best objective');
end;

procedure TTestNumericalModelling.TestQuadraticProgramOutcomes;
var
  M:TQuadraticProgram;
  O:TConvexOptions;
  R:TConvexResult;
begin
  SetLength(M.Q,1);
  M.Q[0]:=TDoubleArray.Create(0);
  M.C:=TDoubleArray.Create(-1);
  O:=TConvexOptions.Defaults;
  R:=TConvexOptimizationKit.SolveQuadraticProgram(M,O);
  AssertEquals('unbounded QP status',Ord(isUnbounded),Ord(R.Status));
  AssertEquals('unbounded QP certificate dimension',1,Length(R.Certificate));
  AssertNear(Self,1,R.Certificate[0],1E-12,'unbounded descent direction');

  M:=Default(TQuadraticProgram);
  SetLength(M.Q,1);
  M.Q[0]:=TDoubleArray.Create(1);
  M.C:=TDoubleArray.Create(0);
  SetLength(M.InequalityA,2);
  M.InequalityA[0]:=TDoubleArray.Create(1);
  M.InequalityA[1]:=TDoubleArray.Create(-1);
  M.InequalityB:=TDoubleArray.Create(0,-1);
  R:=TConvexOptimizationKit.SolveQuadraticProgram(M,O);
  AssertEquals('infeasible QP status',Ord(isInfeasible),Ord(R.Status));
  AssertTrue('infeasible QP residual',R.Feasibility>O.FeasibilityTolerance);
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
var
  A,B:TIntegrationResult;
  R:TOptResult;
  RandomA,RandomB:TLocalRandom;
  BeforeState,AfterState:TRandomState;
  I:Integer;
begin
  A:=TModellingKit.IntegrateQuasiMonteCarlo(@UnitSquareIntegrand,
    TDoubleArray.Create(0,0),TDoubleArray.Create(1,1),256,17);
  B:=TModellingKit.IntegrateQuasiMonteCarlo(@UnitSquareIntegrand,
    TDoubleArray.Create(0,0),TDoubleArray.Create(1,1),256,17);
  AssertNear(Self,A.Value,B.Value,0,'seeded QMC reproducibility');
  A:=TModellingKit.IntegrateCubature(@UnitSquareIntegrand,
    TDoubleArray.Create(0,0),TDoubleArray.Create(1,1));
  AssertNear(Self,1,A.Value,1E-14,'tensor cubature unit square');
  AssertTrue('cubature has embedded comparison',A.ErrorEstimate<=1E-13);
  RandomA:=TLocalRandom.Seeded(42);
  RandomB:=TLocalRandom.Seeded(42);
  A:=TModellingKit.IntegrateMonteCarlo(@UnitSquareIntegrand,
    TDoubleArray.Create(0,0),TDoubleArray.Create(1,1),1024,RandomA);
  B:=TModellingKit.IntegrateMonteCarlo(@UnitSquareIntegrand,
    TDoubleArray.Create(0,0),TDoubleArray.Create(1,1),1024,RandomB);
  AssertNear(Self,A.Value,B.Value,0,'local RNG Monte Carlo value');
  AssertNear(Self,A.ErrorEstimate,B.ErrorEstimate,0,
    'local RNG Monte Carlo uncertainty');
  BeforeState:=RandomA.GetState;
  try
    TModellingKit.IntegrateMonteCarlo(@NonFiniteIntegrand,
      TDoubleArray.Create(0,0),TDoubleArray.Create(1,1),8,RandomA);
    Fail('non-finite Monte Carlo callback must raise');
  except
    on E:EModellingError do ;
  end;
  AfterState:=RandomA.GetState;
  for I:=0 to 3 do
    AssertTrue('failed Monte Carlo preserves RNG state',
      BeforeState.Words[I]=AfterState.Words[I]);
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

procedure TTestNumericalModelling.TestQualificationEdgeCases;
var
  Scattered:TScatteredInterpolator;
  Fit,RobustFit,RankFit:TFitResult;
  FitOptions:TNonlinearFitOptions;
  Integral:TIntegrationResult;
  ODEOptions:TAdaptiveODEOptions;
  Solution:TAdaptiveODESolution;
  Failed:Boolean;
begin
  Scattered:=TScatteredInterpolator.BuildThinPlate(
    TDoubleArray.Create(0,1,0,1),TDoubleArray.Create(0,0,1,1),
    TDoubleArray.Create(0,1,1,2));
  AssertNear(Self,0.75,Scattered.Evaluate(0.25,0.5),1E-10,
    'thin-plate affine reproduction');
  Failed:=False;
  try
    TScatteredInterpolator.BuildRBF(
      TDoubleArray.Create(0,0,1),TDoubleArray.Create(0,0,1),
      TDoubleArray.Create(1,2,3));
  except
    on E:EInterpolationError do Failed:=True;
  end;
  AssertTrue('duplicate scattered nodes rejected',Failed);

  FitOptions:=TNonlinearFitOptions.Defaults;
  FitOptions.ParameterScales:=TDoubleArray.Create(1E-6,1E6);
  Fit:=TModellingKit.FitNonlinear(@BadScaleResidual,nil,
    TDoubleArray.Create(0,0),FitOptions);
  AssertTrue(Format('scaled nonlinear fit usable status=%s p=(%.6g,%.6g)',
    [IterationStatusName(Fit.Status),Fit.Parameters[0],Fit.Parameters[1]]),
    Fit.Status in [isConverged,isAcceptableLimit,isStagnation]);
  AssertNear(Self,2,Fit.Parameters[0],1E-6,'scaled fit first parameter');
  AssertNear(Self,-3,Fit.Parameters[1],1E-5,'scaled fit second parameter');

  FitOptions:=TNonlinearFitOptions.Defaults;
  Fit:=TModellingKit.FitNonlinear(@OutlierResidual,nil,
    TDoubleArray.Create(0),FitOptions);
  FitOptions.Loss:=rlHuber;
  FitOptions.LossScale:=1;
  RobustFit:=TModellingKit.FitNonlinear(@OutlierResidual,nil,
    TDoubleArray.Create(0),FitOptions);
  AssertTrue('robust loss resists outlier',
    Abs(RobustFit.Parameters[0]-1)<Abs(Fit.Parameters[0]-1));
  AssertEquals('robust covariance is intentionally absent',0,
    Length(RobustFit.Covariance));

  FitOptions:=TNonlinearFitOptions.Defaults;
  FitOptions.LowerBounds:=TDoubleArray.Create(0);
  FitOptions.UpperBounds:=TDoubleArray.Create(2);
  Fit:=TModellingKit.FitNonlinear(@SingleTargetResidual,nil,
    TDoubleArray.Create(0),FitOptions);
  AssertNear(Self,2,Fit.Parameters[0],1E-12,'bounded fit active bound');
  AssertTrue('bounded fit result remains within bounds',Fit.Parameters[0]<=2);

  FitOptions:=TNonlinearFitOptions.Defaults;
  RankFit:=TModellingKit.FitNonlinear(@RankDeficientResidual,nil,
    TDoubleArray.Create(0,0),FitOptions);
  AssertEquals('rank-deficient nonlinear fit rank',1,RankFit.Rank);
  AssertEquals('rank-deficient covariance absent',0,
    Length(RankFit.Covariance));

  Integral:=TModellingKit.IntegrateAdaptive(@DiscontinuousIntegrand,0,1,
    1E-10,1E-10,1000);
  AssertNear(Self,1.5,Integral.Value,1E-9,'discontinuous adaptive integral');
  AssertTrue('adaptive integral exposes error estimate',
    Integral.ErrorEstimate>=0);
  Integral:=TModellingKit.IntegrateAdaptive(@DiscontinuousIntegrand,0,1,
    1E-14,1E-14,1);
  AssertEquals('integration subdivision limit status',
    Ord(isIterationLimit),Ord(Integral.Status));
  IntegrationReentryDepth:=0;
  Integral:=TModellingKit.IntegrateAdaptive(@ReentrantIntegrand,0,1);
  AssertNear(Self,1/3,Integral.Value,1E-10,'nested integration reentrancy');

  ODEOptions:=TAdaptiveODEOptions.Defaults;
  Solution:=TModellingKit.SolveODE(@ExpODE,1,
    TDoubleArray.Create(Exp(1)),0,ODEOptions);
  AssertEquals('reverse-time ODE status',Ord(isConverged),
    Ord(Solution.Status));
  AssertNear(Self,1,Solution.Y[High(Solution.Y)][0],2E-7,
    'reverse-time ODE endpoint');

  ODEOptions:=TAdaptiveODEOptions.Defaults;
  ODEOptions.AbsoluteTolerance:=0;
  ODEOptions.AbsoluteTolerances:=TDoubleArray.Create(1E-10,1E-12);
  Solution:=TModellingKit.SolveODE(@TwoScaleODE,0,
    TDoubleArray.Create(1,1E-6),1,ODEOptions);
  AssertNear(Self,Exp(1),Solution.Y[High(Solution.Y)][0],2E-7,
    'vector-tolerance first component');
  AssertNear(Self,1E-6*Exp(-2),Solution.Y[High(Solution.Y)][1],2E-12,
    'vector-tolerance second component');

  ODEOptions:=TAdaptiveODEOptions.Defaults;
  ODEOptions.Progress:=@CancelAfterTwo;
  Solution:=TModellingKit.SolveODE(@ExpODE,0,
    TDoubleArray.Create(1),10,ODEOptions);
  AssertEquals('ODE cancellation status',Ord(isCancelled),
    Ord(Solution.Status));
  AssertTrue('cancelled ODE retains best finite trajectory',
    Length(Solution.T)>=2);
end;

initialization
  RegisterTest(TTestNumericalModelling);

end.
