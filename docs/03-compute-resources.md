# Provisioning Compute Resources

Kubernetes requires a set of machines to host the Kubernetes control plane and the worker nodes where containers are ultimately run. In this lab you will provision the machines required for setting up a Kubernetes cluster.

## Machine Database

This tutorial will leverage a text file, which will serve as a machine database, to store the various machine attributes that will be used when setting up the Kubernetes control plane and worker nodes. The following schema represents entries in the machine database, one entry per line:

```text
IPV4_ADDRESS FQDN HOSTNAME POD_SUBNET
```

Each of the columns corresponds to a machine IP address `IPV4_ADDRESS`, fully qualified domain name `FQDN`, host name `HOSTNAME`, and the IP subnet `POD_SUBNET`. Kubernetes assigns one IP address per `pod` and the `POD_SUBNET` represents the unique IP address range assigned to each machine in the cluster for doing so.  

Here is an example machine database similar to the one used when creating this tutorial. Notice the IP addresses have been masked out. Your machines can be assigned any IP address as long as each machine is reachable from each other and the `jumpbox`.

```bash
cat machines.txt
```

```text
XXX.XXX.XXX.XXX server.kubernetes.local server  
XXX.XXX.XXX.XXX node-0.kubernetes.local node-0 10.200.0.0/24
XXX.XXX.XXX.XXX node-1.kubernetes.local node-1 10.200.1.0/24
```

Create a `machines.txt` file using the `make_machines_file` returned by OpenTofu.

```bash
cat << EOF > machines.txt
XXX.XXX.XXX.XXX server.kubernetes.local server  
XXX.XXX.XXX.XXX node-0.kubernetes.local node-0 10.200.0.0/24
XXX.XXX.XXX.XXX node-1.kubernetes.local node-1 10.200.1.0/24
EOF
```

## Hostnames

In this section you will assign hostnames to the `server`, `node-0`, and `node-1` machines. The hostname will be used when executing commands from the `jumpbox` to each machine. The hostname also play a major role within the cluster. Instead of Kubernetes clients using an IP address to issue commands to the Kubernetes API server, those client will use the `server` hostname instead. Hostnames are also used by each worker machine, `node-0` and `node-1` when registering with a given Kubernetes cluster.

To configure the hostname for each machine, run the following commands on the `jumpbox`.

Set the hostname on each machine listed in the `machines.txt` file:

```bash
while read IP FQDN HOST SUBNET; do 
    CMD="sudo sed -i '/^127.0.0.1.*/a 127.0.1.1\t${FQDN} ${HOST}/' /etc/hosts"
    ssh -n admin@${IP} "$CMD"
    ssh -n admin@${IP} sudo hostnamectl hostname ${HOST}
done < machines.txt
```

Verify the hostname is set on each machine:

```bash
while read IP FQDN HOST SUBNET; do
  ssh -n admin@${IP} hostname --fqdn
done < machines.txt
```

When prompted, type `yes` and proceed. After accepting the new host fingerprint, running the above command a second time will yield the following.

```text
server
node-0
node-1
```

## DNS

In this section you will generate a DNS `hosts` file which will be appended to `jumpbox` local `/etc/hosts` file and to the `/etc/hosts` file of all three machines used for this tutorial. This will allow each machine to be reachable using a hostname such as `server`, `node-0`, or `node-1`.

Create a new `hosts` file and add a header to identify the machines being added:

```bash
echo "" > hosts
echo "# Kubernetes The Hard Way" >> hosts
```

Generate a DNS entry for each machine in the `machines.txt` file and append it to the `hosts` file:

```bash
while read IP FQDN HOST SUBNET; do 
    ENTRY="${IP} ${FQDN} ${HOST}"
    echo $ENTRY >> hosts
done < machines.txt
```

Review the DNS entries in the `hosts` file:

```bash
cat hosts
```

```text

# Kubernetes The Hard Way
XXX.XXX.XXX.XXX server.kubernetes.local server
XXX.XXX.XXX.XXX node-0.kubernetes.local node-0
XXX.XXX.XXX.XXX node-1.kubernetes.local node-1
```

## Adding DNS Entries To A Local Machine

In this section you will append the DNS entries from the `hosts` file to the local `/etc/hosts` file on your `jumpbox` machine.

Append the DNS entries from `hosts` to `/etc/hosts`:

```bash
sudo sh -c 'cat hosts >> /etc/hosts'
```

Verify that the `/etc/hosts` file has been updated:

```bash
cat /etc/hosts
```

```text
127.0.0.1       localhost
127.0.1.1       jumpbox

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters



# Kubernetes The Hard Way
XXX.XXX.XXX.XXX server.kubernetes.local server
XXX.XXX.XXX.XXX node-0.kubernetes.local node-0
XXX.XXX.XXX.XXX node-1.kubernetes.local node-1
```

At this point you should be able to SSH to each machine listed in the `machines.txt` file using a hostname.

```bash
for host in server node-0 node-1
   do ssh admin@${host} uname -o -m -n
done
```

When prompted, type `yes` and proceed. After accepting the new host fingerprint, running the above command a second time will yield the following.

```text
server aarch64 GNU/Linux
node-0 aarch64 GNU/Linux
node-1 aarch64 GNU/Linux
```

## Adding DNS Entries To The Remote Machines

In this section you will append the DNS entries from `hosts` to `/etc/hosts` on each machine listed in the `machines.txt` text file.

Copy the `hosts` file to each machine and append the contents to `/etc/hosts`:

```bash
while read IP FQDN HOST SUBNET; do
  scp hosts admin@${HOST}:~/
  ssh -n \
    admin@${HOST} "sudo sh -c 'cat hosts >> /etc/hosts'"
done < machines.txt
```

At this point hostnames can be used when connecting to machines from your `jumpbox` machine, or any of the three machines in the Kubernetes cluster. Instead of using IP addresess you can now connect to machines using a hostname such as `server`, `node-0`, or `node-1`.

Next: [Provisioning a CA and Generating TLS Certificates](04-certificate-authority.md)
