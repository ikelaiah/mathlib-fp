unit EngineeringLib.Common;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils;

type
  EEngineeringError = class(Exception);
  EFluidDynamicsError = class(EEngineeringError);
  EThermodynamicsError = class(EEngineeringError);
  ESignalError = class(EEngineeringError);
  EUnitConversionError = class(EEngineeringError);

implementation

end.
