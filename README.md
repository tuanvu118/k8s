# TTCS K8S Deploy Repo

Thu muc `k8s/` nay duoc to chuc theo kieu "deploy repo" de phu hop voi luong:

- moi service code co repo rieng va GitHub Actions rieng
- GitHub Actions build image, push ACR, sau do cap nhat tag image trong `overlays/prod/kustomization.yaml` cua deploy repo
- Argo CD chay trong AKS, theo doi `overlays/prod` va tu sync vao cluster

## Cau truc

```text
k8s/
  argocd/
  base/
    apps/
    platform/
    kustomization.yaml
    namespace.yaml
    secrets.example.yaml
    shared-config.yaml
  overlays/
    prod/
      kustomization.yaml
  templates/
    github-actions/
```

## Microservice hien tai

- `frontend`: static SPA da build san
- `gateway`: Caddy public ra ngoai
- `auth-gateway`: FastAPI verify JWT va RBAC theo path
- `be-service-api`: backend chinh
- `be-checkin-sync-worker`: worker dong bo check-in ve BE chinh
- `be-service-scheduler`: scheduler rieng
- `qr-service-api`: QR/attendance API
- `qr-sync-worker`: dong bo participant tu BE sang QR DB
- `qr-attendance-worker`: xu ly queue diem danh
- `mongodb`, `redis`, `rabbitmq`: platform layer chay noi bo trong cluster

## Mot so quy tac quan trong

- Chi `gateway` moi duoc public.
- Tat ca service con lai la `ClusterIP`.
- `be_service_ttcs` va `qr_service_be_ttcs` da duoc them env flag de API pod khong tu spawn worker nua khi da co worker pod rieng.
- `gateway` dung `caddy:2-alpine` chinh thuc + `ConfigMap` cho `Caddyfile`.
- `frontend` van dung image rieng tu repo `fe_ttcs`.

## Mapping repo -> image -> workload

- repo `fe_ttcs` -> image `ttcs/frontend` -> workload `frontend`
- repo `api_gateway` -> image `ttcs/auth-gateway` -> workload `auth-gateway`
- repo `be_service_ttcs` -> image `ttcs/be-service` -> workloads:
  `be-service-api`, `be-checkin-sync-worker`, `be-service-scheduler`
- repo `qr_service_be_ttcs` -> image `ttcs/qr-service` -> workloads:
  `qr-service-api`, `qr-sync-worker`, `qr-attendance-worker`
- `gateway` khong can image custom luc dau: dung `caddy:2-alpine` + `ConfigMap`

## Buoc 1: Tao ACR moi

Vi ACR cu da bi xoa, tao ACR moi truoc:

```powershell
az acr create `
  --resource-group rg-ttcs-aks `
  --name <acr-name-moi> `
  --sku Basic
```

Lay login server:

```powershell
az acr show --name <acr-name-moi> --query loginServer -o tsv
```

Gan ACR vao AKS:

```powershell
az aks update `
  --resource-group rg-ttcs-aks `
  --name ttcs-aks `
  --attach-acr <acr-name-moi>
```

## Buoc 2: Chuan bi secret runtime

File [base/secrets.example.yaml](/d:/TTCS/k8s/base/secrets.example.yaml) chi la mau. Khong commit secret that.

Ban co 2 cach:

1. Sua file example, tao `secrets.yaml` rieng ngoai Git roi apply.
2. Tao secret bang CLI:

```powershell
kubectl create namespace ttcs
kubectl -n ttcs create secret generic ttcs-app-secrets `
  --from-literal=JWT_SECRET="REPLACE_ME_JWT_SECRET" `
  --from-literal=MONGO_INITDB_ROOT_USERNAME="ttcs_root" `
  --from-literal=MONGO_INITDB_ROOT_PASSWORD="REPLACE_ME_MONGO_PASSWORD" `
  --from-literal=RABBITMQ_USERNAME="guest" `
  --from-literal=RABBITMQ_PASSWORD="guest" `
  --from-literal=CLOUDINARY_NAME="REPLACE_ME_CLOUDINARY_NAME" `
  --from-literal=CLOUDINARY_API_KEY="REPLACE_ME_CLOUDINARY_API_KEY" `
  --from-literal=CLOUDINARY_API_SECRET="REPLACE_ME_CLOUDINARY_API_SECRET" `
  --from-literal=CLOUDINARY_FOLDER="REPLACE_ME_CLOUDINARY_FOLDER"
```

## Buoc 3: Sua image trong overlay

Cap nhat file [overlays/prod/kustomization.yaml](/d:/TTCS/k8s/overlays/prod/kustomization.yaml):

- doi `newName` sang login server cua ACR moi
- doi `newTag` sang tag image ban muon deploy

## Buoc 4: Apply lan dau

```powershell
kubectl apply -k .\k8s\overlays\prod
kubectl -n ttcs get pods
```

## Buoc 5: Cai Argo CD

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Sau do apply file [argocd/application.yaml](/d:/TTCS/k8s/argocd/application.yaml) sau khi sua lai:

- `repoURL`
- `targetRevision`
- `path`

## Luong GitHub Actions + Argo CD

1. Push code len repo service.
2. GitHub Actions cua repo do build image va push ACR.
3. GitHub Actions cap nhat tag image trong `overlays/prod/kustomization.yaml` cua deploy repo.
4. Commit thay doi nay len deploy repo.
5. Argo CD thay repo deploy thay doi va sync vao AKS.

Workflow mau nam o:

- [templates/github-actions/build-and-update-deploy-repo.yaml](/d:/TTCS/k8s/templates/github-actions/build-and-update-deploy-repo.yaml)

## Thu tu trien khai hop ly

1. Tao ACR moi va attach vao AKS.
2. Tao secret runtime.
3. Apply `k8s/overlays/prod`.
4. Kiem tra platform:
   - `kubectl -n ttcs get pods`
   - `kubectl -n ttcs get svc`
5. Test:
   - `curl http://<gateway-external-ip>/api/health`
   - `curl http://<gateway-external-ip>/qr/health`
6. Cai Argo CD.
7. Gan Argo CD vao deploy repo.
8. Bat GitHub Actions o tung source repo.

## Ghi chu

- Ban dang dung mot workspace local gom nhieu repo. Ve mat GitOps, hay coi `k8s/` nay la repo deploy.
- Ve lau dai, co the tach `mongodb`, `redis`, `rabbitmq` sang managed service; luc do chi can sua ConfigMap/Secret va bo cac resource trong `base/platform/`.
