
resource "google_gke_hub_feature_membership" "env2_feature_member" {
  project    = var.env1_gcp_project
  provider   = google-beta
  location   = "global"
  feature    = "configmanagement"
  membership = "projects/${var.env1_gcp_project}/locations/global/memberships/${google_container_aws_cluster.env2_anthos_k8s.name}"
  configmanagement {
    version = "1.15.0"
    config_sync {
      source_format = "hierarchy"
      git {
        sync_repo   = var.env2_sync_repo
        sync_branch = var.env2_sync_branch
        policy_dir  = var.env2_policy_dir
        secret_type = "token"
      }
    }
  }
  depends_on = [
    google_gke_hub_feature.configmanagement_acm_feature
  ]
}