sudo apt-get update
sudo apt-get -y install wget curl vim openssl git
git clone --depth 1 https://github.com/Meuna/kubernetes-the-hard-way-on-aws.git
mv machines.txt kubernetes-the-hard-way-on-aws
cd kubernetes-the-hard-way-on-aws
mkdir downloads
wget -q --show-progress \
  --https-only \
  --timestamping \
  -P downloads \
  -i downloads.txt
{
  chmod +x downloads/kubectl
  sudo cp downloads/kubectl /usr/local/bin/
}

while read IP FQDN HOST SUBNET; do 
    CMD="sudo sed -i '/^127.0.0.1.*/a 127.0.1.1\t${FQDN} ${HOST}/' /etc/hosts"
    ssh -n admin@${IP} "$CMD"
    ssh -n admin@${IP} sudo hostnamectl hostname ${HOST}
done < machines.txt

echo "" > hosts
echo "# Kubernetes The Hard Way" >> hosts
while read IP FQDN HOST SUBNET; do 
    ENTRY="${IP} ${FQDN} ${HOST}"
    echo $ENTRY >> hosts
done < machines.txt
sudo sh -c 'cat hosts >> /etc/hosts'
while read IP FQDN HOST SUBNET; do
  scp hosts admin@${HOST}:~/
  ssh -n \
    admin@${HOST} "sudo sh -c 'cat hosts >> /etc/hosts'"
done < machines.txt

{
  openssl genrsa -out ca.key 4096
  openssl req -x509 -new -sha512 -noenc \
    -key ca.key -days 3653 \
    -config ca.conf \
    -out ca.crt
}
certs=(
  "admin" "node-0" "node-1"
  "kube-proxy" "kube-scheduler"
  "kube-controller-manager"
  "kube-api-server"
  "service-accounts"
)
for i in ${certs[*]}; do
  openssl genrsa -out "${i}.key" 4096

  openssl req -new -key "${i}.key" -sha256 \
    -config "ca.conf" -section ${i} \
    -out "${i}.csr"
  
  openssl x509 -req -days 3653 -in "${i}.csr" \
    -copy_extensions copyall \
    -sha256 -CA "ca.crt" \
    -CAkey "ca.key" \
    -CAcreateserial \
    -out "${i}.crt"
done
for host in node-0 node-1; do
  scp ca.crt $host.crt $host.key admin@$host:/home/admin

  ssh admin@$host sudo sh "-c '\
    mkdir /var/lib/kubelet \
    && mv /home/admin/ca.crt /var/lib/kubelet \
    && mv /home/admin/$host.crt /var/lib/kubelet/kubelet.crt \
    && mv /home/admin/$host.key /var/lib/kubelet/kubelet.key'"
done
scp \
  ca.key ca.crt \
  kube-api-server.key kube-api-server.crt \
  service-accounts.key service-accounts.crt \
  admin@server:~

for host in node-0 node-1; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://server.kubernetes.local:6443 \
    --kubeconfig=${host}.kubeconfig

  kubectl config set-credentials system:node:${host} \
    --client-certificate=${host}.crt \
    --client-key=${host}.key \
    --embed-certs=true \
    --kubeconfig=${host}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${host} \
    --kubeconfig=${host}.kubeconfig

  kubectl config use-context default \
    --kubeconfig=${host}.kubeconfig
done
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://server.kubernetes.local:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.crt \
    --client-key=kube-proxy.key \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default \
    --kubeconfig=kube-proxy.kubeconfig
}
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://server.kubernetes.local:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.crt \
    --client-key=kube-controller-manager.key \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default \
    --kubeconfig=kube-controller-manager.kubeconfig
}
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://server.kubernetes.local:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.crt \
    --client-key=kube-scheduler.key \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default \
    --kubeconfig=kube-scheduler.kubeconfig
}
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default \
    --kubeconfig=admin.kubeconfig
}
for host in node-0 node-1; do
  scp kube-proxy.kubeconfig ${host}.kubeconfig admin@$host:/home/admin

  ssh admin@$host sudo sh "-c ' \
    mkdir /var/lib/kube-proxy \
    && mv /home/admin/kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig \
    && mv /home/admin/${host}.kubeconfig /var/lib/kubelet/kubeconfig'"
done
scp admin.kubeconfig \
  kube-controller-manager.kubeconfig \
  kube-scheduler.kubeconfig \
  admin@server:~

export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
envsubst < configs/encryption-config.yaml > encryption-config.yaml
scp encryption-config.yaml admin@server:~
scp \
  downloads/etcd-v3.4.27-linux-arm64.tar.gz \
  units/etcd.service \
  admin@server:~

scp \
  downloads/kube-apiserver \
  downloads/kube-controller-manager \
  downloads/kube-scheduler \
  downloads/kubectl \
  units/kube-apiserver.service \
  units/kube-controller-manager.service \
  units/kube-scheduler.service \
  configs/kube-scheduler.yaml \
  configs/kube-apiserver-to-kubelet.yaml \
  admin@server:~

for host in node-0 node-1; do
  SUBNET=$(grep $host machines.txt | cut -d " " -f 4)
  sed "s|SUBNET|$SUBNET|g" \
    configs/10-bridge.conf > 10-bridge.conf 
    
  sed "s|SUBNET|$SUBNET|g" \
    configs/kubelet-config.yaml > kubelet-config.yaml
    
  scp 10-bridge.conf kubelet-config.yaml admin@$host:~
done
for host in node-0 node-1; do
  scp \
    downloads/runc.arm64 \
    downloads/crictl-v1.28.0-linux-arm.tar.gz \
    downloads/cni-plugins-linux-arm64-v1.3.0.tgz \
    downloads/containerd-1.7.8-linux-arm64.tar.gz \
    downloads/kubectl \
    downloads/kubelet \
    downloads/kube-proxy \
    configs/99-loopback.conf \
    configs/containerd-config.toml \
    configs/kubelet-config.yaml \
    configs/kube-proxy-config.yaml \
    units/containerd.service \
    units/kubelet.service \
    units/kube-proxy.service \
    admin@$host:~/
done
sudo rm /var/cache/apt/archives/*.deb
sudo apt-get update
sudo apt-get -d -y install socat conntrack ipset
for host in node-0 node-1; do
  scp /var/cache/apt/archives/*.deb admin@$host:~
done

{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://server.kubernetes.local:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}

{
  SERVER_IP=$(grep server machines.txt | cut -d " " -f 1)
  NODE_0_IP=$(grep node-0 machines.txt | cut -d " " -f 1)
  NODE_0_SUBNET=$(grep node-0 machines.txt | cut -d " " -f 4)
  NODE_1_IP=$(grep node-1 machines.txt | cut -d " " -f 1)
  NODE_1_SUBNET=$(grep node-1 machines.txt | cut -d " " -f 4)
}
ssh admin@server "sudo sh -c ' \
  ip route add ${NODE_0_SUBNET} via ${NODE_0_IP} \
  && ip route add ${NODE_1_SUBNET} via ${NODE_1_IP}'"

ssh admin@node-0 "sudo sh -c ' \
  ip route add ${NODE_1_SUBNET} via ${NODE_1_IP}'"

ssh admin@node-1 "sudo sh -c ' \
  ip route add ${NODE_0_SUBNET} via ${NODE_0_IP}'"

