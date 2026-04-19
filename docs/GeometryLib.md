# GeometryLib Reference

`GeometryLib.Geometry` — 2-D and 3-D computational geometry for Free Pascal.

---

## Quick Start

```pascal
uses GeometryLib.Geometry;

// Distance from a point to a line segment
T := 0;
D := TGeometryKit.PointToSegment2D(P, A, B, T);

// Do two segments cross?
if TGeometryKit.SegmentsIntersect2D(A1, A2, B1, B2) then ...

// Convex hull of a point cloud
Hull := TGeometryKit.ConvexHull(Points);

// Point-in-polygon test
if TGeometryKit.PointInPolygon(Mouse, Boundary) then ...
```

All methods are **class static** — no `Create`/`Free` needed.

---

## Types

### 2-D

```pascal
TPoint2D = record
  X, Y: Double;
  class function Create(AX, AY: Double): TPoint2D; static;
  function DistanceTo(const Other: TPoint2D): Double;
  function ToString: String;
end;

TVector2D = record
  X, Y: Double;
  class function Create(AX, AY: Double): TVector2D; static;
  class function FromPoints(const P, Q: TPoint2D): TVector2D; static;
  function Magnitude: Double;
  function Normalise: TVector2D;
  function Dot(const V: TVector2D): Double;
  function Cross(const V: TVector2D): Double;    { 2-D scalar (z-component) }
  function Perpendicular: TVector2D;             { rotate 90° CCW }
end;

TSegment2D = record
  P, Q: TPoint2D;
  function Length: Double;
  function Midpoint: TPoint2D;
  function Direction: TVector2D;
end;

TLine2D = record
  A, B, C: Double;    { ax + by + c = 0, unit normal }
  class function FromPoints(const P, Q: TPoint2D): TLine2D; static;
  function SignedDistance(const P: TPoint2D): Double;
  function Distance(const P: TPoint2D): Double;
  function ClosestPoint(const P: TPoint2D): TPoint2D;
end;

TCircle2D = record
  Centre: TPoint2D;
  Radius: Double;
  function Area: Double;
  function Circumference: Double;
  function ContainsPoint(const P: TPoint2D): Boolean;
end;

TPolygon2D = array of TPoint2D;

TBoundingBox2D = record
  MinX, MinY, MaxX, MaxY: Double;
  function Width: Double;
  function Height: Double;
  function Area: Double;
  function ContainsPoint(const P: TPoint2D): Boolean;
end;
```

### 3-D

```pascal
TPoint3D = record
  X, Y, Z: Double;
  function DistanceTo(const Other: TPoint3D): Double;
end;

TVector3D = record
  X, Y, Z: Double;
  function Magnitude: Double;
  function Normalise: TVector3D;
  function Dot(const V: TVector3D): Double;
  function Cross(const V: TVector3D): TVector3D;
end;

TPlane3D = record
  A, B, C, D: Double;   { ax + by + cz + d = 0, unit normal }
  class function FromPointNormal(const P: TPoint3D; const N: TVector3D): TPlane3D; static;
  class function FromThreePoints(const P1, P2, P3: TPoint3D): TPlane3D; static;
  function SignedDistance(const P: TPoint3D): Double;
  function Distance(const P: TPoint3D): Double;
  function ClosestPoint(const P: TPoint3D): TPoint3D;
end;

TSphere3D = record
  Centre: TPoint3D;
  Radius: Double;
  function Volume: Double;
  function SurfaceArea: Double;
  function ContainsPoint(const P: TPoint3D): Boolean;
end;
```

---

## Distance Functions

### 2-D

```pascal
D := TGeometryKit.PointToPoint2D(A, B);

D := TGeometryKit.PointToSegment2D(P, A, B, T);
// T: parameter in [0,1] of nearest point on segment AB
// T=0 → nearest is A; T=1 → nearest is B

D := TGeometryKit.PointToLine2D(P, A, B);

D := TGeometryKit.SegmentToSegment2D(A1, A2, B1, B2);
// Returns 0 if segments cross or touch
```

### 3-D

```pascal
D := TGeometryKit.PointToPoint3D(A, B);
D := TGeometryKit.PointToSegment3D(P, A, B, T);
D := TGeometryKit.PointToPlane3D(P, Plane);
```

---

## Intersection Tests

### Segment–Segment (2-D)

```pascal
// Boolean test (fast)
if TGeometryKit.SegmentsIntersect2D(A1, A2, B1, B2) then ...

// Find exact point and parameter
if TGeometryKit.SegmentIntersect2D(A1, A2, B1, B2, Pt, T) then
  WriteLn('Intersects at ', Pt.ToString, ' T=', T:6:4);
```

### Line–Line (infinite lines, 2-D)

```pascal
if TGeometryKit.LineIntersect2D(A1, A2, B1, B2, Pt) then
  WriteLn('Lines meet at ', Pt.ToString);
```

### Segment–Circle and Ray–Circle

```pascal
// Does segment PQ cross circle C?
if TGeometryKit.SegmentCircleIntersect(P, Q, C) then ...

// Ray from Origin in Direction vs circle C
// Returns 0, 1, or 2; T1 ≤ T2 are the hit distances
N := TGeometryKit.RayCircleIntersect(Origin, Dir, C, T1, T2);
```

---

## Polygon Operations

### Area, Perimeter, Centroid

```pascal
Area      := TGeometryKit.PolygonArea(Poly);       // positive = CCW
Perimeter := TGeometryKit.PolygonPerimeter(Poly);
Centroid  := TGeometryKit.PolygonCentroid(Poly);
```

### Point-in-Polygon

```pascal
if TGeometryKit.PointInPolygon(P, Poly) then
  WriteLn('Inside');
```

Uses ray casting — works for concave polygons. Does not handle self-intersecting polygons.

### Convexity & Convex Hull

```pascal
// Is the polygon convex?
if TGeometryKit.IsConvex(Poly) then ...

// Compute convex hull (Graham scan, O(n log n))
Hull := TGeometryKit.ConvexHull(Points);
// Hull vertices are in CCW order
```

---

## Transformations (2-D)

```pascal
// Shift all vertices by (DX, DY)
Moved    := TGeometryKit.Translate2D(Poly, DX, DY);

// Scale about the origin
Scaled   := TGeometryKit.Scale2D(Poly, SX, SY);

// Rotate CCW by Angle radians about Centre
Rotated  := TGeometryKit.Rotate2D(Poly, Angle, Centre);
```

All transformation functions return a **new** polygon — the original is unchanged.

---

## Angles & Utility

```pascal
// Signed angle from V1 to V2 (2-D), range −π..π
Angle := TGeometryKit.AngleBetween2D(V1, V2);

// Unsigned angle between V1 and V2 (3-D), range 0..π
Angle := TGeometryKit.AngleBetween3D(V1, V2);

// Triangle area
A2 := TGeometryKit.TriangleArea2D(P1, P2, P3);
A3 := TGeometryKit.TriangleArea3D(P1, P2, P3);

// Axis-aligned bounding box
BB := TGeometryKit.BoundingBox2D(Points);
// BB.MinX, BB.MaxX, BB.MinY, BB.MaxY, BB.Width, BB.Height, BB.Area
```

---

## Error Handling

`EGeometryError` is raised for:
- Normalising a zero-length vector
- `TLine2D.FromPoints` with two identical points
- `TPlane3D.FromThreePoints` with collinear points
- `PolygonArea`, `PolygonCentroid`, `IsConvex` with fewer than 3 vertices
- `ConvexHull` with fewer than 3 points
- `BoundingBox2D` with an empty point set
- `PolygonCentroid` on a degenerate (zero-area) polygon

---

## Dependencies

- `MathBase.SharedTypes` — `TDoubleArray`

No other external libraries required.
