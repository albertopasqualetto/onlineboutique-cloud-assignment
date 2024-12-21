provider "google" {
  credentials = file(var.deployKeyName)
  project     = var.project
  region      = var.region
  zone        = var.zone
}

resource "google_container_cluster" "primary" {
  name     = var.clusterName
  location = var.zone

  enable_autopilot = false
  initial_node_count = var.nodeCount
  node_config {
    machine_type = var.machineType
  }
}

# Get credentials for cluster
module "gcloud" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.0"

  platform              = "linux"
  additional_components = ["kubectl", "beta"]

  create_cmd_entrypoint = "gcloud"
  # Module does not support explicit dependency
  # Enforce implicit dependency through use of local variable
  create_cmd_body = "container clusters get-credentials ${var.clusterName} --zone=${var.zone} --project=${var.project}"
}

# Apply YAML kubernetes-manifest configurations
resource "null_resource" "apply_deployment" {
  provisioner "local-exec" {
    command     = "kubectl apply -k ${var.filepath_manifest}"
  }

  depends_on = [
    module.gcloud
  ]
}

# Wait condition for all Pods to be ready before finishing
resource "null_resource" "wait_conditions" {
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = <<-EOT
    kubectl wait --for=condition=AVAILABLE apiservice/v1beta1.metrics.k8s.io --timeout=180s
    kubectl wait --for=condition=ready pods --all --timeout=280s
    EOT
  }

  depends_on = [
    resource.null_resource.apply_deployment
  ]
}