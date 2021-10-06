BeforeAll {
    Write-Host "Importing modules"
    $moduleName = "UDP.AzureDevOps"

    Get-ChildItem -Path env:

    $module = Join-Path -Path $env:customModulesDirectory -ChildPath $moduleName
    Write-Host "Module 'UDP.AzureDevOps' location: $module"

    Import-Module $module -Force
    Install-Module powershell-yaml -Force
}

Describe "dotnetCore" -Tag dotnetCore {
    Context "Validate YAML" {
        It 'Should create an YAML pipeline' {
            
            # $finalYaml = New-AzureDevOpsPipeline -orgUrl $env:orgUrl `
            #     -teamProject $env:teamProject `
            #     -personalAccessToken $env:personalAccessToken `
            #     -yamlFilePath $env:yamlFilePath `
            #     -pipelineId $env:pipelineId
            
            $finalYaml = New-AzureDevOpsPipeline `
                -personalAccessToken $env:personalAccessToken 

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
        # It 'Should validate YAML structure' {
            
        #     $finalYaml = Test-YamlPipeline -orgUrl $env:orgUrl `
        #         -teamProject $env:teamProject `
        #         -personalAccessToken $env:personalAccessToken `
        #         -yamlFilePath $env:yamlFilePath `
        #         -pipelineId $env:pipelineId

        #     $valid = $true
        #     try {
        #         $obj = ConvertFrom-Yaml $finalYaml
        #         Write-Host $obj
        #     }
        #     catch {
        #         Write-Host "An error occurred:"
            
        #         $valid = $false
        #     }

        #     $valid | Should -BeTrue
        # }
    }
}