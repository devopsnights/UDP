
param(
    $TestResultsPath = "$PSScriptRoot\testResults"
)
  
$testScript = Join-Path -Path $PSScriptRoot -ChildPath 'dotnetcore\dotnetcore.tests.ps1'
$testResultsFile = Join-Path -Path $TestResultsPath -ChildPath 'TestResults.Pester.xml'

if (Test-Path $testScript) {
    $pester = @{
        Script       = $testScript
        OutputFormat = 'NUnitXml'
        OutputFile   = $testResultsFile
        PassThru     = $true 
        ExcludeTag   = 'Incomplete'
    }
    Invoke-Pester @pester
}
