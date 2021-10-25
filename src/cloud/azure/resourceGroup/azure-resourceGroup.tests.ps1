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

    if ($env:Build_SourceBranch) {
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

            Write-Host "Expected pipeline name: $($env:pipelineName)"
            Write-Host "Pipeline name: $($pipeline.name)"

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

            Write-Host "Build: $($build)"
            Write-Host "Build result: $($build)"

            $build.result | Should -Be "Succeeded"
        }
    }
}

Describe "Resource Group" -Tag resourceGroup {
    Context "Validate Resource Group" {
        It 'Resource Group should be provisioned' {

            foreach ($environment in $env:environmentToValidate.Split(",")) {
  
                $appConfigKeys = az appconfig kv list -n $env:appConfigurationName --label $environment -o json | ConvertFrom-Json

                $resourceGroupName = ($appConfigKeys | where { $_.key -eq $env:resourceGroupNameKey }).value

                Write-Host "Validating resources"
                Write-Host "resourceGroupName: $resourceGroupName"

                $resourceGroup = az group show -n RG-UDP-CI-Dev | ConvertFrom-Json

                Write-Host "RG State: $($resourceGroup.properties.provisioningState)"

                $resourceGroup.properties.provisioningState | Should -Be "Succeeded"
            }
        }

        It 'Resource Group location should be equals to AppConfiguration' {

            foreach ($environment in $env:environmentToValidate.Split(",")) {
  
                $appConfigKeys = az appconfig kv list -n $env:appConfigurationName --label $environment -o json | ConvertFrom-Json

                $resourceGroupName = ($appConfigKeys | where { $_.key -eq $env:resourceGroupNameKey }).value
                $resourceGroupLocation = ($appConfigKeys | where { $_.key -eq $env:resourceGroupLocationKey }).value

                Write-Host "Validating resources"
                Write-Host "resourceGroupName: $resourceGroupName"

                $resourceGroup = az group show -n RG-UDP-CI-Dev | ConvertFrom-Json


                Write-Host "RG location: $($resourceGroup.location)"

                $resourceGroup.location | Should -Be $resourceGroupLocation
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
                
            $resourceGroupName = ($keys | where { $_.key -eq $env:resourceGroupNameKey }).value

            Write-Host "Removing resource group: $resourceGroupName"

            az group delete -n $resourceGroupName -y
        }

    }
    else {
        Write-Host "Skipping teardown"
    }
}