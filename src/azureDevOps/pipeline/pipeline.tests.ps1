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

    Write-Verbose "==============================================="
    Write-Verbose "Environment variables:"
    Write-Verbose "==============================================="
    Write-Verbose "personalAccessToken: " $env:personalAccessToken
    Write-Verbose "customModulesDirectory: " $env:customModulesDirectory
    Write-Verbose "orgUrl: " $env:orgUrl
    Write-Verbose "testsTeamProject: " $env:testsTeamProject
    Write-Verbose "yamlFilePath: " $env:yamlFilePath
    Write-Verbose "pipelineName: " $env:pipelineName
    Write-Verbose "repository: " $env:repository
    Write-Verbose "branch: " $env:branch
    Write-Verbose "skipTearDown: " $env:skipTearDown
    Write-Verbose "serviceConnectionId: " $env:serviceConnectionId
    Write-Verbose "pipelineId: " $env:pipelineId
    Write-Verbose "==============================================="

}

Describe "YAML Pipelines" -Tag dotnetCore {
    Context "Validate YAML" {
        It 'Should create an YAML pipeline' {

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