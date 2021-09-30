param(
    [string]$customModulesDirectory = "C:\repo\wes\UDP\modules\",
    [string]$orgUrl,
    [string]$teamProject,
    [string]$personalAccessToken,
    [string]$yamlFilePath,
    [string]$pipelineId 
)

$testFile = "C:\repo\wes\UDP\examples\dotnetcore\dotnetcore.tests.ps1"

Invoke-Pester $testFile -Output Detailed

# $container = New-PesterContainer -Path $testFile -Data @{ `
#         $customModulesDirectory = "C:\repo\wes\UDP\modules\"; `
#         $orgUrl                 = $orgUrl; `
#         $teamProject            = $teamProject; `
#         $personalAccessToken    = $personalAccessToken; `
#         $yamlFilePath           = $yamlFilePath; `
#         $pipelineId             = $pipelineId 
# }
  
# Invoke-Pester -Container $container -Output Detailed