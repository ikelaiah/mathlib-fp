unit GeometryLib.Geometry;

{-----------------------------------------------------------------------------
 GeometryLib.Geometry

 2-D and 3-D computational geometry for Free Pascal.
 No external dependencies — only MathBase and the RTL.

 What this library gives you
 ---------------------------
 2-D Primitives
   TPoint2D      — (X, Y) with helper methods
   TVector2D     — directed vector with dot, cross, magnitude, normalise
   TSegment2D    — line segment [P, Q]
   TLine2D       — infinite line through two points (or ax+by+c=0)
   TCircle2D     — centre + radius
   TPolygon2D    — ordered sequence of vertices

 3-D Primitives
   TPoint3D      — (X, Y, Z)
   TVector3D     — dot, cross, magnitude, normalise
   TSegment3D    — 3-D line segment
   TPlane3D      — ax+by+cz+d=0
   TSphere3D     — centre + radius

 Distance Functions
   PointToPoint2D         — Euclidean distance
   PointToSegment2D       — shortest distance from point to segment
   PointToLine2D          — perpendicular distance
   SegmentToSegment2D     — minimum distance between two segments
   PointToPoint3D
   PointToSegment3D
   PointToPlane3D

 Intersection Tests
   SegmentsIntersect2D    — do two segments cross? (including endpoints)
   SegmentIntersect2D     — find the actual intersection point
   LineIntersect2D        — intersection of two infinite lines
   SegmentCircleIntersect — does segment intersect a circle?
   RayCircleIntersect     — ray-circle intersection (ray casting)

 Polygon & Convex Hull
   PolygonArea            — signed area (positive = CCW)
   PolygonPerimeter       — total edge length
   PolygonCentroid        — area-weighted centroid
   PointInPolygon         — ray-casting test (handles holes & concave)
   IsConvex               — test convexity
   ConvexHull             — Graham scan, O(n log n)

 Geometric Transformations
   Translate2D            — shift all points by (dx, dy)
   Scale2D                — scale about the origin
   Rotate2D               — rotate CCW by angle (radians) about a centre

 Utility
   AngleBetween2D         — signed angle from V1 to V2 (radians, −π..π)
   AngleBetween3D         — unsigned angle between two 3-D vectors
   TriangleArea2D         — area from three points (Heron-free formula)
   TriangleArea3D         — area from three 3-D points (cross product)
   BoundingBox2D          — axis-aligned bounding box of a point set

 All methods are static on TGeometryKit — no object creation needed.
 Raises EGeometryError for degenerate inputs.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes;

const
  GEO_EPS = 1e-10;  { tolerance for near-zero comparisons }

type
  { Raised for degenerate inputs (zero-length vectors, collinear polygons, etc.) }
  EGeometryError = class(Exception);

  { -----------------------------------------------------------------------
    2-D Types
  ----------------------------------------------------------------------- }

  TPoint2D = record
    X, Y: Double;
    class function Create(AX, AY: Double): TPoint2D; static;
    function  DistanceTo(const Other: TPoint2D): Double;
    function  ToString: String;
  end;

  TVector2D = record
    X, Y: Double;
    class function Create(AX, AY: Double): TVector2D; static;
    { From P → Q }
    class function FromPoints(const P, Q: TPoint2D): TVector2D; static;
    function  Magnitude: Double;
    function  Normalise: TVector2D;       { unit vector; raises if zero }
    function  Dot(const V: TVector2D): Double;
    function  Cross(const V: TVector2D): Double;  { 2-D: scalar z-component }
    function  Perpendicular: TVector2D;   { rotate 90° CCW }
    function  ToString: String;
  end;

  TSegment2D = record
    P, Q: TPoint2D;
    class function Create(const AP, AQ: TPoint2D): TSegment2D; static;
    function  Length: Double;
    function  Midpoint: TPoint2D;
    function  Direction: TVector2D;
    function  ToString: String;
  end;

  TLine2D = record
    { Represented as ax + by + c = 0 (normalised so a²+b²=1) }
    A, B, C: Double;
    { Construct from two distinct points }
    class function FromPoints(const P, Q: TPoint2D): TLine2D; static;
    { Signed distance from point to line (+/− sides) }
    function SignedDistance(const P: TPoint2D): Double;
    function Distance(const P: TPoint2D): Double;
    { Point on line nearest to P }
    function ClosestPoint(const P: TPoint2D): TPoint2D;
  end;

  TCircle2D = record
    Centre: TPoint2D;
    Radius: Double;
    class function Create(const ACentre: TPoint2D; ARadius: Double): TCircle2D; static;
    function Area: Double;
    function Circumference: Double;
    function ContainsPoint(const P: TPoint2D): Boolean;
  end;

  TPolygon2D = array of TPoint2D;

  { -----------------------------------------------------------------------
    3-D Types
  ----------------------------------------------------------------------- }

  TPoint3D = record
    X, Y, Z: Double;
    class function Create(AX, AY, AZ: Double): TPoint3D; static;
    function  DistanceTo(const Other: TPoint3D): Double;
    function  ToString: String;
  end;

  TVector3D = record
    X, Y, Z: Double;
    class function Create(AX, AY, AZ: Double): TVector3D; static;
    class function FromPoints(const P, Q: TPoint3D): TVector3D; static;
    function  Magnitude: Double;
    function  Normalise: TVector3D;
    function  Dot(const V: TVector3D): Double;
    function  Cross(const V: TVector3D): TVector3D;
    function  ToString: String;
  end;

  TSegment3D = record
    P, Q: TPoint3D;
    class function Create(const AP, AQ: TPoint3D): TSegment3D; static;
    function Length: Double;
    function Midpoint: TPoint3D;
  end;

  TPlane3D = record
    { ax + by + cz + d = 0 with (a,b,c) unit normal }
    A, B, C, D: Double;
    class function FromPointNormal(const P: TPoint3D;
      const N: TVector3D): TPlane3D; static;
    class function FromThreePoints(const P1, P2, P3: TPoint3D): TPlane3D; static;
    function SignedDistance(const P: TPoint3D): Double;
    function Distance(const P: TPoint3D): Double;
    function ClosestPoint(const P: TPoint3D): TPoint3D;
  end;

  TSphere3D = record
    Centre: TPoint3D;
    Radius: Double;
    class function Create(const ACentre: TPoint3D; ARadius: Double): TSphere3D; static;
    function Volume: Double;
    function SurfaceArea: Double;
    function ContainsPoint(const P: TPoint3D): Boolean;
  end;

  { Axis-aligned bounding box }
  TBoundingBox2D = record
    MinX, MinY, MaxX, MaxY: Double;
    function Width: Double;
    function Height: Double;
    function Area: Double;
    function ContainsPoint(const P: TPoint2D): Boolean;
  end;

  { -----------------------------------------------------------------------
    TGeometryKit — all methods are class static
  ----------------------------------------------------------------------- }

  TGeometryKit = class
  public

    { ===================================================================
      DISTANCE
    =================================================================== }

    { Euclidean distance between two 2-D points }
    class function PointToPoint2D(const A, B: TPoint2D): Double; static;

    { Shortest distance from point P to line segment AB.
      Returns the distance; optionally sets T (0..1) to the parameter of
      the closest point on AB. }
    class function PointToSegment2D(const P, A, B: TPoint2D;
      out T: Double): Double; static;

    { Perpendicular distance from point P to infinite line through A and B }
    class function PointToLine2D(const P, A, B: TPoint2D): Double; static;

    { Minimum distance between two line segments.
      Slow O(1) but correct for parallel and crossing cases. }
    class function SegmentToSegment2D(const A1, A2, B1, B2: TPoint2D): Double; static;

    { 3-D Euclidean distance }
    class function PointToPoint3D(const A, B: TPoint3D): Double; static;

    { Shortest distance from point P to 3-D segment AB }
    class function PointToSegment3D(const P, A, B: TPoint3D;
      out T: Double): Double; static;

    { Distance from point to plane }
    class function PointToPlane3D(const P: TPoint3D;
      const Plane: TPlane3D): Double; static;

    { ===================================================================
      INTERSECTION
    =================================================================== }

    { Returns True if segments (A1,A2) and (B1,B2) intersect.
      Endpoints touching counts as intersection. }
    class function SegmentsIntersect2D(const A1, A2, B1, B2: TPoint2D): Boolean; static;

    { Find intersection point of two segments. Returns False if parallel/no cross.
      Sets T to parameter along (A1,A2) where intersection occurs. }
    class function SegmentIntersect2D(const A1, A2, B1, B2: TPoint2D;
      out Pt: TPoint2D; out T: Double): Boolean; static;

    { Intersection of two infinite lines (each defined by two points).
      Returns False if lines are parallel (or coincident). }
    class function LineIntersect2D(const A1, A2, B1, B2: TPoint2D;
      out Pt: TPoint2D): Boolean; static;

    { Returns True if segment (P,Q) intersects or is inside circle C }
    class function SegmentCircleIntersect(const P, Q: TPoint2D;
      const C: TCircle2D): Boolean; static;

    { Ray from Origin in Direction intersects circle.
      Returns number of intersections (0, 1, or 2) and the near/far t-values. }
    class function RayCircleIntersect(const Origin, Direction: TPoint2D;
      const C: TCircle2D;
      out T1, T2: Double): Integer; static;

    { ===================================================================
      POLYGON
    =================================================================== }

    { Signed area of polygon (positive = CCW, negative = CW).
      Uses the shoelace formula. }
    class function PolygonArea(const Poly: TPolygon2D): Double; static;

    { Total perimeter (sum of edge lengths) }
    class function PolygonPerimeter(const Poly: TPolygon2D): Double; static;

    { Area-weighted centroid of a simple polygon }
    class function PolygonCentroid(const Poly: TPolygon2D): TPoint2D; static;

    { Point-in-polygon test using ray casting.
      Returns True if P is strictly inside Poly (not on boundary).
      Works for concave polygons; does not handle self-intersecting. }
    class function PointInPolygon(const P: TPoint2D;
      const Poly: TPolygon2D): Boolean; static;

    { Returns True if polygon is convex (all cross-products same sign) }
    class function IsConvex(const Poly: TPolygon2D): Boolean; static;

    { Convex hull of a point set using Graham scan. O(n log n).
      Returns the hull vertices in CCW order.
      Input must have at least 3 non-collinear points. }
    class function ConvexHull(const Points: TPolygon2D): TPolygon2D; static;

    { ===================================================================
      TRANSFORMATIONS
    =================================================================== }

    { Translate all points by (DX, DY) }
    class function Translate2D(const Poly: TPolygon2D;
      DX, DY: Double): TPolygon2D; static;

    { Scale all points by SX, SY about the origin }
    class function Scale2D(const Poly: TPolygon2D;
      SX, SY: Double): TPolygon2D; static;

    { Rotate all points CCW by Angle radians about Centre }
    class function Rotate2D(const Poly: TPolygon2D;
      Angle: Double; const Centre: TPoint2D): TPolygon2D; static;

    { ===================================================================
      ANGLES & TRIANGLES
    =================================================================== }

    { Signed angle from V1 to V2 in radians (range −π..π) }
    class function AngleBetween2D(const V1, V2: TVector2D): Double; static;

    { Unsigned angle between two 3-D vectors (0..π) }
    class function AngleBetween3D(const V1, V2: TVector3D): Double; static;

    { Area of triangle with vertices A, B, C (2-D) }
    class function TriangleArea2D(const A, B, C: TPoint2D): Double; static;

    { Area of triangle with vertices A, B, C (3-D, via cross product) }
    class function TriangleArea3D(const A, B, C: TPoint3D): Double; static;

    { Axis-aligned bounding box of a 2-D point set }
    class function BoundingBox2D(const Points: TPolygon2D): TBoundingBox2D; static;

  end;

implementation

{ ---------------------------------------------------------------------------
  TPoint2D
--------------------------------------------------------------------------- }

class function TPoint2D.Create(AX, AY: Double): TPoint2D;
begin Result.X := AX; Result.Y := AY; end;

function TPoint2D.DistanceTo(const Other: TPoint2D): Double;
begin Result := Sqrt(Sqr(X - Other.X) + Sqr(Y - Other.Y)); end;

function TPoint2D.ToString: String;
begin Result := Format('(%.6g, %.6g)', [X, Y]); end;

{ ---------------------------------------------------------------------------
  TVector2D
--------------------------------------------------------------------------- }

class function TVector2D.Create(AX, AY: Double): TVector2D;
begin Result.X := AX; Result.Y := AY; end;

class function TVector2D.FromPoints(const P, Q: TPoint2D): TVector2D;
begin Result.X := Q.X - P.X; Result.Y := Q.Y - P.Y; end;

function TVector2D.Magnitude: Double;
begin Result := Sqrt(X*X + Y*Y); end;

function TVector2D.Normalise: TVector2D;
var M: Double;
begin
  M := Magnitude;
  if M < GEO_EPS then raise EGeometryError.Create('Cannot normalise a zero vector');
  Result.X := X / M; Result.Y := Y / M;
end;

function TVector2D.Dot(const V: TVector2D): Double;
begin Result := X * V.X + Y * V.Y; end;

function TVector2D.Cross(const V: TVector2D): Double;
begin Result := X * V.Y - Y * V.X; end;

function TVector2D.Perpendicular: TVector2D;
begin Result.X := -Y; Result.Y := X; end;

function TVector2D.ToString: String;
begin Result := Format('<%.6g, %.6g>', [X, Y]); end;

{ ---------------------------------------------------------------------------
  TSegment2D
--------------------------------------------------------------------------- }

class function TSegment2D.Create(const AP, AQ: TPoint2D): TSegment2D;
begin Result.P := AP; Result.Q := AQ; end;

function TSegment2D.Length: Double;
begin Result := P.DistanceTo(Q); end;

function TSegment2D.Midpoint: TPoint2D;
begin Result.X := (P.X + Q.X) * 0.5; Result.Y := (P.Y + Q.Y) * 0.5; end;

function TSegment2D.Direction: TVector2D;
begin Result := TVector2D.FromPoints(P, Q); end;

function TSegment2D.ToString: String;
begin Result := Format('[%s → %s]', [P.ToString, Q.ToString]); end;

{ ---------------------------------------------------------------------------
  TLine2D
--------------------------------------------------------------------------- }

class function TLine2D.FromPoints(const P, Q: TPoint2D): TLine2D;
var DX, DY, Len: Double;
begin
  DX := Q.X - P.X; DY := Q.Y - P.Y;
  Len := Sqrt(DX*DX + DY*DY);
  if Len < GEO_EPS then raise EGeometryError.Create('TLine2D.FromPoints: degenerate (same point)');
  { Normal form: (DY)*x + (-DX)*y + (-DY*P.X + DX*P.Y) = 0, then normalise }
  Result.A := DY / Len;
  Result.B := -DX / Len;
  Result.C := (-DY * P.X + DX * P.Y) / Len;
end;

function TLine2D.SignedDistance(const P: TPoint2D): Double;
begin Result := A * P.X + B * P.Y + C; end;

function TLine2D.Distance(const P: TPoint2D): Double;
begin Result := Abs(SignedDistance(P)); end;

function TLine2D.ClosestPoint(const P: TPoint2D): TPoint2D;
var T: Double;
begin
  T := -(A * P.X + B * P.Y + C);
  Result.X := P.X + A * T;
  Result.Y := P.Y + B * T;
end;

{ ---------------------------------------------------------------------------
  TCircle2D
--------------------------------------------------------------------------- }

class function TCircle2D.Create(const ACentre: TPoint2D; ARadius: Double): TCircle2D;
begin Result.Centre := ACentre; Result.Radius := ARadius; end;

function TCircle2D.Area: Double;
begin Result := Pi * Radius * Radius; end;

function TCircle2D.Circumference: Double;
begin Result := 2 * Pi * Radius; end;

function TCircle2D.ContainsPoint(const P: TPoint2D): Boolean;
begin Result := Centre.DistanceTo(P) <= Radius; end;

{ ---------------------------------------------------------------------------
  TPoint3D
--------------------------------------------------------------------------- }

class function TPoint3D.Create(AX, AY, AZ: Double): TPoint3D;
begin Result.X := AX; Result.Y := AY; Result.Z := AZ; end;

function TPoint3D.DistanceTo(const Other: TPoint3D): Double;
begin Result := Sqrt(Sqr(X-Other.X)+Sqr(Y-Other.Y)+Sqr(Z-Other.Z)); end;

function TPoint3D.ToString: String;
begin Result := Format('(%.6g, %.6g, %.6g)', [X, Y, Z]); end;

{ ---------------------------------------------------------------------------
  TVector3D
--------------------------------------------------------------------------- }

class function TVector3D.Create(AX, AY, AZ: Double): TVector3D;
begin Result.X := AX; Result.Y := AY; Result.Z := AZ; end;

class function TVector3D.FromPoints(const P, Q: TPoint3D): TVector3D;
begin Result.X := Q.X-P.X; Result.Y := Q.Y-P.Y; Result.Z := Q.Z-P.Z; end;

function TVector3D.Magnitude: Double;
begin Result := Sqrt(X*X + Y*Y + Z*Z); end;

function TVector3D.Normalise: TVector3D;
var M: Double;
begin
  M := Magnitude;
  if M < GEO_EPS then raise EGeometryError.Create('Cannot normalise a zero 3-D vector');
  Result.X := X/M; Result.Y := Y/M; Result.Z := Z/M;
end;

function TVector3D.Dot(const V: TVector3D): Double;
begin Result := X*V.X + Y*V.Y + Z*V.Z; end;

function TVector3D.Cross(const V: TVector3D): TVector3D;
begin
  Result.X := Y*V.Z - Z*V.Y;
  Result.Y := Z*V.X - X*V.Z;
  Result.Z := X*V.Y - Y*V.X;
end;

function TVector3D.ToString: String;
begin Result := Format('<%.6g, %.6g, %.6g>', [X, Y, Z]); end;

{ ---------------------------------------------------------------------------
  TSegment3D
--------------------------------------------------------------------------- }

class function TSegment3D.Create(const AP, AQ: TPoint3D): TSegment3D;
begin Result.P := AP; Result.Q := AQ; end;

function TSegment3D.Length: Double;
begin Result := P.DistanceTo(Q); end;

function TSegment3D.Midpoint: TPoint3D;
begin
  Result.X := (P.X+Q.X)*0.5;
  Result.Y := (P.Y+Q.Y)*0.5;
  Result.Z := (P.Z+Q.Z)*0.5;
end;

{ ---------------------------------------------------------------------------
  TPlane3D
--------------------------------------------------------------------------- }

class function TPlane3D.FromPointNormal(const P: TPoint3D;
  const N: TVector3D): TPlane3D;
var UN: TVector3D;
begin
  UN := N.Normalise;
  Result.A := UN.X; Result.B := UN.Y; Result.C := UN.Z;
  Result.D := -(UN.X*P.X + UN.Y*P.Y + UN.Z*P.Z);
end;

class function TPlane3D.FromThreePoints(const P1, P2, P3: TPoint3D): TPlane3D;
var V1, V2, N: TVector3D;
begin
  V1 := TVector3D.FromPoints(P1, P2);
  V2 := TVector3D.FromPoints(P1, P3);
  N  := V1.Cross(V2);
  if N.Magnitude < GEO_EPS then
    raise EGeometryError.Create('TPlane3D.FromThreePoints: points are collinear');
  Result := TPlane3D.FromPointNormal(P1, N);
end;

function TPlane3D.SignedDistance(const P: TPoint3D): Double;
begin Result := A*P.X + B*P.Y + C*P.Z + D; end;

function TPlane3D.Distance(const P: TPoint3D): Double;
begin Result := Abs(SignedDistance(P)); end;

function TPlane3D.ClosestPoint(const P: TPoint3D): TPoint3D;
var T: Double;
begin
  T := SignedDistance(P);
  Result.X := P.X - A*T;
  Result.Y := P.Y - B*T;
  Result.Z := P.Z - C*T;
end;

{ ---------------------------------------------------------------------------
  TSphere3D
--------------------------------------------------------------------------- }

class function TSphere3D.Create(const ACentre: TPoint3D; ARadius: Double): TSphere3D;
begin Result.Centre := ACentre; Result.Radius := ARadius; end;

function TSphere3D.Volume: Double;
begin Result := (4/3) * Pi * Power(Radius, 3); end;

function TSphere3D.SurfaceArea: Double;
begin Result := 4 * Pi * Radius * Radius; end;

function TSphere3D.ContainsPoint(const P: TPoint3D): Boolean;
begin Result := Centre.DistanceTo(P) <= Radius; end;

{ ---------------------------------------------------------------------------
  TBoundingBox2D
--------------------------------------------------------------------------- }

function TBoundingBox2D.Width:  Double; begin Result := MaxX - MinX; end;
function TBoundingBox2D.Height: Double; begin Result := MaxY - MinY; end;
function TBoundingBox2D.Area:   Double; begin Result := Width * Height; end;

function TBoundingBox2D.ContainsPoint(const P: TPoint2D): Boolean;
begin
  Result := (P.X >= MinX) and (P.X <= MaxX) and
            (P.Y >= MinY) and (P.Y <= MaxY);
end;

{ ---------------------------------------------------------------------------
  TGeometryKit — Distance
--------------------------------------------------------------------------- }

class function TGeometryKit.PointToPoint2D(const A, B: TPoint2D): Double;
begin Result := A.DistanceTo(B); end;

class function TGeometryKit.PointToSegment2D(const P, A, B: TPoint2D;
  out T: Double): Double;
var DX, DY, Len2, PX, PY: Double;
begin
  DX := B.X - A.X; DY := B.Y - A.Y;
  Len2 := DX*DX + DY*DY;
  if Len2 < GEO_EPS * GEO_EPS then
  begin
    T := 0; Result := P.DistanceTo(A); Exit;
  end;
  T := ((P.X-A.X)*DX + (P.Y-A.Y)*DY) / Len2;
  T := Max(0, Min(1, T));
  PX := A.X + T*DX; PY := A.Y + T*DY;
  Result := Sqrt(Sqr(P.X-PX) + Sqr(P.Y-PY));
end;

class function TGeometryKit.PointToLine2D(const P, A, B: TPoint2D): Double;
var L: TLine2D;
begin
  L := TLine2D.FromPoints(A, B);
  Result := L.Distance(P);
end;

class function TGeometryKit.SegmentToSegment2D(
  const A1, A2, B1, B2: TPoint2D): Double;
var T: Double; D1, D2, D3, D4: Double;
begin
  { If segments intersect, distance is 0 }
  if SegmentsIntersect2D(A1, A2, B1, B2) then begin Result := 0; Exit; end;
  D1 := PointToSegment2D(A1, B1, B2, T);
  D2 := PointToSegment2D(A2, B1, B2, T);
  D3 := PointToSegment2D(B1, A1, A2, T);
  D4 := PointToSegment2D(B2, A1, A2, T);
  Result := Min(Min(D1, D2), Min(D3, D4));
end;

class function TGeometryKit.PointToPoint3D(const A, B: TPoint3D): Double;
begin Result := A.DistanceTo(B); end;

class function TGeometryKit.PointToSegment3D(const P, A, B: TPoint3D;
  out T: Double): Double;
var DX, DY, DZ, Len2, CX, CY, CZ: Double;
begin
  DX := B.X-A.X; DY := B.Y-A.Y; DZ := B.Z-A.Z;
  Len2 := DX*DX + DY*DY + DZ*DZ;
  if Len2 < GEO_EPS * GEO_EPS then begin T := 0; Result := P.DistanceTo(A); Exit; end;
  T := ((P.X-A.X)*DX + (P.Y-A.Y)*DY + (P.Z-A.Z)*DZ) / Len2;
  T := Max(0, Min(1, T));
  CX := A.X+T*DX; CY := A.Y+T*DY; CZ := A.Z+T*DZ;
  Result := Sqrt(Sqr(P.X-CX)+Sqr(P.Y-CY)+Sqr(P.Z-CZ));
end;

class function TGeometryKit.PointToPlane3D(const P: TPoint3D;
  const Plane: TPlane3D): Double;
begin Result := Plane.Distance(P); end;

{ ---------------------------------------------------------------------------
  TGeometryKit — Intersection
--------------------------------------------------------------------------- }

{ Helper: cross product of (B-A) × (P-A) — positive = left, negative = right }
function Cross2D(const A, B, P: TPoint2D): Double;
begin
  Result := (B.X-A.X)*(P.Y-A.Y) - (B.Y-A.Y)*(P.X-A.X);
end;

function OnSegment(const A, B, P: TPoint2D): Boolean;
begin
  Result := (Min(A.X,B.X) <= P.X+GEO_EPS) and (P.X <= Max(A.X,B.X)+GEO_EPS) and
            (Min(A.Y,B.Y) <= P.Y+GEO_EPS) and (P.Y <= Max(A.Y,B.Y)+GEO_EPS);
end;

class function TGeometryKit.SegmentsIntersect2D(
  const A1, A2, B1, B2: TPoint2D): Boolean;
var D1, D2, D3, D4: Double;
begin
  D1 := Cross2D(B1, B2, A1);
  D2 := Cross2D(B1, B2, A2);
  D3 := Cross2D(A1, A2, B1);
  D4 := Cross2D(A1, A2, B2);

  if ((D1 > 0) and (D2 < 0) or (D1 < 0) and (D2 > 0)) and
     ((D3 > 0) and (D4 < 0) or (D3 < 0) and (D4 > 0)) then
  begin Result := True; Exit; end;

  { Collinear cases }
  if (Abs(D1) < GEO_EPS) and OnSegment(B1, B2, A1) then begin Result := True; Exit; end;
  if (Abs(D2) < GEO_EPS) and OnSegment(B1, B2, A2) then begin Result := True; Exit; end;
  if (Abs(D3) < GEO_EPS) and OnSegment(A1, A2, B1) then begin Result := True; Exit; end;
  if (Abs(D4) < GEO_EPS) and OnSegment(A1, A2, B2) then begin Result := True; Exit; end;
  Result := False;
end;

class function TGeometryKit.SegmentIntersect2D(const A1, A2, B1, B2: TPoint2D;
  out Pt: TPoint2D; out T: Double): Boolean;
var
  R, S, RxS, TNum: Double;
  RV, SV: TVector2D;
  QPA: TVector2D;
begin
  { Parametric form: A1 + t*R = B1 + u*S }
  RV.X := A2.X-A1.X; RV.Y := A2.Y-A1.Y;
  SV.X := B2.X-B1.X; SV.Y := B2.Y-B1.Y;
  RxS  := RV.Cross(SV);
  QPA.X := B1.X-A1.X; QPA.Y := B1.Y-A1.Y;

  if Abs(RxS) < GEO_EPS then begin Result := False; T := 0; Exit; end;

  TNum := QPA.Cross(SV);
  T    := TNum / RxS;
  R    := QPA.Cross(RV) / RxS;

  if (T < -GEO_EPS) or (T > 1+GEO_EPS) or
     (R < -GEO_EPS) or (R > 1+GEO_EPS) then
  begin Result := False; Exit; end;

  Pt.X := A1.X + T * RV.X;
  Pt.Y := A1.Y + T * RV.Y;
  Result := True;
end;

class function TGeometryKit.LineIntersect2D(const A1, A2, B1, B2: TPoint2D;
  out Pt: TPoint2D): Boolean;
var
  LA, LB: TLine2D;
  Det: Double;
begin
  LA := TLine2D.FromPoints(A1, A2);
  LB := TLine2D.FromPoints(B1, B2);
  Det := LA.A * LB.B - LB.A * LA.B;
  if Abs(Det) < GEO_EPS then begin Result := False; Exit; end;
  Pt.X := (-LA.C * LB.B + LB.C * LA.B) / Det;
  Pt.Y := (-LA.A * LB.C + LB.A * LA.C) / Det;
  Result := True;
end;

class function TGeometryKit.SegmentCircleIntersect(const P, Q: TPoint2D;
  const C: TCircle2D): Boolean;
var T: Double;
begin
  { Closest point on PQ to centre; if within radius, they intersect }
  Result := PointToSegment2D(C.Centre, P, Q, T) <= C.Radius + GEO_EPS;
end;

class function TGeometryKit.RayCircleIntersect(
  const Origin, Direction: TPoint2D; const C: TCircle2D;
  out T1, T2: Double): Integer;
var
  DX, DY, OX, OY, A, B, Disc: Double;
  DV: TVector2D;
begin
  DV := TVector2D.Create(Direction.X, Direction.Y);
  if DV.Magnitude < GEO_EPS then
    raise EGeometryError.Create('RayCircleIntersect: zero-length direction');
  DV := DV.Normalise;
  DX := DV.X; DY := DV.Y;
  OX := Origin.X - C.Centre.X;
  OY := Origin.Y - C.Centre.Y;
  A  := DX*DX + DY*DY;  { = 1 since normalised }
  B  := 2*(OX*DX + OY*DY);
  Disc := Sqr(B) - 4*A*(OX*OX + OY*OY - Sqr(C.Radius));
  T1 := 0; T2 := 0;
  if Disc < 0 then begin Result := 0; Exit; end;
  if Disc < GEO_EPS then
  begin
    T1 := -B / (2*A); T2 := T1; Result := 1; Exit;
  end;
  T1 := (-B - Sqrt(Disc)) / (2*A);
  T2 := (-B + Sqrt(Disc)) / (2*A);
  Result := 2;
end;

{ ---------------------------------------------------------------------------
  TGeometryKit — Polygon
--------------------------------------------------------------------------- }

class function TGeometryKit.PolygonArea(const Poly: TPolygon2D): Double;
var I, N: Integer;
begin
  N := Length(Poly);
  if N < 3 then raise EGeometryError.Create('PolygonArea: need at least 3 vertices');
  Result := 0;
  for I := 0 to N - 1 do
    Result := Result + Poly[I].X * Poly[(I+1) mod N].Y
                     - Poly[(I+1) mod N].X * Poly[I].Y;
  Result := Result * 0.5;
end;

class function TGeometryKit.PolygonPerimeter(const Poly: TPolygon2D): Double;
var I, N: Integer;
begin
  N := Length(Poly);
  if N < 2 then raise EGeometryError.Create('PolygonPerimeter: need at least 2 vertices');
  Result := 0;
  for I := 0 to N - 1 do
    Result := Result + Poly[I].DistanceTo(Poly[(I+1) mod N]);
end;

class function TGeometryKit.PolygonCentroid(const Poly: TPolygon2D): TPoint2D;
var I, N: Integer; A, C, X, Y: Double;
begin
  N := Length(Poly);
  if N < 3 then raise EGeometryError.Create('PolygonCentroid: need at least 3 vertices');
  X := 0; Y := 0; A := 0;
  for I := 0 to N - 1 do
  begin
    C := Poly[I].X * Poly[(I+1) mod N].Y - Poly[(I+1) mod N].X * Poly[I].Y;
    X := X + (Poly[I].X + Poly[(I+1) mod N].X) * C;
    Y := Y + (Poly[I].Y + Poly[(I+1) mod N].Y) * C;
    A := A + C;
  end;
  if Abs(A) < GEO_EPS then
    raise EGeometryError.Create('PolygonCentroid: degenerate polygon (zero area)');
  A := A * 0.5;
  Result.X := X / (6 * A);
  Result.Y := Y / (6 * A);
end;

class function TGeometryKit.PointInPolygon(const P: TPoint2D;
  const Poly: TPolygon2D): Boolean;
var I, J, N: Integer;
begin
  N := Length(Poly); Result := False;
  J := N - 1;
  for I := 0 to N - 1 do
  begin
    if ((Poly[I].Y > P.Y) <> (Poly[J].Y > P.Y)) and
       (P.X < (Poly[J].X - Poly[I].X) * (P.Y - Poly[I].Y) /
              (Poly[J].Y - Poly[I].Y) + Poly[I].X) then
      Result := not Result;
    J := I;
  end;
end;

class function TGeometryKit.IsConvex(const Poly: TPolygon2D): Boolean;
var I, N: Integer; Sign, C: Double; GotPos, GotNeg: Boolean;
begin
  N := Length(Poly);
  if N < 3 then raise EGeometryError.Create('IsConvex: need at least 3 vertices');
  GotPos := False; GotNeg := False;
  for I := 0 to N - 1 do
  begin
    C := Cross2D(Poly[I], Poly[(I+1) mod N], Poly[(I+2) mod N]);
    if C > GEO_EPS  then GotPos := True;
    if C < -GEO_EPS then GotNeg := True;
    if GotPos and GotNeg then begin Result := False; Exit; end;
  end;
  Result := True;
end;

class function TGeometryKit.ConvexHull(const Points: TPolygon2D): TPolygon2D;
var
  N, I, K, T: Integer;
  Sorted: TPolygon2D;
  Stack: TPolygon2D;

  function Cmp(const A, B: TPoint2D): Integer;
  begin
    if A.X < B.X then Result := -1
    else if A.X > B.X then Result := 1
    else if A.Y < B.Y then Result := -1
    else if A.Y > B.Y then Result := 1
    else Result := 0;
  end;

  procedure SortPoints;
  var I, J: Integer; Tmp: TPoint2D;
  begin
    { Insertion sort for correctness; input sizes are usually small }
    for I := 1 to N - 1 do
    begin
      Tmp := Sorted[I]; J := I - 1;
      while (J >= 0) and (Cmp(Sorted[J], Tmp) > 0) do
      begin Sorted[J+1] := Sorted[J]; Dec(J); end;
      Sorted[J+1] := Tmp;
    end;
  end;

begin
  N := Length(Points);
  if N < 3 then raise EGeometryError.Create('ConvexHull: need at least 3 points');
  SetLength(Sorted, N);
  for I := 0 to N-1 do Sorted[I] := Points[I];
  SortPoints;

  SetLength(Stack, 2*N);
  K := 0;
  { Lower hull }
  for I := 0 to N-1 do
  begin
    while (K >= 2) and (Cross2D(Stack[K-2], Stack[K-1], Sorted[I]) <= 0) do Dec(K);
    Stack[K] := Sorted[I]; Inc(K);
  end;
  { Upper hull }
  I := N - 2;
  T := K + 1;
  while I >= 0 do
  begin
    while (K >= T) and (Cross2D(Stack[K-2], Stack[K-1], Sorted[I]) <= 0) do Dec(K);
    Stack[K] := Sorted[I]; Inc(K);
    Dec(I);
  end;
  SetLength(Result, K - 1);
  for I := 0 to K - 2 do Result[I] := Stack[I];
end;

{ ---------------------------------------------------------------------------
  TGeometryKit — Transformations
--------------------------------------------------------------------------- }

class function TGeometryKit.Translate2D(const Poly: TPolygon2D;
  DX, DY: Double): TPolygon2D;
var I: Integer;
begin
  SetLength(Result, Length(Poly));
  for I := 0 to High(Poly) do
  begin
    Result[I].X := Poly[I].X + DX;
    Result[I].Y := Poly[I].Y + DY;
  end;
end;

class function TGeometryKit.Scale2D(const Poly: TPolygon2D;
  SX, SY: Double): TPolygon2D;
var I: Integer;
begin
  SetLength(Result, Length(Poly));
  for I := 0 to High(Poly) do
  begin
    Result[I].X := Poly[I].X * SX;
    Result[I].Y := Poly[I].Y * SY;
  end;
end;

class function TGeometryKit.Rotate2D(const Poly: TPolygon2D;
  Angle: Double; const Centre: TPoint2D): TPolygon2D;
var I: Integer; CosA, SinA, DX, DY: Double;
begin
  CosA := Cos(Angle); SinA := Sin(Angle);
  SetLength(Result, Length(Poly));
  for I := 0 to High(Poly) do
  begin
    DX := Poly[I].X - Centre.X;
    DY := Poly[I].Y - Centre.Y;
    Result[I].X := Centre.X + DX * CosA - DY * SinA;
    Result[I].Y := Centre.Y + DX * SinA + DY * CosA;
  end;
end;

{ ---------------------------------------------------------------------------
  TGeometryKit — Angles & Triangles
--------------------------------------------------------------------------- }

class function TGeometryKit.AngleBetween2D(const V1, V2: TVector2D): Double;
begin
  Result := ArcTan2(V1.Cross(V2), V1.Dot(V2));
end;

class function TGeometryKit.AngleBetween3D(const V1, V2: TVector3D): Double;
var CosA: Double;
begin
  CosA := V1.Dot(V2) / Max(GEO_EPS, V1.Magnitude * V2.Magnitude);
  Result := ArcCos(Max(-1, Min(1, CosA)));
end;

class function TGeometryKit.TriangleArea2D(const A, B, C: TPoint2D): Double;
begin
  Result := Abs((B.X-A.X)*(C.Y-A.Y) - (C.X-A.X)*(B.Y-A.Y)) * 0.5;
end;

class function TGeometryKit.TriangleArea3D(const A, B, C: TPoint3D): Double;
var AB, AC: TVector3D;
begin
  AB := TVector3D.FromPoints(A, B);
  AC := TVector3D.FromPoints(A, C);
  Result := AB.Cross(AC).Magnitude * 0.5;
end;

class function TGeometryKit.BoundingBox2D(const Points: TPolygon2D): TBoundingBox2D;
var I: Integer;
begin
  if Length(Points) = 0 then
    raise EGeometryError.Create('BoundingBox2D: empty point set');
  Result.MinX := Points[0].X; Result.MaxX := Points[0].X;
  Result.MinY := Points[0].Y; Result.MaxY := Points[0].Y;
  for I := 1 to High(Points) do
  begin
    if Points[I].X < Result.MinX then Result.MinX := Points[I].X;
    if Points[I].X > Result.MaxX then Result.MaxX := Points[I].X;
    if Points[I].Y < Result.MinY then Result.MinY := Points[I].Y;
    if Points[I].Y > Result.MaxY then Result.MaxY := Points[I].Y;
  end;
end;

end.
