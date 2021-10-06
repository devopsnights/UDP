param(
    $TestResultsFile
)
  
Get-ChildItem $PSScriptRoot -Recurse

$testScript = Join-Path -Path $PSScriptRoot -ChildPath 'pipeline-tests.ps1'
# $testResultsFile = Join-Path -Path $TestResultsPath -ChildPath 'TestResults.Pester.xml'

# Create configuration for pester execution
$container = New-PesterContainer -Path $testScript 

$config = New-PesterConfiguration
$config.TestResult.OutputFormat = "NUnitXML"
$config.TestResult.OutputPath = $testResultsFile 
$config.Run.Container = $container

Write-Host "TestResultsFile: $testResultsFile"


Invoke-Pester -Configuration $config 