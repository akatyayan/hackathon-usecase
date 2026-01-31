# Step-by-Step Execution Guide

Follow these steps **in order**. Choose either **Path A (GitHub Actions)** or **Path B (Local commands)**.

---

## Before You Start

- You need: a **GCP project** with billing enabled, and (for Path A) a **GitHub repo** with this code.
- Set your project ID once (use your real project ID):

```bash
export PROJECT_ID="your-gcp-project-id"   # e.g. e-analogy-465316-c2
```

---

# Path A: Run Everything with GitHub Actions

## Step A1: One-time GCP setup (run on your machine)

### 1. Install gcloud (if needed)

- macOS: `brew install google-cloud-sdk`
- Or: https://cloud.google.com/sdk/docs/install

### 2. Log in and set project

```bash
gcloud auth login
gcloud config set project $PROJECT_ID
```

### 3. Enable required APIs

```bash
gcloud services enable container.googleapis.com \
  compute.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  --project=$PROJECT_ID
```

### 4. Create Terraform state bucket

```bash
gsutil mb -p $PROJECT_ID -l us-central1 gs://${PROJECT_ID}-terraform-state/
gsutil versioning set on gs://${PROJECT_ID}-terraform-state/
```

### 5. Create service account for GitHub Actions

```bash
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions" \
  --project=$PROJECT_ID
```

### 6. Grant roles to the service account

```bash
for role in roles/container.admin roles/artifactregistry.admin roles/compute.networkAdmin roles/iam.serviceAccountUser roles/secretmanager.admin roles/storage.admin; do
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role=$role
done
```

### 7. Create and download the key (JSON)

```bash
gcloud iam service-accounts keys create key.json \
  --iam-account=github-actions@${PROJECT_ID}.iam.gserviceaccount.com
```

**Important:** Open `key.json`, copy its **entire contents** (you will paste it into GitHub in the next step). Do not commit this file.

---

## Step A2: Add GitHub secrets

1. Open your repo on GitHub → **Settings** → **Secrets and variables** → **Actions**.
2. Click **New repository secret** and add:

| Name                  | Value                                                                 |
|-----------------------|-----------------------------------------------------------------------|
| **GCP_PROJECT_ID**    | Your GCP project ID (e.g. `e-analogy-465316-c2`)                       |
| **GCP_PROJECT_NUMBER**| Your GCP project number (numeric). Run: `gcloud projects describe PROJECT_ID --format='value(projectNumber)'` |

---

## Step A3: Set Terraform values in the repo

1. In the repo, ensure **`Terraform/environments/test/terraform.tfvars`** has your values (do not commit if it has secrets; for project_id it’s usually fine):
   - `project_id` = your GCP project ID  
   - `region` = e.g. `us-central1`  
   - `environment` = e.g. `dev`

2. In **`Terraform/environments/test/main.tf`**, in the `backend "gcs"` block, set:
   - `bucket = "<YOUR_PROJECT_ID>-terraform-state"`  
   Example: `bucket = "e-analogy-465316-c2-terraform-state"`

3. Commit and push to `main` (only the main.tf and, if you use it, a tfvars.example — keep real tfvars out of git if your policy says so).

---

## Step A4: Run Terraform (GitHub Actions)

1. Go to **Actions** → select workflow **Terraform**.
2. Click **Run workflow** → choose branch **main** → **Run workflow**.
3. Wait until the workflow completes (Plan + Apply).  
   If Apply does not run (e.g. only on push), push a small change under `Terraform/` to `main` to trigger it again.

Result: VPC, GKE cluster (**dev-gke-cluster**), Artifact Registry, IAM, and secrets are created.

---

## Step A5: Build and push Docker images (GitHub Actions)

1. Go to **Actions** → **Build and Push Images**.
2. Click **Run workflow** → **main** → **Run workflow**.
3. Wait until it finishes.

Result: Images are in Artifact Registry: `application-service`, `patient-service`, `order-service` (tagged `latest` and short SHA).

---

## Step A6: Deploy to GKE (GitHub Actions)

1. After **Build and Push Images** succeeds, the **Deploy to GKE** workflow runs automatically.
2. Or run it manually: **Actions** → **Deploy to GKE** → **Run workflow** → **main** → **Run workflow**.
3. Wait until the deploy job completes.

Result: All three services are deployed on GKE via Helm.

---

## Step A7: Get the app URL and access

1. Install **kubectl** and get cluster credentials (use the same region as in Terraform, e.g. `us-central1`):

```bash
gcloud container clusters get-credentials dev-gke-cluster \
  --region us-central1 \
  --project $PROJECT_ID
```

2. Get the Ingress external IP (can take 5–10 minutes after deploy):

```bash
kubectl get ingress
```

3. Use the **ADDRESS** from the output:
   - Application service: `http://<ADDRESS>/application`
   - Patient service: `http://<ADDRESS>/patient`
   - Order service: `http://<ADDRESS>/order`

---

# Path B: Run Everything Locally (commands only)

Use this if you want to run Terraform, Docker, and Helm from your machine.

## Step B1: One-time GCP setup

Same as **Step A1** (steps 1–7). Set `PROJECT_ID` and run the same commands for login, APIs, bucket, service account, roles, and key.

---

## Step B2: Terraform (local)

```bash
cd Terraform/environments/test
```

Create `terraform.tfvars` (copy from example and edit):

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set project_id, region (e.g. us-central1), environment (e.g. dev)
```

Initialize Terraform (use your project ID in the bucket name):

```bash
terraform init \
  -backend-config="bucket=${PROJECT_ID}-terraform-state" \
  -backend-config="prefix=dev/state"
```

Plan and apply:

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
```

---

## Step B3: Configure Docker for Artifact Registry

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev --quiet
```

(Use the same region as in `terraform.tfvars`.)

---

## Step B4: Build and push images (local)

From the **repo root**:

```bash
export REGISTRY="us-central1-docker.pkg.dev/${PROJECT_ID}/hackathon-apps"

docker build -t $REGISTRY/application-service:latest ./application-service
docker push $REGISTRY/application-service:latest

docker build -t $REGISTRY/patient-service:latest ./patient-service
docker push $REGISTRY/patient-service:latest

docker build -t $REGISTRY/order-service:latest ./order-service
docker push $REGISTRY/order-service:latest
```

(Replace `us-central1` if you use another region.)

---

## Step B5: Get GKE credentials and deploy with Helm (local)

```bash
gcloud container clusters get-credentials dev-gke-cluster \
  --region us-central1 \
  --project $PROJECT_ID
```

From the **repo root**:

```bash
helm upgrade --install hackathon-apps ./helm/hackathon-apps \
  --set global.imageRegistry=us-central1-docker.pkg.dev/${PROJECT_ID}/hackathon-apps \
  --set global.imageTag=latest \
  --wait --timeout 5m
```

---

## Step B6: Get the app URL and access

Same as **Step A7**:

```bash
kubectl get ingress
```

Then open in browser:

- `http://<ADDRESS>/application`
- `http://<ADDRESS>/patient`
- `http://<ADDRESS>/order`

---

# Quick reference: order of steps

| Order | Path A (GitHub Actions)     | Path B (Local)                    |
|-------|-----------------------------|-----------------------------------|
| 1     | GCP setup (APIs, bucket, SA, key) | Same                             |
| 2     | Add GitHub secrets          | —                                 |
| 3     | Set tfvars + backend bucket | Terraform init / plan / apply     |
| 4     | Run Terraform workflow      | Docker auth + build + push        |
| 5     | Run Build and Push workflow | Helm upgrade --install            |
| 6     | Deploy workflow (auto/manual) | kubectl get ingress              |
| 7     | kubectl get ingress → open URLs | Same                             |

---

# Troubleshooting

- **Terraform: “bucket not found”**  
  Run Step A1.4 (or B1) to create the state bucket.

- **Terraform: “permission denied”**  
  Ensure the SA (or your user) has the roles in Step A1.6.

- **Build-push: “denied” or “repository not found”**  
  Run Terraform first so Artifact Registry exists. Ensure Docker is configured for `REGION-docker.pkg.dev`.

- **Deploy: “cluster not found”**  
  Use the same region everywhere (e.g. `us-central1`). Cluster name from Terraform is **dev-gke-cluster**.

- **Ingress has no ADDRESS**  
  Wait 5–10 minutes. Check: `kubectl describe ingress hackathon-apps-ingress`.
