
# Get the image. This setup assumes Ubuntu 22.04 LTS
data "aws_ami" "env2_alloydb" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_key_pair" "alloydb" {
  key_name   = var.env2_aws_alloydb_ssh_keys.name
  public_key = var.env2_aws_alloydb_ssh_keys.publickey
}

resource "aws_security_group" "env2_alloydb" {
  name        = "env2_alloydb"
  description = "Env2 Alloydb allow SSH from Bastion"
  vpc_id      = module.vpc.vpc_id
  tags        = var.env2_aws_res_tags
}

resource "aws_security_group_rule" "alloy_icmp" {
  type              = "ingress"
  description       = "ICMP from all"
  from_port         = 0
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.env2_alloydb.id
}

resource "aws_security_group_rule" "alloy_egress" {
  type              = "egress"
  description       = "Egress from all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.env2_alloydb.id
}

resource "aws_security_group_rule" "alloy_bastion_ssh" {
  type                     = "ingress"
  description              = "SSH from bastion"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.env2_alloydb.id
  source_security_group_id = aws_security_group.env2_bastion.id
}

resource "aws_security_group_rule" "alloyssh_all" {
  type              = "ingress"
  description       = "SSH from allocated ranges"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.env2_alloydb.id
  cidr_blocks       = var.env2_allow_ssh_ranges
}

resource "aws_security_group_rule" "alloy_bastion_postgres" {
  type        = "ingress"
  description = "Postgres from Bastion"

  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.env2_alloydb.id
  source_security_group_id = aws_security_group.env2_bastion.id
}

# By default, the Google Anthos module creates many security groups for the worker nodes
# We can use this data source to edit them. The alternative is to create a custom security group. 
# data "aws_security_groups" "anthos_np" {
#   tags = {
#     Name = "anthos-cp"
#   }
# }

# resource "aws_security_group_rule" "alloy_anthos_np_postgres" {
#   for_each                 = toset(data.aws_security_groups.anthos_np.ids)
#   description              = "Allow Anthos node pools to access alloydb"
#   type                     = "ingress"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.env2_alloydb.id
#   source_security_group_id = each.value
# }

# resource "aws_security_group_rule" "alloy_anthos_np_postgres_egress" {
#   for_each                 = toset(data.aws_security_groups.anthos_np.ids)
#   description              = "Allow Alloydb egress to Anthos node pools "
#   type                     = "egress"
#   from_port                = 0
#   to_port                  = 65535
#   protocol                 = "tcp"
#   security_group_id        = each.value
#   source_security_group_id = aws_security_group.env2_alloydb.id
# }


resource "aws_network_interface" "env2_alloydb" {
  subnet_id       = module.vpc.public_subnets[0]
  tags            = var.env2_aws_res_tags
  security_groups = [aws_security_group.env2_alloydb.id]
}

resource "aws_eip" "env2_alloydb" {
  domain = "vpc"
}

resource "aws_eip_association" "env2_alloydb" {
  instance_id   = aws_instance.env2_alloydb.id
  allocation_id = aws_eip.env2_alloydb.id
}

locals {
  env2_alloydb = {
    "Name" = "env2-db01"
  }
}

data "template_file" "alloydb_install" {
  template = file("${path.module}/files/aws/alloydb_install.sh.tpl")
  vars = {
    env2_alloydb_data_device_name = var.env2_alloydb_data_device_name
    env2_alloydb_myapp_user       = var.env2_alloydb_myapp_user
    env2_alloydb_myapp_pwd        = var.env2_alloydb_myapp_pwd
  }
}

resource "aws_ebs_volume" "env2_alloydb_data" {
  availability_zone = "${var.env2_aws_default_region}a"
  size              = var.env2_alloydb_data_volume_size
  type              = var.env2_alloydb_data_volume_type
  tags              = merge(var.env2_aws_res_tags, local.env2_alloydb)
}

resource "aws_volume_attachment" "env2_alloydb_data" {
  device_name = var.env2_alloydb_data_device_name
  volume_id   = aws_ebs_volume.env2_alloydb_data.id
  instance_id = aws_instance.env2_alloydb.id
}


resource "aws_instance" "env2_alloydb" {
  ami           = data.aws_ami.env2_alloydb.image_id
  instance_type = var.env2_alloydb_instance_type

  network_interface {
    network_interface_id = aws_network_interface.env2_alloydb.id
    device_index         = 0
  }
  root_block_device {
    volume_type           = var.env2_alloydb_root_volume_type
    volume_size           = var.env2_alloydb_root_volume_size
    delete_on_termination = true
  }

  key_name         = var.env2_aws_bastion_ssh_keys.name
  tags             = merge(var.env2_aws_res_tags, local.env2_alloydb)
  user_data_base64 = base64encode(data.template_file.alloydb_install.rendered)
}

# Create an auto-recovery setup for this instance
resource "aws_cloudwatch_metric_alarm" "env2_alloydb" {
  alarm_name          = "env2-alloydb"
  metric_name         = "StatusCheckFailed_System"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"

  dimensions = {
    InstanceId = aws_instance.env2_alloydb.id
  }

  namespace         = "AWS/EC2"
  period            = "60"
  statistic         = "Minimum"
  threshold         = "0"
  alarm_description = "Auto-recover the instance if the system status check fails for two minutes"
  alarm_actions = compact(
    concat(
      [
        "arn:${data.aws_partition.current.partition}:automate:${data.aws_region.current.name}:ec2:recover",
      ]
    )
  )
}