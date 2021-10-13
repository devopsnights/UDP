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

    # create yaml pipeline 
    $pipeline = New-AzureDevOpsPipeline `
        -personalAccessToken $env:personalAccessToken `
        -orgUrl $env:orgUrl `
        -teamProject $env:testsTeamProject `
        -yamlFilePath $env:yamlFilePath `
        -pipelineName $env:pipelineName `
        -repository $env:repository `
        -branch $env:branch `
        -serviceConnection $env:serviceConnectionId

    # run yaml pipeline to deploy
    $pipeline = New-AzureDevOpsPipelineRun `
        -personalAccessToken $env:personalAccessToken `
        -orgUrl $env:orgUrl `
        -teamProject $env:testsTeamProject `
        -pipelineName $env:pipelineName 

    # wait until the pipeline runs
    if ($pipeline) {
        $build = Wait-AzureDevOpsPipelineRuns `
            -personalAccessToken $env:personalAccessToken `
            -orgUrl $env:orgUrl `
            -teamProject $env:testsTeamProject `
            -pipelineId $pipeline.definition.id `
            -timeoutMinutes $env:timeoutMinutes
    }
}

Describe "dotnetCore" -Tag dotnetCore {
    Context "Validate YAML" {
        It 'Web App state should be running' {

           $webApp = az webapp show -n $env:webAppName -g $env:resourceGroupName | ConvertFrom-Json

           $webApp.state | Should -Be "Running"
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