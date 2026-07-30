unit StatsLib.Inference;

{ Statistical distributions, estimation, hypothesis tests, and regression
  diagnostics. Public arrays are owned by result records. Random sampling uses
  caller-owned TLocalRandom state and never touches the RTL global generator. }

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math,
  MathBase.SharedTypes, MathBase.Iteration, MathBase.Random,
  ProbabilityLib.Distributions,
  AlgebraLib.DenseMatrices, AlgebraLib.DenseDecompositions;

type
  EInferenceError = class(Exception);
  TCountMatrix = array of TIntegerArray;

  TNormalDistribution = record
    Mean, StandardDeviation:Double;
    class function Create(const MeanValue,StandardDeviationValue:Double):
      TNormalDistribution; static;
    function PDF(const X:Double):Double;
    function LogPDF(const X:Double):Double;
    function CDF(const X:Double):Double;
    function Survival(const X:Double):Double;
    function Quantile(const Probability:Double):Double;
    function Sample(var Random:TLocalRandom):Double;
  end;

  TExponentialDistribution = record
    Rate:Double;
    class function Create(const RateValue:Double):TExponentialDistribution;
      static;
    function PDF(const X:Double):Double;
    function LogPDF(const X:Double):Double;
    function CDF(const X:Double):Double;
    function Survival(const X:Double):Double;
    function Quantile(const Probability:Double):Double;
    function Sample(var Random:TLocalRandom):Double;
  end;

  TBinomialDistribution = record
    Trials:Integer;
    Probability:Double;
    class function Create(const TrialCount:Integer;
      const SuccessProbability:Double):TBinomialDistribution; static;
    function PMF(const Successes:Integer):Double;
    function LogPMF(const Successes:Integer):Double;
    function CDF(const Successes:Integer):Double;
    function Survival(const Successes:Integer):Double;
    function Quantile(const CumulativeProbability:Double):Integer;
    function Sample(var Random:TLocalRandom):Integer;
  end;

  TDistributionEstimate = record
    Parameters:TDoubleArray;
    StandardErrors:TDoubleArray;
    LogLikelihood:Double;
    Iterations:Integer;
    Status:TIterationStatus;
    Identifiable:Boolean;
  end;

  TInferenceTestResult = record
    Statistic:Double;
    PValue:Double;
    DegreesOfFreedom:Double;
    EffectSize:Double;
    ConfidenceLow:Double;
    ConfidenceHigh:Double;
  end;

  TANOVAResult = record
    FStatistic:Double;
    PValue:Double;
    BetweenDegreesOfFreedom:Integer;
    WithinDegreesOfFreedom:Integer;
    EtaSquared:Double;
  end;

  TContingencyResult = record
    ChiSquare:Double;
    PValue:Double;
    DegreesOfFreedom:Integer;
    CramersV:Double;
  end;

  TRegressionDiagnostics = record
    Coefficients:TDoubleArray;
    StandardErrors:TDoubleArray;
    Fitted:TDoubleArray;
    Residuals:TDoubleArray;
    RSquared:Double;
    AdjustedRSquared:Double;
    Rank:Integer;
    DegreesOfFreedom:Integer;
    Status:TIterationStatus;
  end;

  TLogisticRegressionResult = record
    Coefficients:TDoubleArray;
    StandardErrors:TDoubleArray;
    Probabilities:TDoubleArray;
    Deviance:Double;
    Iterations:Integer;
    Status:TIterationStatus;
    Identifiable:Boolean;
  end;

  TInferenceKit = class
  public
    class function EstimateNormal(const Samples:TDoubleArray):
      TDistributionEstimate; static;
    class function EstimateExponential(const Samples:TDoubleArray):
      TDistributionEstimate; static;
    class function EstimateGamma(const Samples:TDoubleArray):
      TDistributionEstimate; static;
    class function EstimateBinomial(const Successes,Trials:Integer):
      TDistributionEstimate; static;

    class function OneSampleT(const Samples:TDoubleArray;
      const NullMean:Double=0; const ConfidenceLevel:Double=0.95):
      TInferenceTestResult; static;
    class function PairedT(const A,B:TDoubleArray;
      const ConfidenceLevel:Double=0.95):TInferenceTestResult; static;
    class function WelchT(const A,B:TDoubleArray;
      const ConfidenceLevel:Double=0.95):TInferenceTestResult; static;
    class function OneWayANOVA(const Groups:array of TDoubleArray):
      TANOVAResult; static;
    class function ChiSquareContingency(const Counts:TCountMatrix):
      TContingencyResult; static;
    class function MannWhitneyU(const A,B:TDoubleArray):
      TInferenceTestResult; static;
    class function AdjustBonferroni(const PValues:TDoubleArray):
      TDoubleArray; static;
    class function AdjustBenjaminiHochberg(const PValues:TDoubleArray):
      TDoubleArray; static;

    class function FitOLS(const Design:IDenseDoubleMatrix;
      const Response:TDoubleArray):TRegressionDiagnostics; static;
    class function FitLogistic(const Design:IDenseDoubleMatrix;
      const Labels:TIntegerArray; const MaxIterations:Integer=100;
      const Tolerance:Double=1E-8):TLogisticRegressionResult; static;
  end;

implementation

const
  LN_TWO_PI=1.837877066409345483560659472811;

function Finite(const X:Double):Boolean; inline;
begin Result:=not IsNan(X) and not IsInfinite(X); end;

procedure RequireProbability(const P:Double; const Name:String;
  AllowEndpoints:Boolean=True);
begin
  if not Finite(P) or
     (AllowEndpoints and ((P<0) or (P>1))) or
     ((not AllowEndpoints) and ((P<=0) or (P>=1))) then
    raise EInferenceError.Create(Name+': probability is outside its valid range.');
end;

procedure RequireSamples(const X:TDoubleArray; const Name:String;
  MinCount:Integer=1; Positive:Boolean=False);
var I:Integer; Qualification:String;
begin
  if Positive then Qualification:=' and positive' else Qualification:='';
  if Length(X)<MinCount then
    raise EInferenceError.CreateFmt('%s: at least %d samples are required.',
      [Name,MinCount]);
  for I:=0 to High(X) do
    if not Finite(X[I]) or (Positive and (X[I]<=0)) then
      raise EInferenceError.CreateFmt(
        '%s: sample %d must be finite%s.',[Name,I,
        Qualification]);
end;

function MeanVariance(const X:TDoubleArray; out Mean,Variance:Double):Integer;
var
  I:Integer;
  Delta,M2:Double;
begin
  Mean:=0; M2:=0;
  for I:=0 to High(X) do
  begin
    Delta:=X[I]-Mean;
    Mean:=Mean+Delta/(I+1);
    M2:=M2+Delta*(X[I]-Mean);
  end;
  Result:=Length(X);
  if Length(X)>1 then Variance:=M2/(Length(X)-1) else Variance:=0;
end;

function NormalQuantile(const P:Double):Double;
var
  Lo,Hi,Mid:Double;
  I:Integer;
begin
  RequireProbability(P,'Normal quantile');
  if P=0 then Exit(-Infinity);
  if P=1 then Exit(Infinity);
  Lo:=-40; Hi:=40;
  for I:=1 to 100 do
  begin
    Mid:=(Lo+Hi)/2;
    if TProbabilityKit.NormalCDF(Mid,0,1)<P then Lo:=Mid else Hi:=Mid;
  end;
  Result:=(Lo+Hi)/2;
end;

function StudentQuantile(const P:Double; DF:Integer):Double;
var
  Lo,Hi,Mid:Double;
  I:Integer;
begin
  RequireProbability(P,'Student t quantile',False);
  Lo:=-1E6; Hi:=1E6;
  for I:=1 to 100 do
  begin
    Mid:=(Lo+Hi)/2;
    if TProbabilityKit.StudentTCDF(Mid,DF)<P then Lo:=Mid else Hi:=Mid;
  end;
  Result:=(Lo+Hi)/2;
end;

class function TNormalDistribution.Create(const MeanValue,
  StandardDeviationValue:Double):TNormalDistribution;
begin
  if not Finite(MeanValue) or not Finite(StandardDeviationValue) or
     (StandardDeviationValue<=0) then
    raise EInferenceError.Create(
      'TNormalDistribution.Create: mean must be finite and standard deviation positive.');
  Result.Mean:=MeanValue;
  Result.StandardDeviation:=StandardDeviationValue;
end;

function TNormalDistribution.PDF(const X:Double):Double;
begin Result:=TProbabilityKit.NormalPDF(X,Mean,StandardDeviation); end;

function TNormalDistribution.LogPDF(const X:Double):Double;
var Z:Double;
begin
  if not Finite(X) then
    raise EInferenceError.Create('Normal LogPDF: X must be finite.');
  Z:=(X-Mean)/StandardDeviation;
  Result:=-0.5*LN_TWO_PI-Ln(StandardDeviation)-0.5*Z*Z;
end;

function TNormalDistribution.CDF(const X:Double):Double;
begin Result:=TProbabilityKit.NormalCDF(X,Mean,StandardDeviation); end;

function TNormalDistribution.Survival(const X:Double):Double;
begin Result:=TProbabilityKit.NormalSurvival(X,Mean,StandardDeviation); end;

function TNormalDistribution.Quantile(const Probability:Double):Double;
begin Result:=Mean+StandardDeviation*NormalQuantile(Probability); end;

function TNormalDistribution.Sample(var Random:TLocalRandom):Double;
begin Result:=Mean+StandardDeviation*Random.NextNormal; end;

class function TExponentialDistribution.Create(
  const RateValue:Double):TExponentialDistribution;
begin
  if not Finite(RateValue) or (RateValue<=0) then
    raise EInferenceError.Create(
      'TExponentialDistribution.Create: rate must be finite and positive.');
  Result.Rate:=RateValue;
end;

function TExponentialDistribution.PDF(const X:Double):Double;
begin Result:=TProbabilityKit.ExponentialPDF(X,Rate); end;

function TExponentialDistribution.LogPDF(const X:Double):Double;
begin
  if not Finite(X) then
    raise EInferenceError.Create('Exponential LogPDF: X must be finite.');
  if X<0 then Exit(-Infinity);
  Result:=Ln(Rate)-Rate*X;
end;

function TExponentialDistribution.CDF(const X:Double):Double;
begin Result:=TProbabilityKit.ExponentialCDF(X,Rate); end;

function TExponentialDistribution.Survival(const X:Double):Double;
begin Result:=TProbabilityKit.ExponentialSurvival(X,Rate); end;

function TExponentialDistribution.Quantile(const Probability:Double):Double;
begin
  RequireProbability(Probability,'Exponential quantile');
  if Probability=1 then Exit(Infinity);
  Result:=-Ln(1-Probability)/Rate;
end;

function TExponentialDistribution.Sample(var Random:TLocalRandom):Double;
var U:Double;
begin
  repeat U:=Random.NextDouble until U>0;
  Result:=-Ln(U)/Rate;
end;

class function TBinomialDistribution.Create(const TrialCount:Integer;
  const SuccessProbability:Double):TBinomialDistribution;
begin
  if TrialCount<1 then
    raise EInferenceError.Create(
      'TBinomialDistribution.Create: trials must be positive.');
  RequireProbability(SuccessProbability,'Binomial success probability');
  Result.Trials:=TrialCount;
  Result.Probability:=SuccessProbability;
end;

function TBinomialDistribution.PMF(const Successes:Integer):Double;
begin Result:=TProbabilityKit.BinomialPMF(Successes,Trials,Probability); end;

function TBinomialDistribution.LogPMF(const Successes:Integer):Double;
var V:Double;
begin
  V:=PMF(Successes);
  if V=0 then Result:=-Infinity else Result:=Ln(V);
end;

function TBinomialDistribution.CDF(const Successes:Integer):Double;
begin Result:=TProbabilityKit.BinomialCDF(Successes,Trials,Probability); end;

function TBinomialDistribution.Survival(const Successes:Integer):Double;
begin
  Result:=TProbabilityKit.BinomialSurvival(Successes,Trials,Probability);
end;

function TBinomialDistribution.Quantile(
  const CumulativeProbability:Double):Integer;
begin
  RequireProbability(CumulativeProbability,'Binomial quantile');
  Result:=0;
  while (Result<Trials) and (CDF(Result)<CumulativeProbability) do Inc(Result);
end;

function TBinomialDistribution.Sample(var Random:TLocalRandom):Integer;
var I:Integer;
begin
  Result:=0;
  for I:=1 to Trials do
    if Random.NextDouble<Probability then Inc(Result);
end;

class function TInferenceKit.EstimateNormal(
  const Samples:TDoubleArray):TDistributionEstimate;
var
  Mean,Variance,MLEVariance,Delta:Double;
  I,N:Integer;
begin
  Result:=Default(TDistributionEstimate);
  RequireSamples(Samples,'EstimateNormal',2);
  N:=MeanVariance(Samples,Mean,Variance);
  MLEVariance:=Variance*(N-1)/N;
  SetLength(Result.Parameters,2);
  SetLength(Result.StandardErrors,2);
  Result.Parameters[0]:=Mean;
  Result.Parameters[1]:=Sqrt(MLEVariance);
  if Result.Parameters[1]<=0 then
  begin
    Result.Status:=isNumericalBreakdown;
    Result.Identifiable:=False;
    Exit;
  end;
  Result.StandardErrors[0]:=Result.Parameters[1]/Sqrt(N);
  Result.StandardErrors[1]:=Result.Parameters[1]/Sqrt(2*N);
  Result.LogLikelihood:=0;
  for I:=0 to High(Samples) do
  begin
    Delta:=(Samples[I]-Mean)/Result.Parameters[1];
    Result.LogLikelihood:=Result.LogLikelihood-0.5*LN_TWO_PI-
      Ln(Result.Parameters[1])-0.5*Delta*Delta;
  end;
  Result.Identifiable:=Result.Parameters[1]>0;
  if Result.Identifiable then Result.Status:=isConverged
  else Result.Status:=isNumericalBreakdown;
end;

class function TInferenceKit.EstimateExponential(
  const Samples:TDoubleArray):TDistributionEstimate;
var
  Sum:Double;
  I,N:Integer;
begin
  Result:=Default(TDistributionEstimate);
  RequireSamples(Samples,'EstimateExponential',1,True);
  Sum:=0;
  for I:=0 to High(Samples) do Sum:=Sum+Samples[I];
  N:=Length(Samples);
  SetLength(Result.Parameters,1);
  SetLength(Result.StandardErrors,1);
  Result.Parameters[0]:=N/Sum;
  Result.StandardErrors[0]:=Result.Parameters[0]/Sqrt(N);
  Result.LogLikelihood:=N*Ln(Result.Parameters[0])-
    Result.Parameters[0]*Sum;
  Result.Identifiable:=True;
  Result.Status:=isConverged;
end;

class function TInferenceKit.EstimateGamma(
  const Samples:TDoubleArray):TDistributionEstimate;
var
  Mean,Variance,Pdf:Double;
  I,N:Integer;
begin
  Result:=Default(TDistributionEstimate);
  RequireSamples(Samples,'EstimateGamma',2,True);
  N:=MeanVariance(Samples,Mean,Variance);
  SetLength(Result.Parameters,2);
  SetLength(Result.StandardErrors,2);
  if Variance<=0 then
  begin
    Result.Status:=isNumericalBreakdown;
    Result.Identifiable:=False;
    Exit;
  end;
  { Method-of-moments baseline: shape alpha and rate beta. }
  Result.Parameters[0]:=Sqr(Mean)/Variance;
  Result.Parameters[1]:=Mean/Variance;
  Result.StandardErrors[0]:=Result.Parameters[0]*Sqrt(2/N);
  Result.StandardErrors[1]:=Result.Parameters[1]/Sqrt(N);
  Result.LogLikelihood:=0;
  for I:=0 to High(Samples) do
  begin
    Pdf:=TProbabilityKit.GammaPDF(Samples[I],Result.Parameters[0],
      Result.Parameters[1]);
    if Pdf<=0 then Result.LogLikelihood:=-Infinity
    else if not IsInfinite(Result.LogLikelihood) then
      Result.LogLikelihood:=Result.LogLikelihood+Ln(Pdf);
  end;
  Result.Identifiable:=True;
  Result.Status:=isAcceptableLimit;
end;

class function TInferenceKit.EstimateBinomial(const Successes,
  Trials:Integer):TDistributionEstimate;
var P:Double;
begin
  Result:=Default(TDistributionEstimate);
  if (Trials<1) or (Successes<0) or (Successes>Trials) then
    raise EInferenceError.Create(
      'EstimateBinomial: require 0 <= successes <= positive trials.');
  P:=Successes/Trials;
  SetLength(Result.Parameters,1);
  SetLength(Result.StandardErrors,1);
  Result.Parameters[0]:=P;
  Result.StandardErrors[0]:=Sqrt(P*(1-P)/Trials);
  Result.LogLikelihood:=TBinomialDistribution.Create(Trials,P).
    LogPMF(Successes);
  Result.Identifiable:=(Successes>0) and (Successes<Trials);
  if Result.Identifiable then Result.Status:=isConverged
  else Result.Status:=isAcceptableLimit;
end;

class function TInferenceKit.OneSampleT(const Samples:TDoubleArray;
  const NullMean,ConfidenceLevel:Double):TInferenceTestResult;
var
  Mean,Variance,SE,Critical:Double;
  N,DF:Integer;
begin
  Result:=Default(TInferenceTestResult);
  RequireSamples(Samples,'OneSampleT',2);
  RequireProbability(ConfidenceLevel,'OneSampleT confidence',False);
  N:=MeanVariance(Samples,Mean,Variance);
  if Variance<=0 then
    raise EInferenceError.Create('OneSampleT: sample variance must be positive.');
  DF:=N-1; SE:=Sqrt(Variance/N);
  Result.Statistic:=(Mean-NullMean)/SE;
  Result.PValue:=TProbabilityKit.StudentTTwoTail(Result.Statistic,DF);
  Result.DegreesOfFreedom:=DF;
  Result.EffectSize:=(Mean-NullMean)/Sqrt(Variance);
  Critical:=StudentQuantile(0.5+ConfidenceLevel/2,DF);
  Result.ConfidenceLow:=Mean-Critical*SE;
  Result.ConfidenceHigh:=Mean+Critical*SE;
end;

class function TInferenceKit.PairedT(const A,B:TDoubleArray;
  const ConfidenceLevel:Double):TInferenceTestResult;
var
  Difference:TDoubleArray;
  I:Integer;
begin
  if Length(A)<>Length(B) then
    raise EInferenceError.Create('PairedT: sample lengths must match.');
  RequireSamples(A,'PairedT A',2);
  RequireSamples(B,'PairedT B',2);
  SetLength(Difference,Length(A));
  for I:=0 to High(A) do Difference[I]:=A[I]-B[I];
  Result:=OneSampleT(Difference,0,ConfidenceLevel);
end;

class function TInferenceKit.WelchT(const A,B:TDoubleArray;
  const ConfidenceLevel:Double):TInferenceTestResult;
var
  MeanA,MeanB,VarA,VarB,SE2,DF,Critical:Double;
  NA,NB,DFRounded:Integer;
begin
  Result:=Default(TInferenceTestResult);
  RequireSamples(A,'WelchT A',2); RequireSamples(B,'WelchT B',2);
  RequireProbability(ConfidenceLevel,'WelchT confidence',False);
  NA:=MeanVariance(A,MeanA,VarA); NB:=MeanVariance(B,MeanB,VarB);
  SE2:=VarA/NA+VarB/NB;
  if SE2<=0 then
    raise EInferenceError.Create('WelchT: pooled standard error is zero.');
  Result.Statistic:=(MeanA-MeanB)/Sqrt(SE2);
  DF:=Sqr(SE2)/(Sqr(VarA/NA)/(NA-1)+Sqr(VarB/NB)/(NB-1));
  DFRounded:=Max(1,Round(DF));
  Result.PValue:=TProbabilityKit.StudentTTwoTail(
    Result.Statistic,DFRounded);
  Result.DegreesOfFreedom:=DF;
  Result.EffectSize:=(MeanA-MeanB)/Sqrt(
    ((NA-1)*VarA+(NB-1)*VarB)/(NA+NB-2));
  Critical:=StudentQuantile(0.5+ConfidenceLevel/2,DFRounded);
  Result.ConfidenceLow:=(MeanA-MeanB)-Critical*Sqrt(SE2);
  Result.ConfidenceHigh:=(MeanA-MeanB)+Critical*Sqrt(SE2);
end;

class function TInferenceKit.OneWayANOVA(
  const Groups:array of TDoubleArray):TANOVAResult;
var
  I,J,TotalN:Integer;
  GroupMean,GroupVariance,GrandMean,SSBetween,SSWithin,SSTotal:Double;
begin
  Result:=Default(TANOVAResult);
  if Length(Groups)<2 then
    raise EInferenceError.Create('OneWayANOVA: at least two groups are required.');
  TotalN:=0; GrandMean:=0;
  for I:=0 to High(Groups) do
  begin
    RequireSamples(Groups[I],'OneWayANOVA group',2);
    for J:=0 to High(Groups[I]) do GrandMean:=GrandMean+Groups[I][J];
    Inc(TotalN,Length(Groups[I]));
  end;
  GrandMean:=GrandMean/TotalN;
  SSBetween:=0; SSWithin:=0;
  for I:=0 to High(Groups) do
  begin
    MeanVariance(Groups[I],GroupMean,GroupVariance);
    SSBetween:=SSBetween+Length(Groups[I])*Sqr(GroupMean-GrandMean);
    SSWithin:=SSWithin+(Length(Groups[I])-1)*GroupVariance;
  end;
  Result.BetweenDegreesOfFreedom:=Length(Groups)-1;
  Result.WithinDegreesOfFreedom:=TotalN-Length(Groups);
  if SSWithin=0 then
    raise EInferenceError.Create('OneWayANOVA: within-group variance is zero.');
  Result.FStatistic:=(SSBetween/Result.BetweenDegreesOfFreedom)/
    (SSWithin/Result.WithinDegreesOfFreedom);
  Result.PValue:=TProbabilityKit.FSurvival(Result.FStatistic,
    Result.BetweenDegreesOfFreedom,Result.WithinDegreesOfFreedom);
  SSTotal:=SSBetween+SSWithin;
  if SSTotal>0 then Result.EtaSquared:=SSBetween/SSTotal;
end;

class function TInferenceKit.ChiSquareContingency(
  const Counts:TCountMatrix):TContingencyResult;
var
  RowTotals,ColumnTotals:TDoubleArray;
  I,J,Rows,Cols,Total,Expected:Integer;
  ExpectedValue:Double;
begin
  Result:=Default(TContingencyResult);
  Rows:=Length(Counts);
  if Rows<2 then
    raise EInferenceError.Create(
      'ChiSquareContingency: at least two rows are required.');
  Cols:=Length(Counts[0]);
  if Cols<2 then
    raise EInferenceError.Create(
      'ChiSquareContingency: at least two columns are required.');
  SetLength(RowTotals,Rows); SetLength(ColumnTotals,Cols); Total:=0;
  for I:=0 to Rows-1 do
  begin
    if Length(Counts[I])<>Cols then
      raise EInferenceError.Create(
        'ChiSquareContingency: count matrix must be rectangular.');
    for J:=0 to Cols-1 do
    begin
      if Counts[I][J]<0 then
        raise EInferenceError.Create(
          'ChiSquareContingency: counts must be non-negative.');
      RowTotals[I]:=RowTotals[I]+Counts[I][J];
      ColumnTotals[J]:=ColumnTotals[J]+Counts[I][J];
      Inc(Total,Counts[I][J]);
    end;
  end;
  if Total=0 then
    raise EInferenceError.Create(
      'ChiSquareContingency: total count must be positive.');
  for I:=0 to Rows-1 do for J:=0 to Cols-1 do
  begin
    ExpectedValue:=RowTotals[I]*ColumnTotals[J]/Total;
    if ExpectedValue<=0 then
      raise EInferenceError.Create(
        'ChiSquareContingency: every row and column total must be positive.');
    Result.ChiSquare:=Result.ChiSquare+
      Sqr(Counts[I][J]-ExpectedValue)/ExpectedValue;
  end;
  Result.DegreesOfFreedom:=(Rows-1)*(Cols-1);
  Result.PValue:=TProbabilityKit.ChiSquaredSurvival(Result.ChiSquare,
    Result.DegreesOfFreedom);
  Expected:=Min(Rows-1,Cols-1);
  Result.CramersV:=Sqrt(Result.ChiSquare/(Total*Expected));
end;

class function TInferenceKit.MannWhitneyU(const A,B:TDoubleArray):
  TInferenceTestResult;
type
  TRankItem=record Value:Double; Group:Integer; end;
var
  Items:array of TRankItem;
  I,J,K,N,NA,NB:Integer;
  Temp:TRankItem;
  RankSumA,RankValue,TieTerm,VarianceU,MeanU,Z,U1,U2:Double;
begin
  Result:=Default(TInferenceTestResult);
  RequireSamples(A,'MannWhitneyU A',1);
  RequireSamples(B,'MannWhitneyU B',1);
  NA:=Length(A); NB:=Length(B); N:=NA+NB; SetLength(Items,N);
  for I:=0 to NA-1 do begin Items[I].Value:=A[I]; Items[I].Group:=0; end;
  for I:=0 to NB-1 do begin Items[NA+I].Value:=B[I]; Items[NA+I].Group:=1; end;
  for I:=0 to N-2 do for J:=I+1 to N-1 do
    if Items[J].Value<Items[I].Value then
    begin Temp:=Items[I]; Items[I]:=Items[J]; Items[J]:=Temp; end;
  I:=0; RankSumA:=0; TieTerm:=0;
  while I<N do
  begin
    J:=I;
    while (J+1<N) and (Items[J+1].Value=Items[I].Value) do Inc(J);
    RankValue:=((I+1)+(J+1))/2;
    for K:=I to J do if Items[K].Group=0 then RankSumA:=RankSumA+RankValue;
    if J>I then TieTerm:=TieTerm+(J-I+1)*(Sqr(J-I+1)-1);
    I:=J+1;
  end;
  U1:=RankSumA-NA*(NA+1)/2; U2:=NA*NB-U1;
  Result.Statistic:=Min(U1,U2);
  MeanU:=NA*NB/2;
  VarianceU:=NA*NB/12*((N+1)-TieTerm/(N*(N-1)));
  if VarianceU<=0 then
    raise EInferenceError.Create('MannWhitneyU: rank variance is zero.');
  Z:=(Result.Statistic-MeanU+0.5)/Sqrt(VarianceU);
  Result.PValue:=Min(1,2*TProbabilityKit.NormalCDF(Z,0,1));
  Result.EffectSize:=1-2*Result.Statistic/(NA*NB);
end;

class function TInferenceKit.AdjustBonferroni(
  const PValues:TDoubleArray):TDoubleArray;
var I:Integer;
begin
  Result:=nil; SetLength(Result,Length(PValues));
  for I:=0 to High(PValues) do
  begin
    RequireProbability(PValues[I],'AdjustBonferroni');
    Result[I]:=Min(1,PValues[I]*Length(PValues));
  end;
end;

class function TInferenceKit.AdjustBenjaminiHochberg(
  const PValues:TDoubleArray):TDoubleArray;
var
  Order:TIntegerArray;
  I,J,Temp,N:Integer;
  Running:Double;
begin
  Result:=nil; N:=Length(PValues);
  SetLength(Result,N); SetLength(Order,N);
  for I:=0 to N-1 do
  begin RequireProbability(PValues[I],'AdjustBenjaminiHochberg'); Order[I]:=I; end;
  for I:=0 to N-2 do for J:=I+1 to N-1 do
    if PValues[Order[J]]<PValues[Order[I]] then
    begin Temp:=Order[I]; Order[I]:=Order[J]; Order[J]:=Temp; end;
  Running:=1;
  for I:=N-1 downto 0 do
  begin
    Running:=Min(Running,PValues[Order[I]]*N/(I+1));
    Result[Order[I]]:=Running;
  end;
end;

procedure ValidateRegression(const Design:IDenseDoubleMatrix;
  const Count:Integer; const Name:String);
var I,J:Integer;
begin
  if Design=nil then raise EInferenceError.Create(Name+': design is nil.');
  if (Design.Rows<>Count) or (Design.Rows<1) or (Design.Cols<1) then
    raise EInferenceError.Create(
      Name+': response length must match a non-empty design.');
  for I:=0 to Design.Rows-1 do for J:=0 to Design.Cols-1 do
    if not Finite(Design[I,J]) then
      raise EInferenceError.CreateFmt(
        '%s: design value [%d,%d] must be finite.',[Name,I,J]);
end;

class function TInferenceKit.FitOLS(const Design:IDenseDoubleMatrix;
  const Response:TDoubleArray):TRegressionDiagnostics;
var
  Factor:IDenseDoubleSVD;
  RHS,Solution,V:IDenseDoubleMatrix;
  Singular:TDoubleArray;
  I,J:Integer;
  MeanY,SSE,SST,Sigma2:Double;
begin
  Result:=Default(TRegressionDiagnostics);
  RequireSamples(Response,'FitOLS response',1);
  ValidateRegression(Design,Length(Response),'FitOLS');
  RHS:=TDenseDoubleMatrix.FromVector(Response,True);
  Factor:=FactorSVD(Design);
  Solution:=Factor.SolveMinimumNorm(RHS);
  Singular:=Factor.SingularValues; V:=Factor.V;
  Result.Rank:=Factor.NumericalRank;
  Result.DegreesOfFreedom:=Design.Rows-Result.Rank;
  SetLength(Result.Coefficients,Design.Cols);
  SetLength(Result.StandardErrors,Design.Cols);
  SetLength(Result.Fitted,Design.Rows);
  SetLength(Result.Residuals,Design.Rows);
  for J:=0 to Design.Cols-1 do Result.Coefficients[J]:=Solution[J,0];
  MeanY:=0;
  for I:=0 to High(Response) do MeanY:=MeanY+Response[I];
  MeanY:=MeanY/Length(Response); SSE:=0; SST:=0;
  for I:=0 to Design.Rows-1 do
  begin
    for J:=0 to Design.Cols-1 do
      Result.Fitted[I]:=Result.Fitted[I]+
        Design[I,J]*Result.Coefficients[J];
    Result.Residuals[I]:=Response[I]-Result.Fitted[I];
    SSE:=SSE+Sqr(Result.Residuals[I]);
    SST:=SST+Sqr(Response[I]-MeanY);
  end;
  if SST>0 then Result.RSquared:=1-SSE/SST;
  if Result.DegreesOfFreedom>0 then
  begin
    Sigma2:=SSE/Result.DegreesOfFreedom;
    for I:=0 to Design.Cols-1 do
      for J:=0 to Result.Rank-1 do
        if Singular[J]>Factor.Tolerance then
          Result.StandardErrors[I]:=Result.StandardErrors[I]+
            Sqr(V[I,J])/Sqr(Singular[J]);
    for I:=0 to High(Result.StandardErrors) do
      Result.StandardErrors[I]:=Sqrt(Sigma2*Result.StandardErrors[I]);
    if Design.Rows>1 then
      Result.AdjustedRSquared:=1-(1-Result.RSquared)*
        (Design.Rows-1)/Result.DegreesOfFreedom;
  end;
  if Result.Rank=Design.Cols then Result.Status:=isConverged
  else Result.Status:=isAcceptableLimit;
end;

function LogisticValue(const X:Double):Double;
begin
  if X>=0 then Result:=1/(1+Exp(-X))
  else Result:=Exp(X)/(1+Exp(X));
end;

class function TInferenceKit.FitLogistic(const Design:IDenseDoubleMatrix;
  const Labels:TIntegerArray; const MaxIterations:Integer;
  const Tolerance:Double):TLogisticRegressionResult;
var
  Weighted,Target,Solution,V:IDenseDoubleMatrix;
  Factor:IDenseDoubleSVD;
  Singular,OldCoefficients:TDoubleArray;
  I,J,Iteration,PositiveCount:Integer;
  Eta,P,W,Z,Change,LogLikelihood:Double;
begin
  Result:=Default(TLogisticRegressionResult);
  ValidateRegression(Design,Length(Labels),'FitLogistic');
  if (MaxIterations<1) or not Finite(Tolerance) or (Tolerance<=0) then
    raise EInferenceError.Create('FitLogistic: invalid iteration options.');
  PositiveCount:=0;
  for I:=0 to High(Labels) do
  begin
    if not (Labels[I] in [0,1]) then
      raise EInferenceError.Create('FitLogistic: labels must be zero or one.');
    Inc(PositiveCount,Labels[I]);
  end;
  if (PositiveCount=0) or (PositiveCount=Length(Labels)) then
  begin Result.Status:=isNumericalBreakdown; Exit; end;
  SetLength(Result.Coefficients,Design.Cols);
  SetLength(Result.Probabilities,Design.Rows);
  SetLength(Result.StandardErrors,Design.Cols);
  for Iteration:=1 to MaxIterations do
  begin
    OldCoefficients:=Copy(Result.Coefficients);
    Weighted:=TDenseDoubleMatrix.Zeros(Design.Rows,Design.Cols);
    Target:=TDenseDoubleMatrix.Zeros(Design.Rows,1);
    for I:=0 to Design.Rows-1 do
    begin
      Eta:=0;
      for J:=0 to Design.Cols-1 do Eta:=Eta+Design[I,J]*OldCoefficients[J];
      P:=LogisticValue(Eta);
      W:=Max(1E-12,P*(1-P));
      Z:=Eta+(Labels[I]-P)/W;
      W:=Sqrt(W);
      for J:=0 to Design.Cols-1 do Weighted[I,J]:=W*Design[I,J];
      Target[I,0]:=W*Z;
    end;
    Factor:=FactorSVD(Weighted);
    Solution:=Factor.SolveMinimumNorm(Target);
    Change:=0;
    for J:=0 to Design.Cols-1 do
    begin
      Result.Coefficients[J]:=Solution[J,0];
      Change:=Max(Change,Abs(Result.Coefficients[J]-OldCoefficients[J]));
    end;
    Result.Iterations:=Iteration;
    if Change<=Tolerance*(1+Max(1,Abs(Result.Coefficients[0]))) then
    begin Result.Status:=isConverged; Break; end;
    for J:=0 to Design.Cols-1 do
      if Abs(Result.Coefficients[J])>30 then
      begin Result.Status:=isNumericalBreakdown; Break; end;
    if Result.Status=isNumericalBreakdown then Break;
  end;
  if Result.Status=isUnknown then Result.Status:=isIterationLimit;
  LogLikelihood:=0;
  for I:=0 to Design.Rows-1 do
  begin
    Eta:=0;
    for J:=0 to Design.Cols-1 do
      Eta:=Eta+Design[I,J]*Result.Coefficients[J];
    P:=LogisticValue(Eta);
    Result.Probabilities[I]:=P;
    LogLikelihood:=LogLikelihood+
      Labels[I]*Ln(Max(P,1E-300))+
      (1-Labels[I])*Ln(Max(1-P,1E-300));
  end;
  Result.Deviance:=-2*LogLikelihood;
  Result.Identifiable:=(Result.Status=isConverged) and
    (Factor.NumericalRank=Design.Cols);
  if Result.Identifiable then
  begin
    Singular:=Factor.SingularValues; V:=Factor.V;
    for I:=0 to Design.Cols-1 do
      for J:=0 to Factor.NumericalRank-1 do
        if Singular[J]>Factor.Tolerance then
          Result.StandardErrors[I]:=Result.StandardErrors[I]+
            Sqr(V[I,J])/Sqr(Singular[J]);
    for I:=0 to High(Result.StandardErrors) do
      Result.StandardErrors[I]:=Sqrt(Result.StandardErrors[I]);
  end
  else if Result.Status=isConverged then
    Result.Status:=isAcceptableLimit;
end;

end.
