# Ingress Controller 

This part of the repository implements an Ingress Controller as alternative to the Load Balancer Controller of the baseline architecture. The Ingress Controller, here the HaProxy, serves as a reverse proxy and load balancer that directs traffic to the cluster.   
The HaProxy Ingress Controller is used to deploy functionalities from the section *Guarded Ingress*, as alternative to the AWS-native options. 

## Prerequisites

1. Provisioned EKS Cluster: [Baseline Architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture).
2. Connection to the cluster (via ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster``).
3. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - A command line tool for interacting with AWS services.
4. [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - A command line tool for working with Kubernetes clusters.
5. [eksctl](https://eksctl.io/) - A command line tool for working with EKS clusters.
6. [Helm 3.7+](https://helm.sh/) - A tool for installing and managing Kubernetes applications.

## Install HaProxy Ingress Controller

Install via Helm (adjusted from: https://www.haproxy.com/documentation/kubernetes-ingress/community/installation/aws/).
1. ``helm repo add haproxytech https://haproxytech.github.io/helm-charts``.
2. ``helm repo update``.
3. ``helm install haproxy-kubernetes-ingress haproxytech/kubernetes-ingress --create-namespace --namespace haproxy-controller --set controller.service.type=LoadBalancer --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="external" --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-nlb-target-type"="ip" --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"="internet-facing" ``.
4. Configure App Deployment: The HaProxy creates per default an NLB. The install statement from 3 ensures it is internet-facing, so that the created DNS can be used to access the TeaStore WebUI. Run: `` kubectl get services --namespace haproxy-controller ``.
5. Insert External IP (similar to kubectl get services --namespace haproxy-controller) into the [TeaStore Deployment file](https://github.com/frankakn/reliability-deployment/blob/main/Deployment/Reliability/GuardedIngress/IngressController/TeaStore/teastore-haproxy.yaml) as hostname.
6. Navigate into this folder (IngressController).
7. Deploy Teastore: ``kubectl create -f TeaStore\teastore-haproxy.yaml`` .

## Access

8. Acess the TeaStore WebUI via the external IP of the load balancer (`` kubectl get services --namespace haproxy-controller ``).

**NOTE:** Even if the NLB in the console shows active, it may take up to 10 minutes for the load balancer being reachable.

## CleanUp

In order to delete the application, as well as the terraform cluster conduct:
1. `` kubectl delete -f  TeaStore\teastore-haproxy.yaml ``. This removes the TeaStore from the cluster. 
2. ``Terraform destroy`` confirm with ``yes``. This may take up to 20 min. 
