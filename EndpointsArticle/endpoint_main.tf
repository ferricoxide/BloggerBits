locals {
  vpc_id = aws_vpc.vpc.id

  # Split Endpoints by their type
  gateway_endpoints = toset(
    [
      for e in data.aws_vpc_endpoint_service.this :
      e.service_name if e.service_type == "Gateway"
    ]
  )
  interface_endpoints = toset(
    [
      for e in data.aws_vpc_endpoint_service.this :
      e.service_name if e.service_type == "Interface"
    ]
  )

  # Only Interface Endpoints support SGs
  security_groups = toset(
    length(local.interface_endpoints) > 0 ? (
      var.create_sg_per_endpoint ? local.interface_endpoints : ["shared"]
    ) : []
  )

  # Regex of Interface services that do not support Private DNS
  no_private_dns = "s3"
}

# Create SG to apply to interface-endpoints
resource "aws_security_group" "endpoint_access" {
  name_prefix = "vpc_endpoint"
  description = "Allow all resources in VPC to access the interface-endpoints"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "10.0.0.0/8",
    ]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_endpoint_access"
  }
}

# Iteratively create VPC (interface) endpoints
resource "aws_vpc_endpoint" "interface_services" {
  for_each = local.interface_endpoints

  service_name = each.key
  security_group_ids = [
    aws_security_group.endpoint_access.id,
  ]
  # create a list by iterating over the subnet object-lists
  subnet_ids = concat(
    [for subnet in aws_subnet.private : subnet.id],
  )
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.vpc.id

}

# Iteratively create VPC (gateway) endpoints
resource "aws_vpc_endpoint" "gateway_services" {
  for_each = local.gateway_endpoints

  route_table_ids = [
    aws_route_table.private.id,
    aws_route_table.public.id,
  ]
  service_name      = each.key
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.vpc.id
}
