# Implementation of Cluster Autoscaler

This part of the repository complements the AWS EKS Cluster creation by implementing the Kubernetes Cluster Autoscaler. The Autoscaler scales the nodes of a cluster according to the workloads, i.e. pods that are to be scheduled. It ensures that no empty nodes are running as well as that new nodes are scheduled if pods are pending to be deployed. Thus, it complements the EC2 Autoscaling groups (by adhering to the node limits set), which implements scaling based on utilization but neglects the pods to be scheduled.

**NOTE**  
The Cluster Autoscaler will be deployed as a Kubernetes Deployment within the actual EKS cluster. Currently, no adequate and official Terraform module has been found for this purpose. Therefore, the implementation relies on the official commands from the Kubernetes [Cluster Autoscaler Github Repo](https://github.com/kubernetes/autoscaler).

## Prerequisites 

1. Provisioned EKS Cluster: [Baseline Architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture).
2. Connection to the cluster (via ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster``).
3. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - A command line tool for interacting with AWS services.
4. [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - A command line tool for working with Kubernetes clusters.


## Setup

1. Execute ``bash cluster-autoscaler.sh``.
2. Deploy the application, for example: [ALB](https://github.com/frankakn/reliability-deployment/blob/main/Deployment/BaselineArchitecture/TeaStore/teastore-alb.yaml).


## Testing

To easily test the Cluster Autoscaler, we increase the replicas of some services of the application by executing:

1. ``kubectl -n teastore-namespace --replicas=2 deployment/teastore-webui``. Increase replicas depending on the free cluster capacity.
2. ``kubectl -n teastore-namespace --replicas=2 deployment/teastore-recommender``.
3. Monitor the status of the pods by executing: ``kubectl -n teastore-namespace get pods``.
4. Monitor the amount of nodes by executing: ``kubectl get nodes``.

After some minutes new nodes should be in state ready and all pods are running. 

## Cleanup

1. Delete application via ``kubectl delete -f TeaStore\teastore-alb.yaml`` from within the baseline architecture directoy. 
2. Run ``bash shutdown-autoscaler.sh`` and enter the name of the cluster (eks-cluster). 
3. Delete Cluster: ``Terraform destroy`` confirm with ``yes``. This may take up to 20 min. 
