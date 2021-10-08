BeforeAll {
   
    Write-Host "==============================================="
    Write-Host "Environment variables:"
    Write-Host "==============================================="
    Write-Host "personalAccessToken: " $env:personalAccessToken
    Write-Host "customModulesDirectory: " $env:customModulesDirectory
    Write-Host "orgUrl: " $env:orgUrl
    Write-Host "testsTeamProject: " $env:testsTeamProject
    Write-Host "yamlFilePath: " $env:yamlFilePath
    Write-Host "pipelineName: " $env:pipelineName
    Write-Host "repository: " $env:repository
    Write-Host "branch: " $env:branch
    Write-Host "skipTearDown: " $env:skipTearDown
    Write-Host "serviceConnectionId: " $env:serviceConnectionId
    Write-Host "pipelineId: " $env:pipelineId
    Write-Host "==============================================="
    
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

Describe "YAML Pipelines" -Tag YAMLPipelines {
    Context "Validate YAML" {
        It 'Should create a YAML pipeline definition and execute successfuly' {

            $pipeline = New-AzureDevOpsPipeline `
                -personalAccessToken $env:personalAccessToken `
                -orgUrl $env:orgUrl `
                -teamProject $env:testsTeamProject `
                -yamlFilePath $env:yamlFilePath `
                -pipelineName $env:pipelineName `
                -repository $env:repository `
                -branch $env:branch `
                -serviceConnection $env:serviceConnectionId
                # -pipelineId $env:pipelineId `
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

    Write-Host "TearDown var:  $env:skipTearDown"
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