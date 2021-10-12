
if ($env:personalAccessToken.Length -eq 0) {
    Write-Host "Personal Access Token not loaded" -ForegroundColor Yellow
    $pat = Read-Host "Enter the Azure DevOps Personal Access Token (PAT)..."
    Set-Item -Path Env:personalAccessToken -Value $pat
}

Set-Item -Path Env:customModulesDirectory -Value "C:\repo\wes\UDP\modules\"
Set-Item -Path Env:orgUrl -Value "https://dev.azure.com/wesleycamargo"
Set-Item -Path Env:teamProject -Value "UDP"
Set-Item -Path Env:testsTeamProject -Value "UDP-Tests"
Set-Item -Path Env:yamlFilePath -Value "examples/dotnetcore/azure-pipelines.yml"
Set-Item -Path Env:pipelineId  -Value "99"
Set-Item -Path Env:pipelineName  -Value "dotnetCore-tests"
Set-Item -Path Env:testFilesToRun -Value "C:\repo\wes\UDP\src\azureDevOps\pipeline\pipeline.tests.ps1"
Set-Item -Path Env:Build_SourcesDirectory  -Value "C:\repo\wes\UDP"
Set-Item -Path Env:serviceConnectionId  -Value "ceb2bb80-16b4-4450-b4a9-4cfaf1b73234"
Set-Item -Path Env:repository  -Value "https://github.com/wesleycamargo/UDP"
Set-Item -Path Env:branch  -Value "feature/tests"
Set-Item -Path Env:SYSTEM_DEBUG -Value "false"
Set-Item -Path Env:timeoutMinutes -Value 5

cls

Write-Host "===============================================" -ForegroundColor Green
Write-Host "Created environment variables:" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
if ($env:personalAccessToken) {
    Write-Host "personalAccessToken: ***" -ForegroundColor Green
}
else{
    Write-Host "personalAccessToken: notDefined" -ForegroundColor Red 
}
Write-Host "customModulesDirectory: " $env:customModulesDirectory -ForegroundColor Green
Write-Host "orgUrl: " $env:orgUrl -ForegroundColor Green
Write-Host "testsTeamProject: " $env:testsTeamProject -ForegroundColor Green
Write-Host "yamlFilePath: " $env:yamlFilePath -ForegroundColor Green
Write-Host "pipelineName: " $env:pipelineName -ForegroundColor Green
Write-Host "repository: " $env:repository -ForegroundColor Green
Write-Host "branch: " $env:branch -ForegroundColor Green
Write-Host "skipTeardown: " $env:skipTeardown -ForegroundColor Green
Write-Host "serviceConnectionId: " $env:serviceConnectionId -ForegroundColor Green
Write-Host "pipelineId: " $env:pipelineId -ForegroundColor Green
Write-Host "pipelineId: " $env:SYSTEM_DEBUG -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green