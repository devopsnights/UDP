param(
    [string]$TestResultsDirectory = "$env:Build_SourcesDirectory\tests\results\",
    [string[]]$TestScripts
)

Write-Host "Test scripts: $env:testFilesToRun"

if ($env:system_debug) {
    Get-ChildItem -Path Env:
}

# Create configuration for pester execution
$container = New-PesterContainer -Path $env:testFilesToRun.Split(",")

$config = New-PesterConfiguration
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = "NUnitXML"
$config.TestResult.OutputPath = Join-Path $TestResultsDirectory -ChildPath "testResults.xml" 
$config.CodeCoverage.Enabled = $false
$config.CodeCoverage.OutputPath = Join-Path $TestResultsDirectory -ChildPath "coverage.xml"
$config.Run.Container = $container
$config.Output.Verbosity = "Detailed"

Invoke-Pester -Configuration $config 