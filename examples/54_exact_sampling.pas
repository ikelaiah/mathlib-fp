program ExactSampling;

{$mode objfpc}{$H+}{$J-}

uses
  CombinatoricsLib.Combinatorics, MathBase.ExactArithmetic;

var
  Total, Marked: TBigInteger;
  Probability: TBigRational;
begin
  { Choose fifty units from a lot with fifty marked and fifty unmarked
    units. Exactly twenty-five marked means choosing twenty-five of each. }
  Total := TCombinatoricsKit.CombinationExact(100, 50);
  Marked := TCombinatoricsKit.CombinationExact(50, 25);
  Probability := TBigRational.FromRatio(Marked * Marked, Total);
  if (Total.ToText <> '100891344545564193334812497256') or
    (Probability.ToText <> '2110031698716658293304/13322197258529868226331') then
    Halt(1);
  Writeln('C(100, 50) = ', Total.ToText);
  Writeln('exact probability = ', Probability.ToText);
  Writeln('exact sampling: success');
end.
