# Karpenter Module for Amazon EKS
This part of the repository contains the implementation of the Kubernetes Node Autoscaler Karpenter.  
Karpenter serves as an alternative to the [Cluster Autoscaler](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/Autoscaling/ClusterAutoscaler) and scales up nodes according demands. In contrast to the Cluster Autoscaler, new nodes are provisioned independently of the existing node groups and can vary in size based on the requirements of the workload. 

## Prerequisites

1. Provisioned EKS Cluster: [Baseline Architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture).
2. Connection to the cluster (via ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster``).
3. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - A command line tool for interacting with AWS services.
4. [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - A command line tool for working with Kubernetes clusters.
5. [eksctl](https://eksctl.io/) - A command line tool for working with EKS clusters.
6. [Helm 3.7+](https://helm.sh/) - A tool for installing and managing Kubernetes applications.


## Deployment

1. Initialize the repository with:  ``Terraform init``.
2. Install Karpenter on the AWS EKS cluster: ``Terraform apply`` and confirm with ``yes``.
3. Since the AWS EKS is created seperately, the AWS Configmap has to be updated. ``kubectl edit configmap aws-auth -n kube-system``. 
    The configmap should resemble the following: ensure that AccountID and NodeGroupIDs are replaced accordingly.
```
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: aws-auth
      namespace: kube-system
    mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::ACCOUNTID:role/KarpenterNodeRole
      username: system:node:{{EC2PrivateDNSName}}
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::ACCOUNTID:role/node-group-1-eks-node-group-20230930153533048600000002
      username: system:node:{{EC2PrivateDNSName}}
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::ACCOUNTID:role/node-group-2-eks-node-group-20230930153533048100000001
      username: system:node:{{EC2PrivateDNSName}}

```

4. Deploy the Provisioner Resource: ``kubectl create -f provisioner.yaml``
5. Deploy the application, for example: [ALB](https://github.com/frankakn/reliability-deployment/blob/main/Deployment/BaselineArchitecture/TeaStore/teastore-alb.yaml).

## Testing

For testing the Karpenter node provisioner, replicas of services could be scaled up, so that the cluster capacity exceeds.  
``kubectl -n teastore-namespace scale --replicas=5 deployment/teastore-webui``.   
Via `` kubectl get nodes`` and `` kubectl logs -f -n karpenter -c controller -l app.kubernetes.io/name=karpenter`` the behavior of Karpenter can be monitored. 

## Clean-Up

1. Delete application via  ``kubectl delete -f Teastore\teastore-alb.yaml`` from within the baseline architecture directory.
2. Delete Policies: ``Terraform destroy`` confirm with ``yes``. (Within this folder).
3. Delete Cluster: ``Terraform destroy`` confirm with ``yes``. (Within the Baseline Arhcitecture Folder).