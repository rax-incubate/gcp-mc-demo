
# This creates a bunch of KMS configuration for Anthos
# See https://cloud.google.com/anthos/clusters/docs/multi-cloud/aws/how-to/create-aws-iam-roles#create_the_control_plane_role


resource "aws_kms_key" "anthos_db_kms_key" {
  description = "AWS Database Encryption KMS Key"
}

resource "aws_kms_alias" "anthos_db_kms_key_alias" {
  target_key_id = aws_kms_key.anthos_db_kms_key.arn
  name          = "alias/anthos-database-key"
}

resource "aws_kms_key" "anthos_cp_config_kms_key" {
  description = "Control Plane Configuration KMS Key"
}

resource "aws_kms_alias" "anthos_cp_config_kms_key_alias" {
  target_key_id = aws_kms_key.anthos_cp_config_kms_key.arn
  name          = "alias/anthos-cp-config-key"
}

resource "aws_kms_key" "anthos_cp_main_volume_kms_key" {
  description = "Control Plane Main Volume KMS Key"
}

resource "aws_kms_alias" "anthos_cp_main_volume_kms_key_alias" {
  target_key_id = aws_kms_key.anthos_cp_main_volume_kms_key.arn
  name          = "alias/anthos-cp-main-volume-key"
}

resource "aws_kms_key" "anthos_cp_root_volume_kms_key" {
  description = "Control Plane Root Volume  KMS Key"
  policy      = data.aws_iam_policy_document.anthos_root_volume_policy_document.json
}

resource "aws_kms_alias" "anthos_cp_root_volume_kms_key_alias" {
  target_key_id = aws_kms_key.anthos_cp_root_volume_kms_key.arn
  name          = "alias/anthos-cp-root-volume-key"
}

data "aws_iam_policy_document" "anthos_root_volume_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["kms:CreateGrant"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "arn:aws:kms:${var.env2_aws_default_region}:${data.aws_caller_identity.current.account_id}:key/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
  }
  statement {
    effect  = "Allow"
    actions = ["kms:GenerateDataKeyWithoutPlaintext"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "arn:aws:kms:${var.env2_aws_default_region}:${data.aws_caller_identity.current.account_id}:key/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
  }
  // Allow access by root account.
  statement {
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
  }
}

resource "aws_kms_key" "anthos_np_config_kms_key" {
  description = "Anthos Node Pool Configuration Encryption KMS Key"
}

resource "aws_kms_alias" "anthos_np_config_kms_key_alias" {
  target_key_id = aws_kms_key.anthos_np_config_kms_key.arn
  name          = "alias/anthos-np-config-key"
}

resource "aws_kms_key" "anthos_np_root_volume_kms_key" {
  description = "Anthos Node Pool Root Volume Encryption KMS Key"
  policy      = data.aws_iam_policy_document.anthos_root_volume_policy_document.json
}

resource "aws_kms_alias" "anthos_np_root_volume_kms_key_alias" {
  target_key_id = aws_kms_key.anthos_np_root_volume_kms_key.arn
  name          = "alias/anthos-np-root-volume-key"
}
