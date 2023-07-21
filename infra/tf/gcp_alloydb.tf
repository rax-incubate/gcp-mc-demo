data "google_project" "env1_project" {
  project_id = var.env1_gcp_project
}


resource "google_alloydb_cluster" "env1_db" {
  project    = var.env1_gcp_project
  cluster_id = "env1-clu01"
  location   = var.env1_gcp_default_region
  network    = "projects/${data.google_project.env1_project.number}/global/networks/${google_compute_network.env1_gcp_vpc.name}"

  initial_user {
    user     = var.env1_gcp_alloydb_initial_user
    password = var.env1_gcp_alloydb_initial_pwd
  }

  automated_backup_policy {
    location      = var.env1_gcp_default_region
    backup_window = "1800s"
    enabled       = true

    weekly_schedule {
      days_of_week = ["MONDAY"]

      start_times {
        hours   = 23
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }

    quantity_based_retention {
      count = 2
    }
  }
  labels = var.env1_gcp_res_labels
}

resource "google_alloydb_instance" "env1_db_primary_instance" {
  cluster       = google_alloydb_cluster.env1_db.name
  instance_id   = "env1-db01"
  instance_type = "PRIMARY"
  display_name  = "Env1 Primary"

  availability_type = "REGIONAL"

  labels = merge(var.env1_gcp_res_labels)

  machine_config {
    cpu_count = 2
  }

  depends_on = [google_service_networking_connection.env1_db_vpc_connection]
}

resource "google_alloydb_instance" "env1_db_read_instance" {
  cluster       = google_alloydb_cluster.env1_db.name
  instance_id   = "read-instance"
  instance_type = "READ_POOL"
  display_name  = "Env1 Read"

  labels = merge(var.env1_gcp_res_labels)

  machine_config {
    cpu_count = 2
  }

  read_pool_config {
    node_count = 1
  }

  depends_on = [google_alloydb_instance.env1_db_primary_instance]
}

resource "google_compute_global_address" "env1_db_private_ip" {
  project = var.env1_gcp_project

  name          = "alloydb-cluster"
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  prefix_length = 16
  network       = google_compute_network.env1_gcp_vpc.id
}

resource "google_service_networking_connection" "env1_db_vpc_connection" {
  network                 = google_compute_network.env1_gcp_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.env1_db_private_ip.name]
}
