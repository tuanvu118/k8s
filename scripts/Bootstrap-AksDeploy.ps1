param(
    [Parameter(Mandatory = $true)]
    [string]$AksResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$AksName,

    [switch]$InstallArgoCd
)

$ErrorActionPreference = "Stop"

Write-Output "Fetching AKS credentials..."
az aks get-credentials --resource-group $AksResourceGroup --name $AksName --overwrite-existing

Write-Output "Applying TTCS manifests..."
kubectl apply -k "d:\TTCS\k8s\overlays\prod"

Write-Output "Current pods in namespace ttcs:"
kubectl -n ttcs get pods

if ($InstallArgoCd) {
    Write-Output "Installing Argo CD..."
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    Write-Output "Applying Argo CD application..."
    kubectl apply -f "d:\TTCS\k8s\argocd\application.yaml"
}

Write-Output "Gateway service:"
kubectl -n ttcs get svc gateway
