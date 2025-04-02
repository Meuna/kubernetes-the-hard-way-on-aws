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
