# StatefulSet and Persistent Volumes using the AWS Elastic File Storage
This part of the repository implements the physical data distribution of the TeaStores MariaDB.  
Instead of relying on a managed database service, as oulined [here](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/Distribution/Data/RDS) the Kubernetes workload type StatefulSets together with PersistentVolumes and PersistentVolumeClaims are used to replicate the database.   

Therefore, first the EFS is created via a Terraform script. Afterwards the storage class, which refers to the EFS as well as the volumeClaimTemplates enable a dynamic provisioning of the required PV and PVC for the TeaStore application.   

The physical distribution across availability zones requires the usage and creation of the AWS EFS instead of the already provisioned AWS EBS, which is only accessible from within the same availability zone. For the distribution itself, the mechanisms from the service distribution, here pod affinitiy rules were applied with soft constraints to distribute pods but ensure that all repicas are scheduled accordingly. 

## Prerequisites

1. Provisioned EKS Cluster: [Baseline Architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture).
2. Connection to the cluster (via ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster``).
3. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - A command line tool for interacting with AWS services.
4. [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - A command line tool for working with Kubernetes clusters.
5. [eksctl](https://eksctl.io/) - A command line tool for working with EKS clusters.
6. [Helm 3.7+](https://helm.sh/) - A tool for installing and managing Kubernetes applications.

## Setup

1. Create namespace ``kubectl create namespace teastore-namespace``.
2. Create database access secret within the namespace: ``kubectl -n teastore-namespace create secret generic "mariadb-secret" --from-literal=mariadb-root-password="teapassword"``.
3. Deploy EFS by navigating into this folder, running `` Terraform init `` and ``Terraform apply`` and finally confirm with ``yes``.
4. The terraform module currently does not handle the driver creation, current Terraaform modules where only provided by third parties and were not comptabile. Therefore, first create a IAM Service account and then install the driver via:
- Create Policy: ``aws iam create-policy --policy-name EKS_EFS_CSI_Driver_Policy --policy-document file://iam-policy.json`` .
- Create Service Account: ``eksctl create iamserviceaccount --cluster eks-cluster --namespace kube-system --name efs-csi-controller-sa --attach-policy-arn arn:aws:iam::ACCID:policy/EKS_EFS_CSI_Driver_Policy --approve --region us-east-2 ``. Adjust the ARN with the policy arn output from the step before.
- ``helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/``.
- ``helm repo update aws-efs-csi-driver``.
- ``helm upgrade --install aws-efs-csi-driver --namespace kube-system aws-efs-csi-driver/aws-efs-csi-driver --set controller.serviceAccount.create=false --set controller.serviceAccount.name=efs-csi-controller-sa``.
- Check if 2 controller pods and 3 csi-node pods are running via `` kubectl get pod -n kube-system -l "app.kubernetes.io/name=aws-efs-csi-driver,app.kubernetes.io/instance=aws-efs-csi-driver" ``. 
5. Create storage class and connect to the AWS EFS:
- GET AWS EFS ID: `` aws efs describe-file-systems --query "FileSystems[*].FileSystemId" --output text`` and **INSERT** it into the storageclass.yaml.
- Create storageclass: `` kubectl apply -f storageclass.yaml``.
6. Deploy the TeaStore via: `` kubectl create -f TeaStore\teastore-pvc.yaml``.
7. Check if MariaDB is replicated via: `` kubectl -n teastore-namespace get pods``. mariadb-sts-0, mariadb-sts-1, and mariadb-sts-2 should be up and running. 


## CleanUp

1. Delete Application ``kubectl delete -f TeaStore\teastore-pvc.yaml``.
2. delete file storage: `` Terraform destroy`` confirm with ``yes``. Ensure to execute within this directory.
3. delete cluster: ``Terraform destroy`` confirm with ``yes``. Ensure to conduct within the baseline architecture directly. 
