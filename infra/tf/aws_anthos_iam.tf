
# This creates a bunch of IAM configuration for Anthos
# See https://cloud.google.com/anthos/clusters/docs/multi-cloud/aws/how-to/create-aws-iam-roles#create_the_control_plane_role


data "google_project" "anthos_project" {
  project_id = var.env1_gcp_project

}

data "aws_iam_policy_document" "anthos_api_assume_document" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["accounts.google.com"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "accounts.google.com:sub"
      values = [
        "service-${data.google_project.anthos_project.number}@gcp-sa-gkemulticloud.iam.gserviceaccount.com"
      ]
    }
  }
}

resource "aws_iam_role" "anthos_api_role" {
  name = "anthos-api-role"

  description        = "IAM role for Anthos service"
  assume_role_policy = data.aws_iam_policy_document.anthos_api_assume_document.json

}

data "aws_iam_policy_document" "anthos_api_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:CreateOrUpdateTags",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:DeleteTags",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DisableMetricsCollection",
      "autoscaling:EnableMetricsCollection",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateNetworkInterface",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteLaunchTemplate",
      "ec2:DeleteNetworkInterface",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteTags",
      "ec2:DeleteVolume",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeInstances",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:GetConsoleOutput",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RunInstances",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RemoveTags",
      "iam:AWSServiceName",
      "iam:CreateServiceLinkedRole",
      "iam:PassRole",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKeyWithoutPlaintext"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "anthos_api_role" {
  name   = "anthos-api-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.anthos_api_policy_document.json
}


resource "aws_iam_role_policy_attachment" "anthos_api_role_policy_attachment" {
  role       = aws_iam_role.anthos_api_role.name
  policy_arn = aws_iam_policy.anthos_api_role.arn
}

data "aws_iam_policy_document" "anthos_cp_assume_document" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "anthos_cp_role" {
  name               = "anthos-cp-role"
  description        = "IAM role for the Anthos control plane"
  assume_role_policy = data.aws_iam_policy_document.anthos_cp_assume_document.json

}

data "aws_iam_policy_document" "anthos_cp_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:AttachNetworkInterface",
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateRoute",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteRoute",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSnapshot",
      "ec2:DeleteTags",
      "ec2:DeleteVolume",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVpcs",
      "ec2:DetachVolume",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyVolume",
      "ec2:RevokeSecurityGroupIngress",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:AttachLoadBalancerToSubnets",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancerListeners",
      "elasticloadbalancing:CreateLoadBalancerPolicy",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancerListeners",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeLoadBalancerPolicies",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DetachLoadBalancerFromSubnets",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
      "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
      "elasticfilesystem:CreateAccessPoint",
      "elasticfilesystem:DeleteAccessPoint",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:CreateGrant"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "anthos_cp_policy" {
  name   = "anthos-cp-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.anthos_cp_policy_document.json
}


resource "aws_iam_role_policy_attachment" "anthos_cp_role_policy_attachment" {
  role       = aws_iam_role.anthos_cp_role.name
  policy_arn = aws_iam_policy.anthos_cp_policy.arn
}

resource "aws_iam_instance_profile" "anthos_cp_instance_profile" {
  name = "anthos-cp-instance-profile"
  role = aws_iam_role.anthos_cp_role.id
}

data "aws_iam_policy_document" "anthos_np_assume_document" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "anthos_np_role" {
  name               = "anthos-np-role"
  description        = "IAM role for the Anthos node pool"
  assume_role_policy = data.aws_iam_policy_document.anthos_np_assume_document.json

}

data "aws_iam_policy_document" "anthos_np_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "anthos_np_policy" {
  name   = "anthos-np-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.anthos_np_policy_document.json
}

resource "aws_iam_role_policy_attachment" "anthos_np_role_policy_attachment" {
  role       = aws_iam_role.anthos_np_role.name
  policy_arn = aws_iam_policy.anthos_np_policy.arn
}

resource "aws_iam_instance_profile" "anthos_np_instance_profile" {
  name = "anthos-np-instance-profile"
  role = aws_iam_role.anthos_np_role.id
}