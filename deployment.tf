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
