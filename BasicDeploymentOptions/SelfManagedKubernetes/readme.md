# Deployment Option with a self-managed Kubernetes Cluster

This setup is based on the work by [https://github.com/garutilorenzo/k8s-aws-terraform-cluster] with small adaptations.

## Deploy the Kubernetes Cluster

### 1. Install and configure AWS CLI

Install the AWS CLI tool and configure it with credentials so that terraform can access AWS

### 2. Set variables as needed

Edit the file `example-deployment/variables.tf` to fit your needs:

* For the variable `my_public_ip_cidr` set a CIDR range which covers the public ip of your machine so that you can connect via SSH to cluster machines
* Add an email address for `certmanager_email_address`
* Prepare an SSH key pair from which you upload the public key to AWS. Set the name of this SSH key pair to `ssk_key_pair_name`

### 3. Run terraform to deploy the cluster

Change into `example-deployment` and run:

```sh
example-deployment$ terraform init
example-deployment$ terraform plan
example-deployment$ terraform apply
```

If everything works you get an output like the following:

```sh
bastion_host_ip = [
  "3.143.255.141",
]
k8s_dns_name = tolist([
  "k8s-ext-lb-staging-8b54683fff11090e.elb.us-east-2.amazonaws.com",
])
k8s_server_private_ips = [
  tolist([
    "172.68.4.38",
    "172.68.5.249",
    "172.68.3.83",
  ]),
]
k8s_workers_private_ips = [
  tolist([
    "172.68.5.51",
    "172.68.4.152",
    "172.68.3.82",
  ]),
]
private_subnets_ids = [
  "subnet-091abbbe51f7fa535",
  "subnet-0082eb2af37906237",
  "subnet-0ed14ccfc68c2a38f",
]
public_subnets_ids = [
  "subnet-03a1b413cb04576c4",
  "subnet-0fb73530341e69f75",
  "subnet-0735450c1b9928116",
]
security_group_id = "sg-0dde197a5870eb031"
vpc_id = "vpc-035094675200ac2b5"
```

### 4. Connect to the cluster

Now you can use the bastion host as a jump host to access one of the kubernetes service machines:

`ssh ec2-user@172.68.4.38 -oProxyCommand="ssh bastion@3.143.255.141 -i ~/.ssh/<THE NAME OF YOUR SSH KEY> -W %h:%p" -i ~/.ssh/<THE NAME OF YOUR SSH KEY>`

Within the host you can get the Kubernetes credentials with: `sudo cat /etc/kubernetes/admin.conf`.
Use the content of this file to set up `kubectl` as you like, for example by copying the content to `~/.kube/config` on your local machine.

Use the internal server address to forward the kubernetes api port to a local port, for example:

`ssh -L 6444:k8s-int-lb-staging-cdd68aac7c4c8d50.elb.us-east-2.amazonaws.com:6443 ec2-user@172.68.4.38 -oProxyCommand="ssh bastion@3.143.255.141 -i ~/.ssh/<THE NAME OF YOUR SSH KEY> -W %h:%p" -i ~/.ssh/<THE NAME OF YOUR SSH KEY>`

Now you can update the server address in `~/.kube/config` to `https://localhost:6444` and you should be able to connect to the cluster from your local machine.

### 5. Deploy the TeaStore

**TODO**
