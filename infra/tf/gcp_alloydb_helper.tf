resource "google_service_account" "env1_alloy_helper" {
  project      = var.env1_gcp_project
  account_id   = "env1-alloy-helper"
  display_name = "Env1 Alloy helper service account"
}

resource "google_project_iam_member" "env1_helper_alloy_binding1" {
  project = var.env1_gcp_project
  role    = "roles/alloydb.client"
  member  = "serviceAccount:${google_service_account.env1_alloy_helper.email}"
}

resource "google_project_iam_member" "env1_helper_alloy_binding2" {
  project = var.env1_gcp_project
  role    = "roles/alloydb.databaseUser"
  member  = "serviceAccount:${google_service_account.env1_alloy_helper.email}"
}


resource "google_compute_address" "env1_alloy_helper" {
  project = var.env1_gcp_project
  region  = var.env1_gcp_default_region
  name    = "env1-alloy-helper"
}


resource "google_compute_instance" "env1_alloy_helper" {

  depends_on = [google_alloydb_instance.env1_db_primary_instance]

  project        = var.env1_gcp_project
  name           = "env1-alloy-helper"
  machine_type   = var.env1_gcp_alloy_helper_instance_type
  can_ip_forward = false
  labels         = merge(var.env1_gcp_res_labels)
  tags           = ["env1-alloy-helper"]
  zone           = "${var.env1_gcp_default_region}-${var.env1_gcp_default_zone_suffix}"

  boot_disk {
    initialize_params {
      image = var.env1_gcp_default_instance_image
    }
  }

  network_interface {
    network            = google_compute_network.env1_gcp_vpc.name
    subnetwork         = google_compute_subnetwork.env1_vpc_subnetwork_private.name
    subnetwork_project = var.env1_gcp_project
    access_config {
      nat_ip = google_compute_address.env1_alloy_helper.address
    }
  }

  metadata = {
    ssh-keys = join("\n", [for key in var.env1_gcp_alloy_helper_ssh_keys : "${key.user}:${key.publickey}"])
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  service_account {
    email  = google_service_account.env1_alloy_helper.email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = <<EOF
#! /bin/bash
sudo apt-get update
sudo apt-get install -y postgresql-client
export PGPASSWORD=${var.env1_gcp_alloydb_initial_pwd}
export ALLOYDB_PRIMARY_IP=${google_alloydb_instance.env1_db_primary_instance.ip_address}
export MYAPP_USER=${var.env1_alloydb_myapp_user}
export MYAPP_USER_PWD=${var.env1_alloydb_myapp_pwd}
psql -h $${ALLOYDB_PRIMARY_IP} -U root template1 -c "CREATE USER $${MYAPP_USER} WITH LOGIN ENCRYPTED PASSWORD '"$${MYAPP_USER_PWD}"'"
psql -h $${ALLOYDB_PRIMARY_IP} -U root template1 -c "ALTER USER $${MYAPP_USER} CREATEDB"
export PGPASSWORD=$${MYAPP_USER_PWD}
psql -h $${ALLOYDB_PRIMARY_IP} -U $${MYAPP_USER} template1 -c "CREATE DATABASE imdb"
psql -h $${ALLOYDB_PRIMARY_IP} -U $${MYAPP_USER} imdb -c "CREATE TABLE title_basics(tconst varchar(12), title_type varchar(80), primary_title varchar(512), original_title varchar(512), is_adult boolean,start_year smallint, end_year smallint, runtime_minutes int, genres varchar(80))"
gsutil cp gs://gcp-mc-demo/myapp/title.basics.tsv.gz /home/ubuntu/
gunzip /home/ubuntu/title.basics.tsv.gz
psql -h $${ALLOYDB_PRIMARY_IP} -U $${MYAPP_USER} imdb -c "\copy title_basics FROM '/home/ubuntu/title.basics.tsv'"
EOF
}
