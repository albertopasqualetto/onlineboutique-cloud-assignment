# The Report
## Deploying the original application in GKE
We created the cluster from GKE dashboard, choosing the standard configuration (zone, cluster name, node count ...).

Then we cloned the repository;
 and we connected to the cluster with 
**gcloud container clusters get-credentials onlineboutique**

***kubectl apply -f ./release/kubernetes-manifests.yaml***

We verified the deployment was succesfull obtaining the ip address of the frontends load balancer with ***kubectl get services frontend-external*** and throw output of the load generator with ***kubectl logs loadgenerator-5fcfd6896b-q4dlv***

Explain the Autopilot mod.

## Analyzing the provided configuration

gia fatto

## Deploying the load generator on a local machine

We build the image of the load generator ***microservices-demo/src/loadgenerator/Dockerfile*** using the command ***docker buildx build path/to/Dockerfile parent***. Then we ran the container with ***docker run -e FRONTEND_ADDR=[ADDRESS] -e USERS=10 [IMAGE ID]*** and we analyzed the output and we understood that it was accesible outside.

## Deploying automatically the load generator in Google Cloud

- We took from "Running MPI applications" the Terraform-related files (`simple_deployment.tf`, `variables.tf`, `parse-tf-state.py`, `setup.sh`) and we modified them to run an image with docker engine installed (`boot_disk.initialize_params.image="cos-cloud/cos-117-lts"`) within our GCP project.
- We created the ansible ? `upload_build_run_docker.yml` to upload the Locust loadgenerator Dockerfile to the GCP project, build and run it. # TODO .env?

# TODO change loadgenerator folder

# TODO using kustomize

# TODO test new automated deployment.tf