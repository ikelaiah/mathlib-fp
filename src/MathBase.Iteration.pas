unit MathBase.Iteration;

{ Shared termination vocabulary for iterative numerical algorithms.

  The enumeration is deliberately independent of a solver domain. Result
  records retain the best finite iterate and use this status to distinguish
  ordinary convergence from usable limits and expected failure modes. }

{$mode objfpc}{$H+}{$J-}

interface

type
  TIterationStatus = (
    isUnknown,
    isConverged,
    isAcceptableLimit,
    isStagnation,
    isNumericalBreakdown,
    isInfeasible,
    isUnbounded,
    isIterationLimit,
    isCancelled
  );

function IterationStatusName(const Status: TIterationStatus): String;

implementation

function IterationStatusName(const Status: TIterationStatus): String;
begin
  case Status of
    isConverged:          Result := 'converged';
    isAcceptableLimit:    Result := 'acceptable limit';
    isStagnation:         Result := 'stagnation';
    isNumericalBreakdown: Result := 'numerical breakdown';
    isInfeasible:         Result := 'infeasible';
    isUnbounded:          Result := 'unbounded';
    isIterationLimit:     Result := 'iteration limit';
    isCancelled:          Result := 'cancelled';
  else
    Result := 'unknown';
  end;
end;

end.
