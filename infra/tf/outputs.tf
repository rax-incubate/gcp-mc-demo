output "env1_cluster_location" {
  value = module.env1_gke.location
}

output "env1_cluster_name" {
  value = module.env1_gke.name
}

output "env1_bastion_ip" {
  value = google_compute_address.env1_bastion.address
}

output "env1_alloydb_helper_ip" {
  value = google_compute_address.env1_alloy_helper.address
}

output "env1_db_prim_ip" {
  value = google_alloydb_instance.env1_db_primary_instance.ip_address
}

output "env1_db_prim_id" {
  value = google_alloydb_instance.env1_db_primary_instance.id
}

output "env1_db_read_ip" {
  value = google_alloydb_instance.env1_db_read_instance.ip_address
}

output "env1_db_read_id" {
  value = google_alloydb_instance.env1_db_read_instance.id
}

output "env2_bastion_ip" {
  value = aws_eip.env2_bastion.public_ip
}

output "env2_bastion_private_ip" {
  value = aws_eip.env2_bastion.private_ip
}


output "env2_cluster_name" {
  value = google_container_aws_cluster.env2_anthos_k8s.name
}

output "env2_cluster_location" {
  value = google_container_aws_cluster.env2_anthos_k8s.location
}


output "env2_anthos_api_role_arn" {
  value = aws_iam_role.anthos_api_role.arn
}

output "env2_anthos_cp_role_arn" {
  value = aws_iam_role.anthos_cp_role.arn
}

output "env2_anthos_np_role_arn" {
  value = aws_iam_role.anthos_np_role.arn
}

output "env2_db_prim_public_ip" {
  value = aws_eip.env2_alloydb.public_ip
}

output "env2_db_prim_ip" {
  value = aws_instance.env2_alloydb.private_ip
}

output "bigquery_omni_role" {
    value = aws_iam_role.bq_omni.arn
}
