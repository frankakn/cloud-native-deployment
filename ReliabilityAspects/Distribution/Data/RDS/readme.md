# AWS RDS for MariaDB
This part of the repository replaces the MariaDB container of the TeaStore with an Amazon RDS Maria DB Instance in order to achieve physical data distribution. 
For the creation of the database instance, AWS Controllers for Kubernetes (ACK) is used, which allows to create AWS resources within the Kubernetes environment. 

**NOTE:** The repository also sets a username and password for the created database, since these specific values are later used by the teastore application to access the database and therefore can not be changed. 

## Prerequisites

1. Provisioned EKS Cluster: [Baseline Architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture).
2. Connection to the cluster (via ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster``)
2. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - A command line tool for interacting with AWS services.
3. [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - A command line tool for working with Kubernetes clusters.
4. [eksctl](https://eksctl.io/) - A command line tool for working with EKS clusters.
5. [Helm 3.7+](https://helm.sh/) - A tool for installing and managing Kubernetes applications.

## Setup 

1. Install ACK controller: ``bash controller.sh``.
2. Create Service account for ACK controller: ``bash IAM.sh``.
3. Check if the RDS controller is up an running: ``kubectl get deployments -n ack-system``.
4. Create the database (including security groups, anmespace, secrets, and subnet groups) via ``bash db.sh``.  
**NOTE:** The database takes up to 10 minutes to create.

### Physical Data Distribution

The database is created as a Multi-AZ database. For MariaDB instances this means, that an additional DB instance is provided in another availability zone (selected from the created subnet group) that serves only as a fallback.  
In order to achieve further distribution, that also serves requets readreplicas can be created with the following commands:

```
aws rds create-db-instance-read-replica \
    --db-instance-identifier first-read-replica \
    --source-db-instance-identifier maria-db \
    --allocated-storage 20 \
    --max-allocated-storage 20 \
    --availability-zone us-east-2a
```

```
aws rds modify-db-instance \
    --db-instance-identifier first-read-replica  \
    --backup-retention-period 3 \
    --apply-immediately
```

```
aws rds create-db-instance-read-replica \
    --db-instance-identifier second-read-replica \
    --source-db-instance-identifier first-read-replica \
    --allocated-storage 20 \
    --max-allocated-storage 20 \
    --availability-zone us-east-2b
```

Following this approach, cascading read replicas are created. AWS RDS allows up to 4 db instances. Thereby, each replica is added to a chain of replicas, with the advantage taht the main db instance (that also serves the write requests) experiences no downtime when creating additional replicas.  
(Ensure the db replica is available before creating the next one via: ``aws rds describe-db-instances --db-instance-identifier first-read-replica``)

### Deploy TeaStore

Execute `` kubectl create -f TeaStore\teastore-rds.yaml `` 

## Clean Up

The repository created:
1. Shutdown Teastore: ``kubectl delete -f TeaStore\teastore-rds.yaml``.
2. RDS Controller within the cluster: Deletes with the cluster.
3. Namespace within the cluster: Deletes with the cluster.
4. Database Instance: ``kubectl delete -f rds-mariadb.yaml``.
5. ReadReplicas: ``aws rds delete-db-instance --db-instance-identifier second-read-replica --skip-final-snapshot`` (Replace name also with second-read-replicas).
6. Secret within the cluster ``kubectl delete secret maria-db-password``.
7. IAM Role for the RDS Controller: ``aws iam delete-role --role-name ack-rds-controller``.
8. Subnet Group ``kubectl delete -f db-subnet-groups.yaml``.