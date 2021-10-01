# param(
#     [string]$customModulesDirectory = "C:\repo\wes\UDP\modules\",
#     [string]$orgUrl,
#     [string]$teamProject,
#     [string]$personalAccessToken,
#     [string]$yamlFilePath,
#     [string]$pipelineId 
# )

BeforeAll {
    # Import-Module C:\repo\wes\UDP\modules\UDP.AzureDevOps


    $moduleName = "UDP.AzureDevOps"
    $module = Join-Path -Path $env:customModulesDirectory -ChildPath $moduleName

    Import-Module $module -Force
    Install-Module powershell-yaml -Force
}

Describe "dotnetCore" -Tag dotnetCore {
    Context "Validate YAML" {
        It 'Should validate YAML structure' {
            
            Write-Host "pat: $env:personalAccessToken"


            $finalYaml = Test-YamlPipeline -orgUrl $env:orgUrl `
                -teamProject $env:teamProject `
                -personalAccessToken $env:personalAccessToken `
                -yamlFilePath $env:yamlFilePath `
                -pipelineId $env:pipelineId

            $valid = $true
            try {
                $obj = ConvertFrom-Yaml $finalYaml
                Write-Host $obj
            }
            catch {
                Write-Host "An error occurred:"
            
                $valid = $false
            }

            $valid | Should -BeTrue
        }
    }
}