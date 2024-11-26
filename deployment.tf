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


resource "null_resource" "apply_kustomization" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.clusterName} --zone ${var.zone} --project ${var.project} && kubectl apply -k ."
  }
  depends_on = [google_container_cluster.primary]
}
