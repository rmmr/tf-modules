locals {
  availability_zones = var.availability_zones != null ? var.availability_zones : data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "_" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags                 = var.tags
}

resource "aws_internet_gateway" "_" {
  count  = var.enable_internet_gateway ? 1 : 0
  vpc_id = aws_vpc._.id
  tags   = var.tags
}

resource "aws_subnet" "public" {
  count = var.create_public_subnet ? length(local.availability_zones) : 0

  vpc_id            = aws_vpc._.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone = local.availability_zones[count.index]

  tags = var.tags
}

resource "aws_subnet" "private" {
  count = length(local.availability_zones)

  vpc_id            = aws_vpc._.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 100 + count.index)
  availability_zone = local.availability_zones[count.index]

  tags = var.tags
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc._.id
  tags   = var.tags
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[count.index].id
}

resource "aws_vpc_endpoint" "s3" {
  count        = var.enable_s3_endpoint ? 1 : 0
  vpc_id       = aws_vpc._.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  tags         = var.tags
}

resource "aws_vpc_endpoint" "dynamodb" {
  count        = var.enable_dynamodb_endpoint ? 1 : 0
  vpc_id       = aws_vpc._.id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"
  tags         = var.tags
}

resource "aws_vpc_endpoint" "sqs" {
  count               = var.enable_sqs_endpoint ? 1 : 0
  vpc_id              = aws_vpc._.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.aws_region}.sqs"
  security_group_ids  = var.security_group_ids
  subnet_ids          = aws_subnet.private.*.id
  private_dns_enabled = var.enable_dns_hostnames
  tags                = var.tags
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  count           = var.enable_s3_endpoint ? 1 : 0
  route_table_id  = aws_route_table.private.id
  vpc_endpoint_id = aws_vpc_endpoint.s3[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb" {
  count           = var.enable_dynamodb_endpoint ? 1 : 0
  route_table_id  = aws_route_table.private.id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[count.index].id
}
