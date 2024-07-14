resource "aws_subnet" "k8s_pub" {
  vpc_id                  = aws_vpc.k8s.id
  cidr_block              = "192.168.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-the-hard-way-pub"
  }
}

resource "aws_route_table" "k8s_pub" {
  vpc_id = aws_vpc.k8s.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s.id
  }

  tags = {
    Name = "k8s-the-hard-way-pub"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.k8s_pub.id
  route_table_id = aws_route_table.k8s_pub.id
}
