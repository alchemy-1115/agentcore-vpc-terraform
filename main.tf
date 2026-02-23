# VPCの作成
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# インターネットゲートウェイの作成
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# プライベートサブネットの作成（AZ-a）
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone = "${var.aws_region}a"
}

# プライベートサブネットの作成（AZ-c）
resource "aws_subnet" "private_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2)
  availability_zone = "${var.aws_region}c"
}

# Regional NAT Gatewayの作成
resource "aws_nat_gateway" "regional" {
  vpc_id            = aws_vpc.main.id
  connectivity_type = "public"
  availability_mode = "regional"

  depends_on = [aws_internet_gateway.main]
}

# プライベートルートテーブルの作成
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.regional.id
  }
}

# プライベートサブネット（1a）とルートテーブルの関連付け
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}

# プライベートサブネット（1c）とルートテーブルの関連付け
resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private.id
}
