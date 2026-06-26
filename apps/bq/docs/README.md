# Github/GCP integration via Workload Identity Federation (WIF)

##1. Crea il Workload Identity Pool
```
gcloud iam workload-identity-pools create github-pool \
    --project=invcerts \
    --location=global \
    --display-name="GitHub Pool"
```

#2. Crea il Provider OIDC
```
gcloud iam workload-identity-pools providers create-oidc github \
    --project=invcerts \
    --location=global \
    --workload-identity-pool=github-pool \
    --display-name="GitHub Provider" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
    --attribute-condition="assertion.repository=='mixxr/rws' && assertion.ref=='refs/heads/main'" 
```

##3. Recupera il nome del Provider
Ti servirà nella GitHub Action.
```
gcloud iam workload-identity-pools providers describe github \
    --location=global \
    --workload-identity-pool=github-pool \
    --project=invcerts
```
il risultato lo inserirai:
```
- uses: google-github-actions/auth@v3
  with:
    workload_identity_provider: projects/<your-prj-id>/locations/global/workloadIdentityPools/github-pool/providers/github
    service_account: <your-svc-acc-id>@my-project.iam.gserviceaccount.com
```

##4.Impersonate Setup
```
gcloud iam service-accounts add-iam-policy-binding \
  github-actions@invcerts.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/600125851897/locations/global/workloadIdentityPools/github-pool/attribute.repository/mixxr/rws"
```