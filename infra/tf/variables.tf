# Any variable with env1 is GCP and env2 is AWS

## Env1 General

variable "env1_gcp_project" {
  type        = string
  description = "The GCP project where resources will created. Make sure env1_gcp_project is set at the command line or this is setup in the tfvars file"
}

variable "env1_gcp_default_region" {
  type        = string
  description = "The default GCP Region for resources"
  default     = "us-east4"
}

variable "env1_gcp_default_zone_suffix" {
  type        = string
  description = "The single letter sufix for a zone used with the default region."
  default     = "c"
}

variable "env1_gcp_res_labels" {
  description = "Labels that apply to all resources"
  type        = map(any)
  default = {
    "management_tool" = "terraform"
    "environment"     = "test"
  }
}

variable "env1_gcp_project_service_list" {
  description = "The list of apis necessary"
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "iamcredentials.googleapis.com",
    "iam.googleapis.com",
    "cloudbilling.googleapis.com",
    "monitoring.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "containersecurity.googleapis.com",
    "osconfig.googleapis.com",
    "alloydb.googleapis.com",
    "compute.googleapis.com",
    "gkehub.googleapis.com",
    "anthosconfigmanagement.googleapis.com"
  ]
}

## Env1 VPC
variable "env1_gcp_vpc" {
  description = "All GCP VPC Variables"
  type        = map(any)
  default = {
    name                                  = "env1-vpc"
    description                           = "Env1 Vpc"
    private_primary_ip_range_name         = "env1-private"
    private_primary_ip_cidr_range         = "172.25.0.0/16"
    secondary_gke_pods_ip_range_name      = "env1-gke-pods"
    secondary_gke_pod_ip_cidr_range       = "172.26.0.0/16"
    secondary_gke_services_ip_range_name  = "env1-gke-services"
    secondary2_gke_services_ip_cidr_range = "172.27.0.0/16"
  }
}

## Env1 GKE
variable "env1_gke_cluster_autoscaling" {
  type = object({
    enabled             = bool
    autoscaling_profile = string
    min_cpu_cores       = number
    max_cpu_cores       = number
    min_memory_gb       = number
    max_memory_gb       = number
    gpu_resources = list(object({
      resource_type = string
      minimum       = number
      maximum       = number
    }))
    auto_repair  = bool
    auto_upgrade = bool
  })
  description = "Cluster autoscaling configuration. See [more details](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1beta1/projects.locations.clusters#clusterautoscaling)"
}

## Env1 ACM

variable "env1_sync_repo" {
  type        = string
  description = "git URL for the repo which will be sync'ed into the cluster via Config Management. See Readme on how to setup private repos with credentials"
  default     = "https://github.com/rax-incubate/gcp-multi-cloud-demo.git"
}

variable "env1_sync_branch" {
  type        = string
  description = "the git branch in the repo to sync"
  default     = "main"
}

variable "env1_policy_dir" {
  type        = string
  description = "The directory in the repo branch that contains the app resources."
  default     = "apps/env1"

}

## Env1 Bastion

variable "env1_gcp_bastion_ssh_keys" {
  type = list(object({
    publickey = string
    user      = string
  }))
  description = "List of public ssh keys that have access to Bastion."
  default = [
    {
      user      = "ubuntu"
      publickey = "ssh-rsa NOKEY=="
    }
  ]
}

variable "env1_allow_ssh_ranges" {
  description = "List of IP ranges to allow SSH from"
  type        = list
  default     = ["0.0.0.0/0"]
}

variable "env1_gcp_bastion_instance_type" {
  description = "Bastion Instance type"
  type        = string
  default     = "e2-micro"

}

variable "env1_gcp_default_instance_image" {
  description = "OS image used for bastion"
  type        = string
  default     = "projects/ubuntu-os-cloud/global/images/ubuntu-1804-bionic-v20221005"
}

## Env1 AlloyDB

variable "env1_gcp_alloydb_initial_user" {
  description = "Username for the initial user with admin privs"
  type        = string
}

variable "env1_gcp_alloydb_initial_pwd" {
  description = "Password for the initial user with admin privs"
  type        = string
}

variable "env1_alloydb_myapp_user" {
  type        = string
  description = "User that is created inside Postgres using cloud init. See Readme for details"
}

variable "env1_alloydb_myapp_pwd" {
  type        = string
  description = "Password that is set for the  env2_alloydb_myapp_user user on Postgres. See Readme for details"
}

variable "env1_gcp_alloy_helper_ssh_keys" {
  type = list(object({
    publickey = string
    user      = string
  }))
  description = "List of public ssh keys that have access to Bastion."
  default = [
    {
      user      = "ubuntu"
      publickey = "ssh-rsa NOKEY=="
    }
  ]
}

variable "env1_gcp_alloy_helper_instance_type" {
  description = "Bastion Instance type"
  type        = string
  default     = "e2-micro"

}


## Env2 General

variable "env2_aws_default_region" {
  type        = string
  description = "The default AWS Region for resources. Must match a supported region https://cloud.google.com/anthos/clusters/docs/multi-cloud/aws/reference/supported-regions"
  default     = "us-east-1"
}

variable "env2_bq_omni_region" {
  type        = string
  description = "The default AWS Region for resources. Must match a supported region https://cloud.google.com/anthos/clusters/docs/multi-cloud/aws/reference/supported-regions"
  default     = "us-east-1"
}


variable "env2_aws_res_tags" {
  description = "AWS tags that apply to all resources"
  type        = map(any)
  default = {
    "management_tool" = "terraform"
    "environment"     = "test"
  }
}

## Env2 VPC
variable "env2_aws_vpc" {
  description = "All AWS VPC Variables"
  type        = map(any)
  default = {
    name        = "env2-network"
    description = "Env2 VPC"
    az_count    = 2

    cidr_block           = "10.0.0.0/16"
    private_cidr_range_1 = "10.0.0.0/19"
    private_cidr_range_2 = "10.0.32.0/19"
    public_cidr_range_1  = "10.0.64.0/19"
    public_cidr_range_2  = "10.0.86.0/23"
  }
}

## Env2 Bastion
variable "env2_aws_bastion_ssh_keys" {
  type        = map(any)
  description = "Public ssh key that has access to Bastion"
}

variable "env2_allow_ssh_ranges" {
  description = "List of IP ranges to allow SSH from"
  type        = list
  default     = ["0.0.0.0/0"]
}

## Env2 AlloyDB

variable "env2_aws_alloydb_ssh_keys" {
  type        = map(any)
  description = "Public ssh key that has access to AlloyDB instances"
}

variable "env2_alloydb_instance_type" {
  type        = string
  description = "Instance type for Ec2. For test, t3 instances will work. For prod, see https://cloud.google.com/alloydb/docs/omni/install"
  default     = "t3.large"
}

variable "env2_alloydb_root_volume_type" {
  type        = string
  description = "Root volume type"
  default     = "gp2"
}

variable "env2_alloydb_root_volume_size" {
  type        = string
  description = "Root volume size"
  default     = "64"
}

variable "env2_alloydb_data_volume_type" {
  type        = string
  description = "Data volume type"
  default     = "gp2"
}

variable "env2_alloydb_data_volume_size" {
  type        = string
  description = "Data volume size"
  default     = "64"
}

variable "env2_alloydb_data_device_name" {
  type        = string
  description = "Device name used to mount the EBS volumen on the alloydb instance"
  default     = "/dev/xvdbd"
}

variable "env2_alloydb_myapp_user" {
  type        = string
  description = "User that is created inside Postgres using cloud init. See Readme for details"
}

variable "env2_alloydb_myapp_pwd" {
  type        = string
  description = "Password that is set for the  env2_alloydb_myapp_user user on Postgres. See Readme for details"
}


## Env2 Anthos

variable "env2_anthos_admin_users" {
  type        = list(string)
  description = "Users to perform operations as a cluster admin. A managed ClusterRoleBinding will be created to grant the cluster-admin ClusterRole to the users. Up to ten admin users can be provided. For more info on RBAC, see https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles"
}

variable "env2_node_pool_instance_type" {
  type        = string
  description = "Instance type for the worker nodes"
  default     = "t3.medium"
}


variable "env2_control_plane_instance_type" {
  type        = string
  description = "Instance type for the control plane nodes"
  default     = "t3.medium"
}

variable "env2_anthos_cluster_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.25.5-gke.2000"
}

variable "env2_pod_address_cidr" {
  type        = list(any)
  description = "Pod addresses for k8s"
  default     = ["10.2.0.0/16"]
}

variable "env2_svc_address_cidr" {
  type        = list(any)
  description = "Service addresses for k8s"
  default     = ["10.3.0.0/16"]
}

## Env2 ACM

variable "env2_sync_repo" {
  type        = string
  description = "git URL for the repo which will be sync'ed into the cluster via Config Management. See Readme on how to setup private repos with credentials"
  default     = "https://github.com/rax-incubate/gcp-multi-cloud-demo.git"
}

variable "env2_sync_branch" {
  type        = string
  description = "the git branch in the repo to sync"
  default     = "main"
}

variable "env2_policy_dir" {
  type        = string
  description = "The directory in the repo branch that contains the app resources."
  default     = "apps/env2"
}

## Env2 BQ

variable "env2_bq_data_bucket" {
  type        = string
  description = "S3 bucket used with BQ"
}
