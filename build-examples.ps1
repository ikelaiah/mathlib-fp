param(
  [string]$Compiler = 'fpc'
)

# Compile every runnable example into example-bin/.
# Run from any directory with: ./build-examples.ps1

$ErrorActionPreference = 'Stop'

$exampleDir = Join-Path $PSScriptRoot 'examples'
$sourceDir = Join-Path $PSScriptRoot 'src'
$outputDir = Join-Path $PSScriptRoot 'example-bin'
$unitDir = Join-Path $outputDir 'units'

New-Item -ItemType Directory -Force -Path $unitDir | Out-Null

$examples = @(Get-ChildItem -LiteralPath $exampleDir -Filter '*.pas' |
  Sort-Object Name)
if ($examples.Count -eq 0) {
  throw "No .pas examples found in $exampleDir"
}

foreach ($example in $examples) {
  Write-Host "Compiling $($example.Name)"
  & $Compiler `
    '-B' `
    '-FcUTF8' `
    "-Fu$sourceDir" `
    "-FU$unitDir" `
    "-FE$outputDir" `
    $example.FullName
  if ($LASTEXITCODE -ne 0) {
    throw "FPC failed while compiling $($example.Name)"
  }
}

Write-Host "Compiled $($examples.Count) examples into $outputDir"
