terraform {
  required_version = ">= 1"
  required_providers {
    google = {
    }
    google-beta = {
    }
    aws = {
    }
  }
}

provider "google" {
  alias   = "env1"
  project = var.env1_gcp_project
  region  = var.default_region
}

provider "google-beta" {
  alias   = "env1"
  project = var.env1_gcp_project
  region  = var.env1_gcp_default_region
}

provider "aws" {
  region = var.env2_aws_default_region
}

data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "aws_partition" "current" {
}
