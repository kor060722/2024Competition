#
# Create Key-pair
#
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_keypair" {
  key_name   = "bastion-keypair.pem"
  public_key = tls_private_key.bastion_key.public_key_openssh
} 

resource "local_file" "bastion_local" {
  filename        = "task1.pem"
  content         = tls_private_key.bastion_key.private_key_pem
}


#
# Create Security_Group
#
  resource "aws_security_group" "Bastion_Instance_SG" {
  name        = "warm-bastion-ec2-sg"
  description = "warm-bastion-ec2-sg"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "warm-bastion-ec2-sg"
  }
}

#
# Create Security_Group_Rule
#
  data "http" "myip" {
    url = "http://ipv4.icanhazip.com"
}

  resource "aws_security_group_rule" "Bastion_Instance_SG_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  security_group_id = "${aws_security_group.Bastion_Instance_SG.id}"
}
  resource "aws_security_group_rule" "Bastion_Instance_SG_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.Bastion_Instance_SG.id}"
}

#
# Create Bastion_Role
#
data "aws_iam_policy_document" "AdministratorAccessDocument" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "AdministratorAccess" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "bastion_role" {
  name               = "warm-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.AdministratorAccessDocument.json
}

resource "aws_iam_role_policy_attachment" "bastion_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = data.aws_iam_policy.AdministratorAccess.arn
}

#
# Create Bastion_profile
#
resource "aws_iam_instance_profile" "bastion_profiles" {
  name = "bastion_profiles"
  role = aws_iam_role.bastion_role.name
}

#
# Create Bastion_Instance
#
  resource "aws_instance" "Bastion_Instance" {
  subnet_id     = aws_subnet.public_subnet_a.id
  security_groups = [aws_security_group.Bastion_Instance_SG.id]
  ami           = "ami-01123b84e2a4fba05" #amazonlinux2023
  iam_instance_profile   = aws_iam_instance_profile.bastion_profiles.name
  instance_type = "t3.small"
  key_name = "bastion-keypair.pem"
  user_data = <<EOF
#!/bin/bash
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
echo 'Skill53##' | passwd --stdin ec2-user
EOF

  tags = {
    Name = "warm-bastion-ec2"
  }
}

#
# Create Bastion_EIP
#
  resource "aws_eip" "bastion_eip" {
  domain   = "vpc"

  tags = {
    Name = "warm-bastion-eip"
  }
 } 

resource "aws_eip_association" "bastion_eip_assocation" {
  instance_id   = aws_instance.Bastion_Instance.id
  allocation_id = aws_eip.bastion_eip.id
}
