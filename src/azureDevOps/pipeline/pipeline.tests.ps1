BeforeAll {
   
    $moduleName = "UDP.AzureDevOps"

    if (Get-Module -ListAvailable -Name $moduleName) {
        Write-Host "Module $moduleName already loaded"
    } 
    else {
        Write-Host "Importing modules $moduleName "
        $module = Join-Path -Path $env:customModulesDirectory -ChildPath $moduleName
        Write-Host "Module 'UDP.AzureDevOps' location: $module"
        Import-Module $module -Force
    }
}

Describe "YAML Pipelines" -Tag dotnetCore {
    Context "Validate YAML" {
        It 'Should create an YAML pipeline' {

            $pipeline = New-AzureDevOpsPipeline `
                -personalAccessToken $env:personalAccessToken `
                -orgUrl $env:orgUrl `
                -teamProject $env:testsTeamProject `
                -yamlFilePath $env:yamlFilePath `
                -pipelineId $env:pipelineId `
                -pipelineName "dotnetCore-tests"
                -repository $env:repository
                -branch $env:branch
                -serviceConnection "ceb2bb80-16b4-4450-b4a9-4cfaf1b73234"
            
            if ($pipeline) {
                $build = Wait-AzureDevOpsPipelineRuns `
                    -personalAccessToken $env:personalAccessToken `
                    -orgUrl $env:orgUrl `
                    -teamProject $env:testsTeamProject `
                    -pipelineId $pipeline.definition.id
            }

            $build.result | Should -Be "succeeded"
        }
    }
}


AfterAll {

    Write-Host "Test execution finished. Tearing down pipelines." -ForegroundColor Yellow
    $pipelines = Get-AzureDevOpsPipelines `
        -personalAccessToken $env:personalAccessToken `
        -orgUrl $env:orgUrl `
        -teamProject $env:testsTeamProject

    Write-Host "Removing ALL pipelines on Team Project $teamProject" -ForegroundColor Yellow
    
    foreach ($pipeline in $pipelines) {
        Write-Host "Removing pipeline:" -ForegroundColor Yellow
        Write-Host "Name: $($pipeline.name)" -ForegroundColor Yellow
        Write-Host "Id $($pipeline.id)" -ForegroundColor Yellow

        Remove-AzureDevOpsPipelines `
            -personalAccessToken $env:personalAccessToken `
            -orgUrl $env:orgUrl `
            -teamProject $env:testsTeamProject `
            -pipelineId  $pipeline.id
    }   
}