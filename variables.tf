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

variable "nodeCount" {
  default = 4
}

variable "machineType" {
  default = "e2-standard-2"
}

variable "clusterName" {
  default = "onlineboutique"
}

variable "filepath_manifest" {
  description = "Path to folder where resides the main kustomization.yaml file"
  default     = "."
}