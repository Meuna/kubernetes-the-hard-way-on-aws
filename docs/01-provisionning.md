# Provisioning

In this lab you will provision the machine necessary to follow this tutorial using OpenTofu and AWS.

As a prerequisite, you will need the following:

* An AWS account
* [Sign in through the AWS Command Line Interface](https://docs.aws.amazon.com/signin/latest/userguide/command-line-sign-in.html)
* [Installing OpenTopfu](https://opentofu.org/docs/intro/install/)

## Generate an SSH key pair

Generate an SSH keypair used for the provisioning of the machines. Use the following commands from your machine:

```bash
ssh-keygen
```

```text
Generating public/private rsa key pair.
Enter file in which to save the key (/home/XXXX/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/XXXX/.ssh/id_rsa
Your public key has been saved in /home/XXXX/.ssh/id_rsa.pub
```

## Provisioning EC2 instances

The OpenTofu stack provided will create the following resources on your AWS account.

| Name    | Description            | Type      |
|---------|------------------------|-----------|
| jumpbox | Administration host    | t4g.nano  |
| server  | Kubernetes server      | t4g.small |
| node-0  | Kubernetes worker node | t4g.small |
| node-1  | Kubernetes worker node | t4g.small |

You will need your public key to provision the cluster:

```bash 
cat ~/.ssh/id_rsa.pub
```

```text
ssh-rsa XXX... XXX@XXX
```

Copy the key to the clipboard. Move to the tofu folder and run the `tofu apply` command.

```bash 
cd tofu
tofu apply
```

```text
var.pubkey
  Enter a value:
```

Paste the public key into the prompt (no echo is generated) and proceed. When prompted, type `yes` and proceed again.

```text
Do you want to perform these actions?
  OpenTofu will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

At the end of the provisioning, OpenTofu report the ip of the created resources:

```text
Outputs:

jumphost-pubip = "XX.XX.XX.XX"
machines = <<EOT
XXX.XXX.XXX.XXX server.kubernetes.local server  
XXX.XXX.XXX.XXX node-0.kubernetes.local node-0 10.200.0.0/24
XXX.XXX.XXX.XXX node-1.kubernetes.local node-1 10.200.1.0/24

EOT
```

Keep the the generated `machines` string for later.

## Configuring SSH Access

### Generate an SSH config file

Create an SSH config file. Below, replace the `XX.XX.XX.XX` section with the `jumphost-pubip` returned by OpenTofu.

```bash 
cat << EOF >> ~/.ssh/config

Host jumphost
  User admin
  ForwardAgent yes
  HostName XX.XX.XX.XX
EOF
```

### Use the ssh-agent

This step must be repeated for each shell you use to connect to your cluster. First, start the `ssh-agent`.

```bash
eval `ssh-agent`
```

```text
Agent pid 5322
```

Add the created key

```bash
ssh-add ~/.ssh/id_rsa
```

```text
Identity added: /home/XXX/.ssh/id_rsa (XXX@XXX)
```

### Test the correct provisioning

Try to connect to the jumphost:

```bash
ssh jumphost
```

```text
The authenticity of host 'XX.XX.XX.XX (XX.XX.XX.XX)' can't be established.
ED25519 key fingerprint is SHA256:XXXXXXXXXXXXXX.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Type `yes` and proceed.

```text
Warning: Permanently added 'XX.XX.XX.XX' (ED25519) to the list of known hosts.
Linux ip-XX.XX.XX.XX 6.7.12+bpo-cloud-arm64 #1 SMP Debian 6.7.12-1~bpo12+1 (2024-05-06) aarch64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
admin@ip-XX.XX.XX.XX:~$
```

Next: [setting-up-the-jumpbox](02-jumpbox.md)
