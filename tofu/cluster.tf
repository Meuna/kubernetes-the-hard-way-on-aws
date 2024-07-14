resource "aws_instance" "master" {
  count           = 1
  ami             = data.aws_ami.debian_arm.id
  instance_type   = "t4g.small"
  key_name        = aws_key_pair.k8s.key_name
  subnet_id       = aws_subnet.k8s_pri.id
  security_groups = [aws_security_group.jumphost_allow_ssh.id, aws_security_group.k8s_master.id, aws_security_group.allow_all_out.id]

  instance_market_options { market_type = "spot" }

  tags = {
    Name = "k8s-the-hard-way-master${count.index}"
  }
}

resource "aws_instance" "workers" {
  count           = 2
  ami             = data.aws_ami.debian_arm.id
  instance_type   = "t4g.small"
  key_name        = aws_key_pair.k8s.key_name
  subnet_id       = aws_subnet.k8s_pri.id
  security_groups = [aws_security_group.jumphost_allow_ssh.id, aws_security_group.k8s_worker.id, aws_security_group.allow_all_out.id]

  instance_market_options { market_type = "spot" }

  tags = {
    Name = "k8s-the-hard-way-worker${count.index}"
  }
}
