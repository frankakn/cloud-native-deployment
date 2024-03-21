# Create an IAM Policy
aws iam create-policy --policy-name AmazonEKSClusterAutoscalerPolicy --policy-document file://AmazonEKSClusterAutoscalerPolicy.json

# Save the POLICY_ARN as an environment variable
POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`AmazonEKSClusterAutoscalerPolicy`].Arn' --output text)

# Set necessary environment variables
CLUSTER_NAME=eks-cluster
ROLE_NAME=AmazonEKSClusterAutoscalerRole
SA_NAME=cluster-autoscaler

# Create a Service Account and IAM Role with POLICY 
eksctl create iamserviceaccount \
    --name $SA_NAME \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn=$POLICY_ARN \
    --role-name $ROLE_NAME \
    --namespace kube-system \
    --override-existing-serviceaccounts \
    --approve

# Save the ROLE_ARN as an environment variable
ROLE_ARN=$(aws iam list-roles --query 'Roles[?RoleName==`AmazonEKSClusterAutoscalerRole`].Arn' --output text)

export ROLE_ARN=$(aws iam list-roles --query 'Roles[?RoleName==`AmazonEKSClusterAutoscalerRole`].Arn' --output text)
export CLUSTER_NAME=eks-cluster

# Download the manifest file
curl https://raw.githubusercontent.com/shamimice03/EKS-Cluster-AutoScaler/main/cluster-autoscaler.yaml > cluster-autoscaler.yaml

# Replace <ROLE ARN> place holder with "ROLE_ARN" environment variable 
sed -i "s#<ROLE ARN>#$ROLE_ARN#" cluster-autoscaler.yaml

# Replace the <YOUR CLUSTER NAME> placeholder with the CLUSTER_NAME and 
# Two commands under the the cluster-autoscaler deployment
printf -v spc %12s
sed -i "s#<YOUR CLUSTER NAME>#$CLUSTER_NAME\n${spc}- --balance-similar-node-groups\n${spc}- --skip-nodes-with-system-pods=false#g" cluster-autoscaler.yaml

# Deploy the manifest file
kubectl create -f cluster-autoscaler.yaml