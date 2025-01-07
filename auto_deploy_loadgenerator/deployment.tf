provider "google" {
  credentials = file(var.deployKeyName)
  project     = var.project
  region      = var.region
  zone        = var.zone
}


resource "google_compute_instance" "vm_instance" {
  count        = var.machineCount
  name         = "${var.instanceName}-${count.index}"
  zone         = var.zone

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

# output "ip" {
#   value = "${google_compute_instance.vm_instance[0].network_interface.0.access_config.0.nat_ip}"
# }

resource "local_file" "hosts" {
    # content  = google_compute_instance.vm_instance.*.network_interface.0.access_config.0.access_config.0.nat_ip
    content = <<EOF
${google_compute_instance.vm_instance[0].network_interface.0.access_config.0.nat_ip}

[all:vars]
ansible_ssh_user=${var.GCPUserID}
ansible_ssh_private_key_file='${var.GCPPrivateSSHKeyFile}'
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
    filename = "hosts"
}
