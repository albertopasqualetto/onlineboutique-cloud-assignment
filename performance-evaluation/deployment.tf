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
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network       = "default"
    access_config {
    }
  }
}

resource "local_file" "hosts" {
    content = <<EOF
%{ for i in range(var.machineCount) }
${google_compute_instance.vm_instance[i].network_interface.0.access_config.0.nat_ip}
%{ endfor }

[all:vars]
ansible_ssh_user=${var.GCPUserID}
ansible_ssh_private_key_file='${var.GCPPrivateSSHKeyFile}'
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
    filename = "hosts"
}

resource "local_file" "loadgenerator_ips" {
    content = <<EOF
%{ for i in range(var.machineCount) }${google_compute_instance.vm_instance[i].network_interface.0.access_config.0.nat_ip}${i < var.machineCount - 1 ? "," : ""}%{ endfor }
EOF
    filename = "loadgenerator_ips"
}