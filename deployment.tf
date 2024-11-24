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

output "kubeconfig" {
  value = google_container_cluster.primary.endpoint
}


provider "kubernetes" {
  host                   = google_container_cluster.primary.endpoint
  client_certificate     = base64decode(google_container_cluster.primary.master_auth.0.client_certificate)
  client_key             = base64decode(google_container_cluster.primary.master_auth.0.client_key)
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}

resource "null_resource" "apply_kustomization" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${var.clusterName} --region ${var.region} --project ${var.project}
      kubectl apply -k .
    EOT
  }

  depends_on = [google_container_cluster.primary]
}
