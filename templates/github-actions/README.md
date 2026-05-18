# GitHub Actions Template

File [build-and-update-deploy-repo.yaml](/d:/TTCS/k8s/templates/github-actions/build-and-update-deploy-repo.yaml) la workflow mau cho tung source repo.

## Cach dien env

### Repo `fe_ttcs`

- `IMAGE_REPOSITORY=ttcs/frontend`
- `KUSTOMIZE_IMAGE_NAME=frontend-image`

### Repo `api_gateway`

- `IMAGE_REPOSITORY=ttcs/auth-gateway`
- `KUSTOMIZE_IMAGE_NAME=auth-gateway-image`

### Repo `be_service_ttcs`

- `IMAGE_REPOSITORY=ttcs/be-service`
- `KUSTOMIZE_IMAGE_NAME=be-service-image`

### Repo `qr_service_be_ttcs`

- `IMAGE_REPOSITORY=ttcs/qr-service`
- `KUSTOMIZE_IMAGE_NAME=qr-service-image`

## Secret can co trong source repo

- `ACR_USERNAME`
  username cua ACR de GitHub Actions login registry
- `ACR_PASSWORD`
  password cua ACR de GitHub Actions login registry
- `DEPLOY_REPO_PAT`
  PAT co quyen push vao deploy repo

## Ghi chu

- `gateway` khong can workflow build image rieng neu ban giu `caddy:2-alpine`.
- Neu chi sua `Caddyfile`, ban cap nhat manifest/ConfigMap trong deploy repo la du; Argo CD se sync.
