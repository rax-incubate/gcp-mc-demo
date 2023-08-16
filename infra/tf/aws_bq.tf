resource "aws_s3_bucket" "bq_data" {
  bucket = var.env2_bq_data_bucket

  tags = merge(var.env2_aws_res_tags, local.env2_bastion)
}

resource "google_bigquery_connection" "bq_omni" {
  project       = var.env1_gcp_project
  connection_id = "bq-omni-aws-connection"
  friendly_name = "bq-omni-aws-connection"

  location = "aws-${var.env2_aws_default_region}"
  aws {
    access_role {
      # This must be constructed as a string instead of referencing the AWS resources
      # directly to avoid a resource dependency cycle in Terraform.
      iam_role_id = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/bq-omni-connection"
    }
  }
}