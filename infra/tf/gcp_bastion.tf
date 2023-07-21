resource "google_service_account" "env1_bastion" {
  project      = var.env1_gcp_project
  account_id   = "env1-bastion"
  display_name = "Env1 Bastion service account"
}

resource "google_project_iam_member" "env1_bastion_alloy_binding1" {
  project = var.env1_gcp_project
  role    = "roles/alloydb.client"
  member  = "serviceAccount:${google_service_account.env1_bastion.email}"
}

resource "google_project_iam_member" "env1_bastion_alloy_binding2" {
  project = var.env1_gcp_project
  role    = "roles/alloydb.databaseUser"
  member  = "serviceAccount:${google_service_account.env1_bastion.email}"
}

resource "google_compute_address" "env1_bastion" {
  project = var.env1_gcp_project
  region  = var.env1_gcp_default_region
  name    = "env1-bastion"
}

resource "google_compute_instance_template" "env1_bastion" {
  project = var.env1_gcp_project
  region  = var.env1_gcp_default_region

  name_prefix          = "env1-bastion-"
  description          = "Env1 Bastion Temmplate."
  instance_description = "Env1 Bastion"
  machine_type         = var.env1_gcp_bastion_instance_type
  can_ip_forward       = false
  labels               = merge(var.env1_gcp_res_labels)
  tags                 = ["env1-bastion"]

  lifecycle {
    create_before_destroy = true
  }

  metadata = {
    ssh-keys = join("\n", [for key in var.env1_gcp_bastion_ssh_keys : "${key.user}:${key.publickey}"])
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = var.env1_gcp_default_instance_image
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network            = google_compute_network.env1_gcp_vpc.name
    subnetwork         = google_compute_subnetwork.env1_vpc_subnetwork_private.name
    subnetwork_project = var.env1_gcp_project
    access_config {
      nat_ip = google_compute_address.env1_bastion.address
    }
  }

  service_account {
    email = google_service_account.env1_bastion.email
    #scopes = ["userinfo-email", "compute-rw", "storage-rw", "cloud-platform", "bigquery"]
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<EOF
#! /bin/bash
sudo apt-get update
sudo apt-get install -y postgresql-client
sudo wget https://storage.googleapis.com/alloydb-auth-proxy/v1.3.0/alloydb-auth-proxy.linux.amd64 -O /usr/local/bin/alloydb-auth-proxy
sudo chmod +x /usr/local/bin/alloydb-auth-proxy
echo "startup:success" > /tmp/startup-status
EOF

}

resource "google_compute_instance_group_manager" "env1_bastion" {
  project            = var.env1_gcp_project
  name               = "env1-bastion01"
  base_instance_name = "env1-bastion"
  zone               = "${var.env1_gcp_default_region}-${var.env1_gcp_default_zone_suffix}"
  target_size        = 1
  version {
    name              = "bastion"
    instance_template = google_compute_instance_template.env1_bastion.self_link
  }
}
