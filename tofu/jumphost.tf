resource "aws_instance" "jumphost" {
  ami             = data.aws_ami.debian_arm.id
  instance_type   = "t4g.nano"
  key_name        = aws_key_pair.k8s.key_name
  subnet_id       = aws_subnet.k8s_pub.id
  security_groups = [aws_security_group.myip_allow_ssh.id, aws_security_group.allow_all_out.id]

  instance_market_options { market_type = "spot" }

  tags = {
    Name = "k8s-the-hard-way-jumphost"
  }
}
