unit TestGeometryLib;

{-----------------------------------------------------------------------------
 TestGeometryLib

 Comprehensive tests for GeometryLib.Geometry.
 All expected values are analytically computed.

 Coverage
   TPoint2D / TVector2D helpers
   TSegment2D / TLine2D / TCircle2D helpers
   TPoint3D / TVector3D / TSegment3D / TPlane3D / TSphere3D helpers
   PointToPoint2D / PointToSegment2D / PointToLine2D / SegmentToSegment2D
   PointToPoint3D / PointToSegment3D / PointToPlane3D
   SegmentsIntersect2D — crossing, touching, parallel, collinear
   SegmentIntersect2D  — intersection point and t parameter
   LineIntersect2D     — two non-parallel lines
   SegmentCircleIntersect / RayCircleIntersect
   PolygonArea (CW and CCW)
   PolygonPerimeter / PolygonCentroid
   PointInPolygon (inside, outside, concave polygon)
   IsConvex (square=true, L-shape=false)
   ConvexHull (triangle, square + interior points)
   Translate2D / Scale2D / Rotate2D
   AngleBetween2D / AngleBetween3D
   TriangleArea2D / TriangleArea3D
   BoundingBox2D
   Error handling — EGeometryError
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  fpcunit, testutils, testregistry,
  MathBase.SharedTypes,
  GeometryLib.Geometry;

type
  TTestGeometryLib = class(TTestCase)
  private
    procedure AssertNear(const AMsg: string; Expected, Got: Double; Tol: Double = 1e-9);
    procedure AssertPoint2DNear(const AMsg: string; EX, EY: Double; const Got: TPoint2D; Tol: Double = 1e-9);
    procedure AssertVector2DNear(const AMsg: string; EX, EY: Double; const Got: TVector2D; Tol: Double = 1e-9);
    procedure AssertVector3DNear(const AMsg: string; EX, EY, EZ: Double; const Got: TVector3D; Tol: Double = 1e-9);
    procedure AssertGeoError(const AMsg: string; AProc: TProcedure);
    { Build a unit square CCW: (0,0),(1,0),(1,1),(0,1) }
    function UnitSquare: TPolygon2D;
    { Build a regular triangle CCW }
    function Triangle: TPolygon2D;
  published
    { --- 2-D Primitives ---------------------------------------------------- }
    procedure TestPoint2D_DistanceTo;
    procedure TestVector2D_Magnitude;
    procedure TestVector2D_Normalise;
    procedure TestVector2D_ExtremeMagnitudeAndNormalise;
    procedure TestVector2D_Dot;
    procedure TestVector2D_Cross;
    procedure TestVector2D_Perpendicular;
    procedure TestVector2D_ArithmeticOperators;
    procedure TestSegment2D_Length;
    procedure TestSegment2D_Midpoint;
    procedure TestLine2D_Distance;
    procedure TestLine2D_ClosestPoint;
    procedure TestCircle2D_Area;
    procedure TestCircle2D_ContainsPoint;
    { --- 3-D Primitives ---------------------------------------------------- }
    procedure TestPoint3D_DistanceTo;
    procedure TestVector3D_Magnitude;
    procedure TestVector3D_Normalise;
    procedure TestVector3D_ExtremeMagnitudeAndNormalise;
    procedure TestVector3D_Dot;
    procedure TestVector3D_Cross;
    procedure TestVector3D_ArithmeticOperators;
    procedure TestVectorArithmetic_PropertiesAndDimensionalAgreement;
    procedure TestVectorArithmetic_ExistingOperationProperties;
    procedure TestVectorArithmetic_NonFiniteAndOverflow;
    procedure TestVectorArithmetic_ZeroDivisionAndSignedZero;
    procedure TestSegment3D_Length;
    procedure TestSegment3D_Midpoint;
    procedure TestPlane3D_Distance;
    procedure TestPlane3D_ClosestPoint;
    procedure TestSphere3D_Volume;
    procedure TestSphere3D_ContainsPoint;
    { --- Distance ---------------------------------------------------------- }
    procedure TestPointToPoint2D;
    procedure TestPointToSegment2D_Interior;
    procedure TestPointToSegment2D_Endpoint;
    procedure TestPointToLine2D;
    procedure TestSegmentToSegment2D_Crossing;
    procedure TestSegmentToSegment2D_Parallel;
    procedure TestPointToPoint3D;
    procedure TestPointToSegment3D;
    procedure TestPointToPlane3D;
    { --- Intersection ------------------------------------------------------ }
    procedure TestSegmentsIntersect2D_Crossing;
    procedure TestSegmentsIntersect2D_Touching;
    procedure TestSegmentsIntersect2D_Parallel;
    procedure TestSegmentsIntersect2D_Collinear;
    procedure TestSegmentIntersect2D_FindsPoint;
    procedure TestSegmentIntersect2D_Parallel;
    procedure TestLineIntersect2D_FindsPoint;
    procedure TestLineIntersect2D_Parallel;
    procedure TestSegmentCircleIntersect_Crossing;
    procedure TestSegmentCircleIntersect_Outside;
    procedure TestRayCircleIntersect_Two;
    procedure TestRayCircleIntersect_None;
    { --- Polygon ----------------------------------------------------------- }
    procedure TestPolygonArea_CCW;
    procedure TestPolygonArea_CW;
    procedure TestPolygonPerimeter_Square;
    procedure TestPolygonCentroid_Square;
    procedure TestPolygonCentroid_Triangle;
    procedure TestPointInPolygon_Inside;
    procedure TestPointInPolygon_Outside;
    procedure TestPointInPolygon_Concave;
    procedure TestIsConvex_Square;
    procedure TestIsConvex_LShaped;
    procedure TestConvexHull_Triangle;
    procedure TestConvexHull_SquarePlusInterior;
    { --- Transformations --------------------------------------------------- }
    procedure TestTranslate2D;
    procedure TestScale2D;
    procedure TestRotate2D_90Degrees;
    procedure TestRotate2D_360Degrees;
    { --- Angles & Areas ---------------------------------------------------- }
    procedure TestAngleBetween2D_Perpendicular;
    procedure TestAngleBetween2D_Parallel;
    procedure TestAngleBetween3D_Perpendicular;
    procedure TestTriangleArea2D;
    procedure TestTriangleArea3D;
    procedure TestBoundingBox2D;
    { --- Error handling ---------------------------------------------------- }
    procedure TestVector2D_NormaliseZeroRaises;
    procedure TestVector3D_NormaliseZeroRaises;
    procedure TestVectorNormalise_NonFiniteRaises;
    procedure TestLine2D_SamePointRaises;
    procedure TestPolygonArea_TooFewRaises;
    procedure TestConvexHull_TooFewRaises;
    procedure TestBoundingBox2D_EmptyRaises;
    procedure TestPlane3D_CollinearRaises;
    procedure TestRayCircleRejectsIntersectionsBehindOrigin;
    procedure TestRayCircleFromInsideHasOneForwardHit;
    procedure TestPointInPolygonBoundaryIsInside;
    procedure TestConvexHullLargeInputProperties;
  end;

implementation

{ ---------------------------------------------------------------------------
  Unit-level state for error-test helpers (FPC 3.2.2: no anonymous procs)
--------------------------------------------------------------------------- }
var
  GErrPts: TPolygon2D;

function NegativeZero: Double;
var
  Bits: QWord;
begin
  Bits := QWord($8000000000000000);
  Move(Bits, Result, SizeOf(Result));
end;

procedure ErrNormaliseZero;
var V: TVector2D;
begin V := TVector2D.Create(0, 0); V.Normalise; end;

procedure ErrNormalise3DZero;
var V: TVector3D;
begin V := TVector3D.Create(0, 0, 0); V.Normalise; end;

procedure ErrNormalise2DInfinity;
var V: TVector2D;
begin V := TVector2D.Create(Infinity, 1); V.Normalise; end;

procedure ErrNormalise3DNaN;
var V: TVector3D;
begin V := TVector3D.Create(1, NaN, 2); V.Normalise; end;

procedure ErrLineSamePoint;
begin TLine2D.FromPoints(TPoint2D.Create(1,1), TPoint2D.Create(1,1)); end;

procedure ErrPolygonAreaTooFew;
begin TGeometryKit.PolygonArea(GErrPts); end;

procedure ErrConvexHullTooFew;
begin TGeometryKit.ConvexHull(GErrPts); end;

procedure ErrBoundingBoxEmpty;
begin TGeometryKit.BoundingBox2D(GErrPts); end;

procedure ErrPlaneCollinear;
begin
  TPlane3D.FromThreePoints(
    TPoint3D.Create(0,0,0),
    TPoint3D.Create(1,0,0),
    TPoint3D.Create(2,0,0));
end;

{ ---------------------------------------------------------------------------
  Helpers
--------------------------------------------------------------------------- }

procedure TTestGeometryLib.AssertNear(const AMsg: string; Expected, Got: Double; Tol: Double);
begin
  if Abs(Got - Expected) > Tol then
    Fail(AMsg + Format(' — expected %.10g, got %.10g', [Expected, Got]));
end;

procedure TTestGeometryLib.AssertPoint2DNear(const AMsg: string; EX, EY: Double; const Got: TPoint2D; Tol: Double);
begin
  AssertNear(AMsg + ' X', EX, Got.X, Tol);
  AssertNear(AMsg + ' Y', EY, Got.Y, Tol);
end;

procedure TTestGeometryLib.AssertVector2DNear(const AMsg: string; EX, EY: Double; const Got: TVector2D; Tol: Double);
begin
  AssertNear(AMsg + ' X', EX, Got.X, Tol);
  AssertNear(AMsg + ' Y', EY, Got.Y, Tol);
end;

procedure TTestGeometryLib.AssertVector3DNear(const AMsg: string; EX, EY, EZ: Double; const Got: TVector3D; Tol: Double);
begin
  AssertNear(AMsg + ' X', EX, Got.X, Tol);
  AssertNear(AMsg + ' Y', EY, Got.Y, Tol);
  AssertNear(AMsg + ' Z', EZ, Got.Z, Tol);
end;

procedure TTestGeometryLib.AssertGeoError(const AMsg: string; AProc: TProcedure);
begin
  try
    AProc;
    Fail(AMsg + ': expected EGeometryError but none raised');
  except
    on E: EGeometryError do { pass }
    else raise;
  end;
end;

function TTestGeometryLib.UnitSquare: TPolygon2D;
begin
  Result := nil;
  SetLength(Result, 4);
  Result[0] := TPoint2D.Create(0, 0);
  Result[1] := TPoint2D.Create(1, 0);
  Result[2] := TPoint2D.Create(1, 1);
  Result[3] := TPoint2D.Create(0, 1);
end;

function TTestGeometryLib.Triangle: TPolygon2D;
begin
  Result := nil;
  SetLength(Result, 3);
  Result[0] := TPoint2D.Create(0, 0);
  Result[1] := TPoint2D.Create(4, 0);
  Result[2] := TPoint2D.Create(0, 3);
end;

{ ---------------------------------------------------------------------------
  2-D PRIMITIVES
--------------------------------------------------------------------------- }

procedure TTestGeometryLib.TestPoint2D_DistanceTo;
var A, B: TPoint2D;
begin
  A := TPoint2D.Create(0, 0); B := TPoint2D.Create(3, 4);
  AssertNear('DistanceTo 3-4-5', 5.0, A.DistanceTo(B));
end;

procedure TTestGeometryLib.TestVector2D_Magnitude;
var V: TVector2D;
begin
  V := TVector2D.Create(3, 4);
  AssertNear('Magnitude 3-4-5', 5.0, V.Magnitude);
end;

procedure TTestGeometryLib.TestVector2D_Normalise;
var V, N: TVector2D;
begin
  V := TVector2D.Create(3, 4);
  N := V.Normalise;
  AssertNear('Normalise Mag=1', 1.0, N.Magnitude);
  AssertNear('Normalise X', 0.6, N.X);
  AssertNear('Normalise Y', 0.8, N.Y);
end;

procedure TTestGeometryLib.TestVector2D_ExtremeMagnitudeAndNormalise;
var
  V, N: TVector2D;
begin
  V := TVector2D.Create(1E308, 1E308);
  AssertNear('large 2-D magnitude remains representable', Sqrt(2.0),
    V.Magnitude / 1E308, 1E-15);
  N := V.Normalise;
  AssertNear('large 2-D normal X', 1.0 / Sqrt(2.0), N.X, 1E-15);
  AssertNear('large 2-D normal Y', 1.0 / Sqrt(2.0), N.Y, 1E-15);

  V := TVector2D.Create(1.7E308, 1.7E308);
  N := V.Normalise;
  AssertVector2DNear('2-D normal survives unrepresentable magnitude',
    1.0 / Sqrt(2.0), 1.0 / Sqrt(2.0), N, 1E-15);

  V := TVector2D.Create(3E-300, 4E-300);
  AssertNear('tiny 2-D magnitude does not underflow', 5.0,
    V.Magnitude / 1E-300, 1E-14);
  N := V.Normalise;
  AssertVector2DNear('tiny 2-D vector normalises', 0.6, 0.8, N, 1E-15);
end;

procedure TTestGeometryLib.TestVector2D_Dot;
var V1, V2: TVector2D;
begin
  V1 := TVector2D.Create(1, 2); V2 := TVector2D.Create(3, 4);
  AssertNear('Dot 1*3+2*4=11', 11.0, V1.Dot(V2));
  { Perpendicular → dot = 0 }
  V1 := TVector2D.Create(1, 0); V2 := TVector2D.Create(0, 1);
  AssertNear('Dot perpendicular=0', 0.0, V1.Dot(V2));
end;

procedure TTestGeometryLib.TestVector2D_Cross;
var V1, V2: TVector2D;
begin
  V1 := TVector2D.Create(1, 0); V2 := TVector2D.Create(0, 1);
  AssertNear('Cross (1,0)×(0,1)=1', 1.0, V1.Cross(V2));
  { Reversed → -1 }
  AssertNear('Cross (0,1)×(1,0)=-1', -1.0, V2.Cross(V1));
  { Parallel → 0 }
  V2 := TVector2D.Create(2, 0);
  AssertNear('Cross parallel=0', 0.0, V1.Cross(V2));
end;

procedure TTestGeometryLib.TestVector2D_Perpendicular;
var V, P: TVector2D;
begin
  V := TVector2D.Create(1, 0);
  P := V.Perpendicular;
  AssertNear('Perp X', 0.0, P.X);
  AssertNear('Perp Y', 1.0, P.Y);
  { Dot with original = 0 }
  AssertNear('Perp dot = 0', 0.0, V.Dot(P));
end;

procedure TTestGeometryLib.TestVector2D_ArithmeticOperators;
var
  A, B, V: TVector2D;
begin
  A := TVector2D.Create(3, -4);
  B := TVector2D.Create(-1, 2);
  AssertVector2DNear('addition', 2, -2, A + B);
  AssertVector2DNear('subtraction', 4, -6, A - B);
  AssertVector2DNear('unary negation', -3, 4, -A);
  AssertVector2DNear('vector times scalar', 6, -8, A * 2.0);
  AssertVector2DNear('scalar times vector', 6, -8, 2.0 * A);
  AssertVector2DNear('vector divided by scalar', 1.5, -2, A / 2.0);
  V := A + B;
  AssertVector2DNear('left operand remains a value', 3, -4, A);
  AssertVector2DNear('right operand remains a value', -1, 2, B);
  V := V + V;
  AssertVector2DNear('self assignment is value-safe', 4, -4, V);
end;

procedure TTestGeometryLib.TestSegment2D_Length;
var S: TSegment2D;
begin
  S := TSegment2D.Create(TPoint2D.Create(0,0), TPoint2D.Create(5,12));
  AssertNear('Segment length 5-12-13', 13.0, S.Length);
end;

procedure TTestGeometryLib.TestSegment2D_Midpoint;
var S: TSegment2D; M: TPoint2D;
begin
  S := TSegment2D.Create(TPoint2D.Create(2,4), TPoint2D.Create(8,10));
  M := S.Midpoint;
  AssertNear('Midpoint X', 5.0, M.X);
  AssertNear('Midpoint Y', 7.0, M.Y);
end;

procedure TTestGeometryLib.TestLine2D_Distance;
var L: TLine2D;
begin
  { Horizontal line y=0: distance from (0,3) should be 3 }
  L := TLine2D.FromPoints(TPoint2D.Create(0,0), TPoint2D.Create(1,0));
  AssertNear('Line dist y=0 from (0,3)', 3.0, L.Distance(TPoint2D.Create(0,3)));
  { Vertical line x=0: distance from (4,0) should be 4 }
  L := TLine2D.FromPoints(TPoint2D.Create(0,0), TPoint2D.Create(0,1));
  AssertNear('Line dist x=0 from (4,0)', 4.0, L.Distance(TPoint2D.Create(4,0)));
end;

procedure TTestGeometryLib.TestLine2D_ClosestPoint;
var L: TLine2D; C: TPoint2D;
begin
  { Horizontal y=0: closest point to (3,5) is (3,0) }
  L := TLine2D.FromPoints(TPoint2D.Create(0,0), TPoint2D.Create(1,0));
  C := L.ClosestPoint(TPoint2D.Create(3, 5));
  AssertNear('ClosestPt X', 3.0, C.X);
  AssertNear('ClosestPt Y', 0.0, C.Y);
end;

procedure TTestGeometryLib.TestCircle2D_Area;
var C: TCircle2D;
begin
  C := TCircle2D.Create(TPoint2D.Create(0,0), 1.0);
  AssertNear('Circle area r=1', Pi, C.Area);
  C := TCircle2D.Create(TPoint2D.Create(0,0), 3.0);
  AssertNear('Circle area r=3', 9*Pi, C.Area);
end;

procedure TTestGeometryLib.TestCircle2D_ContainsPoint;
var C: TCircle2D;
begin
  C := TCircle2D.Create(TPoint2D.Create(0,0), 5.0);
  AssertTrue('Circle contains origin', C.ContainsPoint(TPoint2D.Create(0,0)));
  AssertTrue('Circle contains (3,4)', C.ContainsPoint(TPoint2D.Create(3,4)));
  AssertFalse('Circle excludes (4,4)', C.ContainsPoint(TPoint2D.Create(4,4)));
end;

{ ---------------------------------------------------------------------------
  3-D PRIMITIVES
--------------------------------------------------------------------------- }

procedure TTestGeometryLib.TestPoint3D_DistanceTo;
var A, B: TPoint3D;
begin
  A := TPoint3D.Create(0,0,0); B := TPoint3D.Create(1,2,2);
  AssertNear('3D dist sqrt(9)=3', 3.0, A.DistanceTo(B));
end;

procedure TTestGeometryLib.TestVector3D_Magnitude;
var V: TVector3D;
begin
  V := TVector3D.Create(2,3,6);
  AssertNear('3D mag sqrt(49)=7', 7.0, V.Magnitude);
end;

procedure TTestGeometryLib.TestVector3D_Normalise;
var V, N: TVector3D;
begin
  V := TVector3D.Create(1,2,2);
  N := V.Normalise;
  AssertNear('3D norm mag=1', 1.0, N.Magnitude);
  AssertNear('3D norm X', 1/3, N.X);
end;

procedure TTestGeometryLib.TestVector3D_ExtremeMagnitudeAndNormalise;
var
  V, N: TVector3D;
begin
  V := TVector3D.Create(1E308, 1E308, 1E308);
  AssertNear('large 3-D magnitude remains representable', Sqrt(3.0),
    V.Magnitude / 1E308, 1E-15);
  N := V.Normalise;
  AssertVector3DNear('large 3-D vector normalises', 1.0 / Sqrt(3.0),
    1.0 / Sqrt(3.0), 1.0 / Sqrt(3.0), N, 1E-15);

  V := TVector3D.Create(1.7E308, 1.7E308, 1.7E308);
  N := V.Normalise;
  AssertVector3DNear('3-D normal survives unrepresentable magnitude',
    1.0 / Sqrt(3.0), 1.0 / Sqrt(3.0), 1.0 / Sqrt(3.0), N, 1E-15);

  V := TVector3D.Create(1E-300, 2E-300, 2E-300);
  AssertNear('tiny 3-D magnitude does not underflow', 3.0,
    V.Magnitude / 1E-300, 1E-14);
  N := V.Normalise;
  AssertVector3DNear('tiny 3-D vector normalises', 1.0 / Sqrt(9.0),
    2.0 / Sqrt(9.0), 2.0 / Sqrt(9.0), N, 1E-15);
end;

procedure TTestGeometryLib.TestVector3D_Dot;
var V1, V2: TVector3D;
begin
  V1 := TVector3D.Create(1,2,3); V2 := TVector3D.Create(4,5,6);
  AssertNear('3D dot 1*4+2*5+3*6=32', 32.0, V1.Dot(V2));
end;

procedure TTestGeometryLib.TestVector3D_Cross;
var V1, V2, C: TVector3D;
begin
  V1 := TVector3D.Create(1,0,0); V2 := TVector3D.Create(0,1,0);
  C  := V1.Cross(V2);
  AssertNear('Cross X=0', 0.0, C.X);
  AssertNear('Cross Y=0', 0.0, C.Y);
  AssertNear('Cross Z=1', 1.0, C.Z);
  { Anti-commutative: V2 × V1 = -Z }
  C := V2.Cross(V1);
  AssertNear('Anti-comm Z=-1', -1.0, C.Z);
end;

procedure TTestGeometryLib.TestVector3D_ArithmeticOperators;
var
  A, B, V: TVector3D;
begin
  A := TVector3D.Create(3, -4, 5);
  B := TVector3D.Create(-1, 2, 7);
  AssertVector3DNear('addition', 2, -2, 12, A + B);
  AssertVector3DNear('subtraction', 4, -6, -2, A - B);
  AssertVector3DNear('unary negation', -3, 4, -5, -A);
  AssertVector3DNear('vector times scalar', 6, -8, 10, A * 2.0);
  AssertVector3DNear('scalar times vector', 6, -8, 10, 2.0 * A);
  AssertVector3DNear('vector divided by scalar', 1.5, -2, 2.5, A / 2.0);
  V := A + B;
  AssertVector3DNear('left operand remains a value', 3, -4, 5, A);
  AssertVector3DNear('right operand remains a value', -1, 2, 7, B);
  V := V + V;
  AssertVector3DNear('self assignment is value-safe', 4, -4, 24, V);
end;

procedure TTestGeometryLib.TestVectorArithmetic_PropertiesAndDimensionalAgreement;
var
  A2, B2, Z2: TVector2D;
  A3, B3, Z3: TVector3D;
  Scale: Double;
begin
  A2 := TVector2D.Create(3.5, -4.25);
  B2 := TVector2D.Create(-1.25, 2.5);
  Z2 := TVector2D.Create(0, 0);
  A3 := TVector3D.Create(A2.X, A2.Y, 0);
  B3 := TVector3D.Create(B2.X, B2.Y, 0);
  Z3 := TVector3D.Create(0, 0, 0);
  Scale := -2.75;

  AssertVector2DNear('2-D additive identity', A2.X, A2.Y, A2 + Z2);
  AssertVector2DNear('2-D additive inverse', 0, 0, A2 + -A2);
  AssertVector2DNear('2-D distributivity', (Scale * A2 + Scale * B2).X,
    (Scale * A2 + Scale * B2).Y, Scale * (A2 + B2));
  AssertVector2DNear('2-D scale inverse', A2.X, A2.Y, (A2 * Scale) / Scale);
  AssertVector3DNear('3-D additive identity', A3.X, A3.Y, A3.Z, A3 + Z3);
  AssertVector3DNear('3-D additive inverse', 0, 0, 0, A3 + -A3);
  AssertVector3DNear('3-D distributivity', (Scale * A3 + Scale * B3).X,
    (Scale * A3 + Scale * B3).Y, (Scale * A3 + Scale * B3).Z,
    Scale * (A3 + B3));
  AssertVector3DNear('3-D scale inverse', A3.X, A3.Y, A3.Z,
    (A3 * Scale) / Scale);
  AssertVector3DNear('2-D and 3-D addition agree', (A2 + B2).X,
    (A2 + B2).Y, 0, A3 + B3);
  AssertVector3DNear('2-D and 3-D subtraction agree', (A2 - B2).X,
    (A2 - B2).Y, 0, A3 - B3);
  AssertVector3DNear('2-D and 3-D scaling agree', (A2 * Scale).X,
    (A2 * Scale).Y, 0, A3 * Scale);
end;

procedure TTestGeometryLib.TestVectorArithmetic_ExistingOperationProperties;
var
  A2, B2, C2: TVector2D;
  A3, B3, C3: TVector3D;
  Scale: Double;
begin
  A2 := TVector2D.Create(1.25, -2.5);
  B2 := TVector2D.Create(3.75, 0.5);
  C2 := TVector2D.Create(-2.0, 4.0);
  A3 := TVector3D.Create(1.25, -2.5, 0.75);
  B3 := TVector3D.Create(3.75, 0.5, -1.25);
  C3 := TVector3D.Create(-2.0, 4.0, 3.0);
  Scale := -3.5;

  AssertNear('2-D dot is linear over addition', A2.Dot(C2) + B2.Dot(C2),
    (A2 + B2).Dot(C2), 1E-14);
  AssertNear('3-D dot is linear over addition', A3.Dot(C3) + B3.Dot(C3),
    (A3 + B3).Dot(C3), 1E-14);
  AssertNear('2-D magnitude respects scaling', Abs(Scale) * A2.Magnitude,
    (Scale * A2).Magnitude, 1E-14);
  AssertNear('3-D magnitude respects scaling', Abs(Scale) * A3.Magnitude,
    (Scale * A3).Magnitude, 1E-14);
end;

procedure TTestGeometryLib.TestVectorArithmetic_NonFiniteAndOverflow;
var
  SavedMask: TFPUExceptionMask;
  V2: TVector2D;
  V3: TVector3D;
begin
  SavedMask := GetExceptionMask;
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow,
    exUnderflow, exPrecision]);
  try
    V2 := TVector2D.Create(Infinity, 1.0) + TVector2D.Create(-Infinity, NaN);
    AssertTrue('2-D indeterminate infinity addition is NaN', IsNan(V2.X));
    AssertTrue('2-D NaN propagates', IsNan(V2.Y));
    V2 := TVector2D.Create(1E308, -1E308) * 2.0;
    AssertTrue('2-D positive overflow is infinity', IsInfinite(V2.X) and (V2.X > 0));
    AssertTrue('2-D negative overflow is infinity', IsInfinite(V2.Y) and (V2.Y < 0));

    V3 := TVector3D.Create(Infinity, 0.0, 1.0) * 0.0;
    AssertTrue('3-D infinity times zero is NaN', IsNan(V3.X));
    AssertTrue('3-D zero times zero remains zero', V3.Y = 0.0);
    AssertTrue('3-D finite times zero remains zero', V3.Z = 0.0);
    V3 := TVector3D.Create(1E308, -1E308, 1E308) * 2.0;
    AssertTrue('3-D positive overflow is infinity', IsInfinite(V3.X) and (V3.X > 0));
    AssertTrue('3-D negative overflow is infinity', IsInfinite(V3.Y) and (V3.Y < 0));
    AssertTrue('3-D positive overflow is infinity', IsInfinite(V3.Z) and (V3.Z > 0));
  finally
    SetExceptionMask(SavedMask);
  end;
end;

procedure TTestGeometryLib.TestVectorArithmetic_ZeroDivisionAndSignedZero;
var
  SavedMask: TFPUExceptionMask;
  Negative: Double;
  V2: TVector2D;
  V3: TVector3D;
begin
  SavedMask := GetExceptionMask;
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow,
    exUnderflow, exPrecision]);
  try
    Negative := NegativeZero;
    V2 := TVector2D.Create(1.0, 0.0) / Negative;
    AssertTrue('2-D division by negative zero has negative infinity',
      IsInfinite(V2.X) and (V2.X < 0.0));
    AssertTrue('2-D zero divided by zero is NaN', IsNan(V2.Y));
    V2 := TVector2D.Create(Negative, 2.0) * 1.0;
    AssertTrue('2-D multiplication retains negative zero', (V2.X = 0.0) and
      ((1.0 / V2.X) < 0.0));

    V3 := TVector3D.Create(1.0, -1.0, 0.0) / Negative;
    AssertTrue('3-D positive division by negative zero is negative infinity',
      IsInfinite(V3.X) and (V3.X < 0.0));
    AssertTrue('3-D negative division by negative zero is positive infinity',
      IsInfinite(V3.Y) and (V3.Y > 0.0));
    AssertTrue('3-D zero divided by zero is NaN', IsNan(V3.Z));
  finally
    SetExceptionMask(SavedMask);
  end;
end;

procedure TTestGeometryLib.TestSegment3D_Length;
var S: TSegment3D;
begin
  S := TSegment3D.Create(TPoint3D.Create(0,0,0), TPoint3D.Create(1,2,2));
  AssertNear('3D seg length=3', 3.0, S.Length);
end;

procedure TTestGeometryLib.TestSegment3D_Midpoint;
var S: TSegment3D; M: TPoint3D;
begin
  S := TSegment3D.Create(TPoint3D.Create(2,4,6), TPoint3D.Create(8,10,12));
  M := S.Midpoint;
  AssertNear('3D midpoint X', 5.0, M.X);
  AssertNear('3D midpoint Y', 7.0, M.Y);
  AssertNear('3D midpoint Z', 9.0, M.Z);
end;

procedure TTestGeometryLib.TestPlane3D_Distance;
var Plane: TPlane3D; P: TPoint3D;
begin
  { XY plane (z=0): distance from (0,0,5) = 5 }
  Plane := TPlane3D.FromPointNormal(
    TPoint3D.Create(0,0,0), TVector3D.Create(0,0,1));
  P := TPoint3D.Create(0,0,5);
  AssertNear('Plane dist z=5', 5.0, Plane.Distance(P));
end;

procedure TTestGeometryLib.TestPlane3D_ClosestPoint;
var Plane: TPlane3D; P, C: TPoint3D;
begin
  { XY plane: closest point to (3,4,7) is (3,4,0) }
  Plane := TPlane3D.FromPointNormal(
    TPoint3D.Create(0,0,0), TVector3D.Create(0,0,1));
  P := TPoint3D.Create(3,4,7);
  C := Plane.ClosestPoint(P);
  AssertNear('PlaneCP X', 3.0, C.X);
  AssertNear('PlaneCP Y', 4.0, C.Y);
  AssertNear('PlaneCP Z', 0.0, C.Z);
end;

procedure TTestGeometryLib.TestSphere3D_Volume;
var S: TSphere3D;
begin
  S := TSphere3D.Create(TPoint3D.Create(0,0,0), 1.0);
  AssertNear('Sphere vol r=1', 4/3*Pi, S.Volume);
end;

procedure TTestGeometryLib.TestSphere3D_ContainsPoint;
var S: TSphere3D;
begin
  S := TSphere3D.Create(TPoint3D.Create(0,0,0), 5.0);
  AssertTrue('Sphere contains (1,2,2)', S.ContainsPoint(TPoint3D.Create(1,2,2)));
  AssertFalse('Sphere excludes (4,4,4)', S.ContainsPoint(TPoint3D.Create(4,4,4)));
end;

{ ---------------------------------------------------------------------------
  DISTANCE
--------------------------------------------------------------------------- }

procedure TTestGeometryLib.TestPointToPoint2D;
begin
  AssertNear('P2P2D 3-4-5', 5.0,
    TGeometryKit.PointToPoint2D(TPoint2D.Create(0,0), TPoint2D.Create(3,4)));
end;

procedure TTestGeometryLib.TestPointToSegment2D_Interior;
{ Point (0,1) to segment (0,0)-(2,0): closest is (0,0), dist=1 }
var T, D: Double;
begin
  D := TGeometryKit.PointToSegment2D(
    TPoint2D.Create(1,2), TPoint2D.Create(0,0), TPoint2D.Create(4,0), T);
  AssertNear('PtToSeg interior dist', 2.0, D);
  AssertNear('PtToSeg T',            0.25, T);
end;

procedure TTestGeometryLib.TestPointToSegment2D_Endpoint;
{ Point (-1,0) to segment (0,0)-(1,0): closest is endpoint (0,0), dist=1 }
var T, D: Double;
begin
  D := TGeometryKit.PointToSegment2D(
    TPoint2D.Create(-1,0), TPoint2D.Create(0,0), TPoint2D.Create(1,0), T);
  AssertNear('PtToSeg endpoint dist', 1.0, D);
  AssertNear('PtToSeg T=0', 0.0, T);
end;

procedure TTestGeometryLib.TestPointToLine2D;
{ Point (0,3) to line through (0,0)-(1,0) (x-axis): dist=3 }
begin
  AssertNear('PtToLine2D', 3.0,
    TGeometryKit.PointToLine2D(
      TPoint2D.Create(0,3), TPoint2D.Create(0,0), TPoint2D.Create(1,0)));
end;

procedure TTestGeometryLib.TestSegmentToSegment2D_Crossing;
{ Crossing segments: distance = 0 }
begin
  AssertNear('SegToSeg crossing=0', 0.0,
    TGeometryKit.SegmentToSegment2D(
      TPoint2D.Create(0,0), TPoint2D.Create(2,2),
      TPoint2D.Create(0,2), TPoint2D.Create(2,0)));
end;

procedure TTestGeometryLib.TestSegmentToSegment2D_Parallel;
{ Parallel horizontal segments with gap of 1: dist=1 }
begin
  AssertNear('SegToSeg parallel gap=1', 1.0,
    TGeometryKit.SegmentToSegment2D(
      TPoint2D.Create(0,0), TPoint2D.Create(2,0),
      TPoint2D.Create(0,1), TPoint2D.Create(2,1)));
end;

procedure TTestGeometryLib.TestPointToPoint3D;
begin
  AssertNear('P2P3D dist sqrt(14)',
    Sqrt(14),
    TGeometryKit.PointToPoint3D(
      TPoint3D.Create(0,0,0), TPoint3D.Create(1,2,3)));
end;

procedure TTestGeometryLib.TestPointToSegment3D;
{ Point (0,1,0) to segment (0,0,0)-(0,0,2): closest is (0,0,0), dist=1 }
var T, D: Double;
begin
  D := TGeometryKit.PointToSegment3D(
    TPoint3D.Create(1,0,0),
    TPoint3D.Create(0,0,0), TPoint3D.Create(0,0,2), T);
  AssertNear('PtToSeg3D dist', 1.0, D);
  AssertNear('PtToSeg3D T',    0.0, T);
end;

procedure TTestGeometryLib.TestPointToPlane3D;
var Plane: TPlane3D;
begin
  Plane := TPlane3D.FromPointNormal(
    TPoint3D.Create(0,0,0), TVector3D.Create(0,0,1));
  AssertNear('PtToPlane z=3', 3.0,
    TGeometryKit.PointToPlane3D(TPoint3D.Create(5,5,3), Plane));
end;

{ ---------------------------------------------------------------------------
  INTERSECTION
--------------------------------------------------------------------------- }

procedure TTestGeometryLib.TestSegmentsIntersect2D_Crossing;
begin
  AssertTrue('Crossing segs intersect',
    TGeometryKit.SegmentsIntersect2D(
      TPoint2D.Create(0,0), TPoint2D.Create(2,2),
      TPoint2D.Create(0,2), TPoint2D.Create(2,0)));
end;

procedure TTestGeometryLib.TestSegmentsIntersect2D_Touching;
{ T-junction: endpoint of one segment touches middle of other }
begin
  AssertTrue('T-junction intersect',
    TGeometryKit.SegmentsIntersect2D(
      TPoint2D.Create(0,0), TPoint2D.Create(2,0),
      TPoint2D.Create(1,0), TPoint2D.Create(1,2)));
end;

procedure TTestGeometryLib.TestSegmentsIntersect2D_Parallel;
begin
  AssertFalse('Parallel segs no intersect',
    TGeometryKit.SegmentsIntersect2D(
      TPoint2D.Create(0,0), TPoint2D.Create(2,0),
      TPoint2D.Create(0,1), TPoint2D.Create(2,1)));
end;

procedure TTestGeometryLib.TestSegmentsIntersect2D_Collinear;
{ Overlapping collinear segments DO intersect }
begin
  AssertTrue('Collinear overlap intersect',
    TGeometryKit.SegmentsIntersect2D(
      TPoint2D.Create(0,0), TPoint2D.Create(3,0),
      TPoint2D.Create(1,0), TPoint2D.Create(4,0)));
end;

procedure TTestGeometryLib.TestSegmentIntersect2D_FindsPoint;
{ Diagonals of unit square: intersect at (0.5, 0.5) }
var Pt: TPoint2D; T: Double;
begin
  AssertTrue('Diag intersect found',
    TGeometryKit.SegmentIntersect2D(
      TPoint2D.Create(0,0), TPoint2D.Create(1,1),
      TPoint2D.Create(1,0), TPoint2D.Create(0,1),
      Pt, T));
  AssertNear('Intersect X', 0.5, Pt.X);
  AssertNear('Intersect Y', 0.5, Pt.Y);
  AssertNear('Intersect T', 0.5, T);
end;

procedure TTestGeometryLib.TestSegmentIntersect2D_Parallel;
var Pt: TPoint2D; T: Double;
begin
  AssertFalse('Parallel no intersect',
    TGeometryKit.SegmentIntersect2D(
      TPoint2D.Create(0,0), TPoint2D.Create(2,0),
      TPoint2D.Create(0,1), TPoint2D.Create(2,1),
      Pt, T));
end;

procedure TTestGeometryLib.TestLineIntersect2D_FindsPoint;
{ x-axis and y-axis intersect at origin }
var Pt: TPoint2D;
begin
  AssertTrue('Lines intersect',
    TGeometryKit.LineIntersect2D(
      TPoint2D.Create(-1,0), TPoint2D.Create(1,0),
      TPoint2D.Create(0,-1), TPoint2D.Create(0,1),
      Pt));
  AssertNear('LineInt X', 0.0, Pt.X);
  AssertNear('LineInt Y', 0.0, Pt.Y);
end;

procedure TTestGeometryLib.TestLineIntersect2D_Parallel;
var Pt: TPoint2D;
begin
  AssertFalse('Parallel lines no intersect',
    TGeometryKit.LineIntersect2D(
      TPoint2D.Create(0,0), TPoint2D.Create(1,0),
      TPoint2D.Create(0,1), TPoint2D.Create(1,1),
      Pt));
end;

procedure TTestGeometryLib.TestSegmentCircleIntersect_Crossing;
{ Segment (−2,0)−(2,0) vs unit circle at origin: clearly crosses }
var C: TCircle2D;
begin
  C := TCircle2D.Create(TPoint2D.Create(0,0), 1.0);
  AssertTrue('Seg-Circle crossing',
    TGeometryKit.SegmentCircleIntersect(
      TPoint2D.Create(-2,0), TPoint2D.Create(2,0), C));
end;

procedure TTestGeometryLib.TestSegmentCircleIntersect_Outside;
{ Segment (2,0)−(3,0) vs unit circle: outside }
var C: TCircle2D;
begin
  C := TCircle2D.Create(TPoint2D.Create(0,0), 1.0);
  AssertFalse('Seg-Circle outside',
    TGeometryKit.SegmentCircleIntersect(
      TPoint2D.Create(2,0), TPoint2D.Create(3,0), C));
end;

procedure TTestGeometryLib.TestRayCircleIntersect_Two;
{ Ray from (−5,0) in direction (1,0) through unit circle: 2 intersections }
var C: TCircle2D; T1, T2: Double; N: Integer;
begin
  C := TCircle2D.Create(TPoint2D.Create(0,0), 1.0);
  N := TGeometryKit.RayCircleIntersect(
    TPoint2D.Create(-5,0), TPoint2D.Create(1,0), C, T1, T2);
  AssertEquals('Ray-Circle 2 hits', 2, N);
  AssertNear('T1=4', 4.0, T1);
  AssertNear('T2=6', 6.0, T2);
end;

procedure TTestGeometryLib.TestRayCircleIntersect_None;
{ Ray from (0,5) in direction (1,0): misses unit circle }
var C: TCircle2D; T1, T2: Double;
begin
  C := TCircle2D.Create(TPoint2D.Create(0,0), 1.0);
  AssertEquals('Ray-Circle 0 hits', 0,
    TGeometryKit.RayCircleIntersect(
      TPoint2D.Create(0,5), TPoint2D.Create(1,0), C, T1, T2));
end;

{ ---------------------------------------------------------------------------
  POLYGON
--------------------------------------------------------------------------- }

procedure TTestGeometryLib.TestPolygonArea_CCW;
{ Unit square CCW: area = 1 (positive) }
begin
  AssertNear('Area unit square', 1.0, TGeometryKit.PolygonArea(UnitSquare));
end;

procedure TTestGeometryLib.TestPolygonArea_CW;
{ Unit square CW: area = −1 (negative) }
var Sq: TPolygon2D;
begin
  SetLength(Sq, 4);
  Sq[0] := TPoint2D.Create(0,0);
  Sq[1] := TPoint2D.Create(0,1);
  Sq[2] := TPoint2D.Create(1,1);
  Sq[3] := TPoint2D.Create(1,0);
  AssertNear('Area CW = -1', -1.0, TGeometryKit.PolygonArea(Sq));
end;

procedure TTestGeometryLib.TestPolygonPerimeter_Square;
begin
  AssertNear('Perimeter unit square=4', 4.0,
    TGeometryKit.PolygonPerimeter(UnitSquare));
end;

procedure TTestGeometryLib.TestPolygonCentroid_Square;
{ Unit square centroid = (0.5, 0.5) }
var C: TPoint2D;
begin
  C := TGeometryKit.PolygonCentroid(UnitSquare);
  AssertNear('Centroid square X', 0.5, C.X);
  AssertNear('Centroid square Y', 0.5, C.Y);
end;

procedure TTestGeometryLib.TestPolygonCentroid_Triangle;
{ Triangle (0,0),(6,0),(0,6): centroid = (2,2) }
var Tri: TPolygon2D; C: TPoint2D;
begin
  SetLength(Tri, 3);
  Tri[0] := TPoint2D.Create(0,0);
  Tri[1] := TPoint2D.Create(6,0);
  Tri[2] := TPoint2D.Create(0,6);
  C := TGeometryKit.PolygonCentroid(Tri);
  AssertNear('Centroid tri X', 2.0, C.X);
  AssertNear('Centroid tri Y', 2.0, C.Y);
end;

procedure TTestGeometryLib.TestPointInPolygon_Inside;
begin
  AssertTrue('Centre inside square',
    TGeometryKit.PointInPolygon(TPoint2D.Create(0.5,0.5), UnitSquare));
end;

procedure TTestGeometryLib.TestPointInPolygon_Outside;
begin
  AssertFalse('Outside square',
    TGeometryKit.PointInPolygon(TPoint2D.Create(2,2), UnitSquare));
end;

procedure TTestGeometryLib.TestPointInPolygon_Concave;
{ L-shaped polygon; point inside the notch should be outside }
var L: TPolygon2D;
begin
  SetLength(L, 6);
  L[0] := TPoint2D.Create(0,0); L[1] := TPoint2D.Create(3,0);
  L[2] := TPoint2D.Create(3,1); L[3] := TPoint2D.Create(1,1);
  L[4] := TPoint2D.Create(1,3); L[5] := TPoint2D.Create(0,3);
  { Point in the notch (2,2) is OUTSIDE the L }
  AssertFalse('Point in notch is outside',
    TGeometryKit.PointInPolygon(TPoint2D.Create(2,2), L));
  { Point in the stem (0.5, 0.5) is INSIDE }
  AssertTrue('Point in stem is inside',
    TGeometryKit.PointInPolygon(TPoint2D.Create(0.5,0.5), L));
end;

procedure TTestGeometryLib.TestIsConvex_Square;
begin
  AssertTrue('Unit square is convex', TGeometryKit.IsConvex(UnitSquare));
end;

procedure TTestGeometryLib.TestIsConvex_LShaped;
var L: TPolygon2D;
begin
  SetLength(L, 6);
  L[0] := TPoint2D.Create(0,0); L[1] := TPoint2D.Create(3,0);
  L[2] := TPoint2D.Create(3,1); L[3] := TPoint2D.Create(1,1);
  L[4] := TPoint2D.Create(1,3); L[5] := TPoint2D.Create(0,3);
  AssertFalse('L-shape is not convex', TGeometryKit.IsConvex(L));
end;

procedure TTestGeometryLib.TestConvexHull_Triangle;
{ 3 non-collinear points: hull = same 3 points }
var Pts, Hull: TPolygon2D;
begin
  SetLength(Pts, 3);
  Pts[0] := TPoint2D.Create(0,0);
  Pts[1] := TPoint2D.Create(4,0);
  Pts[2] := TPoint2D.Create(2,3);
  Hull := TGeometryKit.ConvexHull(Pts);
  AssertEquals('Hull of triangle = 3', 3, Length(Hull));
end;

procedure TTestGeometryLib.TestConvexHull_SquarePlusInterior;
{ Unit square + interior point: hull should still have 4 vertices }
var Pts, Hull: TPolygon2D;
begin
  SetLength(Pts, 5);
  Pts[0] := TPoint2D.Create(0,0); Pts[1] := TPoint2D.Create(1,0);
  Pts[2] := TPoint2D.Create(1,1); Pts[3] := TPoint2D.Create(0,1);
  Pts[4] := TPoint2D.Create(0.5,0.5);  { interior }
  Hull := TGeometryKit.ConvexHull(Pts);
  AssertEquals('Hull of square+interior = 4', 4, Length(Hull));
end;

{ ---------------------------------------------------------------------------
  TRANSFORMATIONS
--------------------------------------------------------------------------- }

procedure TTestGeometryLib.TestTranslate2D;
var Sq, T: TPolygon2D;
begin
  Sq := UnitSquare;
  T  := TGeometryKit.Translate2D(Sq, 3, 5);
  AssertNear('Translate X', 3.0, T[0].X);
  AssertNear('Translate Y', 5.0, T[0].Y);
  AssertNear('Translate corner X', 4.0, T[1].X);
end;

procedure TTestGeometryLib.TestScale2D;
var Sq, S: TPolygon2D;
begin
  Sq := UnitSquare;
  S  := TGeometryKit.Scale2D(Sq, 2, 3);
  AssertNear('Scale (1,0)→(2,0) X', 2.0, S[1].X);
  AssertNear('Scale (1,1)→(2,3) Y', 3.0, S[2].Y);
end;

procedure TTestGeometryLib.TestRotate2D_90Degrees;
{ Rotate (1,0) by 90° CCW about origin → (0,1) }
var Pts, R: TPolygon2D;
begin
  SetLength(Pts, 1);
  Pts[0] := TPoint2D.Create(1, 0);
  R := TGeometryKit.Rotate2D(Pts, Pi/2, TPoint2D.Create(0,0));
  AssertNear('Rotate 90° X', 0.0, R[0].X);
  AssertNear('Rotate 90° Y', 1.0, R[0].Y);
end;

procedure TTestGeometryLib.TestRotate2D_360Degrees;
{ Full rotation returns to original position }
var Pts, R: TPolygon2D;
begin
  SetLength(Pts, 1);
  Pts[0] := TPoint2D.Create(3, 4);
  R := TGeometryKit.Rotate2D(Pts, 2*Pi, TPoint2D.Create(0,0));
  AssertNear('Rotate 360° X', 3.0, R[0].X);
  AssertNear('Rotate 360° Y', 4.0, R[0].Y);
end;

{ ---------------------------------------------------------------------------
  ANGLES & AREAS
--------------------------------------------------------------------------- }

procedure TTestGeometryLib.TestAngleBetween2D_Perpendicular;
{ (1,0) to (0,1): signed angle = +π/2 }
var V1, V2: TVector2D;
begin
  V1 := TVector2D.Create(1,0); V2 := TVector2D.Create(0,1);
  AssertNear('Angle 90°', Pi/2, TGeometryKit.AngleBetween2D(V1,V2));
end;

procedure TTestGeometryLib.TestAngleBetween2D_Parallel;
{ Same direction: angle = 0 }
var V: TVector2D;
begin
  V := TVector2D.Create(1,0);
  AssertNear('Angle parallel=0', 0.0, TGeometryKit.AngleBetween2D(V,V));
end;

procedure TTestGeometryLib.TestAngleBetween3D_Perpendicular;
var V1, V2: TVector3D;
begin
  V1 := TVector3D.Create(1,0,0); V2 := TVector3D.Create(0,1,0);
  AssertNear('3D angle 90°', Pi/2, TGeometryKit.AngleBetween3D(V1,V2));
end;

procedure TTestGeometryLib.TestTriangleArea2D;
{ Triangle (0,0),(4,0),(0,3): area = 6 }
begin
  AssertNear('TriArea2D=6', 6.0,
    TGeometryKit.TriangleArea2D(
      TPoint2D.Create(0,0), TPoint2D.Create(4,0), TPoint2D.Create(0,3)));
end;

procedure TTestGeometryLib.TestTriangleArea3D;
{ Same triangle in XY plane: area = 6 }
begin
  AssertNear('TriArea3D=6', 6.0,
    TGeometryKit.TriangleArea3D(
      TPoint3D.Create(0,0,0), TPoint3D.Create(4,0,0), TPoint3D.Create(0,3,0)));
end;

procedure TTestGeometryLib.TestBoundingBox2D;
var Pts: TPolygon2D; BB: TBoundingBox2D;
begin
  SetLength(Pts, 4);
  Pts[0] := TPoint2D.Create(1,2); Pts[1] := TPoint2D.Create(5,3);
  Pts[2] := TPoint2D.Create(3,7); Pts[3] := TPoint2D.Create(-1,4);
  BB := TGeometryKit.BoundingBox2D(Pts);
  AssertNear('BB MinX', -1.0, BB.MinX);
  AssertNear('BB MaxX',  5.0, BB.MaxX);
  AssertNear('BB MinY',  2.0, BB.MinY);
  AssertNear('BB MaxY',  7.0, BB.MaxY);
  AssertNear('BB Width', 6.0, BB.Width);
  AssertNear('BB Height',5.0, BB.Height);
  AssertTrue('BB contains (2,3)', BB.ContainsPoint(TPoint2D.Create(2,3)));
  AssertFalse('BB excludes (6,3)', BB.ContainsPoint(TPoint2D.Create(6,3)));
end;

{ ---------------------------------------------------------------------------
  ERROR HANDLING
--------------------------------------------------------------------------- }

procedure TTestGeometryLib.TestVector2D_NormaliseZeroRaises;
begin
  AssertGeoError('Normalise zero vector', @ErrNormaliseZero);
end;

procedure TTestGeometryLib.TestVector3D_NormaliseZeroRaises;
begin
  AssertGeoError('Normalise zero 3-D vector', @ErrNormalise3DZero);
end;

procedure TTestGeometryLib.TestVectorNormalise_NonFiniteRaises;
begin
  AssertGeoError('Normalise infinite 2-D vector', @ErrNormalise2DInfinity);
  AssertGeoError('Normalise NaN 3-D vector', @ErrNormalise3DNaN);
end;

procedure TTestGeometryLib.TestLine2D_SamePointRaises;
begin
  AssertGeoError('Line from same point', @ErrLineSamePoint);
end;

procedure TTestGeometryLib.TestPolygonArea_TooFewRaises;
begin
  SetLength(GErrPts, 2);
  GErrPts[0] := TPoint2D.Create(0,0); GErrPts[1] := TPoint2D.Create(1,0);
  AssertGeoError('Area < 3 vertices', @ErrPolygonAreaTooFew);
end;

procedure TTestGeometryLib.TestConvexHull_TooFewRaises;
begin
  SetLength(GErrPts, 2);
  GErrPts[0] := TPoint2D.Create(0,0); GErrPts[1] := TPoint2D.Create(1,0);
  AssertGeoError('Hull < 3 points', @ErrConvexHullTooFew);
end;

procedure TTestGeometryLib.TestBoundingBox2D_EmptyRaises;
begin
  SetLength(GErrPts, 0);
  AssertGeoError('BBox empty', @ErrBoundingBoxEmpty);
end;

procedure TTestGeometryLib.TestPlane3D_CollinearRaises;
begin
  AssertGeoError('Plane from collinear points', @ErrPlaneCollinear);
end;

procedure TTestGeometryLib.TestRayCircleRejectsIntersectionsBehindOrigin;
var
  C: TCircle2D;
  T1, T2: Double;
begin
  C := TCircle2D.Create(TPoint2D.Create(0, 0), 1.0);
  AssertEquals('supporting-line hits behind a ray are excluded', 0,
    TGeometryKit.RayCircleIntersect(TPoint2D.Create(5, 0),
      TPoint2D.Create(1, 0), C, T1, T2));
end;

procedure TTestGeometryLib.TestRayCircleFromInsideHasOneForwardHit;
var
  C: TCircle2D;
  T1, T2: Double;
begin
  C := TCircle2D.Create(TPoint2D.Create(0, 0), 2.0);
  AssertEquals('inside ray has one forward exit', 1,
    TGeometryKit.RayCircleIntersect(TPoint2D.Create(0, 0),
      TPoint2D.Create(1, 0), C, T1, T2));
  AssertNear('forward exit parameter', 2.0, T1);
end;

procedure TTestGeometryLib.TestPointInPolygonBoundaryIsInside;
var
  P: TPolygon2D;
begin
  SetLength(P, 4);
  P[0] := TPoint2D.Create(0, 0); P[1] := TPoint2D.Create(2, 0);
  P[2] := TPoint2D.Create(2, 2); P[3] := TPoint2D.Create(0, 2);
  AssertTrue('edge point counts as inside',
    TGeometryKit.PointInPolygon(TPoint2D.Create(1, 0), P));
  AssertTrue('vertex counts as inside',
    TGeometryKit.PointInPolygon(TPoint2D.Create(2, 2), P));
end;

procedure TTestGeometryLib.TestConvexHullLargeInputProperties;
var
  Points, Hull: TPolygon2D;
  I: Integer;
begin
  SetLength(Points, 10000);
  for I := 0 to High(Points) do
    Points[I] := TPoint2D.Create((I * 7919) mod 1009,
      (I * I + 17 * I) mod 1013);
  Hull := TGeometryKit.ConvexHull(Points);
  AssertTrue('non-degenerate hull has at least three points', Length(Hull) >= 3);
  AssertTrue('hull cannot contain more points than input', Length(Hull) <= Length(Points));
  AssertTrue('large hull result is convex', TGeometryKit.IsConvex(Hull));
end;

initialization
  RegisterTest(TTestGeometryLib);
end.
