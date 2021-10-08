BeforeAll {
   
    Write-Host "##[section]==============================================="
    Write-Host "##[section]Environment variables:"
    Write-Host "##[section]==============================================="
    Write-Host "##[section]personalAccessToken: " $env:personalAccessToken
    Write-Host "##[section]customModulesDirectory: " $env:customModulesDirectory
    Write-Host "##[section]orgUrl: " $env:orgUrl
    Write-Host "##[section]testsTeamProject: " $env:testsTeamProject
    Write-Host "##[section]yamlFilePath: " $env:yamlFilePath
    Write-Host "##[section]pipelineName: " $env:pipelineName
    Write-Host "##[section]repository: " $env:repository
    Write-Host "##[section]branch: " $env:branch
    Write-Host "##[section]skipTearDown: " $env:skipTearDown
    Write-Host "##[section]serviceConnectionId: " $env:serviceConnectionId
    Write-Host "##[section]pipelineId: " $env:pipelineId
    Write-Host "##[section]==============================================="
    
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

            if ($pipeline) {
                $build = Wait-AzureDevOpsPipelineRuns `
                    -personalAccessToken $env:personalAccessToken `
                    -orgUrl $env:orgUrl `
                    -teamProject $env:testsTeamProject `
                    -pipelineId $pipeline.definition.id `
                    -timeoutMinutes $env:timeoutMinutes
            }

            $build.result | Should -Be "succeeded"
        }
    }
}


AfterAll {

    Write-Host "TearDown var:  $env:skipTearDown"
    if ($env:skipTearDown -ne "true") {
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