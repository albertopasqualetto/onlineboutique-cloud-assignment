variable "project" {
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-b"
}

variable "deployKeyName" {
}

variable "machineCount" {
}

variable "machineType" {
  default = "f1-micro"
}

variable "instanceName" {
  default = "loadgenerator"
}

variable "GCPUserID" {
}

variable "GCPPrivateSSHKeyFile" {
}