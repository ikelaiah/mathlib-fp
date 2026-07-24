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

// Fixed-size vector arithmetic
V := 2.0 * (V1 + V2) / 3.0;

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
  class operator +(const A, B: TVector2D): TVector2D;
  class operator -(const A, B: TVector2D): TVector2D;
  class operator -(const A: TVector2D): TVector2D;
  class operator *(const A: TVector2D; const Scalar: Double): TVector2D;
  class operator *(const Scalar: Double; const A: TVector2D): TVector2D;
  class operator /(const A: TVector2D; const Scalar: Double): TVector2D;
  function ToString: String;
end;

TSegment2D = record
  P, Q: TPoint2D;
  class function Create(const AP, AQ: TPoint2D): TSegment2D; static;
  function Length: Double;
  function Midpoint: TPoint2D;
  function Direction: TVector2D;
  function ToString: String;
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
  class function Create(const ACentre: TPoint2D; ARadius: Double): TCircle2D; static;
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
  class function Create(AX, AY, AZ: Double): TPoint3D; static;
  function DistanceTo(const Other: TPoint3D): Double;
  function ToString: String;
end;

TVector3D = record
  X, Y, Z: Double;
  class function Create(AX, AY, AZ: Double): TVector3D; static;
  class function FromPoints(const P, Q: TPoint3D): TVector3D; static;
  function Magnitude: Double;
  function Normalise: TVector3D;
  function Dot(const V: TVector3D): Double;
  function Cross(const V: TVector3D): TVector3D;
  class operator +(const A, B: TVector3D): TVector3D;
  class operator -(const A, B: TVector3D): TVector3D;
  class operator -(const A: TVector3D): TVector3D;
  class operator *(const A: TVector3D; const Scalar: Double): TVector3D;
  class operator *(const Scalar: Double; const A: TVector3D): TVector3D;
  class operator /(const A: TVector3D; const Scalar: Double): TVector3D;
  function ToString: String;
end;

TSegment3D = record
  P, Q: TPoint3D;
  class function Create(const AP, AQ: TPoint3D): TSegment3D; static;
  function Length: Double;
  function Midpoint: TPoint3D;
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
  class function Create(const ACentre: TPoint3D; ARadius: Double): TSphere3D; static;
  function Volume: Double;
  function SurfaceArea: Double;
  function ContainsPoint(const P: TPoint3D): Boolean;
end;
```

---

## Vector arithmetic

`TVector2D` and `TVector3D` are fixed-size value records. Addition,
subtraction, negation, scalar multiplication, and vector/scalar division are
componentwise and leave both operands unchanged. They allocate no storage, so
assignments such as `V := V + Step` and `V := 2.0 * V` are value-safe.

```pascal
V2 := TVector2D.Create(3, -4) + TVector2D.Create(1, 2);  // (4, -2)
V2 := -V2 / 2.0;                                         // (-2, 1)

V3 := 0.5 * TVector3D.Create(2, 4, 6);                  // (1, 2, 3)
```

For a vector `V` and scalar `S`, `V * S`, `S * V`, and `V / S` apply the
corresponding `Double` operation to every coordinate. The 2-D and 3-D forms
have the same operator set; `Perpendicular` remains the intentionally 2-D
operation.

The arithmetic operators and numeric vector methods are O(1) for these fixed
dimensions and perform no heap allocation on successful calls. They keep no
hidden state and are reentrant. Concurrent calls are safe provided no thread
modifies the same record storage while another thread is reading it.

### Magnitude and normalization

`Magnitude` uses scaled sum-of-squares accumulation. It therefore avoids
premature overflow and underflow when a finite 2-D or 3-D magnitude is
representable. An infinite component makes the magnitude infinite; otherwise a
NaN component makes it NaN.

`Normalise` uses that scale-safe magnitude and accepts every finite, non-zero
vector, including vectors whose components are much smaller than `GEO_EPS` or
whose full magnitude is larger than `Double` can represent. It returns a new
unit vector without changing the source. Exact-zero and non-finite vectors have
no supported direction and raise `EGeometryError`.

The runnable [GeometryLib example](../examples/12_geometry.pas) normalizes both
tiny and near-maximum finite vectors and prints the resulting unit lengths.

### Floating-point behavior

Arithmetic operators use ordinary IEEE-754 `Double` component operations and
do not raise `EGeometryError` for non-finite values. NaN propagates through
the affected coordinate, infinities follow the underlying operation rules, and
finite overflow produces a signed infinity. Signed zero is retained where the
underlying operation retains it. For division by `+0.0` or `-0.0`, a non-zero
finite coordinate produces the corresponding signed infinity; zero divided by
zero produces NaN. Callers who require finite vectors should validate their
inputs and results before using them in a geometric construction. These results
are returned when the corresponding IEEE status exceptions are masked. The
operators do not change the caller's FPU exception mask, so a caller that has
unmasked invalid-operation, zero-divide, or overflow exceptions receives its
configured FPU exception instead.

### Theodorus spiral

The runnable [GeometryLib example](../examples/12_geometry.pas) includes a
compact Theodorus-spiral construction. Each new unit-length perpendicular step
is added with `Radius := Radius + Step`, so the successive radii have lengths
`sqrt(1)`, `sqrt(2)`, and so on without rebuilding a vector coordinate by
coordinate.

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

`SegmentsIntersect2D` includes collinear overlaps. `SegmentIntersect2D` returns
`False` for parallel or collinear segments, so it cannot return a representative
point for an overlapping interval.

### Line–Line (infinite lines, 2-D)

```pascal
if TGeometryKit.LineIntersect2D(A1, A2, B1, B2, Pt) then
  WriteLn('Lines meet at ', Pt.ToString);
```

### Segment–Circle and Ray–Circle

```pascal
// Does segment PQ touch, cross, or lie inside circle C?
if TGeometryKit.SegmentCircleIntersect(P, Q, C) then ...

// Ray from Origin in Direction vs circle C
// Returns 0, 1, or 2; T1 ≤ T2 are the hit distances
N := TGeometryKit.RayCircleIntersect(Origin, Dir, C, T1, T2);
```

`Direction` is normalised internally, so the returned `T` values are forward
distances along the ray. Intersections behind the origin are discarded. A ray
starting inside the circle has one forward hit; a tangent has one hit.

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

Uses ray casting and works for concave simple polygons. Points on an edge or
vertex are classified as inside. Self-intersecting polygons and polygons with
holes are unsupported.

### Convexity & Convex Hull

```pascal
// Is the polygon convex?
if TGeometryKit.IsConvex(Poly) then ...

// Compute convex hull (monotone chain)
Hull := TGeometryKit.ConvexHull(Points);
// Hull vertices are in CCW order
```

Points are ordered in O(n log n) average time before the linear monotone-chain
scan. Collinear interior boundary points are discarded. At least three input
points are required; all-collinear input produces the two extreme endpoints.

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

Angle helpers reject zero-length vectors because their mutual angle is
undefined.

---

## Error Handling

`EGeometryError` is raised for:
- Normalising a zero-length or non-finite vector
- `TLine2D.FromPoints` with two identical points
- `TPlane3D.FromThreePoints` with collinear points
- `PolygonArea`, `PolygonCentroid`, `IsConvex` with fewer than 3 vertices
- `ConvexHull` with fewer than 3 points
- `BoundingBox2D` with an empty point set
- `PolygonCentroid` on a degenerate (zero-area) polygon
- `RayCircleIntersect` with a zero-length direction
- Circle or sphere construction with a negative or non-finite radius
- `AngleBetween2D` / `AngleBetween3D` with a zero-length vector

---

## Dependencies

- `MathBase.SharedTypes` — `TDoubleArray`

No other external libraries required.
