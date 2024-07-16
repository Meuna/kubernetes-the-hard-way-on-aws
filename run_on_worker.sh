sudo dpkg -i *.deb
sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes
{
  mkdir -p containerd
  tar -xvf crictl-v1.28.0-linux-arm.tar.gz
  tar -xvf containerd-1.7.8-linux-arm64.tar.gz -C containerd
  sudo tar -xvf cni-plugins-linux-arm64-v1.3.0.tgz -C /opt/cni/bin/
  mv runc.arm64 runc
  chmod +x crictl kubectl kube-proxy kubelet runc 
  sudo mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
  sudo mv containerd/bin/* /bin/
}
sudo mv 10-bridge.conf 99-loopback.conf /etc/cni/net.d/
{
  sudo mkdir -p /etc/containerd/
  sudo mv containerd-config.toml /etc/containerd/config.toml
  sudo mv containerd.service /etc/systemd/system/
}
{
  sudo mv kubelet-config.yaml /var/lib/kubelet/
  sudo mv kubelet.service /etc/systemd/system/
}
{
  sudo mv kube-proxy-config.yaml /var/lib/kube-proxy/
  sudo mv kube-proxy.service /etc/systemd/system/
}
{
  sudo systemctl daemon-reload
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl start containerd kubelet kube-proxy
}
