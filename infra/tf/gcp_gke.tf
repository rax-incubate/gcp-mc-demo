resource "google_service_account" "env1_gke" {
  project      = var.env1_gcp_project
  account_id   = "env1-gkesa"
  display_name = "GKE service account"
}


resource "google_project_iam_member" "env1_gke_artifacts" {
  project = var.env1_gcp_project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.env1_gke.email}"
}

resource "google_project_iam_member" "env1_gke_alloydb" {
  project = var.env1_gcp_project
  role    = "roles/alloydb.client"
  member  = "serviceAccount:${google_service_account.env1_gke.email}"
}


resource "google_project_iam_member" "env1_gke_secrets" {
  project = var.env1_gcp_project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.env1_gke.email}"
}


module "env1_gke" {
  source     = "terraform-google-modules/kubernetes-engine/google"
  project_id = var.env1_gcp_project
  name       = "env1-clu01"
  region     = var.env1_gcp_default_region
  zones      = ["${var.env1_gcp_default_region}-${var.env1_gcp_default_zone_suffix}"]
  network    = google_compute_network.env1_gcp_vpc.name
  subnetwork = google_compute_subnetwork.env1_vpc_subnetwork_private.name

  ip_range_pods     = var.env1_gcp_vpc.secondary_gke_pods_ip_range_name
  ip_range_services = var.env1_gcp_vpc.secondary_gke_services_ip_range_name

  create_service_account            = true
  remove_default_node_pool          = false
  disable_legacy_metadata_endpoints = true
  cluster_autoscaling               = var.env1_gke_cluster_autoscaling

  logging_enabled_components = ["SYSTEM_COMPONENTS", "CONTROLLER_MANAGER", "APISERVER", "WORKLOADS",  "SCHEDULER"]

  node_pools = [
    {
      name            = "env1-pool-01"
      machine_type    = "n2-standard-4"
      min_count       = 2
      max_count       = 3
      disk_size_gb    = 30
      disk_type       = "pd-standard"
      service_account = google_service_account.env1_gke.email
      auto_repair     = true
      auto_upgrade    = true
    },
    # Optional nodel pool
    # {
    #   name               = "env2-pool-02"
    #   machine_type       = "e2-small"
    #   min_count          = 2
    #   max_count          = 3
    #   disk_size_gb       = 30
    #   disk_type          = "pd-standard"
    #   auto_repair        = true
    #   auto_upgrade    = true
    #   service_account = google_service_account.env1_gke.email
    # }
  ]

  node_pools_metadata = {
    env1-pool-01 = {
      shutdown-script = "kubectl --kubeconfig=/var/lib/kubelet/kubeconfig drain --force=true --ignore-daemonsets=true --delete-local-data \"$HOSTNAME\""
    }
  }

  node_pools_labels = {
    all = var.env1_gcp_res_labels
    env1-pool-01 = {
      tier = "silver"
    }
  }

  node_pools_tags = {
    all = [
      "env1-gke-nodes",
    ]
  }

  node_pools_linux_node_configs_sysctls = {
    all = {
      "net.core.netdev_max_backlog" = "10000"
    }
  }
  monitoring_enabled_components = ["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER"]
}

