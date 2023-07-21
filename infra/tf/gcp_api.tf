
resource "google_project_service" "dev_standalone_services" {
  for_each           = toset(var.env1_gcp_project_service_list)
  project            = var.env1_gcp_project
  service            = each.key
  disable_on_destroy = false
}

