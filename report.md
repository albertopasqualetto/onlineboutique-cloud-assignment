# The Report

Every command is to be run from the root of the repository.

## Deploying the original application in GKE

We created the cluster from GKE dashboard, choosing the standard configuration (zone, cluster name, node count ...).

Then we cloned the repository;
 and we connected to the cluster with `gcloud container clusters get-credentials onlineboutique`

`kubectl apply -f ./release/kubernetes-manifests.yaml`

We verified the deployment was succesfull obtaining the ip address of the frontends load balancer with `kubectl get services frontend-external` and throw output of the load generator with `kubectl logs <LOADGENERATOR POD NAME>`. # TODO substitute with pod name

Explain the Autopilot mode.

## Analyzing the provided configuration

gia fatto

## Deploying the load generator on a local machine

We used the image of the load generator provided by the original repository (`us-central1-docker.pkg.dev/google-samples/microservices-demo/loadgenerator:v0.10.2`) and we ran it with the command `docker run -e FRONTEND_ADDR=<ADDRESS> -e USERS=10 <IMAGE ID>` and we analyzed the output and we understood it was accesible outside.

<!-- We build the image of the load generator ***microservices-demo/src/loadgenerator/Dockerfile*** using the command ***docker buildx build path/to/Dockerfile parent***. Then we ran the container with ***docker run -e FRONTEND_ADDR=[ADDRESS] -e USERS=10 [IMAGE ID]*** and we analyzed the output and we understood that it was accesible outside. -->

## Deploying automatically the load generator in Google Cloud

- We took from "Running MPI applications" the Terraform-related files (`simple_deployment.tf`, `variables.tf`, `parse-tf-state.py`, `setup.sh`) and we modified them to run an image with docker engine installed (`boot_disk.initialize_params.image="cos-cloud/cos-117-lts"`) within our GCP project and then we ran with `terraform -chdir=auto_deploy_loadgenerator init`.
- To run it, `GCPUserID` and `GCPPrivateSSHKeyFile` variables are needed.
- Everything is setup by terraform (hosts inventory file also)
- `terraform -chdir="auto_deploy_loadgenerator" plan -var-file="../terraform.tfvars"`
- `terraform -chdir="auto_deploy_loadgenerator" apply -var-file="../terraform.tfvars"`

- We created the ansible playbook `run_docker_image.yml` to run the Locust loadgenerator.
- `ansible-playbook -i ./auto_deploy_loadgenerator/hosts ./auto_deploy_loadgenerator/run_docker_image.yml --extra-vars "frontend_external_ip=$(kubectl get svc frontend-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}')` # TODO fix this with new istio
- ansible does not work from Windows!!!

