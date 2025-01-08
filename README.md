# onlineboutique-cloud-assignment

## To run the application

1. Run the following commands to create a service account and download the key file:

    ```bash
    # Replace [SERVICE_NAME] and [PROJECT_NAME] with your own values
    gcloud iam service-accounts create [SERVICE_NAME]
    gcloud projects add-iam-policy-binding [PROJECT_NAME] --member serviceAccount:[SERVICE_NAME]@[PROJECT_NAME].iam.gserviceaccount.com --role roles/editor
    gcloud iam service-accounts keys create ./[SERVICE_NAME].json --iam-account [SERVICE_NAME]@[PROJECT_NAME].iam.gserviceaccount.com
    ```

2. Copy terraform.tfvars.example to terraform.tfvars and update the values
3. `terraform init` and `terraform apply`
4. Update conguration with `kubectl apply -k .`

> [!IMPORTANT]
> Don't forget get the credentials with `gcloud container clusters get-credentials onlineboutique`

## Steps

### Mandatory base steps

- [x] Deploying the original application in GKE
- [x] Analyzing the provided configuration
- [x] Deploying the load generator on a local machine
- [x] Deploying automatically the load generator in Google Cloud

### Mandatory advanced steps

- [x] A | Monitoring the application and the infrastructure
- [ ] Next | Performance evaluation
- [ ] M | Canary releases

### Bonus steps

- [x] A | Monitoring the application and the infrastructure [Bonus]
- [ ] Next | Performance evaluation [Bonus]
- [ ] Next | Autoscaling [Bonus]
- [ ] Next | Optimizing the cost of your deployment [Bonus]
- [ ] M | Canary releases [Bonus]
- [ ] Next | Managing a storage backend for logging orders [Bonus]
- [ ] Next | Deploying your own Kubernetes infrastructure [Bonus]
- [ ] End | Review of recent publications [Bonus]


`kubectl debug -it <POD> --image=curlimages/curl -- /bin/sh` used for debugging with curl