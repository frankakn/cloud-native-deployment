# Kubernetes Vertical Pod Autoscaler 
This part of the repository installs the Kubernetes Vertical Pod Autoscaler to the Amazon EKS Cluster.  

To install the VPA into the EKS cluster, currently, no Terraform module exists. Instead, AWS and the official github repository of the Kubernetes Autoscalers provide a short tutorial on how to install the VPA into the cluster. The following steps are based on these tutorials but will highlight a few changes in the setup as, currently, the latest version of the VPA contains a bug (see [Issue](https://github.com/kubernetes/autoscaler/issues/5982#issuecomment-1651663433)). 

## VPA Configuration Decisions

In order to make use of the installed VPA, a vpa.yaml resource has to be created that determines how, when and if pods should be scaled if their allocated resources do not fit accordingly. The parameter that decides if and when VPA pods are scaled is updateMode in the vpa.yaml. It can be set to auto, recreate, initial, or off. Currently it is set to off, so the recommender only makes recommendations but does not pursue them. 

## Prerequisites

1. Provisioned EKS Cluster: [Baseline Architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture).
2. Connection to the cluster (via ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster``).
3. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - A command line tool for interacting with AWS services.
4. [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - A command line tool for working with Kubernetes clusters.
5. OpenSSL 1.1.1 or later installed on your device.

## Steps

1. Install the Kubernetes Metrics Server: ``kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml``.
2. Clone the Kubernetes Autoscaler Repository: ``git clone https://github.com/kubernetes/autoscaler.git`` **NOTE:** Suggestion to do this outside the current repository, otherwise the path name can be too long for windows.
3. Switch to the latest stable version: ``git checkout vertical-pod-autoscaler-0.14.0`` **NOTE:** At the time of execution the master version does not work, this may have been fixed by updates.
4. Navigate into the VPA directory: ``cd autoscaler/vertical-pod-autoscaler/``.
5. Deploy the VPA: ``./hack/vpa-up.sh``.
6. If an errors occures while creating the certificate authority, navigate to ``autoscaler\vertical-pod-autoscaler\pkg\admission-controller\gencerts.sh`` and escape the /CN= to //CN (2 replacements).
7. Check if metrics server, vpa-admission-controller, vpa-recommender, vpa-updater are running :``kubectl get pods -n kube-system``.
8. Open new CMD or navigate back to this repo & deploy vpa.yaml: ``kubectl create -f vpa.yaml``.
9. Deploy the application: [ALB](https://github.com/frankakn/reliability-deployment/blob/main/Deployment/BaselineArchitecture/TeaStore/teastore-alb.yaml).
10. check the Recommendations of the VPA: ``kubectl -n teastore-namespace describe vpa teastore-deployment-vpa-webui`` (or -recommender, -persistence ...) **NOTE:** This may take a few minutes until some recommendations show up.


## Clean Up

1. Delete the application: ``kubectl delete -f TeaStore\teastore-alb.yaml`` from within the baseline architecture directory.
2. Remove the VPA rules: ``kubectl delete -f vpa.yaml``.
3. Remove the VPA from the Cluster: `` ./hack/vpa-down.sh``.
4. Delete Cluster: ``Terraform destroy`` confirm with ``yes``. (Within the Baseline Arhcitecture Folder).