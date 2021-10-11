BeforeAll {
   
    Write-Host "##[section]===============================================" -ForegroundColor Green
    Write-Host "##[section]Environment variables:"
    Write-Host "##[section]===============================================" -ForegroundColor Green
    if ($env:personalAccessToken) {
        Write-Host "personalAccessToken: ***" -ForegroundColor Green
    }
    else{
        Write-Host "personalAccessToken: notDefined" -ForegroundColor Red 
    }
    Write-Host "##[section]customModulesDirectory: " $env:customModulesDirectory -ForegroundColor Green
    Write-Host "##[section]orgUrl: " $env:orgUrl -ForegroundColor Green
    Write-Host "##[section]testsTeamProject: " $env:testsTeamProject -ForegroundColor Green
    Write-Host "##[section]yamlFilePath: " $env:yamlFilePath -ForegroundColor Green
    Write-Host "##[section]pipelineName: " $env:pipelineName -ForegroundColor Green
    Write-Host "##[section]repository: " $env:repository -ForegroundColor Green
    Write-Host "##[section]branch: " $env:branch -ForegroundColor Green
    Write-Host "##[section]skipTeardown: " $env:skipTeardown -ForegroundColor Green
    Write-Host "##[section]serviceConnectionId: " $env:serviceConnectionId -ForegroundColor Green
    Write-Host "##[section]pipelineId: " $env:pipelineId -ForegroundColor Green
    Write-Host "##[section]===============================================" -ForegroundColor Green
    
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
        It 'Should create a YAML pipeline definition' {

            $pipeline = New-AzureDevOpsPipeline `
                -personalAccessToken $env:personalAccessToken `
                -orgUrl $env:orgUrl `
                -teamProject $env:testsTeamProject `
                -yamlFilePath $env:yamlFilePath `
                -pipelineName $env:pipelineName `
                -repository $env:repository `
                -branch $env:branch `
                -serviceConnection $env:serviceConnectionId

            $pipeline.name | Should -Be $env:pipelineName
        }

        It 'Should execute successfuly a pipeline definition' {

            $pipeline = New-AzureDevOpsPipelineRun `
                -personalAccessToken $env:personalAccessToken `
                -orgUrl $env:orgUrl `
                -teamProject $env:testsTeamProject `
                -pipelineName $env:pipelineName `
                -branch $env:branch

            if ($pipeline) {
                $build = Wait-AzureDevOpsPipelineRuns `
                    -personalAccessToken $env:personalAccessToken `
                    -orgUrl $env:orgUrl `
                    -teamProject $env:testsTeamProject `
                    -pipelineId $pipeline.definition.id `
                    -timeoutMinutes $env:timeoutMinutes
            }

            Write-Host $pipeline

            $build.result | Should -Be "succeeded"
        }
    }
}


AfterAll {

    Write-Host "TearDown var:  $env:skipTeardown"
    
    if ($env:skipTeardown -ne "true") {
        Write-Host "##[warning]Test execution finished. Tearing down pipelines on Team Project $env:testsTeamProject." -ForegroundColor Yellow
        $pipelines = Get-AzureDevOpsPipelines `
            -personalAccessToken $env:personalAccessToken `
            -orgUrl $env:orgUrl `
            -teamProject $env:testsTeamProject

        Write-Host "Removing ALL pipelines on Team Project $teamProject" -ForegroundColor Yellow
    
        foreach ($pipeline in $pipelines) {
            Write-Host "##[warning]Removing pipeline:" -ForegroundColor Yellow
            Write-Host "##[warning]Name: $($pipeline.name)" -ForegroundColor Yellow
            Write-Host "##[warning]Id $($pipeline.id)" -ForegroundColor Yellow

            Remove-AzureDevOpsPipelines `
                -personalAccessToken $env:personalAccessToken `
                -orgUrl $env:orgUrl `
                -teamProject $env:testsTeamProject `
                -pipelineId  $pipeline.id
        }
    }else{
        Write-Host "Skipping teardown"
    }
}