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
4. `istioctl manifest install --set profile=default` to install Istio
5. `kubectl label namespace default istio-injection=enabled` to enable Istio sidecar injection
6. Apply conguration with `kubectl apply -k .`

> [!IMPORTANT]
> Don't forget to get the credentials with `gcloud container clusters get-credentials onlineboutique`

`kubectl debug -it <POD> --image=curlimages/curl -- /bin/sh` used for debugging with curl

Report [here](./report.md).