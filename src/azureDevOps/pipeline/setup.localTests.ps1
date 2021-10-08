Set-Item -Path Env:personalAccessToken -Value ""

Set-Item -Path Env:customModulesDirectory -Value "C:\repo\wes\UDP\modules\"
Set-Item -Path Env:orgUrl -Value "https://dev.azure.com/wesleycamargo"
Set-Item -Path Env:teamProject -Value "UDP"
Set-Item -Path Env:testsTeamProject -Value "UDP-Tests"
Set-Item -Path Env:yamlFilePath -Value "examples\dotnetcore\azure-pipelines.yml"
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

Write-Host "##[section]==============================================="
Write-Host "##[section]Created environment variables:"
Write-Host "##[section]==============================================="
Write-Host "##[section]personalAccessToken: " $env:personalAccessToken
Write-Host "##[section]customModulesDirectory: " $env:customModulesDirectory
Write-Host "##[section]orgUrl: " $env:orgUrl
Write-Host "##[section]testsTeamProject: " $env:testsTeamProject
Write-Host "##[section]yamlFilePath: " $env:yamlFilePath
Write-Host "##[section]pipelineName: " $env:pipelineName
Write-Host "##[section]repository: " $env:repository
Write-Host "##[section]branch: " $env:branch
Write-Host "##[section]skipTeardown: " $env:skipTeardown
Write-Host "##[section]serviceConnectionId: " $env:serviceConnectionId
Write-Host "##[section]pipelineId: " $env:pipelineId
Write-Host "##[section]pipelineId: " $env:SYSTEM_DEBUG
Write-Host "##[section]==============================================="