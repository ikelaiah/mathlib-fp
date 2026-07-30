unit OptimizationLib.Convex;

{ Dense convex quadratic and feasible-start second-order-cone optimisation.
  Algorithms are portable Object Pascal and keep all callback/model state local. }

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math, MathBase.SharedTypes, MathBase.Iteration,
  AlgebraLib.DenseMatrices, AlgebraLib.DenseSolvers,
  AlgebraLib.DenseDecompositions;

type
  EConvexOptimizationError = class(Exception);
  TConvexMatrix = array of TDoubleArray;
  TConvexProgress = function(Iteration, Evaluations: Integer;
    Objective, Feasibility: Double): Boolean;

  TConvexResult = record
    X: TDoubleArray;
    Objective: Double;
    GradientNorm: Double;
    Feasibility: Double;
    Iterations: Integer;
    Evaluations: Integer;
    Status: TIterationStatus;
    BestX: TDoubleArray;
    BestObjective: Double;
    Certificate: TDoubleArray;
  end;

  TQuadraticProgram = record
    Q: TConvexMatrix;       { symmetric positive-semidefinite Hessian }
    C: TDoubleArray;
    InequalityA: TConvexMatrix; { A*x <= b }
    InequalityB: TDoubleArray;
    EqualityA: TConvexMatrix;   { Aeq*x = beq }
    EqualityB: TDoubleArray;
    LowerBounds: TDoubleArray;
    UpperBounds: TDoubleArray;
  end;

  TSecondOrderCone = record
    A: TConvexMatrix; { ||A*x + B||_2 <= Dot(D,x) + E }
    B: TDoubleArray;
    D: TDoubleArray;
    E: Double;
  end;
  TSecondOrderCones = array of TSecondOrderCone;

  TConvexOptions = record
    AbsoluteTolerance: Double;
    RelativeTolerance: Double;
    FeasibilityTolerance: Double;
    MaxIterations: Integer;
    InitialX: TDoubleArray;
    Progress: TConvexProgress;
    class function Defaults: TConvexOptions; static;
  end;

  TConvexOptimizationKit = class
  public
    class function SolveQuadraticProgram(const Model: TQuadraticProgram;
      const Options: TConvexOptions): TConvexResult; static;
    class function SolveSecondOrderConeProgram(const C: TDoubleArray;
      const Cones: TSecondOrderCones; const Options: TConvexOptions):
      TConvexResult; static;
  end;

implementation

const
  DoubleEpsilon = 2.2204460492503131E-16;

function IsFiniteValue(X:Double):Boolean; inline;
begin Result:=not IsNan(X) and not IsInfinite(X); end;

procedure ValidateVector(const X:TDoubleArray; N:Integer; const Name:String;
  AllowEmpty:Boolean=False);
var I:Integer;
begin
  if ((not AllowEmpty) and (Length(X)<>N)) or
     (AllowEmpty and (Length(X)<>0) and (Length(X)<>N)) then
  begin
    if AllowEmpty then
      raise EConvexOptimizationError.CreateFmt(
        '%s: length %d; expected %d or empty.',[Name,Length(X),N])
    else
      raise EConvexOptimizationError.CreateFmt(
        '%s: length %d; expected %d.',[Name,Length(X),N]);
  end;
  for I:=0 to High(X) do if not IsFiniteValue(X[I]) then
    raise EConvexOptimizationError.CreateFmt(
      '%s: value %d must be finite.',[Name,I]);
end;

procedure ValidateMatrix(const A:TConvexMatrix; N:Integer; const Name:String;
  AllowEmpty:Boolean=True);
var I,J:Integer;
begin
  if Length(A)=0 then begin
    if AllowEmpty then Exit else raise EConvexOptimizationError.Create(
      Name+': matrix must not be empty.'); end;
  for I:=0 to High(A) do begin
    if Length(A[I])<>N then raise EConvexOptimizationError.CreateFmt(
      '%s: row %d has %d columns; expected %d.',[Name,I,Length(A[I]),N]);
    for J:=0 to N-1 do if not IsFiniteValue(A[I][J]) then
      raise EConvexOptimizationError.CreateFmt(
        '%s: value [%d,%d] must be finite.',[Name,I,J]); end;
end;

function Dot(const A,B:TDoubleArray):Double;
var I:Integer; begin Result:=0; for I:=0 to High(A) do Result:=Result+A[I]*B[I]; end;

function Norm(const A:TDoubleArray):Double;
var I:Integer; begin Result:=0; for I:=0 to High(A) do Result:=Result+Sqr(A[I]);
  Result:=Sqrt(Result); end;

function MatVec(const A:TConvexMatrix;const X:TDoubleArray):TDoubleArray;
var I,J:Integer; begin Result:=nil; SetLength(Result,Length(A));
  for I:=0 to High(A) do begin Result[I]:=0;
    for J:=0 to High(X) do Result[I]:=Result[I]+A[I][J]*X[J]; end; end;

function DenseFromMatrix(const A:TConvexMatrix):IDenseDoubleMatrix;
var I,J:Integer; begin Result:=TDenseDoubleMatrix.Zeros(Length(A),Length(A[0]));
  for I:=0 to High(A) do for J:=0 to High(A[I]) do Result[I,J]:=A[I][J]; end;

function DenseFromVector(const A:TDoubleArray):IDenseDoubleMatrix;
begin Result:=TDenseDoubleMatrix.FromVector(A,True); end;

function VectorFromDense(const A:IDenseDoubleMatrix):TDoubleArray;
var I:Integer; begin Result:=nil; SetLength(Result,A.Rows);
  for I:=0 to A.Rows-1 do Result[I]:=A[I,0]; end;

class function TConvexOptions.Defaults:TConvexOptions;
begin Result:=Default(TConvexOptions); Result.AbsoluteTolerance:=1E-9;
  Result.RelativeTolerance:=1E-7; Result.FeasibilityTolerance:=1E-8;
  Result.MaxIterations:=10000; end;

procedure ValidateOptions(const O:TConvexOptions);
begin
  if (O.AbsoluteTolerance<0) or (O.RelativeTolerance<0) or
     (O.AbsoluteTolerance+O.RelativeTolerance<=0) or
     (O.FeasibilityTolerance<=0) or (O.MaxIterations<=0) or
     not IsFiniteValue(O.AbsoluteTolerance) or
     not IsFiniteValue(O.RelativeTolerance) or
     not IsFiniteValue(O.FeasibilityTolerance) then
    raise EConvexOptimizationError.Create('Convex solver: invalid options.');
end;

function QPObjective(const Model:TQuadraticProgram;const X:TDoubleArray):Double;
var I,J:Integer; begin Result:=Dot(Model.C,X);
  for I:=0 to High(X) do for J:=0 to High(X) do
    Result:=Result+0.5*X[I]*Model.Q[I][J]*X[J]; end;

function QPGradient(const Model:TQuadraticProgram;const X:TDoubleArray):TDoubleArray;
var I,J:Integer; begin Result:=nil; SetLength(Result,Length(X));
  for I:=0 to High(X) do begin Result[I]:=Model.C[I];
    for J:=0 to High(X) do Result[I]:=Result[I]+Model.Q[I][J]*X[J]; end; end;

function UnconstrainedQPRecessionCertificate(const Model:TQuadraticProgram;
  out Direction:TDoubleArray):Boolean;
var
  Eig:IDenseDoubleSymmetricEigen;
  Vectors:IDenseDoubleMatrix;
  Values:TDoubleArray;
  I,J,N:Integer;
  Curvature,LinearPart,Scale,Tol:Double;
begin
  Result:=False;
  Direction:=nil;
  if (Length(Model.InequalityA)>0) or (Length(Model.EqualityA)>0) or
     (Length(Model.LowerBounds)>0) or (Length(Model.UpperBounds)>0) then
    Exit;
  N:=Length(Model.C);
  Eig:=FactorSymmetricEigen(DenseFromMatrix(Model.Q));
  Values:=Eig.Eigenvalues;
  Vectors:=Eig.Eigenvectors;
  Scale:=1;
  if Length(Values)>0 then Scale:=Max(Scale,Abs(Values[High(Values)]));
  Tol:=1E-10*Scale;
  for J:=0 to N-1 do
  begin
    Curvature:=Values[J];
    if Abs(Curvature)>Tol then Continue;
    LinearPart:=0;
    for I:=0 to N-1 do LinearPart:=LinearPart+Model.C[I]*Vectors[I,J];
    if Abs(LinearPart)<=1E-12*Max(1,Norm(Model.C)) then Continue;
    SetLength(Direction,N);
    if LinearPart>0 then
      for I:=0 to N-1 do Direction[I]:=-Vectors[I,J]
    else
      for I:=0 to N-1 do Direction[I]:=Vectors[I,J];
    Exit(True);
  end;
end;

function ProjectEqualities(const A:TConvexMatrix;const B:TDoubleArray;
  const X:TDoubleArray):TDoubleArray;
var
  Gram:TConvexMatrix; R:TDoubleArray; I,J,K,M:Integer;
  Sol:IDenseDoubleMatrix;
begin
  Result:=Copy(X); M:=Length(A); if M=0 then Exit;
  SetLength(Gram,M); SetLength(R,M);
  for I:=0 to M-1 do begin SetLength(Gram[I],M); R[I]:=Dot(A[I],X)-B[I];
    for J:=0 to M-1 do begin Gram[I][J]:=0;
      for K:=0 to High(X) do Gram[I][J]:=Gram[I][J]+A[I][K]*A[J][K]; end; end;
  try Sol:=Solve(DenseFromMatrix(Gram),DenseFromVector(R)); R:=VectorFromDense(Sol);
  except on E:Exception do raise EConvexOptimizationError.Create(
    'SolveQuadraticProgram: equality constraints are rank deficient.'); end;
  for K:=0 to High(X) do for I:=0 to M-1 do Result[K]:=Result[K]-A[I][K]*R[I];
end;

procedure ProjectFeasible(const Model:TQuadraticProgram;var X:TDoubleArray;
  Sweeps:Integer);
var I,J,K:Integer; V,N2:Double;
begin
  for K:=1 to Sweeps do begin
    if Length(Model.LowerBounds)>0 then for I:=0 to High(X) do X[I]:=Max(X[I],Model.LowerBounds[I]);
    if Length(Model.UpperBounds)>0 then for I:=0 to High(X) do X[I]:=Min(X[I],Model.UpperBounds[I]);
    if Length(Model.EqualityA)>0 then X:=ProjectEqualities(Model.EqualityA,Model.EqualityB,X);
    for I:=0 to High(Model.InequalityA) do begin
      V:=Dot(Model.InequalityA[I],X)-Model.InequalityB[I];
      if V>0 then begin N2:=Dot(Model.InequalityA[I],Model.InequalityA[I]);
        if N2=0 then Continue;
        for J:=0 to High(X) do X[J]:=X[J]-V*Model.InequalityA[I][J]/N2; end; end;
  end;
end;

function QPFeasibility(const M:TQuadraticProgram;const X:TDoubleArray):Double;
var I:Integer;
begin Result:=0;
  for I:=0 to High(M.InequalityA) do Result:=Max(Result,Dot(M.InequalityA[I],X)-M.InequalityB[I]);
  for I:=0 to High(M.EqualityA) do Result:=Max(Result,Abs(Dot(M.EqualityA[I],X)-M.EqualityB[I]));
  if Length(M.LowerBounds)>0 then for I:=0 to High(X) do Result:=Max(Result,M.LowerBounds[I]-X[I]);
  if Length(M.UpperBounds)>0 then for I:=0 to High(X) do Result:=Max(Result,X[I]-M.UpperBounds[I]);
  if Result<0 then Result:=0;
end;

procedure ValidateQP(const M:TQuadraticProgram);
var
  I,J,N:Integer; Eig:IDenseDoubleSymmetricEigen; Values:TDoubleArray;
  Tol:Double;
begin
  N:=Length(M.C); if N=0 then raise EConvexOptimizationError.Create(
    'SolveQuadraticProgram: cost vector must not be empty.');
  ValidateVector(M.C,N,'QP C'); ValidateMatrix(M.Q,N,'QP Q',False);
  if Length(M.Q)<>N then raise EConvexOptimizationError.Create(
    'SolveQuadraticProgram: Q must be square.');
  Tol:=1E-12;
  for I:=0 to N-1 do for J:=I+1 to N-1 do
    if Abs(M.Q[I][J]-M.Q[J][I])>Tol*Max(1,Max(Abs(M.Q[I][J]),Abs(M.Q[J][I]))) then
      raise EConvexOptimizationError.Create('SolveQuadraticProgram: Q must be symmetric.');
  Eig:=FactorSymmetricEigen(DenseFromMatrix(M.Q)); Values:=Eig.Eigenvalues;
  if (Length(Values)>0) and (Values[0]<-1E-10*Max(1,Abs(Values[High(Values)]))) then
    raise EConvexOptimizationError.Create(
      'SolveQuadraticProgram: Q must be positive semidefinite.');
  ValidateMatrix(M.InequalityA,N,'QP inequality A');
  ValidateVector(M.InequalityB,Length(M.InequalityA),'QP inequality B');
  ValidateMatrix(M.EqualityA,N,'QP equality A');
  ValidateVector(M.EqualityB,Length(M.EqualityA),'QP equality B');
  ValidateVector(M.LowerBounds,N,'QP lower bounds',True);
  ValidateVector(M.UpperBounds,N,'QP upper bounds',True);
  if (Length(M.LowerBounds)>0) and (Length(M.UpperBounds)>0) then
    for I:=0 to N-1 do
    if M.LowerBounds[I]>M.UpperBounds[I] then raise EConvexOptimizationError.CreateFmt(
      'SolveQuadraticProgram: lower bound exceeds upper bound at %d.',[I]);
end;

class function TConvexOptimizationKit.SolveQuadraticProgram(
  const Model:TQuadraticProgram;const Options:TConvexOptions):TConvexResult;
var
  X,Trial,G,PG,Direction:TDoubleArray; I,K,N,Stale:Integer;
  L,Step,Obj,NewObj,PrevObj,Tol:Double;
begin
  Result:=Default(TConvexResult); ValidateOptions(Options); ValidateQP(Model);
  if UnconstrainedQPRecessionCertificate(Model,Direction) then
  begin
    Result.Status:=isUnbounded;
    Result.Certificate:=Copy(Direction);
    Result.Objective:=-Infinity;
    Exit;
  end;
  N:=Length(Model.C); if Length(Options.InitialX)=0 then begin SetLength(X,N);
    for I:=0 to N-1 do begin
      if Length(Model.LowerBounds)>0 then X[I]:=Max(X[I],Model.LowerBounds[I]);
      if Length(Model.UpperBounds)>0 then X[I]:=Min(X[I],Model.UpperBounds[I]); end; end
  else begin ValidateVector(Options.InitialX,N,'QP InitialX'); X:=Copy(Options.InitialX); end;
  ProjectFeasible(Model,X,100);
  Result.Feasibility:=QPFeasibility(Model,X);
  if Result.Feasibility>Max(1E-4,100*Options.FeasibilityTolerance) then begin
    Result.X:=Copy(X); Result.BestX:=Copy(X);
    Result.Objective:=QPObjective(Model,X);
    Result.BestObjective:=Result.Objective;
    Result.Status:=isInfeasible; Exit; end;
  L:=0; for I:=0 to N-1 do begin Step:=0;
    for K:=0 to N-1 do Step:=Step+Abs(Model.Q[I][K]); L:=Max(L,Step); end;
  if L=0 then L:=1; Step:=1/L; Obj:=QPObjective(Model,X); Inc(Result.Evaluations);
  Result.BestX:=Copy(X); Result.BestObjective:=Obj;
  Stale:=0;
  for K:=1 to Options.MaxIterations do begin
    G:=QPGradient(Model,X); Inc(Result.Evaluations); Trial:=Copy(X);
    for I:=0 to N-1 do Trial[I]:=X[I]-Step*G[I];
    ProjectFeasible(Model,Trial,10); PG:=Copy(Trial);
    for I:=0 to N-1 do PG[I]:=(X[I]-Trial[I])/Step;
    Result.GradientNorm:=Norm(PG); Result.Feasibility:=QPFeasibility(Model,Trial);
    Tol:=Options.AbsoluteTolerance+Options.RelativeTolerance*Max(1,Norm(X));
    if (Result.GradientNorm<=Tol) and
       (Result.Feasibility<=Options.FeasibilityTolerance) then begin
      X:=Trial; Result.Status:=isConverged; Result.Iterations:=K; Break; end;
    NewObj:=QPObjective(Model,Trial); Inc(Result.Evaluations);
    if NewObj>Obj+1E-12*Max(1,Abs(Obj)) then begin Step:=Step/2;
      if Step<1E-16 then begin Result.Status:=isStagnation; Break; end; Continue; end;
    PrevObj:=Obj; Obj:=NewObj; X:=Trial;
    if Obj<Result.BestObjective then
    begin Result.BestObjective:=Obj; Result.BestX:=Copy(X); end;
    if Abs(PrevObj-Obj)<=DoubleEpsilon*Max(1,Abs(Obj)) then Inc(Stale) else Stale:=0;
    if Stale>=20 then begin Result.Status:=isStagnation; Break; end;
    Result.Iterations:=K;
    if Assigned(Options.Progress) and
       not Options.Progress(K,Result.Evaluations,Obj,Result.Feasibility) then begin
      Result.Status:=isCancelled; Break; end;
  end;
  if Result.Status=isUnknown then Result.Status:=isIterationLimit;
  Result.X:=Copy(X); Result.Objective:=QPObjective(Model,X);
  Inc(Result.Evaluations);
end;

function ConeSlack(const Cone:TSecondOrderCone;const X:TDoubleArray;
  out U:TDoubleArray;out T:Double):Double;
var I:Integer;
begin U:=MatVec(Cone.A,X);
  for I:=0 to High(U) do U[I]:=U[I]+Cone.B[I];
  T:=Dot(Cone.D,X)+Cone.E;
  Result:=T*T-Dot(U,U); end;

procedure ValidateCones(const C:TDoubleArray;const Cones:TSecondOrderCones);
var I,N:Integer;
begin N:=Length(C); if N=0 then raise EConvexOptimizationError.Create(
  'SolveSecondOrderConeProgram: cost vector must not be empty.');
  ValidateVector(C,N,'SOCP C'); if Length(Cones)=0 then raise EConvexOptimizationError.Create(
    'SolveSecondOrderConeProgram: at least one cone is required.');
  for I:=0 to High(Cones) do begin ValidateMatrix(Cones[I].A,N,'SOCP cone A',False);
    ValidateVector(Cones[I].B,Length(Cones[I].A),'SOCP cone B');
    ValidateVector(Cones[I].D,N,'SOCP cone D');
    if not IsFiniteValue(Cones[I].E) then raise EConvexOptimizationError.CreateFmt(
      'SOCP cone %d: E must be finite.',[I]); end;
end;

function SOCPFeasibility(const Cones:TSecondOrderCones;const X:TDoubleArray):Double;
var I:Integer;U:TDoubleArray;T:Double;
begin Result:=0; for I:=0 to High(Cones) do begin
  ConeSlack(Cones[I],X,U,T);
  Result:=Max(Result,Norm(U)-T); end; if Result<0 then Result:=0; end;

function BarrierValue(const C:TDoubleArray;const Cones:TSecondOrderCones;
  const X:TDoubleArray;Mu:Double;out Feasible:Boolean):Double;
var I:Integer;U:TDoubleArray;T,S:Double;
begin Result:=Dot(C,X); Feasible:=True;
  for I:=0 to High(Cones) do begin S:=ConeSlack(Cones[I],X,U,T);
    if (T<=0) or (S<=0) then begin Feasible:=False; Exit(Infinity); end;
    Result:=Result-Mu*Ln(S); end; end;

function BarrierGradient(const C:TDoubleArray;const Cones:TSecondOrderCones;
  const X:TDoubleArray;Mu:Double):TDoubleArray;
var I,J,K:Integer;U:TDoubleArray;T,S,ATU:Double;
begin Result:=Copy(C);
  for K:=0 to High(Cones) do begin S:=ConeSlack(Cones[K],X,U,T);
    for J:=0 to High(X) do begin ATU:=0;
      for I:=0 to High(U) do ATU:=ATU+Cones[K].A[I][J]*U[I];
      Result[J]:=Result[J]-2*Mu*(T*Cones[K].D[J]-ATU)/S; end; end; end;

class function TConvexOptimizationKit.SolveSecondOrderConeProgram(
  const C:TDoubleArray;const Cones:TSecondOrderCones;
  const Options:TConvexOptions):TConvexResult;
var
  X,Trial,G:TDoubleArray; I,K,Outer,N,Stale:Integer;
  Mu,Value,NewValue,Step,Tol,Prev:Double; Feasible:Boolean;
  InnerStalled:Boolean;
begin
  Result:=Default(TConvexResult); ValidateOptions(Options); ValidateCones(C,Cones);
  N:=Length(C); ValidateVector(Options.InitialX,N,'SOCP InitialX');
  X:=Copy(Options.InitialX); Value:=BarrierValue(C,Cones,X,1,Feasible);
  if not Feasible then begin Result.X:=X; Result.Feasibility:=SOCPFeasibility(Cones,X);
    Result.Status:=isInfeasible; Exit; end;
  Mu:=1; K:=0;
  for Outer:=1 to 12 do begin Stale:=0; InnerStalled:=False;
    while K<Options.MaxIterations do begin Inc(K);
      G:=BarrierGradient(C,Cones,X,Mu); Inc(Result.Evaluations);
      Result.GradientNorm:=Norm(G); Tol:=Options.AbsoluteTolerance+
        Options.RelativeTolerance*Max(1,Norm(X));
      if Result.GradientNorm<=Tol then Break;
      Step:=1; Prev:=Value;
      repeat Trial:=Copy(X); for I:=0 to N-1 do Trial[I]:=X[I]-Step*G[I];
        NewValue:=BarrierValue(C,Cones,Trial,Mu,Feasible); Inc(Result.Evaluations);
        if Feasible and (NewValue<=Value-1E-4*Step*Sqr(Result.GradientNorm)) then Break;
        Step:=Step/2;
      until Step<1E-16;
      if Step<1E-16 then begin InnerStalled:=True; Break; end;
      X:=Trial; Value:=NewValue;
      if Abs(Prev-Value)<=DoubleEpsilon*Max(1,Abs(Value)) then Inc(Stale) else Stale:=0;
      if Stale>=20 then begin InnerStalled:=True; Break; end;
      Result.Feasibility:=SOCPFeasibility(Cones,X); Result.Iterations:=K;
      if Assigned(Options.Progress) and
         not Options.Progress(K,Result.Evaluations,Dot(C,X),Result.Feasibility) then begin
        Result.Status:=isCancelled; Break; end;
    end;
    if Result.Status=isCancelled then Break;
    if Mu*Length(Cones)<=Options.AbsoluteTolerance+
       Options.RelativeTolerance*Max(1,Abs(Dot(C,X))) then begin
      Result.Status:=isConverged; Break; end;
    Mu:=Mu*0.1; Value:=BarrierValue(C,Cones,X,Mu,Feasible);
    if InnerStalled and (Mu<1E-14) then Break;
  end;
  if Result.Status=isUnknown then begin
    if K>=Options.MaxIterations then Result.Status:=isIterationLimit
    else Result.Status:=isAcceptableLimit; end;
  Result.X:=X; Result.Objective:=Dot(C,X);
  Result.Feasibility:=SOCPFeasibility(Cones,X); Result.Iterations:=K;
  if (Result.Status=isStagnation) and
     (Result.Feasibility<=Options.FeasibilityTolerance) and
     (Mu*Length(Cones)<=10*(Options.AbsoluteTolerance+
       Options.RelativeTolerance*Max(1,Abs(Result.Objective)))) then
    Result.Status:=isAcceptableLimit;
end;

end.
