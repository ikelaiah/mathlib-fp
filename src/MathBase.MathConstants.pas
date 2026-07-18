unit MathBase.MathConstants;

{-----------------------------------------------------------------------------
 MathBase.MathConstants

 Mathematical and physical constants used across mathlib-fp.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

const
  { Ratio of a circle's circumference to its diameter }
  MathPi         = 3.14159265358979323846;
  { Base of the natural logarithm }
  MathE          = 2.71828182845904523536;
  { Golden ratio }
  MathPhi        = 1.61803398874989484820;
  { Square root of 2 }
  MathSqrt2      = 1.41421356237309504880;
  { Natural logarithm of 2 }
  MathLn2        = 0.69314718055994530942;
  { Natural logarithm of 10 }
  MathLn10       = 2.30258509299404568402;

  { Physics constants }
  { Boltzmann constant (J/K) }
  BoltzmannConst        = 1.380649e-23;
  { Stefan-Boltzmann constant (W/m²/K⁴) }
  StefanBoltzmannConst  = 5.670374419e-8;
  { Universal gas constant (J/mol/K) }
  IdealGasConst         = 8.314462618;
  { Avogadro constant (1/mol) }
  AvogadroConst         = 6.02214076e23;
  { Standard acceleration of gravity (m/s²) }
  StandardGravity       = 9.80665;
  { Standard atmospheric pressure (Pa) }
  StandardAtmosphere    = 101325.0;
  { Standard temperature (K) — 0°C }
  StandardTemperature   = 273.15;

implementation

end.
