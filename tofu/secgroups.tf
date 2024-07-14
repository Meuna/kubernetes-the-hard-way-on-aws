resource "aws_security_group" "allow_all_out" {
  name        = "allow_all_out"
  description = "Allow SSH inbound traffic from myip"
  vpc_id      = aws_vpc.k8s.id

  tags = {
    Name = "allow_all_out"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_all_out.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_security_group" "myip_allow_ssh" {
  name        = "myip_allow_ssh"
  description = "Allow SSH inbound traffic from myip"
  vpc_id      = aws_vpc.k8s.id

  tags = {
    Name = "myip_allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "myip_allow_ssh" {
  security_group_id = aws_security_group.myip_allow_ssh.id
  cidr_ipv4         = format("%s/%s", data.external.myip.result["myipv4"], 32)
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_security_group" "jumphost_allow_ssh" {
  name        = "jumphost_allow_ssh"
  description = "Allow SSH inbound traffic from jumphost"
  vpc_id      = aws_vpc.k8s.id

  tags = {
    Name = "jumphost_allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "jumphost_allow_ssh" {
  security_group_id = aws_security_group.jumphost_allow_ssh.id
  cidr_ipv4         = format("%s/%s", aws_instance.jumphost.private_ip, 32)
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_security_group" "k8s_master" {
  name        = "k8s_master"
  description = "Allow SSH inbound traffic from jumphost"
  vpc_id      = aws_vpc.k8s.id

  tags = {
    Name = "k8s_master"
  }
}

resource "aws_vpc_security_group_ingress_rule" "k8s_master_kubeapi" {
  security_group_id = aws_security_group.k8s_master.id
  cidr_ipv4         = aws_vpc.k8s.cidr_block
  ip_protocol       = "tcp"
  from_port         = 6443
  to_port           = 6443
}

resource "aws_vpc_security_group_ingress_rule" "k8s_master_etcd" {
  security_group_id = aws_security_group.k8s_master.id
  cidr_ipv4         = aws_vpc.k8s.cidr_block
  ip_protocol       = "tcp"
  from_port         = 2379
  to_port           = 2380
}

resource "aws_vpc_security_group_ingress_rule" "k8s_master_kubelet" {
  security_group_id = aws_security_group.k8s_master.id
  cidr_ipv4         = aws_vpc.k8s.cidr_block
  ip_protocol       = "tcp"
  from_port         = 10250
  to_port           = 10250
}

resource "aws_vpc_security_group_ingress_rule" "k8s_master_sched" {
  security_group_id = aws_security_group.k8s_master.id
  cidr_ipv4         = aws_vpc.k8s.cidr_block
  ip_protocol       = "tcp"
  from_port         = 10259
  to_port           = 10259
}

resource "aws_vpc_security_group_ingress_rule" "k8s_master_mgr" {
  security_group_id = aws_security_group.k8s_master.id
  cidr_ipv4         = aws_vpc.k8s.cidr_block
  ip_protocol       = "tcp"
  from_port         = 10257
  to_port           = 10257
}


resource "aws_security_group" "k8s_worker" {
  name        = "k8s_worker"
  description = "Allow SSH inbound traffic from jumphost"
  vpc_id      = aws_vpc.k8s.id

  tags = {
    Name = "k8s_worker"
  }
}

resource "aws_vpc_security_group_ingress_rule" "k8s_worker_kubelet" {
  security_group_id = aws_security_group.k8s_worker.id
  cidr_ipv4         = aws_vpc.k8s.cidr_block
  ip_protocol       = "tcp"
  from_port         = 10250
  to_port           = 10250
}

resource "aws_vpc_security_group_ingress_rule" "k8s_worker_kubeproxy" {
  security_group_id = aws_security_group.k8s_worker.id
  cidr_ipv4         = aws_vpc.k8s.cidr_block
  ip_protocol       = "tcp"
  from_port         = 10256
  to_port           = 10256
}


resource "aws_vpc_security_group_ingress_rule" "k8s_worker_nodeport" {
  security_group_id = aws_security_group.k8s_worker.id
  cidr_ipv4         = aws_vpc.k8s.cidr_block
  ip_protocol       = "tcp"
  from_port         = 30000
  to_port           = 32767
}


