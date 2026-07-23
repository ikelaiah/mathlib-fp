program example12_geometry;

{-----------------------------------------------------------------------------
 Example 12 — GeometryLib Walkthrough

 Written for someone new to computational geometry.
 Each section introduces one concept with plain-English explanation
 and a concrete, runnable example.

 Compile:  mkdir lib
           fpc -Fu../src -FUlib 12_geometry.pas
 Run:      ./12_geometry   (Linux/macOS)
           12_geometry.exe (Windows)
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math,
  MathBase.SharedTypes,
  GeometryLib.Geometry;

procedure Sep; begin WriteLn(StringOfChar('-', 55)); end;

{ ============================================================
  SECTION 1 — 2-D Points and Vectors
============================================================ }
procedure DemoPoints2D;
var
  A, B, M: TPoint2D;
  V, N: TVector2D;
begin
  WriteLn;
  WriteLn('=== 2-D POINTS AND VECTORS ===');
  Sep;

  A := TPoint2D.Create(0, 0);
  B := TPoint2D.Create(3, 4);
  WriteLn(Format('  A = %s', [A.ToString]));
  WriteLn(Format('  B = %s', [B.ToString]));
  WriteLn(Format('  Distance A→B = %.4f  (3-4-5 triangle)', [A.DistanceTo(B)]));

  { Segment midpoint }
  M := TSegment2D.Create(A, B).Midpoint;
  WriteLn(Format('  Midpoint of AB = %s', [M.ToString]));

  { Vector operations }
  V := TVector2D.FromPoints(A, B);
  N := V.Normalise;
  WriteLn(Format('  Vector AB = %s,  |AB| = %.4f', [V.ToString, V.Magnitude]));
  WriteLn(Format('  Unit vector = %s', [N.ToString]));
  WriteLn(Format('  Dot (1,0)·(0,1) = %.1f  (perpendicular → 0)',
    [TVector2D.Create(1,0).Dot(TVector2D.Create(0,1))]));
  WriteLn(Format('  Cross (1,0)×(0,1) = %.1f  (CCW → positive)',
    [TVector2D.Create(1,0).Cross(TVector2D.Create(0,1))]));
end;

{ ============================================================
  SECTION 1b — Vector Arithmetic and the Theodorus Spiral
============================================================ }
procedure DemoVectorArithmetic;
var
  Radius, Step: TVector2D;
  N: Integer;
begin
  WriteLn;
  WriteLn('=== VECTOR ARITHMETIC ===');
  WriteLn('The Theodorus spiral adds a unit perpendicular step to each radius.');
  Sep;

  Radius := TVector2D.Create(1, 0);
  WriteLn(Format('  Radius 1 = %s, length = %.4f',
    [Radius.ToString, Radius.Magnitude]));
  for N := 2 to 6 do
  begin
    Step := Radius.Normalise.Perpendicular;
    Radius := Radius + Step;
    WriteLn(Format('  Radius %d = %s, length = %.4f  (= sqrt(%d))',
      [N, Radius.ToString, Radius.Magnitude, N]));
  end;

  Radius := 0.5 * (TVector2D.Create(3, -4) + TVector2D.Create(1, 2));
  WriteLn(Format('  0.5 * ((3,-4) + (1,2)) = %s', [Radius.ToString]));
end;

{ ============================================================
  SECTION 2 — Lines and Distances
============================================================ }
procedure DemoDistances;
var
  L: TLine2D;
  P, A, B, Closest: TPoint2D;
  T, D: Double;
begin
  WriteLn;
  WriteLn('=== DISTANCES ===');
  WriteLn('How far is a point from a segment or infinite line?');
  Sep;

  { Distance from (1,3) to segment (0,0)-(4,0) }
  P := TPoint2D.Create(1, 3);
  A := TPoint2D.Create(0, 0);
  B := TPoint2D.Create(4, 0);
  D := TGeometryKit.PointToSegment2D(P, A, B, T);
  WriteLn(Format('  Point %s to segment %s → %s',
    [P.ToString, A.ToString, B.ToString]));
  WriteLn(Format('  Distance = %.4f,  nearest param T = %.4f', [D, T]));

  { Distance to infinite line }
  L := TLine2D.FromPoints(A, B);  { x-axis }
  WriteLn(Format('  Distance to x-axis = %.4f  (= Y-coordinate)', [L.Distance(P)]));
  Closest := L.ClosestPoint(P);
  WriteLn(Format('  Closest point on x-axis = %s', [Closest.ToString]));

  { Two segments: parallel }
  WriteLn;
  WriteLn('  Gap between two parallel horizontal segments:');
  D := TGeometryKit.SegmentToSegment2D(
    TPoint2D.Create(0,0), TPoint2D.Create(3,0),
    TPoint2D.Create(0,2), TPoint2D.Create(3,2));
  WriteLn(Format('  (0,0)-(3,0) vs (0,2)-(3,2): gap = %.4f', [D]));
end;

{ ============================================================
  SECTION 3 — Intersection Tests
============================================================ }
procedure DemoIntersections;
var
  A1, A2, B1, B2, Pt: TPoint2D;
  T: Double;
  C: TCircle2D;
  T1, T2: Double;
  N: Integer;
begin
  WriteLn;
  WriteLn('=== INTERSECTION TESTS ===');
  Sep;

  { Crossing segments }
  A1 := TPoint2D.Create(0,0); A2 := TPoint2D.Create(2,2);
  B1 := TPoint2D.Create(0,2); B2 := TPoint2D.Create(2,0);
  WriteLn('  Crossing diagonals:');
  if TGeometryKit.SegmentIntersect2D(A1, A2, B1, B2, Pt, T) then
    WriteLn(Format('  → Intersect at %s  (T=%.4f along first segment)',
      [Pt.ToString, T]));

  { Parallel segments }
  WriteLn;
  WriteLn('  Parallel horizontal segments:');
  A1 := TPoint2D.Create(0,0); A2 := TPoint2D.Create(4,0);
  B1 := TPoint2D.Create(0,1); B2 := TPoint2D.Create(4,1);
  if not TGeometryKit.SegmentsIntersect2D(A1, A2, B1, B2) then
    WriteLn('  → No intersection (parallel)');

  { Line intersection }
  WriteLn;
  WriteLn('  Two infinite lines (x-axis and y-axis):');
  if TGeometryKit.LineIntersect2D(
    TPoint2D.Create(-1,0), TPoint2D.Create(1,0),
    TPoint2D.Create(0,-1), TPoint2D.Create(0,1), Pt) then
    WriteLn(Format('  → Meet at %s', [Pt.ToString]));

  { Ray vs circle }
  WriteLn;
  C := TCircle2D.Create(TPoint2D.Create(5,0), 2.0);
  WriteLn('  Ray from (0,0) in direction (1,0) vs circle centred at (5,0) r=2:');
  N := TGeometryKit.RayCircleIntersect(
    TPoint2D.Create(0,0), TPoint2D.Create(1,0), C, T1, T2);
  WriteLn(Format('  → %d hit(s): T1=%.4f, T2=%.4f  (hit at x=%.1f and x=%.1f)',
    [N, T1, T2, T1, T2]));
end;

{ ============================================================
  SECTION 4 — Circles
============================================================ }
procedure DemoCircles;
var C: TCircle2D;
begin
  WriteLn;
  WriteLn('=== CIRCLES ===');
  Sep;

  C := TCircle2D.Create(TPoint2D.Create(3, 4), 5.0);
  WriteLn('  Circle: centre=(3,4), radius=5');
  WriteLn(Format('  Area          = %.4f  (π r² = 25π)', [C.Area]));
  WriteLn(Format('  Circumference = %.4f  (2π r = 10π)', [C.Circumference]));
  WriteLn(Format('  Contains (3,4)? %s  (centre → yes)', [BoolToStr(C.ContainsPoint(TPoint2D.Create(3,4)), True)]));
  WriteLn(Format('  Contains (8,4)? %s  (exactly on boundary)', [BoolToStr(C.ContainsPoint(TPoint2D.Create(8,4)), True)]));
  WriteLn(Format('  Contains (9,4)? %s  (outside)', [BoolToStr(C.ContainsPoint(TPoint2D.Create(9,4)), True)]));
end;

{ ============================================================
  SECTION 5 — Polygons
============================================================ }
procedure DemoPolygons;
var
  Square, Triangle, LShape: TPolygon2D;
  Centroid: TPoint2D;
begin
  WriteLn;
  WriteLn('=== POLYGONS ===');
  WriteLn('Area (shoelace), perimeter, centroid, and point-in-polygon.');
  Sep;

  { Unit square CCW }
  SetLength(Square, 4);
  Square[0] := TPoint2D.Create(0,0); Square[1] := TPoint2D.Create(1,0);
  Square[2] := TPoint2D.Create(1,1); Square[3] := TPoint2D.Create(0,1);

  WriteLn('  Unit square (CCW):');
  WriteLn(Format('    Area      = %.4f  (positive = CCW)', [TGeometryKit.PolygonArea(Square)]));
  WriteLn(Format('    Perimeter = %.4f', [TGeometryKit.PolygonPerimeter(Square)]));
  Centroid := TGeometryKit.PolygonCentroid(Square);
  WriteLn(Format('    Centroid  = %s  (= (0.5, 0.5))', [Centroid.ToString]));
  WriteLn(Format('    Point (0.5,0.5) inside? %s',
    [BoolToStr(TGeometryKit.PointInPolygon(TPoint2D.Create(0.5,0.5), Square), True)]));
  WriteLn(Format('    Point (2,2) inside?      %s',
    [BoolToStr(TGeometryKit.PointInPolygon(TPoint2D.Create(2,2), Square), True)]));

  { 3-4-5 right triangle }
  SetLength(Triangle, 3);
  Triangle[0] := TPoint2D.Create(0,0);
  Triangle[1] := TPoint2D.Create(4,0);
  Triangle[2] := TPoint2D.Create(0,3);
  WriteLn;
  WriteLn(Format('  3-4-5 right triangle:  Area = %.4f  (expected: 6)',
    [TGeometryKit.PolygonArea(Triangle)]));

  { L-shaped polygon (concave) }
  SetLength(LShape, 6);
  LShape[0] := TPoint2D.Create(0,0); LShape[1] := TPoint2D.Create(3,0);
  LShape[2] := TPoint2D.Create(3,1); LShape[3] := TPoint2D.Create(1,1);
  LShape[4] := TPoint2D.Create(1,3); LShape[5] := TPoint2D.Create(0,3);
  WriteLn;
  WriteLn('  L-shaped polygon (concave):');
  WriteLn(Format('    Area = %.4f  (3×3 − 2×2 = 5)',
    [TGeometryKit.PolygonArea(LShape)]));
  WriteLn(Format('    Convex? %s  (L-shape has a reflex angle)',
    [BoolToStr(TGeometryKit.IsConvex(LShape), True)]));
  WriteLn(Format('    Point (2,2) inside? %s  (in the notch → outside)',
    [BoolToStr(TGeometryKit.PointInPolygon(TPoint2D.Create(2,2), LShape), True)]));
  WriteLn(Format('    Point (0.5,2) inside? %s  (in the stem → inside)',
    [BoolToStr(TGeometryKit.PointInPolygon(TPoint2D.Create(0.5,2), LShape), True)]));
end;

{ ============================================================
  SECTION 6 — Convex Hull
============================================================ }
procedure DemoConvexHull;
var
  Pts, Hull: TPolygon2D;
  I: Integer;
begin
  WriteLn;
  WriteLn('=== CONVEX HULL (Graham Scan, O(n log n)) ===');
  WriteLn('Given a cloud of points, find the smallest convex polygon that');
  WriteLn('encloses all of them.');
  Sep;

  { 8 points: 4 corners of a square + 4 interior/edge points }
  SetLength(Pts, 8);
  Pts[0] := TPoint2D.Create(0,0); Pts[1] := TPoint2D.Create(4,0);
  Pts[2] := TPoint2D.Create(4,4); Pts[3] := TPoint2D.Create(0,4);
  Pts[4] := TPoint2D.Create(2,2);  { interior }
  Pts[5] := TPoint2D.Create(1,1);  { interior }
  Pts[6] := TPoint2D.Create(3,1);  { interior }
  Pts[7] := TPoint2D.Create(2,4);  { on edge }

  Hull := TGeometryKit.ConvexHull(Pts);
  WriteLn(Format('  Input: %d points → Hull: %d vertices  (expected: 4)',
    [Length(Pts), Length(Hull)]));
  WriteLn('  Hull vertices (CCW):');
  for I := 0 to High(Hull) do
    WriteLn(Format('    [%d] %s', [I, Hull[I].ToString]));
end;

{ ============================================================
  SECTION 7 — Transformations
============================================================ }
procedure DemoTransformations;
var
  Sq, T, S, R: TPolygon2D;
  I: Integer;
begin
  WriteLn;
  WriteLn('=== TRANSFORMATIONS ===');
  WriteLn('Translate, scale, and rotate — all return a new polygon.');
  Sep;

  { Build a unit square }
  SetLength(Sq, 4);
  Sq[0] := TPoint2D.Create(0,0); Sq[1] := TPoint2D.Create(1,0);
  Sq[2] := TPoint2D.Create(1,1); Sq[3] := TPoint2D.Create(0,1);

  { Translate by (2, 3) }
  T := TGeometryKit.Translate2D(Sq, 2, 3);
  WriteLn('  Original:   (0,0),(1,0),(1,1),(0,1)');
  Write('  Translate(2,3): ');
  for I := 0 to 3 do Write(T[I].ToString + ' '); WriteLn;

  { Scale by 2 }
  S := TGeometryKit.Scale2D(Sq, 2, 2);
  Write('  Scale(2,2):     ');
  for I := 0 to 3 do Write(S[I].ToString + ' '); WriteLn;

  { Rotate 90° CCW about origin }
  R := TGeometryKit.Rotate2D(Sq, Pi/2, TPoint2D.Create(0,0));
  Write('  Rotate(90°):    ');
  for I := 0 to 3 do Write(R[I].ToString + ' '); WriteLn;
  WriteLn('  (1,0) rotated 90° CCW → (0,1) ✓');
end;

{ ============================================================
  SECTION 8 — 3-D Geometry
============================================================ }
procedure Demo3D;
var
  A, B: TPoint3D;
  V1, V2, Cx: TVector3D;
  Plane: TPlane3D;
  Sphere: TSphere3D;
  P, Closest: TPoint3D;
begin
  WriteLn;
  WriteLn('=== 3-D GEOMETRY ===');
  Sep;

  A := TPoint3D.Create(0,0,0);
  B := TPoint3D.Create(1,2,2);
  WriteLn(Format('  Distance (0,0,0)→(1,2,2) = %.4f  (= 3)', [A.DistanceTo(B)]));

  { Cross product }
  V1 := TVector3D.Create(1,0,0);
  V2 := TVector3D.Create(0,1,0);
  Cx := V1.Cross(V2);
  WriteLn(Format('  (1,0,0) × (0,1,0) = %s  (= z-axis)', [Cx.ToString]));

  { Plane and point distance }
  WriteLn;
  Plane := TPlane3D.FromPointNormal(
    TPoint3D.Create(0,0,0), TVector3D.Create(0,0,1));
  P := TPoint3D.Create(3, 4, 7);
  WriteLn('  XY plane.  Point (3,4,7):');
  WriteLn(Format('    Distance = %.4f  (= Z-coord)', [Plane.Distance(P)]));
  Closest := Plane.ClosestPoint(P);
  WriteLn(Format('    Closest  = %s  (= (3,4,0))', [Closest.ToString]));

  { Triangle area in 3-D }
  WriteLn;
  WriteLn('  3-D triangle (0,0,0),(4,0,0),(0,3,0):');
  WriteLn(Format('    Area = %.4f  (= 6)', [TGeometryKit.TriangleArea3D(
    TPoint3D.Create(0,0,0), TPoint3D.Create(4,0,0), TPoint3D.Create(0,3,0))]));

  { Sphere }
  WriteLn;
  Sphere := TSphere3D.Create(TPoint3D.Create(0,0,0), 3.0);
  WriteLn(Format('  Sphere r=3:  Volume=%.4f  SurfArea=%.4f',
    [Sphere.Volume, Sphere.SurfaceArea]));
  WriteLn(Format('  Contains (1,2,2)? %s', [BoolToStr(Sphere.ContainsPoint(TPoint3D.Create(1,2,2)), True)]));
end;

{ ============================================================
  MAIN
============================================================ }
begin
  WriteLn('mathlib-fp — GeometryLib Example');
  WriteLn('=================================');

  DemoPoints2D;
  DemoVectorArithmetic;
  DemoDistances;
  DemoIntersections;
  DemoCircles;
  DemoPolygons;
  DemoConvexHull;
  DemoTransformations;
  Demo3D;

  WriteLn;
  WriteLn('Done.');
end.
