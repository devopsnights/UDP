param(
    [string]$TestResultsDirectory = "$env:Build_SourcesDirectory\tests\results\"
)

$testScript = Join-Path -Path $env:Build_SourcesDirectory -ChildPath 'src/azureDevOps/pipeline/pipeline.tests.ps1'

Write-Host "Script path: $testScript"

# Create configuration for pester execution
$container = New-PesterContainer -Path $testScript 

$config = New-PesterConfiguration
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = "NUnitXML"
$config.TestResult.OutputPath = Join-Path $TestResultsDirectory -ChildPath "testResults.xml" 
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.OutputPath = Join-Path $TestResultsDirectory -ChildPath "coverage.xml"
$config.Run.Container = $container
$config.Output.Verbosity = "Detailed"

Invoke-Pester -Configuration $config 