#!/bin/bash

# TODO redundant with variables.tf

### Main variables

# User ID on GCP
export GCP_userID="alberto_pasqualetto01"

# Private key to use to connect to GCP
export GCP_privateKeyFile="~/.ssh/google_compute_engine"

# Name of your GCP project
export TF_VAR_project="cloud-computing-course-438614"

# Name of your selected GCP region
export TF_VAR_region="us-central1"

# Name of your selected GCP zone
export TF_VAR_zone="us-central1-b"



### Other variables used by Terrform

# Number of VMs created
export TF_VAR_machineCount=1

# VM type
export TF_VAR_machineType="f1-micro"

# Prefix for you VM instances
export TF_VAR_instanceName="tf-instance"

# Prefix of your GCP deployment key
export TF_VAR_deployKeyName="/home/alberto_pasqualetto01/terraform-acc.json"
