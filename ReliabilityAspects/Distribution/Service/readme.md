# Service Distribution

This part of the repository compares strategies to distribute stateless services of the microservice-reference application TeaStore.

## Prerequisites

1. Provisioned EKS Cluster: [Baseline Architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture).
2. Connection to the cluster (via ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster``).
3. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - A command line tool for interacting with AWS services.
4. [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - A command line tool for working with Kubernetes clusters.

## Pod Topology Spread Constraints

The TeaStore deployment file has been updated with a configuration to implement the pod topology spread constraints for the topology: zone and set a maxSkew of one. Referring to the baseline architecture this implies that the difference of the number of pods between the three nodes in two availability zones is at maximum one. To compare the default scheduling behavior with the pod topology spread constraints, 7 replicas of the TeaStore WebUI can be created with:
1. ``kubectl create -f TeaStore\teastore-distribution-1.yaml`` (plain app implementation).
2. ``kubectl create -f TeaStore\teastore-distribution-2.yaml`` (app implementation with pod topology spread constraints and maxSkew of 1).

 **NOTE:** Referring to the baseline architecture, three nodes are spread across two availability zones. Therefore not the difference between nodes but availability zones has to be compared. 

## Node Affinity

Affinity rules were applied to schedule pods in such a way that a pod is only assigned to a node if a pod of the same ReplicaSet not already exists in this topology (zone).
Two scenarios with soft and hard constraints were implemented. These show that with three replicas and three nodes in two \acp{AZ}, the hard constraints, in contrast to the soft constraints, prevent the assignment of the third WebUI replica.

1. ``kubectl create -f TeaStore\teastore-distribution-3.yaml`` (hard constraint).
2. ``kubectl create -f TeaStore\teastore-distribution-4.yaml`` (soft constraint).

## Clean Up

Ensure that first the application is removed before destroying the cluster.
1. `` kubectl delete -f  TeaStore\teastore-distribution-x.yaml ``. This removes the TeaStore from the cluster. Replace x + ensure to be within this directoy.
2. ``Terraform destroy`` confirm with ``yes``. This may take up to 20 min. 
