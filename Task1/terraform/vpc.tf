#
# Create VPC 
#
  resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "warm-vpc"
  }
 }

#
# Create Flowlg 
#
resource "aws_flow_log" "example" {
  iam_role_arn    = aws_iam_role.flowlog_role.arn
  log_destination = aws_cloudwatch_log_group.flowlog_cloudwatch.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc.id
}

resource "aws_cloudwatch_log_group" "flowlog_cloudwatch" {
  name = "warm-flowlog-cloudwatch"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flowlog_role" {
  name               = "warm-flowlog-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "flowlog_policy_json" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flowlog_policy" {
  name   = "warm-flowlog-policy"
  role   = aws_iam_role.flowlog_role.id
  policy = data.aws_iam_policy_document.flowlog_policy_json.json
}

#
# Create Public_Subnet 
#
  resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"
 
  map_public_ip_on_launch = true

  tags = {
    Name = "warm-pub-sn-a"
  }
 }

  resource "aws_subnet" "public_subnet_b" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2b"
 
  map_public_ip_on_launch = true

  tags = {
    Name = "warm-pub-sn-b"
  }
 }
 
#
# Create private-subnet 
#
  resource "aws_subnet" "private_subnet_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "warm-priv-sn-a"
  }
 }

  resource "aws_subnet" "private_subnet_b" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "warm-priv-sn-b"
  }
 }

#
# Create prottected-subnet 
#
resource "aws_subnet" "prottected_subnet_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "warm-prot-sn-a"
  }
 }

  resource "aws_subnet" "prottected_subnet_b" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "warm-prot-sn-b"
  }
 }

#
# Create Internet_Gateway 
#
  resource "aws_internet_gateway" "igw" {
  vpc_id     = aws_vpc.vpc.id
  
  tags = {
    Name = "warm-igw"
  }
 }

#
# Create EIP
#
  resource "aws_eip" "eip_a" {
  domain   = "vpc"

  tags = {
    Name = "warm-eip-a"
  }
 }

  resource "aws_eip" "eip_b" {
  domain   = "vpc"

  tags = {
    Name = "warm-eip-b"
  }
 }

#
# Create Nat_Gateway
#
  resource "aws_nat_gateway" "natgw_a" {
  allocation_id = aws_eip.eip_a.id
  subnet_id     = aws_subnet.public_subnet_a.id
  
  tags = {
    Name = "warm-natgw-a"
  }
 }

  resource "aws_nat_gateway" "natgw_b" {
  allocation_id = aws_eip.eip_b.id
  subnet_id     = aws_subnet.public_subnet_b.id
  
  tags = {
    Name = "warm-natgw-b"
  }
 }

#
# Create Public_Route_Table
#
  resource "aws_route_table" "public_rt" {
  vpc_id     = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "warm-pub-rt"
  }
 }

  resource "aws_route_table_association" "public_association_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

  resource "aws_route_table_association" "public_association_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

#
# Create Private_Route_Table
#
  resource "aws_route_table" "private_rt_a" {
  vpc_id     = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw_a.id
  }
  
  tags = {
    Name = "warm-priv-a-rt"
  }
 }

  resource "aws_route_table_association" "private_association_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

  resource "aws_route_table" "private_rt_b" {
  vpc_id     = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw_b.id
  }
  
  tags = {
    Name = "warm-priv-b-rt"
  }
 }

 resource "aws_route_table_association" "private_association_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt_b.id
}

#
# Create prottected_Route_Table
#
  resource "aws_route_table" "prottected_rt_a" {
  vpc_id     = aws_vpc.vpc.id
  
  tags = {
    Name = "warm-prot-a-rt"
  }
 }

  resource "aws_route_table_association" "prottected_association_a" {
  subnet_id      = aws_subnet.prottected_subnet_a.id
  route_table_id = aws_route_table.prottected_rt_a.id
}

  resource "aws_route_table" "prottected_rt_b" {
  vpc_id     = aws_vpc.vpc.id
  
  tags = {
    Name = "warm-prot-b-rt"
  }
 }

 resource "aws_route_table_association" "prottected_association_b" {
  subnet_id      = aws_subnet.prottected_subnet_b.id
  route_table_id = aws_route_table.prottected_rt_b.id
}

#
# Create S3 Endpoint
#
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.ap-northeast-2.s3"

  tags = {
    Name = "warm-s3-endpoint"
  }
}

#
# S3 Endpoint Routingtable Association
#
resource "aws_vpc_endpoint_route_table_association" "s3_endpoint_rt_a_association" {
  route_table_id  = aws_route_table.private_rt_a.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}
resource "aws_vpc_endpoint_route_table_association" "s3_endpoint_rt_b_association" {
  route_table_id  = aws_route_table.private_rt_b.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

#
# ECR Endpoint Security Group
#
resource "aws_security_group" "ecr_endpoint_sg" {
  name        = "warm-ecr-endpoint-sg"
  description = "warm-ecr-endpoint-sg"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "warm-ecr-endpoint-sg"
  }
}

#
# ECR Endpoint Security Group Rule
#
resource "aws_vpc_security_group_ingress_rule" "ecr_endpoint_sg_ingress" {
  security_group_id = aws_security_group.ecr_endpoint_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}
resource "aws_vpc_security_group_egress_rule" "ecr_endpoint_sg_egress" {
  security_group_id = aws_security_group.ecr_endpoint_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

#
# Create ECR Endpoint
#
resource "aws_vpc_endpoint" "ecr_endpoint_api" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.ap-northeast-2.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ecr_endpoint_sg.id
  ]

  private_dns_enabled = true
  tags = {
    Name = "warm-ecr-endpoint-api"
  }
}

resource "aws_vpc_endpoint" "ecr_endpoint_dkr" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.ap-northeast-2.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ecr_endpoint_sg.id,
  ]

  private_dns_enabled = true
  tags = {
    Name = "warm-ecr-endpoint-dkr"
  }
}

#
# Create ECR endpoint Subnet Association
#
resource "aws_vpc_endpoint_subnet_association" "ecr_api_endpoint_subnet_association1" {
  vpc_endpoint_id = aws_vpc_endpoint.ecr_endpoint_api.id
  subnet_id       = aws_subnet.private_subnet_a.id
}
resource "aws_vpc_endpoint_subnet_association" "ecr_api_endpoint_subnet_association2" {
  vpc_endpoint_id = aws_vpc_endpoint.ecr_endpoint_api.id
  subnet_id       = aws_subnet.private_subnet_b.id
}

resource "aws_vpc_endpoint_subnet_association" "ecr_dkr_endpoint_subnet_association1" {
  vpc_endpoint_id = aws_vpc_endpoint.ecr_endpoint_dkr.id
  subnet_id       = aws_subnet.private_subnet_a.id
}
resource "aws_vpc_endpoint_subnet_association" "ecr_dkr_endpoint_subnet_association2" {
  vpc_endpoint_id = aws_vpc_endpoint.ecr_endpoint_dkr.id
  subnet_id       = aws_subnet.private_subnet_b.id
}
