
function Get-Header(){
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
        [object]$header,
        $personalAccessToken
    )

    $azdoBaseUrl = Get-Url -orgUrl $orgUrl -header $header
    
    $projectsUrl = "{0}_apis/projects?api-version=5.0" -f $azdoBaseUrl

    $header = Get-Header -personalAccessToken $personalAccessToken

    $projects = Invoke-RestMethod -Uri $projectsUrl -Method Get -ContentType "application/json" -Headers $header
    Write-Host "Projects: $projects"



    $projectId = $(($projects.value | where { $_.name -eq $teamProject }).id)

    $url = "{0}{1}/" -f $azdoBaseUrl, $projectId

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
    Write-Host "Header: $header"


    $projectBaseUrl = Get-ProjectUrl -teamProject $teamProject -orgUrl $orgUrl -personalAccessToken $personalAccessToken -header $header

    $projectsUrl = "{0}_apis/pipelines/{1}/preview?api-version=6.1-preview.1" -f $projectBaseUrl, $pipelineId
    Write-Host "Project URL: $projectsUrl"

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