# Deployment Option using Container as a Service based on AWS ECS

This setup is based on the work by <https://github.com/garutilorenzo/k8s-aws-terraform-cluster> and <https://nexgeneerz.io/aws-computing-with-ecs-ec2-terraform/> with adaptations.

## Provision the ECS Cluster and deploy the TeaStore application

### 1. Install and configure AWS CLI

Install the AWS CLI tool and configure it with credentials so that terraform can access AWS

### 2. Set variables as needed

Edit the file `example-deployment/variables.tf` to fit your needs:

* For the variable `my_public_ip_cidr` set a CIDR range which covers the public ip of your machine so that you can connect via SSH to cluster machines
* Prepare an SSH key pair from which you upload the public key to AWS. Set the name of this SSH key pair to `ssk_key_pair_name`

### 3. Run terraform to deploy the cluster and deploy the TeaStore application

Because the services of the TeaStore application are directly defined as ECS services using terraform, a separate deployment step for the TeaStore application is not necessary.

Change into `example-deployment` and run:

```sh
example-deployment$ terraform init
example-deployment$ terraform plan
example-deployment$ terraform apply
```

If everything works you get an output like the following:

```sh
alb_dns_name = "ecs-alb-staging-1474765300.us-east-2.elb.amazonaws.com"
bastion_host_ip = [
  "18.225.175.179",
]
private_subnets_ids = [
  "subnet-0b01a83a8f29a037e",
  "subnet-0eb1bb11882bed359",
  "subnet-0bc52e83033e9a039",
]
public_subnets_ids = [
  "subnet-053fb9bbe1f6eb5fd",
  "subnet-0de0036ab5269efc7",
  "subnet-0096e1aa82c6e26ac",
]
security_group_id = "sg-0bd0e620952150036"
vpc_id = "vpc-02f8714eb98a26503"
```

The application can then be reached with the URL of printed as `alb_dns_name` from the terraform output.

*This example only uses HTTP, for HTTPS, an additional ingress resource can be used*
