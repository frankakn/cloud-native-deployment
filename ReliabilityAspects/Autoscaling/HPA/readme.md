# Horizontal Pod Autoscaler

This part of the repository adds the Horizontal Pod Autoscaler for the AWS EKS cluster.  

## Prerequisites

1. Provisioned EKS Cluster: [Baseline Architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture).
2. Connection to the cluster (via ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster``).
3. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - A command line tool for interacting with AWS services.
4. [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - A command line tool for working with Kubernetes clusters.

## Steps

1. Deploy application to the AWS EKS Cluster: ``kubectl create -f TeaStore\teastore-hpa.yaml``.
2. Deploy Metrics Server: ``kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml``.
3. Check if Metrics Server is running: ``kubectl get deployment metrics-server -n kube-system``.
2. Create HPA by running ``Terraform apply`` and confirm with ``yes``.

## Test the HPA

The TeaStore application already provides load testing scripts for Apache Apache JMeter. To test the scaling functionality:
1. Install JMeter ([Installation](https://www.simplilearn.com/tutorials/jmeter-tutorial/jmeter-installation)).
2. Open the GUI (bin/apacheJmeter.jar).
3. Open [JMeter file](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/GuardedIngress/JMeter).
4. Adjust the webpage endpoint (DNS of Load Balancer) (Call ``kubectl get services`` -> External IP of teastore-webui ).
5. Start Thread group 3 (including several http requests).
6. Monitor via kubectl (-n teastore-namespace) get pods.
7. Stop the load testing.

## Clean-Up

1. Delete application ``kubectl delete -f Teastore\teastore-hpa.yaml``. 
2. Delete Policies: ``Terraform destroy`` confirm with ``yes``. (Within this folder)
3. Delete Cluster: ``Terraform destroy`` confirm with ``yes``. (Within the Baseline Arhcitecture Folder)