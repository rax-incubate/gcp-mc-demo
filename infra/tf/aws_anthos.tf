# Instance names
locals {
  env2_anthos_k8s_cp = {
    "Name" = "anthos-cp"
  }
  env2_anthos_k8s_np = {
    "Name" = "anthos-np"
  }
}


resource "google_container_aws_cluster" "env2_anthos_k8s" {
  project     = var.env1_gcp_project
  aws_region  = var.env2_aws_default_region
  description = "Env2 Anthos Cluster"
  location    = var.env1_gcp_default_region
  name        = "env2-cluster"
  authorization {
    dynamic "admin_users" {
      for_each = var.env2_anthos_admin_users
      content {
        username = admin_users.value
      }
    }
  }
  control_plane {
    iam_instance_profile = aws_iam_instance_profile.anthos_cp_instance_profile.name
    instance_type        = var.env2_control_plane_instance_type
    subnet_ids           = module.vpc.public_subnets
    tags                 = merge(var.env2_aws_res_tags, local.env2_anthos_k8s_cp)
    version              = var.env2_anthos_cluster_version

    aws_services_authentication {
      role_arn = aws_iam_role.anthos_api_role.arn
    }

    config_encryption {
      kms_key_arn = aws_kms_key.anthos_cp_config_kms_key.arn
    }

    database_encryption {
      kms_key_arn = aws_kms_key.anthos_db_kms_key.arn
    }

    main_volume {
      size_gib    = 30
      volume_type = "GP3"
      iops        = 3000
      kms_key_arn = aws_kms_key.anthos_cp_main_volume_kms_key.arn
    }

    root_volume {
      size_gib    = 30
      volume_type = "GP3"
      iops        = 3000
      kms_key_arn = aws_kms_key.anthos_cp_root_volume_kms_key.arn
    }
  }

  networking {
    pod_address_cidr_blocks     = var.env2_pod_address_cidr
    service_address_cidr_blocks = var.env2_svc_address_cidr
    vpc_id                      = module.vpc.vpc_id
  }

  fleet {
    project = data.google_project.anthos_project.number
  }

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}


resource "google_container_aws_node_pool" "env2_anthos_k8s" {
  project = var.env1_gcp_project

  name      = "env2-nodepool"
  cluster   = google_container_aws_cluster.env2_anthos_k8s.id
  subnet_id = module.vpc.public_subnets[0]
  version   = var.env2_anthos_cluster_version
  location  = google_container_aws_cluster.env2_anthos_k8s.location

  max_pods_constraint {
    max_pods_per_node = 110
  }

  autoscaling {
    min_node_count = 2
    max_node_count = 5
  }

  config {
    config_encryption {
      kms_key_arn = aws_kms_key.anthos_np_config_kms_key.arn
    }
    instance_type        = var.env2_node_pool_instance_type
    iam_instance_profile = aws_iam_instance_profile.anthos_np_instance_profile.name
    root_volume {
      size_gib    = 30
      volume_type = "GP3"
      iops        = 3000
      kms_key_arn = aws_kms_key.anthos_np_root_volume_kms_key.arn
    }

    # ssh_config {
    #   ec2_key_pair = var.env2_aws_bastion_ssh_keys.name
    # }
    tags = merge(var.env2_aws_res_tags, local.env2_anthos_k8s_np)
  }

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}