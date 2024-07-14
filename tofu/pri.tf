resource "aws_subnet" "k8s_pri" {
  vpc_id     = aws_vpc.k8s.id
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "k8s-the-hard-way-pri"
  }
}

resource "aws_eip" "k8s" {
  domain = "vpc"
}

# resource "aws_nat_gateway" "k8s" {
#   allocation_id = aws_eip.k8s.id
#   subnet_id     = aws_subnet.k8s_pub.id

#   # Explicit dependency for proper ordering with the gw
#   depends_on = [aws_internet_gateway.k8s]
# }

# resource "aws_route_table" "k8s_pri" {
#   vpc_id = aws_vpc.k8s.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.k8s.id
#   }

#   tags = {
#     Name = "k8s-the-hard-way-pub"
#   }
# }

# resource "aws_route_table_association" "a" {
#   subnet_id      = aws_subnet.k8s_pri.id
#   route_table_id = aws_route_table.k8s_pri.id
# }
