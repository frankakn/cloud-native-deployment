locals {
  tags = {
    "environment" = "${var.environment}"
  }
  domain_name = "${var.region}-${var.domain_name}"
}


data "aws_availability_zones" "available_az" {
  state = "available"
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.tags,
    {
      Name = "vpc-${var.region}-${var.environment}"
    }
  )
}

resource "aws_subnet" "public_subnets" {
  count                                       = length(data.aws_availability_zones.available_az.zone_ids)
  vpc_id                                      = aws_vpc.main_vpc.id
  availability_zone_id                        = data.aws_availability_zones.available_az.zone_ids[count.index]
  cidr_block                                  = cidrsubnet(var.vpc_cidr_block, var.vpc_newbits, count.index)
  map_public_ip_on_launch                     = true
  enable_resource_name_dns_a_record_on_launch = true
  private_dns_hostname_type_on_launch         = "resource-name"
  tags = merge(
    local.tags,
    {
      Name = "public-subnet-${data.aws_availability_zones.available_az.names[count.index]}-${var.environment}"
    }
  )
}

resource "aws_subnet" "private_subnets" {
  count                                       = length(data.aws_availability_zones.available_az.zone_ids)
  vpc_id                                      = aws_vpc.main_vpc.id
  availability_zone_id                        = data.aws_availability_zones.available_az.zone_ids[count.index]
  cidr_block                                  = cidrsubnet(var.vpc_cidr_block, var.vpc_newbits, count.index + var.private_subnet_offset)
  map_public_ip_on_launch                     = false
  enable_resource_name_dns_a_record_on_launch = true
  private_dns_hostname_type_on_launch         = "resource-name"
  tags = merge(
    local.tags,
    {
      Name = "private-subnet-${data.aws_availability_zones.available_az.names[count.index]}-${var.environment}"
    }
  )
}

resource "aws_vpc_dhcp_options" "vpc_dhcp" {
  domain_name         = local.domain_name
  domain_name_servers = var.dns_servers

  tags = merge(
    local.tags,
    {
      Name = "dhcp-options-${var.environment}"
    }
  )
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.main_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.vpc_dhcp.id
}

resource "aws_internet_gateway" "vpc_gw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = merge(
    local.tags,
    {
      Name = "internet-gw-${var.environment}"
    }
  )
}

resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.vpc_gw]
  tags = merge(
    local.tags,
    {
      Name = "elastic-ip-nat-gw-${var.environment}"
    }
  )
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnets.*.id, 0)
  depends_on    = [aws_internet_gateway.vpc_gw]
  tags = merge(
    local.tags,
    {
      Name = "nat-gw-${var.environment}"
    }
  )
}


resource "aws_route_table" "vpc_private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(
    local.tags,
    {
      Name = "private-rt-${var.environment}"
    }
  )
}

resource "aws_route_table" "vpc_public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(
    local.tags,
    {
      Name = "public-rt-${var.environment}"
    }
  )
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.vpc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_gw.id
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.vpc_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

resource "aws_route_table_association" "public" {
  count          = length(data.aws_availability_zones.available_az.zone_ids)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.vpc_public_rt.id
}

resource "aws_route_table_association" "private" {
  count          = length(data.aws_availability_zones.available_az.zone_ids)
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = aws_route_table.vpc_private_rt.id
}

resource "aws_security_group" "allow-strict" {
  vpc_id      = aws_vpc.main_vpc.id
  name        = "allow-strict"
  description = "security group that allows ssh and all egress traffic"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_public_ip_cidr]
  }

  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }

  tags = merge(
    local.tags,
    {
      Name = "sg-allow-strict-${var.environment}"
    }
  )
}

