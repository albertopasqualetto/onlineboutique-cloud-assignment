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
  default = 1
}

variable "machineType" {
  default = "f1-micro"
}

variable "instanceName" {
  default = "auto-deploy-loadgenerator"
}

variable "GCPUserID" {
}

variable "GCPPrivateSSHKeyFile" {
}