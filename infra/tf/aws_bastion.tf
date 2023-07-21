data "aws_ami" "env2_bastion" {
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
resource "aws_key_pair" "bastion" {
  key_name   = var.env2_aws_bastion_ssh_keys.name
  public_key = var.env2_aws_bastion_ssh_keys.publickey
}

resource "aws_security_group" "env2_bastion" {
  name        = "env2_bastion"
  description = "Env2 bastion allow SSH"
  vpc_id      = module.vpc.vpc_id
  tags = var.env2_aws_res_tags
}

resource "aws_security_group_rule" "bastion_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.env2_bastion.id
}

resource "aws_security_group_rule" "bastion_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.env2_bastion.id
  cidr_blocks       = var.env2_allow_ssh_ranges
}

resource "aws_security_group_rule" "bastion_icmp" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "icmp"
  security_group_id = aws_security_group.env2_bastion.id
  cidr_blocks       = var.env2_allow_ssh_ranges
}



resource "aws_network_interface" "env2_bastion" {
  subnet_id       = module.vpc.public_subnets[0]
  tags            = var.env2_aws_res_tags
  security_groups = [aws_security_group.env2_bastion.id]
}

resource "aws_eip" "env2_bastion" {
  vpc = true
}

resource "aws_eip_association" "env2_bastion" {
  instance_id   = aws_instance.env2_bastion.id
  allocation_id = aws_eip.env2_bastion.id
}

locals {
  env2_bastion = {
    "Name" = "env2-bastion"
  }
}


data "template_file" "bastion_install" {
  template = file("${path.module}/files/aws/bastion_install.sh.tpl")
  vars = {
    my_hostname = "env2-aws-bastion"
  }
}

resource "aws_instance" "env2_bastion" {
  ami           = data.aws_ami.env2_bastion.image_id
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.env2_bastion.id
    device_index         = 0
  }
  key_name = var.env2_aws_bastion_ssh_keys.name
  tags     = merge(var.env2_aws_res_tags, local.env2_bastion)
  user_data_base64 = base64encode(data.template_file.bastion_install.rendered)

}
