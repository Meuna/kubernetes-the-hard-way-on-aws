{
  tar -xvf etcd-v3.4.27-linux-arm64.tar.gz
  sudo mv etcd-v3.4.27-linux-arm64/etcd* /usr/local/bin/
}
{
  sudo mkdir -p /etc/etcd /var/lib/etcd
  sudo chmod 700 /var/lib/etcd
  sudo cp ca.crt kube-api-server.key kube-api-server.crt /etc/etcd/
}
sudo mv etcd.service /etc/systemd/system/
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd
  sudo systemctl start etcd
}

sudo mkdir -p /etc/kubernetes/config
{
  chmod +x kube-apiserver \
    kube-controller-manager \
    kube-scheduler kubectl
    
  sudo mv kube-apiserver \
    kube-controller-manager \
    kube-scheduler kubectl \
    /usr/local/bin/
}
{
  sudo mkdir -p /var/lib/kubernetes/

  sudo mv ca.crt ca.key \
    kube-api-server.key kube-api-server.crt \
    service-accounts.key service-accounts.crt \
    encryption-config.yaml \
    /var/lib/kubernetes/
}
sudo mv kube-apiserver.service /etc/systemd/system/kube-apiserver.service
sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
sudo mv kube-controller-manager.service /etc/systemd/system/
sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
sudo mv kube-scheduler.yaml /etc/kubernetes/config/
sudo mv kube-scheduler.service /etc/systemd/system/
{
  sudo systemctl daemon-reload
  
  sudo systemctl enable kube-apiserver \
    kube-controller-manager kube-scheduler
    
  sudo systemctl start kube-apiserver \
    kube-controller-manager kube-scheduler
}
sleep 5
kubectl apply -f kube-apiserver-to-kubelet.yaml --kubeconfig admin.kubeconfig
