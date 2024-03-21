EKS_CLUSTER_NAME="eks-cluster"
REGION="us-east-2"
RDS_SUBNET_GROUP_NAME="mariadb-subnets"
RDS_SUBNET_GROUP_DESCRIPTION="private subnets from EKS cluster"
RDS_SECURITY_GROUP_NAME="sgmariadb"
RDS_SECURITY_GROUP_DESCRIPTION="allows traffic to db"
RDS_INSTANCE_NAME="maria-db"

APP_NAMESPACE=teastore-namespace
kubectl create ns "${APP_NAMESPACE}"

EKS_VPC_ID=$(aws eks describe-cluster --name="${EKS_CLUSTER_NAME}" \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text)
EKS_SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=${EKS_VPC_ID}" "Name=tag:Name,Values=private" \
  --query 'Subnets[*].SubnetId' \
  --output text
)

cat <<-EOF > db-subnet-groups.yaml
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBSubnetGroup
metadata:
  name: ${RDS_SUBNET_GROUP_NAME}
  namespace: ${APP_NAMESPACE}
spec:
  name: ${RDS_SUBNET_GROUP_NAME}
  description: ${RDS_SUBNET_GROUP_DESCRIPTION}
  subnetIDs:
$(printf "    - %s\n" ${EKS_SUBNET_IDS})
  tags: []
EOF

kubectl apply -f db-subnet-groups.yaml



EKS_VPC_ID=$(aws eks describe-cluster --name="${EKS_CLUSTER_NAME}" \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text)

EKS_CIDR_RANGE=$(aws ec2 describe-vpcs \
  --vpc-ids $EKS_VPC_ID \
  --query "Vpcs[].CidrBlock" \
  --output text
)

RDS_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name "${RDS_SECURITY_GROUP_NAME}" \
  --description "${RDS_SECURITY_GROUP_DESCRIPTION}" \
  --vpc-id "${EKS_VPC_ID}" \
  --output text
)

aws ec2 authorize-security-group-ingress \
  --group-id "${RDS_SECURITY_GROUP_ID}" \
  --protocol tcp \
  --port 3306 \
  --cidr "${EKS_CIDR_RANGE}"

kubectl create secret generic "${RDS_INSTANCE_NAME}-password" \
  --from-literal=password="teapassword"

cat <<EOF > rds-mariadb.yaml
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBInstance
metadata:
  name: "${RDS_INSTANCE_NAME}"
  namespace: "teastore-namespace"
spec:
  allocatedStorage: 20
  dbInstanceClass: db.t4g.micro
  dbInstanceIdentifier: "${RDS_INSTANCE_NAME}"
  dbName: "teadb"
  dbSubnetGroupName: "${RDS_SUBNET_GROUP_NAME}"
  vpcSecurityGroupIDs:
  - "${RDS_SECURITY_GROUP_ID}"
  engine: mariadb
  engineVersion: "10.6"
  multiAZ: true
  masterUsername: "teauser"
  masterUserPassword:
    namespace: default
    name: "${RDS_INSTANCE_NAME}-password"
    key: password
EOF

## Create DB
kubectl apply -f rds-mariadb.yaml
