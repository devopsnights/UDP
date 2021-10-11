function Get-Header() {
    param (
        [string]$personalAccessToken
    )

    Write-Host "Initialize authentication context" -ForegroundColor Yellow
    $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($personalAccessToken)"))
    return @{authorization = "Basic $token" }
}
function Get-Url() {
    param(
        [string]$orgUrl,
        [string]$teamProject,
        [hashtable]$header
    )
    
    $areaId = "79134c72-4a58-4b42-976c-04e7115f32bf"
    $orgResourceAreasUrl = "{0}/_apis/resourceAreas/{1}?api-preview=6.1-preview.1" -f $orgUrl, $areaId

    # Do a GET on this URL (this returns an object with a "locationUrl" field)
    $results = Invoke-RestMethod -Uri $orgResourceAreasUrl -Headers $header

    # The "locationUrl" field reflects the correct base URL for RM REST API calls
    if ("null" -eq $results) {
        $areaUrl = $orgUrl
    }
    else {
        $areaUrl = $results.locationUrl
    }

    return $areaUrl
}

function Get-ProjectUrl {
    param (
        [string]$orgUrl,
        [string]$teamProject,
        [object]$header
    )

    $azdoBaseUrl = Get-Url -orgUrl $orgUrl -header $header    
    $projectsUrl = "{0}_apis/projects?api-version=5.0" -f $azdoBaseUrl

    Write-Verbose "Projects API URL: $projectsUrl"

    $projects = Invoke-RestMethod -Uri $projectsUrl -Method Get -ContentType "application/json" -Headers $header
    $projectId = $(($projects.value | where { $_.name -eq $teamProject }).id)
    $url = "{0}{1}/" -f $azdoBaseUrl, $projectId

    Write-Verbose "Team Project '$teamProject' URL: $url"

    return $url
}

function Test-YamlPipeline {
    param (
        [string]$orgUrl,
        [string]$teamProject,
        [string]$personalAccessToken,
        [string]$yamlFilePath,
        [string]$pipelineId
    )
    
    $header = Get-Header -personalAccessToken $personalAccessToken

    $projectBaseUrl = Get-ProjectUrl -teamProject $teamProject -orgUrl $orgUrl -personalAccessToken $personalAccessToken -header $header

    $projectsUrl = "{0}_apis/pipelines/{1}/preview?api-version=6.1-preview.1" -f $projectBaseUrl, $pipelineId

    Write-Verbose "Preview API URL: $projectsUrl"

    $body = @{
        PreviewRun = $true
    }

    if ($filePath) {
        $body.YamlOverride = [string](Get-Content -raw $filePath)
    }
    elseif ($YamlOverride) {
        $body.YamlOverride = $YamlOverride
    }

    $projects = $null
    $projects = Invoke-RestMethod -Uri $projectsUrl -Method Post -ContentType "application/json" -Headers $header -Body ($body | ConvertTo-Json -Compress -Depth 100)

    return $projects.finalYaml
}

function New-AzureDevOpsPipeline {
    param (
        [string]$personalAccessToken, 
        [string]$pipelineName,
        [string]$orgUrl,
        [string]$teamProject,
        [string]$repository,
        [string]$branch,
        [string]$yamlFilePath,
        [string]$serviceConnection
    )

    Write-Output $personalAccessToken | az devops login

    Write-Host "##[command]Creating pipeline '$pipelineName'"

    if($env:System_PullRequest_SourceBranch){
        $branchName = $env:System_PullRequest_SourceBranch
    }else{
        $branchName = $env:Build_SourceBranch
    }
    
    $pipeline = az pipelines create `
        --name $pipelineName `
        --org $orgUrl `
        -p $teamProject `
        --repository $repository `
        --branch $branchName `
        --yaml-path $yamlFilePath `
        --skip-first-run `
        --service-connection $serviceConnection -o json | ConvertFrom-Json

    return $pipeline
}


function New-AzureDevOpsPipelineRun {
    param (
        [string]$personalAccessToken,
        [string]$pipelineName,
        [string]$orgUrl,
        [string]$teamProject,
        [string]$branch
    )

    Write-Output $personalAccessToken | az devops login

    Write-Host "##[command]Executing pipeline '$pipelineName'"

    if ($env:SYSTEM_DEBUG -eq "true") {
        $pipeline = az pipelines run --name $pipelineName `
            --org $orgUrl `
            -p $teamProject `
            --branch $branch `
            -o json `
            --debug | ConvertFrom-Json
    }
    else {
        $pipeline = az pipelines run --name $pipelineName `
            --org $orgUrl `
            -p $teamProject `
            --branch $branch `
            -o json | ConvertFrom-Json
    }

    return $pipeline
}

function Get-AzureDevOpsPipelines {
    param (
        [string]$personalAccessToken,
        [string]$pipelineName,
        [string]$orgUrl = "https://dev.azure.com/wesleycamargo",
        [string]$teamProject = "UDP-Tests"
    )
    Write-Output $personalAccessToken | az devops login

    $pipelines = az pipelines list `
        --org $orgUrl `
        -p $teamProject | ConvertFrom-Json

    return $pipelines
}

function Remove-AzureDevOpsPipelines {
    param (
        [string]$personalAccessToken,
        [string]$pipelineId,
        [string]$orgUrl = "https://dev.azure.com/wesleycamargo",
        [string]$teamProject = "UDP-Tests"
    )
    Write-Output $personalAccessToken | az devops login

    $pipeline = az pipelines delete --org $orgUrl -p $teamProject --id $pipelineId -y
    
    Write-Host $pipeline
}

function Wait-AzureDevOpsPipelineRuns {
    param (
        [string]$personalAccessToken,
        [string]$teamProject,
        [string]$orgUrl,
        [string]$pipelineId,
        [string]$timeoutMinutes = 5
    )

    Write-Host "##[command]Getting build runs..." -ForegroundColor Blue

    $header = Get-Header -personalAccessToken $personalAccessToken
    $projectBaseUrl = Get-ProjectUrl -teamProject $teamProject -orgUrl $orgUrl -personalAccessToken $personalAccessToken -header $header
    $buildUrl = "{0}_apis/build/builds?api-version=6.0" -f $projectBaseUrl, $pipelineId

    $timeout = New-TimeSpan -Minutes $timeoutMinutes
    $endTime = (Get-Date).Add($timeout)
    
    do {
        $buildsResult = Invoke-RestMethod -Uri $buildUrl -Method Get -Headers $header -ContentType "application/json"
    
        $pipelineBuilds = $buildsResult.value | where { $_.definition.id -eq $pipelineId }
    
        if ($pipelineBuilds) {
            foreach ($build in $pipelineBuilds) {

                if ($build.status -eq "completed") {
                    Write-Host "##[section]Pipeline status: $($build.status)" -ForegroundColor Green
                }
                else {
                    Write-Host "##[command]Pipeline status: $($build.status)" -ForegroundColor Blue
                }
                Start-Sleep -Seconds 5
            }
        }
        $timeoutReached = ((Get-Date) -gt $endTime)
        if ($timeoutReached) {
            Write-Warning "Timeout reached"
        }
    } until ($build.status -eq "completed" -or $timeoutReached)

    return $build
}
