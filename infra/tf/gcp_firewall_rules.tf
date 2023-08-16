resource "google_compute_firewall" "env1_allow_bastion_ssh" {
  project = var.env1_gcp_project

  name    = "env1-bastion-ssh"
  network = google_compute_network.env1_gcp_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = ["env1-bastion", "env1-alloy-helper"]
  source_ranges = var.env1_allow_ssh_ranges
}


resource "google_compute_firewall" "env1_allow_bastion_icmp" {
  project = var.env1_gcp_project

  name    = "env1-bastion-allow-icmp"
  network = google_compute_network.env1_gcp_vpc.name
  allow {
    protocol = "icmp"
  }
  target_tags   = ["env1-bastion", "env1-alloy-helper"]
  source_ranges = var.env1_allow_ssh_ranges
}


resource "google_compute_firewall" "env1_allow_bastion_icmp_egress" {
  project = var.env1_gcp_project

  name      = "env1-bastion-allow-icmp-egress"
  direction = "EGRESS"
  network   = google_compute_network.env1_gcp_vpc.name
  allow {
    protocol = "icmp"
  }
  target_tags   = ["env1-bastion", "env1-alloy-helper"]
  source_ranges = var.env1_allow_ssh_ranges
}