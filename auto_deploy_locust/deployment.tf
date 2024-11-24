provider "google" {
  credentials = file(var.deployKeyName)
  project     = var.project
  region      = var.region
}


resource "google_compute_instance" "vm_instance" {
  count        = var.machineCount
  name         = "${var.instanceName}-${count.index}"

  machine_type = var.machineType

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-117-lts"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network       = "default"
    access_config {
    }
  }
}


// A variable for extracting the external ip of the instance
output "ip" {
  value = "${google_compute_instance.vm_instance[0].network_interface.0.access_config.0.nat_ip}"
}
