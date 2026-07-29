unit NumericsLib.Interpolation;

{ Reusable one- and two-dimensional interpolants for the 1.7 modelling API.
  Constructors copy caller data; evaluation is read-only and reentrant. }

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math, MathBase.SharedTypes, MathBase.Iteration;

type
  EInterpolationError = class(Exception);
  TInterpolationMatrix = array of TDoubleArray;

  TBarycentricInterpolator = record
    X: TDoubleArray;
    Y: TDoubleArray;
    Weights: TDoubleArray;
    class function Build(const XKnots, YKnots: TDoubleArray):
      TBarycentricInterpolator; static;
    function Evaluate(const AtX: Double): Double;
  end;

  TRationalInterpolationResult = record
    Value: Double;
    ErrorEstimate: Double;
    Status: TIterationStatus;
  end;

  TCubicInterpolationKind = (cikPchip, cikAkima);

  TCubicInterpolator = record
    X: TDoubleArray;
    Y: TDoubleArray;
    Slopes: TDoubleArray;
    Kind: TCubicInterpolationKind;
    class function BuildPchip(const XKnots, YKnots: TDoubleArray):
      TCubicInterpolator; static;
    class function BuildAkima(const XKnots, YKnots: TDoubleArray):
      TCubicInterpolator; static;
    function Evaluate(const AtX: Double): Double;
    function Derivative(const AtX: Double): Double;
    function Antiderivative(const AtX: Double): Double;
    function Integrate(const A, B: Double): Double;
  end;

  TGridSurface = record
    X: TDoubleArray;
    Y: TDoubleArray;
    Values: TInterpolationMatrix; { Values[YIndex][XIndex] }
    class function Build(const XKnots, YKnots: TDoubleArray;
      const GridValues: TInterpolationMatrix): TGridSurface; static;
    function Bilinear(const AtX, AtY: Double): Double;
    function Bicubic(const AtX, AtY: Double): Double;
  end;

  TScatteredInterpolator = record
    X: TDoubleArray;
    Y: TDoubleArray;
    Values: TDoubleArray;
    Weights: TDoubleArray;
    Shape: Double;
    ThinPlate: Boolean;
    class function BuildRBF(const XCoord, YCoord, ZValues: TDoubleArray;
      ShapeParameter: Double = 1.0): TScatteredInterpolator; static;
    class function BuildThinPlate(const XCoord, YCoord,
      ZValues: TDoubleArray): TScatteredInterpolator; static;
    function Evaluate(const AtX, AtY: Double): Double;
  end;

  TInterpolationKit = class
  public
    class function Rational(const XKnots, YKnots: TDoubleArray;
      X: Double): TRationalInterpolationResult; static;
    class function InverseDistance(const XCoord, YCoord, ZValues: TDoubleArray;
      X, Y: Double; Power: Double = 2.0): Double; static;
  end;

implementation

function IsFiniteValue(const X: Double): Boolean; inline;
begin Result := not IsNan(X) and not IsInfinite(X); end;

procedure ValidateKnots(const X, Y: TDoubleArray; const Name: String;
  const Minimum: Integer = 2);
var
  I: Integer;
begin
  if Length(X) <> Length(Y) then
    raise EInterpolationError.CreateFmt(
      '%s: X and Y lengths differ (%d and %d).',
      [Name, Length(X), Length(Y)]);
  if Length(X) < Minimum then
    raise EInterpolationError.CreateFmt(
      '%s: requires at least %d knots.', [Name, Minimum]);
  for I := 0 to High(X) do
  begin
    if not IsFiniteValue(X[I]) or not IsFiniteValue(Y[I]) then
      raise EInterpolationError.CreateFmt(
        '%s: knot %d must be finite.', [Name, I]);
    if (I > 0) and (X[I] <= X[I - 1]) then
      raise EInterpolationError.CreateFmt(
        '%s: X knots must be strictly increasing at index %d.', [Name, I]);
  end;
end;

function LocateInterval(const X: TDoubleArray; Value: Double): Integer;
var
  Lo, Hi, Mid: Integer;
begin
  if Value <= X[0] then Exit(0);
  if Value >= X[High(X)] then Exit(High(X) - 1);
  Lo := 0; Hi := High(X);
  while Hi - Lo > 1 do
  begin
    Mid := Lo + (Hi - Lo) div 2;
    if X[Mid] <= Value then Lo := Mid else Hi := Mid;
  end;
  Result := Lo;
end;

class function TBarycentricInterpolator.Build(
  const XKnots, YKnots: TDoubleArray): TBarycentricInterpolator;
var
  I, J, N: Integer;
  Product, MaxWeight: Double;
begin
  Result := Default(TBarycentricInterpolator);
  ValidateKnots(XKnots, YKnots, 'Barycentric.Build');
  Result.X := Copy(XKnots);
  Result.Y := Copy(YKnots);
  N := Length(XKnots);
  SetLength(Result.Weights, N);
  MaxWeight := 0;
  for I := 0 to N - 1 do
  begin
    Product := 1;
    for J := 0 to N - 1 do
      if J <> I then Product := Product * (XKnots[I] - XKnots[J]);
    if (Product = 0) or not IsFiniteValue(Product) then
      raise EInterpolationError.Create(
        'Barycentric.Build: weight construction overflowed; rescale knots.');
    Result.Weights[I] := 1 / Product;
    MaxWeight := Max(MaxWeight, Abs(Result.Weights[I]));
  end;
  for I := 0 to N - 1 do Result.Weights[I] := Result.Weights[I] / MaxWeight;
end;

function TBarycentricInterpolator.Evaluate(const AtX: Double): Double;
var
  I: Integer;
  Term, Numerator, Denominator, Compensation, YTerm: Double;
begin
  if Length(X) = 0 then
    raise EInterpolationError.Create(
      'Barycentric.Evaluate: interpolator has no knots.');
  if not IsFiniteValue(AtX) then
    raise EInterpolationError.Create(
      'Barycentric.Evaluate: X must be finite.');
  Numerator := 0; Denominator := 0; Compensation := 0;
  for I := 0 to High(X) do
  begin
    if AtX = X[I] then Exit(Y[I]);
    Term := Weights[I] / (AtX - X[I]);
    Denominator := Denominator + Term;
    YTerm := Term * Y[I] - Compensation;
    Term := Numerator + YTerm;
    Compensation := (Term - Numerator) - YTerm;
    Numerator := Term;
  end;
  if Denominator = 0 then
    raise EInterpolationError.Create(
      'Barycentric.Evaluate: numerical denominator is zero.');
  Result := Numerator / Denominator;
end;

class function TInterpolationKit.Rational(
  const XKnots, YKnots: TDoubleArray;
  X: Double): TRationalInterpolationResult;
var
  C, D: TDoubleArray;
  I, M, NS, N: Integer;
  W, T, H, DD, DY: Double;
begin
  Result := Default(TRationalInterpolationResult);
  ValidateKnots(XKnots, YKnots, 'Rational');
  if not IsFiniteValue(X) then
    raise EInterpolationError.Create('Rational: X must be finite.');
  N := Length(XKnots);
  SetLength(C, N); SetLength(D, N);
  NS := 0;
  H := Abs(X - XKnots[0]);
  for I := 0 to N - 1 do
  begin
    if X = XKnots[I] then
    begin
      Result.Value := YKnots[I];
      Result.Status := isConverged;
      Exit;
    end;
    if Abs(X - XKnots[I]) < H then begin NS := I; H := Abs(X-XKnots[I]); end;
    C[I] := YKnots[I];
    D[I] := YKnots[I] + 1E-300;
  end;
  Result.Value := YKnots[NS];
  Dec(NS);
  for M := 1 to N - 1 do
  begin
    for I := 0 to N - M - 1 do
    begin
      W := C[I + 1] - D[I];
      H := XKnots[I + M] - X;
      T := (XKnots[I] - X) * D[I] / H;
      DD := T - C[I + 1];
      if Abs(DD) <= 1E-300 * Max(1.0, Max(Abs(T), Abs(C[I + 1]))) then
      begin
        Result.Status := isNumericalBreakdown;
        Exit;
      end;
      DD := W / DD;
      D[I] := C[I + 1] * DD;
      C[I] := T * DD;
    end;
    if 2 * (NS + 1) < N - M then DY := C[NS + 1]
    else begin DY := D[NS]; Dec(NS); end;
    Result.Value := Result.Value + DY;
    Result.ErrorEstimate := Abs(DY);
  end;
  if IsFiniteValue(Result.Value) then Result.Status := isConverged
  else Result.Status := isNumericalBreakdown;
end;

function EndpointSlope(const H0, H1, D0, D1: Double): Double;
begin
  Result := ((2 * H0 + H1) * D0 - H0 * D1) / (H0 + H1);
  if Result * D0 <= 0 then Result := 0
  else if (D0 * D1 < 0) and (Abs(Result) > Abs(3 * D0)) then
    Result := 3 * D0;
end;

class function TCubicInterpolator.BuildPchip(
  const XKnots, YKnots: TDoubleArray): TCubicInterpolator;
var
  H, Delta: TDoubleArray;
  I, N: Integer;
  W1, W2: Double;
begin
  Result := Default(TCubicInterpolator);
  ValidateKnots(XKnots, YKnots, 'Pchip.Build');
  Result.X := Copy(XKnots); Result.Y := Copy(YKnots);
  Result.Kind := cikPchip;
  N := Length(XKnots);
  SetLength(Result.Slopes, N);
  SetLength(H, N - 1); SetLength(Delta, N - 1);
  for I := 0 to N - 2 do
  begin
    H[I] := XKnots[I + 1] - XKnots[I];
    Delta[I] := (YKnots[I + 1] - YKnots[I]) / H[I];
  end;
  if N = 2 then
  begin
    Result.Slopes[0] := Delta[0]; Result.Slopes[1] := Delta[0]; Exit;
  end;
  Result.Slopes[0] := EndpointSlope(H[0], H[1], Delta[0], Delta[1]);
  Result.Slopes[N - 1] := EndpointSlope(H[N - 2], H[N - 3],
    Delta[N - 2], Delta[N - 3]);
  for I := 1 to N - 2 do
    if (Delta[I - 1] = 0) or (Delta[I] = 0) or
       (Delta[I - 1] * Delta[I] <= 0) then
      Result.Slopes[I] := 0
    else
    begin
      W1 := 2 * H[I] + H[I - 1];
      W2 := H[I] + 2 * H[I - 1];
      Result.Slopes[I] := (W1 + W2) /
        (W1 / Delta[I - 1] + W2 / Delta[I]);
    end;
end;

class function TCubicInterpolator.BuildAkima(
  const XKnots, YKnots: TDoubleArray): TCubicInterpolator;
var
  D: TDoubleArray;
  I, N: Integer;
  W1, W2: Double;
begin
  Result := Default(TCubicInterpolator);
  ValidateKnots(XKnots, YKnots, 'Akima.Build', 5);
  Result.X := Copy(XKnots); Result.Y := Copy(YKnots);
  Result.Kind := cikAkima;
  N := Length(XKnots);
  SetLength(D, N + 3); { secants indexed with +2, including extrapolated ends }
  for I := 0 to N - 2 do
    D[I + 2] := (YKnots[I + 1] - YKnots[I]) /
      (XKnots[I + 1] - XKnots[I]);
  D[1] := 2 * D[2] - D[3];
  D[0] := 2 * D[1] - D[2];
  D[N + 1] := 2 * D[N] - D[N - 1];
  D[N + 2] := 2 * D[N + 1] - D[N];
  SetLength(Result.Slopes, N);
  for I := 0 to N - 1 do
  begin
    W1 := Abs(D[I + 3] - D[I + 2]);
    W2 := Abs(D[I + 1] - D[I]);
    if W1 + W2 > 0 then
      Result.Slopes[I] := (W1 * D[I + 1] + W2 * D[I + 2]) / (W1 + W2)
    else
      Result.Slopes[I] := 0.5 * (D[I + 1] + D[I + 2]);
  end;
end;

procedure HermiteCoefficients(const Interp: TCubicInterpolator;
  const I: Integer; out A, B, C, D, H: Double);
var
  Delta: Double;
begin
  H := Interp.X[I + 1] - Interp.X[I];
  Delta := (Interp.Y[I + 1] - Interp.Y[I]) / H;
  A := Interp.Y[I];
  B := Interp.Slopes[I];
  C := (3 * Delta - 2 * Interp.Slopes[I] - Interp.Slopes[I + 1]) / H;
  D := (Interp.Slopes[I] + Interp.Slopes[I + 1] - 2 * Delta) / (H * H);
end;

function TCubicInterpolator.Evaluate(const AtX: Double): Double;
var
  I: Integer;
  A, B, C, D, H, DX: Double;
begin
  if Length(X) = 0 then raise EInterpolationError.Create(
    'CubicInterpolator.Evaluate: interpolator has no knots.');
  if not IsFiniteValue(AtX) then raise EInterpolationError.Create(
    'CubicInterpolator.Evaluate: X must be finite.');
  if AtX <= X[0] then Exit(Y[0]);
  if AtX >= X[High(X)] then Exit(Y[High(Y)]);
  I := LocateInterval(X, AtX);
  HermiteCoefficients(Self, I, A, B, C, D, H);
  DX := AtX - X[I];
  Result := A + DX * (B + DX * (C + DX * D));
end;

function TCubicInterpolator.Derivative(const AtX: Double): Double;
var
  I: Integer;
  A, B, C, D, H, DX, ClampedX: Double;
begin
  if Length(X) = 0 then raise EInterpolationError.Create(
    'CubicInterpolator.Derivative: interpolator has no knots.');
  if not IsFiniteValue(AtX) then raise EInterpolationError.Create(
    'CubicInterpolator.Derivative: X must be finite.');
  ClampedX := Min(Max(AtX, X[0]), X[High(X)]);
  I := LocateInterval(X, ClampedX);
  HermiteCoefficients(Self, I, A, B, C, D, H);
  DX := ClampedX - X[I];
  Result := B + DX * (2 * C + 3 * D * DX);
end;

function SegmentPrimitive(const Interp: TCubicInterpolator;
  const I: Integer; DX: Double): Double;
var
  A, B, C, D, H: Double;
begin
  HermiteCoefficients(Interp, I, A, B, C, D, H);
  Result := A * DX + B * Sqr(DX) / 2 + C * DX * Sqr(DX) / 3 +
    D * Sqr(Sqr(DX)) / 4;
end;

function TCubicInterpolator.Antiderivative(const AtX: Double): Double;
var
  I, Last: Integer;
  ClampedX, H: Double;
begin
  if Length(X) = 0 then raise EInterpolationError.Create(
    'CubicInterpolator.Antiderivative: interpolator has no knots.');
  if not IsFiniteValue(AtX) then raise EInterpolationError.Create(
    'CubicInterpolator.Antiderivative: X must be finite.');
  ClampedX := Min(Max(AtX, X[0]), X[High(X)]);
  Last := LocateInterval(X, ClampedX);
  Result := 0;
  for I := 0 to Last - 1 do
  begin
    H := X[I + 1] - X[I];
    Result := Result + SegmentPrimitive(Self, I, H);
  end;
  Result := Result + SegmentPrimitive(Self, Last, ClampedX - X[Last]);
end;

function TCubicInterpolator.Integrate(const A, B: Double): Double;
begin
  Result := Antiderivative(B) - Antiderivative(A);
end;

class function TGridSurface.Build(const XKnots, YKnots: TDoubleArray;
  const GridValues: TInterpolationMatrix): TGridSurface;
var
  I, J: Integer;
  DummyX, DummyY: TDoubleArray;
begin
  Result := Default(TGridSurface);
  SetLength(DummyY, Length(XKnots));
  ValidateKnots(XKnots, DummyY, 'GridSurface.Build X');
  SetLength(DummyX, Length(YKnots));
  ValidateKnots(YKnots, DummyX, 'GridSurface.Build Y');
  if Length(GridValues) <> Length(YKnots) then
    raise EInterpolationError.Create(
      'GridSurface.Build: grid row count must equal Y knot count.');
  Result.X := Copy(XKnots); Result.Y := Copy(YKnots);
  SetLength(Result.Values, Length(GridValues));
  for I := 0 to High(GridValues) do
  begin
    if Length(GridValues[I]) <> Length(XKnots) then
      raise EInterpolationError.CreateFmt(
        'GridSurface.Build: row %d has %d columns; expected %d.',
        [I, Length(GridValues[I]), Length(XKnots)]);
    SetLength(Result.Values[I], Length(XKnots));
    for J := 0 to High(GridValues[I]) do
    begin
      if not IsFiniteValue(GridValues[I][J]) then
        raise EInterpolationError.CreateFmt(
          'GridSurface.Build: value [%d,%d] must be finite.', [I, J]);
      Result.Values[I][J] := GridValues[I][J];
    end;
  end;
end;

function TGridSurface.Bilinear(const AtX, AtY: Double): Double;
var
  IX, IY: Integer;
  TX, TY, CX, CY: Double;
begin
  if Length(X) = 0 then raise EInterpolationError.Create(
    'GridSurface.Bilinear: surface is empty.');
  if not IsFiniteValue(AtX) or not IsFiniteValue(AtY) then
    raise EInterpolationError.Create(
      'GridSurface.Bilinear: coordinates must be finite.');
  CX := Min(Max(AtX, X[0]), X[High(X)]);
  CY := Min(Max(AtY, Y[0]), Y[High(Y)]);
  IX := LocateInterval(X, CX); IY := LocateInterval(Y, CY);
  TX := (CX - X[IX]) / (X[IX + 1] - X[IX]);
  TY := (CY - Y[IY]) / (Y[IY + 1] - Y[IY]);
  Result := (1 - TY) * ((1 - TX) * Values[IY][IX] +
    TX * Values[IY][IX + 1]) +
    TY * ((1 - TX) * Values[IY + 1][IX] + TX * Values[IY + 1][IX + 1]);
end;

function TGridSurface.Bicubic(const AtX, AtY: Double): Double;
var
  ColumnValues: TDoubleArray;
  I: Integer;
  RowSpline, ColumnSpline: TCubicInterpolator;
begin
  if Length(X) < 2 then raise EInterpolationError.Create(
    'GridSurface.Bicubic: surface is empty.');
  SetLength(ColumnValues, Length(Y));
  for I := 0 to High(Y) do
  begin
    RowSpline := TCubicInterpolator.BuildPchip(X, Values[I]);
    ColumnValues[I] := RowSpline.Evaluate(AtX);
  end;
  ColumnSpline := TCubicInterpolator.BuildPchip(Y, ColumnValues);
  Result := ColumnSpline.Evaluate(AtY);
end;

class function TInterpolationKit.InverseDistance(
  const XCoord, YCoord, ZValues: TDoubleArray; X, Y: Double;
  Power: Double): Double;
var
  I: Integer;
  DX, DY, D2, W, SumW, SumZ: Double;
begin
  if (Length(XCoord) = 0) or (Length(YCoord) <> Length(XCoord)) or
     (Length(ZValues) <> Length(XCoord)) then
    raise EInterpolationError.Create(
      'InverseDistance: coordinate/value lengths must match and be non-empty.');
  if (Power <= 0) or not IsFiniteValue(Power) or
     not IsFiniteValue(X) or not IsFiniteValue(Y) then
    raise EInterpolationError.Create(
      'InverseDistance: coordinates and positive Power must be finite.');
  for I := 0 to High(YCoord) do
    if not IsFiniteValue(XCoord[I]) or not IsFiniteValue(YCoord[I]) or
       not IsFiniteValue(ZValues[I]) then
      raise EInterpolationError.CreateFmt(
        'InverseDistance: point %d must be finite.', [I]);
  SumW := 0; SumZ := 0;
  for I := 0 to High(XCoord) do
  begin
    DX := X - XCoord[I]; DY := Y - YCoord[I]; D2 := DX * DX + DY * DY;
    if D2 = 0 then Exit(ZValues[I]);
    W := Math.Power(D2, -0.5 * Power);
    SumW := SumW + W; SumZ := SumZ + W * ZValues[I];
  end;
  Result := SumZ / SumW;
end;

function KernelValue(const R, Shape: Double; ThinPlate: Boolean): Double;
begin
  if ThinPlate then
  begin
    if R = 0 then Result := 0 else Result := R * R * Ln(R);
  end
  else
    Result := Exp(-Sqr(Shape * R));
end;

function SolveLinear(var A: TInterpolationMatrix; var B: TDoubleArray):
  TDoubleArray;
var
  I, J, K, P, N: Integer;
  Pivot, Factor, Temp: Double;
begin
  Result := nil;
  N := Length(B); SetLength(Result, N);
  for K := 0 to N - 1 do
  begin
    P := K;
    for I := K + 1 to N - 1 do
      if Abs(A[I][K]) > Abs(A[P][K]) then P := I;
    if Abs(A[P][K]) <= 1E-14 then raise EInterpolationError.Create(
      'ScatteredInterpolator.Build: kernel system is singular or ill-conditioned.');
    if P <> K then
    begin
      for J := K to N - 1 do begin Temp:=A[K][J]; A[K][J]:=A[P][J]; A[P][J]:=Temp; end;
      Temp:=B[K]; B[K]:=B[P]; B[P]:=Temp;
    end;
    Pivot := A[K][K];
    for I := K + 1 to N - 1 do
    begin
      Factor := A[I][K] / Pivot;
      for J := K + 1 to N - 1 do A[I][J] := A[I][J] - Factor * A[K][J];
      B[I] := B[I] - Factor * B[K];
    end;
  end;
  for I := N - 1 downto 0 do
  begin
    Temp := B[I];
    for J := I + 1 to N - 1 do Temp := Temp - A[I][J] * Result[J];
    Result[I] := Temp / A[I][I];
  end;
end;

function BuildScattered(const XCoord, YCoord, ZValues: TDoubleArray;
  Shape: Double; ThinPlate: Boolean): TScatteredInterpolator;
var
  A: TInterpolationMatrix;
  RHS: TDoubleArray;
  I, J, N, Extra: Integer;
  R: Double;
begin
  Result := Default(TScatteredInterpolator);
  if (Length(XCoord) <> Length(YCoord)) or
     (Length(XCoord) <> Length(ZValues)) then
    raise EInterpolationError.Create(
      'ScatteredInterpolator.Build: coordinate/value lengths differ.');
  if Length(XCoord) < 2 then raise EInterpolationError.Create(
    'ScatteredInterpolator.Build: requires at least two points.');
  for I := 0 to High(XCoord) do
  begin
    if not IsFiniteValue(XCoord[I]) or not IsFiniteValue(YCoord[I]) or
       not IsFiniteValue(ZValues[I]) then
      raise EInterpolationError.CreateFmt(
        'ScatteredInterpolator.Build: point %d must be finite.', [I]);
    for J := 0 to I - 1 do
      if (XCoord[I] = XCoord[J]) and (YCoord[I] = YCoord[J]) then
        raise EInterpolationError.CreateFmt(
          'ScatteredInterpolator.Build: duplicate point %d.', [I]);
  end;
  if (not ThinPlate) and ((Shape <= 0) or not IsFiniteValue(Shape)) then
    raise EInterpolationError.Create(
      'RBF.Build: ShapeParameter must be finite and positive.');
  N := Length(XCoord); Extra := Ord(ThinPlate) * 3;
  SetLength(A, N + Extra); SetLength(RHS, N + Extra);
  for I := 0 to N + Extra - 1 do SetLength(A[I], N + Extra);
  for I := 0 to N - 1 do
  begin
    RHS[I] := ZValues[I];
    for J := 0 to N - 1 do
    begin
      R := Hypot(XCoord[I] - XCoord[J], YCoord[I] - YCoord[J]);
      A[I][J] := KernelValue(R, Shape, ThinPlate);
    end;
    if ThinPlate then
    begin
      A[I][N] := 1; A[I][N + 1] := XCoord[I]; A[I][N + 2] := YCoord[I];
      A[N][I] := 1; A[N + 1][I] := XCoord[I]; A[N + 2][I] := YCoord[I];
    end;
  end;
  Result.X := Copy(XCoord); Result.Y := Copy(YCoord);
  Result.Values := Copy(ZValues); Result.Shape := Shape; Result.ThinPlate := ThinPlate;
  Result.Weights := SolveLinear(A, RHS);
end;

class function TScatteredInterpolator.BuildRBF(
  const XCoord, YCoord, ZValues: TDoubleArray;
  ShapeParameter: Double): TScatteredInterpolator;
begin Result := BuildScattered(XCoord, YCoord, ZValues, ShapeParameter, False); end;

class function TScatteredInterpolator.BuildThinPlate(
  const XCoord, YCoord, ZValues: TDoubleArray): TScatteredInterpolator;
begin Result := BuildScattered(XCoord, YCoord, ZValues, 1.0, True); end;

function TScatteredInterpolator.Evaluate(const AtX, AtY: Double): Double;
var
  I, N: Integer;
  R: Double;
begin
  if (Length(X) = 0) or not IsFiniteValue(AtX) or not IsFiniteValue(AtY) then
    raise EInterpolationError.Create(
      'ScatteredInterpolator.Evaluate: interpolator and coordinates must be valid.');
  N := Length(X); Result := 0;
  for I := 0 to N - 1 do
  begin
    R := Hypot(AtX - X[I], AtY - Y[I]);
    Result := Result + Weights[I] * KernelValue(R, Shape, ThinPlate);
  end;
  if ThinPlate then
    Result := Result + Weights[N] + Weights[N + 1] * AtX +
      Weights[N + 2] * AtY;
end;

end.
