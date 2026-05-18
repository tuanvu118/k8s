param(
    [Parameter(Mandatory = $true)]
    [string]$AcrName,

    [Parameter(Mandatory = $true)]
    [string]$AcrLoginServer,

    [Parameter(Mandatory = $true)]
    [string]$DeployRepo,

    [string]$DeployRepoUrl = "",

    [string]$DeployBranch = "main"
)

$ErrorActionPreference = "Stop"

if (-not $DeployRepoUrl) {
    $DeployRepoUrl = "https://github.com/$DeployRepo.git"
}

$root = Split-Path -Parent $PSScriptRoot

$files = @(
    (Join-Path $root "overlays\prod\kustomization.yaml"),
    (Join-Path $root "argocd\application.yaml"),
    (Join-Path $root "templates\github-actions\build-and-update-deploy-repo.yaml"),
    "d:\TTCS\fe_ttcs\.github\workflows\argocd-build-and-promote.yaml",
    "d:\TTCS\be_service_ttcs\.github\workflows\argocd-build-and-promote.yaml",
    "d:\TTCS\qr_service_be_ttcs\.github\workflows\argocd-build-and-promote.yaml",
    "d:\TTCS\api_gateway\.github\workflows\argocd-build-and-promote-auth-gateway.yaml"
)

foreach ($file in $files) {
    if (-not (Test-Path $file)) {
        continue
    }

    $content = Get-Content $file -Raw
    $content = $content.Replace("REPLACE_ME_ACR_NAME", $AcrName)
    $content = $content.Replace("REPLACE_ME_ACR_LOGIN_SERVER", $AcrLoginServer)
    $content = $content.Replace("REPLACE_ME_OWNER/REPLACE_ME_DEPLOY_REPO", $DeployRepo)
    $content = $content.Replace("https://github.com/REPLACE_ME/REPLACE_ME_DEPLOY_REPO.git", $DeployRepoUrl)
    $content = $content.Replace("targetRevision: main", "targetRevision: $DeployBranch")
    Set-Content $file $content
}

Write-Output "Deploy config updated:"
Write-Output "- ACR_NAME=$AcrName"
Write-Output "- ACR_LOGIN_SERVER=$AcrLoginServer"
Write-Output "- DEPLOY_REPO=$DeployRepo"
Write-Output "- DEPLOY_REPO_URL=$DeployRepoUrl"
