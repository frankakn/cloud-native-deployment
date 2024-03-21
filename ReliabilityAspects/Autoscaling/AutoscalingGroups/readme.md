# Implementation of EC2 Autoscaling Group Policies

This part of the repository complements the AWS EKS Cluster creation by adding policies to specifiy the scaling behavior of the EC2 Cluster Autoscaling groups. Per default (using the EKS creation module) node groups are created as EC2 Autoscaling Groups. Thereby, already a minimum, maximum, and desired amount of nodes are specified per node group. In order to enable the automatic scaling, policies that define CPU and memory utilization thresholds are defined. 

**NOTE 1**  
This part of the project only covers utilization thesholds. Scaling up the cluster when nodes run out of capacity to schedule new nodes is implemented via a [Cluster Autoscaler](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/Autoscaling/ClusterAutoscaler)

**NOTE 2**   
EC2 Auto Scaling Groups are implicitly created by the EKS module. Names or tags are not yet available, therefore the resulting name has to be manually inserted here (see step 1 of setup).  
The [EKS cluster creation](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture) prints the names as output variables within the command line tool after a successful cluster creation. Alternatively, the names can be obtained from the AWS console.

## Prerequisites 

1. Provisioned EKS Cluster: [Baseline Architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture).
2. Names of Auto Scaling Groups (Will be displayed after successful creation of the EKS cluster creation script).

## Setup

1. **Insert the names of the Auto Scaling Groups in the variables.tf** (Marked as output within the CMD, alternatively obtain from AWS console.)
2. [Optional] adjust the CPU utilization if required. 
3. Open a CMD / navigate into this directory.
4. Initialize the repo: ``Terraform init``. This initializes the working directory by installing plugins and the modules created in the project structure. 
5. [Optional] Plan the deployment: ``Terraform plan``. This indicates how many resources are to be created and if any errors are present.
6. Deploy the cluster: ``Terraform apply`` confirm with ``yes``. 

## Application Setup

1. Connect to the cluster ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster ``
2. Deploy the application: [ALB](https://github.com/frankakn/reliability-deployment/blob/main/Deployment/BaselineArchitecture/TeaStore/teastore-alb.yaml).

## Testing

The TeaStore application already provides load testing scripts for Apache Apache JMeter. To test the scaling functionality:
1. Install JMeter ([Installtion](https://www.simplilearn.com/tutorials/jmeter-tutorial/jmeter-installation))
2. Open the GUI (bin/apacheJmeter.jar)
3. Open [JMeter file](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/GuardedIngress/JMeter)
4. Adjust the webpage endpoint (DNS of Load Balancer) (Call ``kubectl get services`` -> External IP of teastore-webui )
5. Start Thread group 3 (including several http requests)
6. Monitor via kubectl get nodes
7. Stop the load testing 

## Cleanup

1. Remove the application via ``kubectl delete -f TeaStore\teastore-alb.yaml``. From within the baseline-architecture directory.
2. Run ``Terraform destroy`` confirm with ``yes`` (In the current directory, to only destroy the policy resource). 
3. Destroy EKS cluster from within the baseline architecture directory, via ``Terraform destroy`` and confirm with ``yes``.
