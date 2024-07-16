# Bootstrapping the Kubernetes Worker Nodes

In this lab you will bootstrap two Kubernetes worker nodes. The following components will be installed: [runc](https://github.com/opencontainers/runc), [container networking plugins](https://github.com/containernetworking/cni), [containerd](https://github.com/containerd/containerd), [kubelet](https://kubernetes.io/docs/admin/kubelet), and [kube-proxy](https://kubernetes.io/docs/concepts/cluster-administration/proxies).

## Prerequisites

Copy Kubernetes binaries and systemd unit files to each worker instance:

```bash
for host in node-0 node-1; do
  SUBNET=$(grep $host machines.txt | cut -d " " -f 4)
  sed "s|SUBNET|$SUBNET|g" \
    configs/10-bridge.conf > 10-bridge.conf 
    
  sed "s|SUBNET|$SUBNET|g" \
    configs/kubelet-config.yaml > kubelet-config.yaml
    
  scp 10-bridge.conf kubelet-config.yaml admin@$host:~
done
```

```bash
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
```

Download the OS dependencies (the worker don't have internet access)

```bash
{
  sudo rm /var/cache/apt/archives/*.deb
  sudo apt-get update
  sudo apt-get -d -y install socat conntrack ipset
}
```

```bash
for host in node-0 node-1; do
  scp /var/cache/apt/archives/*.deb admin@$host:~
done
```

> The socat binary enables support for the `kubectl port-forward` command.

## Provisioning a Kubernetes Worker Node

The commands in this lab must be run on each worker instance: `node-0`, `node-1`. Login to the worker instance using the `ssh` command. Example:

```bash
ssh admin@node-0
```

### Install OS dependencies

```bash
sudo dpkg -i *.deb
```

### Disable Swap

By default, the kubelet will fail to start if [swap](https://help.ubuntu.com/community/SwapFaq) is enabled. It is [recommended](https://github.com/kubernetes/kubernetes/issues/7294) that swap be disabled to ensure Kubernetes can provide proper resource allocation and quality of service.

Verify if swap is enabled:

```bash
sudo swapon --show
```

If output is empty then swap is not enabled. If swap is enabled run the following command to disable swap immediately:

```bash
sudo swapoff -a
```

> To ensure swap remains off after reboot consult your Linux distro documentation.

Create the installation directories:

```bash
sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes
```

Install the worker binaries:

```bash
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
```

### Configure CNI Networking

Create the `bridge` network configuration file:

```bash
sudo mv 10-bridge.conf 99-loopback.conf /etc/cni/net.d/
```

### Configure containerd

Install the `containerd` configuration files:

```bash
{
  sudo mkdir -p /etc/containerd/
  sudo mv containerd-config.toml /etc/containerd/config.toml
  sudo mv containerd.service /etc/systemd/system/
}
```

### Configure the Kubelet

Create the `kubelet-config.yaml` configuration file:

```bash
{
  sudo mv kubelet-config.yaml /var/lib/kubelet/
  sudo mv kubelet.service /etc/systemd/system/
}
```

### Configure the Kubernetes Proxy

```bash
{
  sudo mv kube-proxy-config.yaml /var/lib/kube-proxy/
  sudo mv kube-proxy.service /etc/systemd/system/
}
```

### Start the Worker Services

```bash
{
  sudo systemctl daemon-reload
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl start containerd kubelet kube-proxy
}
```

## Verification

The compute instances created in this tutorial will not have permission to complete this section. Run the following commands from the `jumpbox` machine.

List the registered Kubernetes nodes:

```bash
ssh admin@server \
  "kubectl get nodes \
  --kubeconfig admin.kubeconfig"
```

```
NAME     STATUS   ROLES    AGE    VERSION
node-0   Ready    <none>   1m     v1.28.3
node-1   Ready    <none>   10s    v1.28.3
```

Next: [Configuring kubectl for Remote Access](10-configuring-kubectl.md)
