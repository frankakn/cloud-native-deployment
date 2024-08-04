# Elastic Kubernetes Service (EKS) with Managed Node Groups

This section introduces the deployment steps required to deploy the TeaStore [1] on an AWS EKS cluster. The following steps create the baseline architecture, i.e. the required VPC, subnets, and the EKS cluster to deploy the TeaStore application and to add the individual reliability modules.


## Architecture

The general cluster architecture consists of a VPC with six subnets (three private and three public), each in a different availability zone. Here, the *us-east-2* region is used. The cluster itself consists of two managed node groups, one containing one node and the other containing two nodes. This repo applies the module structure enabled by Terraform by splitting the cluster creation into two modules. The first module (eks-cluster-creation) creates the requried VPC, subnets, policies, and the EKS cluster itself with the two node groups. Afterwards, the second module installs the requried add-ons in the cluster, here the aws-load-balancer controller that is required to deploy the application later. 


## Requirements

1. Terraform installed (v1.3+) [locally](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform)
2. AWS Account
3. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - A command line tool for interacting with AWS services. V2.7.0/v1.24.0 or newer (authenticate via aws configure: access key id & secret access key required).
4. [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - A command line tool for working with Kubernetes clusters.V1.24.0 or newer.
5. [Helm 3.7+](https://helm.sh/) - A tool for installing and managing Kubernetes applications. Set as sysenv [variable](https://phoenixnap.com/kb/install-helm).
6. [eksctl](https://eksctl.io/) - A command line tool for working with EKS clusters.



## Cluster Creation

1. Initialize the repo: ``Terraform init``. This initializes the working directory by installing plugins and the modules created in the project structure. **NOTE:** Initializing the repo may result in an error, due to *filename too long*; can be avoided by cloning the repository into a higher level directory.
2. [Optional] Plan the deployment: ``Terraform plan``. This indicates how many resources are to be created and if any errors are present.
3. Deploy the cluster: ``Terraform apply`` confirm with ``yes``. Starts the deployment of the cluster resources. May take up to 30 minutes. Sometimes timeout/errors occur, simply redo the apply step or destroy cluster and reapply.   

**NOTE:** If the cluster deployment failed for the resource `helm_release`, try running `` helm repo update ``.


## Connect to the cluster

Via kubectl connect to the cluster, deploy the application and get the pods, services, deployments.

To connect to the cluster execute: ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster``. Adapt region and name if required.

## Deploy the TeaStore

To deploy the TeaStore using an NLB run: ``kubectl create -f TeaStore\teastore-alb.yaml``.   
To deploy the TeaStore using an ALB run: ``kubectl create -f TeaStore\teastore-nlb.yaml``. 

### Access

1. via kubectl: get information about cluster and services via commands like: ``kubectl -n get services``, ``kubectl describe services``, ``kubectl get pods``, ... (add -n teastore-namespace for ALB Deployment)
2. get endpoint via: ``kubectl get services``. External IP of teastore-webui is reachable via the internet (after provisioning the services the load balancer takes a couple of minutes to spin up and become active (up to 10 minutes)) (add -n teastore-namespace for ALB deployment).

### CleanUp

In order to delete the application, as well as the terraform cluster conduct:
1. `` kubectl delete -f  TeaStore\teastore-alb.yaml `` or `` kubectl delete -f  TeaStore\teastore-nlb.yaml ``. This removes the TeaStore from the cluster. 
2. ``Terraform destroy`` confirm with ``yes``. This may take up to 20 min. 


**NOTE: **  
If the application is not removed via ``kubectl delete`` before ``terraform destroy`` is called, Terraform is not able to delete all resources. The teastore.yaml triggers the creation of a resource of type load balancer which is connected to subnets within the VPC but not managed by terraform. Terraform will be unable to remove the subnets and the load balancer has to be removed via the console.

[1] https://github.com/DescartesResearch/TeaStore

