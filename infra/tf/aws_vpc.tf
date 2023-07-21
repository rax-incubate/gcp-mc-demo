module "vpc" {
  source              = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork//?ref=v0.12.2"
  name                = var.env2_aws_vpc.name
  az_count            = var.env2_aws_vpc.az_count
  cidr_range          = var.env2_aws_vpc.cidr_block
  private_cidr_ranges = [var.env2_aws_vpc.private_cidr_range_1, var.env2_aws_vpc.private_cidr_range_2]
  public_cidr_ranges  = [var.env2_aws_vpc.public_cidr_range_1, var.env2_aws_vpc.public_cidr_range_2]
  tags                = var.env2_aws_res_tags
}

