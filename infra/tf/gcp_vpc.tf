resource "google_compute_network" "env1_gcp_vpc" {
  project                 = var.env1_gcp_project
  name                    = var.env1_gcp_vpc.name
  description             = var.env1_gcp_vpc.description
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}

resource "google_compute_router" "env1_gcp_vpc_router" {
  project = var.env1_gcp_project
  region  = var.env1_gcp_default_region
  name    = "env1-vpc-router"
  network = google_compute_network.env1_gcp_vpc.self_link
}

resource "google_compute_subnetwork" "env1_vpc_subnetwork_private" {
  project                  = var.env1_gcp_project
  region                   = var.env1_gcp_default_region
  network                  = google_compute_network.env1_gcp_vpc.self_link
  name                     = var.env1_gcp_vpc.private_primary_ip_range_name
  ip_cidr_range            = var.env1_gcp_vpc.private_primary_ip_cidr_range
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.env1_gcp_vpc.secondary_gke_pods_ip_range_name
    ip_cidr_range = var.env1_gcp_vpc.secondary_gke_pod_ip_cidr_range
  }

  secondary_ip_range {
    range_name    = var.env1_gcp_vpc.secondary_gke_services_ip_range_name
    ip_cidr_range = var.env1_gcp_vpc.secondary2_gke_services_ip_cidr_range
  }
}

resource "google_compute_router_nat" "env1_vpc_nat" {
  project                            = var.env1_gcp_project
  region                             = var.env1_gcp_default_region
  name                               = "env1-nat"
  router                             = google_compute_router.env1_gcp_vpc_router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.env1_vpc_subnetwork_private.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
