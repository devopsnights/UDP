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

    if($env:Build_SourceBranch){
        $env:branch = $env:Build_SourceBranch
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
                -serviceConnection $env:serviceConnectionId

            $pipeline.name | Should -Be $env:pipelineName
        }

        It 'Should execute successfuly a pipeline definition' {

            $pipeline = New-AzureDevOpsPipelineRun `
                -personalAccessToken $env:personalAccessToken `
                -orgUrl $env:orgUrl `
                -teamProject $env:testsTeamProject `
                -pipelineName $env:pipelineName 

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

Describe "App Service" -Tag dotnetCore {
    Context "Validate YAML" {
        It 'Web App state should be running' {

            foreach ($environment in $env:environmentToValidate.Split(",")) {
                
                $keys = az appconfig kv list -n $env:appConfigurationName --label $environment -o json | ConvertFrom-Json
                
                $webAppName = ($keys | where { $_.key -eq $env:webAppNameKey }).value
                $resourceGroupName = ($keys | where { $_.key -eq $env:resourceGroupNameKey }).value

                Write-Host "Validating resources"
                Write-Host "resourceGroupName: $resourceGroupName"
                Write-Host "wa: $webAppName"

                $webApp = az webapp show -n $webAppName -g $resourceGroupName | ConvertFrom-Json

                $webApp.state | Should -Be "Running"
            }
        }
    }
}

AfterAll {

    Write-Host "Skip TearDown:  $env:skipTeardown"
    
    if ($env:skipTeardown -ne "true") {
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

        foreach ($environment in $env:environmentToValidate.Split(",")) {
            $keys = az appconfig kv list -n $env:appConfigurationName --label $environment -o json | ConvertFrom-Json
                
            $webAppName = ($keys | where { $_.key -eq $env:webAppNameKey }).value
            $resourceGroupName = ($keys | where { $_.key -eq $env:resourceGroupNameKey }).value

            Write-Host "Removing webApp: $webAppName"

            az webapp delete -n $webAppName -g $resourceGroupName

        }
    }
    else {
        Write-Host "Skipping teardown"
    }
}