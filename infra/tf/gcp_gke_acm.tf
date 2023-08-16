
resource "google_gke_hub_membership" "membership" {
  provider      = google-beta
  project       = var.env1_gcp_project
  membership_id = "membership-hub-${module.env1_gke.name}"
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${module.env1_gke.cluster_id}"
    }
  }
}

resource "google_gke_hub_feature" "configmanagement_acm_feature" {
  project  = var.env1_gcp_project
  name     = "configmanagement"
  location = "global"
  provider = google-beta
}

resource "google_gke_hub_feature_membership" "feature_member" {
  project    = var.env1_gcp_project
  provider   = google-beta
  location   = "global"
  feature    = "configmanagement"
  membership = google_gke_hub_membership.membership.membership_id
  configmanagement {
    version = "1.15.0"
    config_sync {
      source_format = "hierarchy"
      git {
        sync_repo   = var.env1_sync_repo
        sync_branch = var.env1_sync_branch
        policy_dir  = var.env1_policy_dir
        secret_type = "none"
        # Set the following if you have private git repos. Also remove the secret_type from above.
        # secret_type = "token"
      }
    }
  }
  depends_on = [
    google_gke_hub_feature.configmanagement_acm_feature
  ]
}