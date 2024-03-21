# Health Checks

This part of the repository introduces the possibilities for conducting health and readiness checks.  
A distinction is made between the health checks options provided by the Kubernetes API and the health checks that can be configured via AWS.

## Liveness and Readiness Probes

The Kubernetes API provides the possibility to implement liveness and readiness probes that check whether a pod is running and ready to serve requests.  
Live and readiness checks, based on the HTTP protocol and the available endpoints of the TeaStore application have been added to the [teastore-health.yaml](https://github.com/frankakn/reliability-deployment/blob/main/Deployment/Reliability/HealthChecks/TeaStore/teastore-health.yaml).  
To deploy the app, including the probes:
1. Provision EKS Cluster: [Baseline Architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture).
2. Install: [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - A command line tool for working with Kubernetes clusters.
3. Connect to the cluster: ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster``.
4. Deploy the application: `` kubectl create -f  TeaStore\teastore-health.yaml ``.

**Note:** Due to the small instance sizes, the initial delay has been set to 60 seconds in order to ensure that the the startup is completed before conducting the first probes. 

### Clean Up

1. Remove the application from the cluster: `` kubectl delete -f  TeaStore\teastore-health.yaml ``. This removes the TeaStore from the cluster. (Within this directory).
2. Run ``terraform destroy`` to destroy the cluster and confirm with ``yes``. (Within the cluster directory)

## Load Balancer Health Check

Additionally, AWS provides methods to conduct health checks. The AWS EKS cluster, serving as a baseline architecture, makes use of ELB to distribute the requests across the availability zones. For an architecture relying on ALBs and NLBs, the following commands configure health checks that regualry query the endpoint of the TeaStore application (i.e., the WebUI) to ensure that requests are only routed towards healthy endpoints. 

### Configure Target Groups 

Target groups are automatically created together with the load balancer when deploying the application to the cluster. Therefore, the corresponding resource is not managed by Terraform.  
Changes to the existing target group resource (and target of the TeaStore Webui) can be made via the console. To adjust the path and thresholds execute the following:

1. Get the specifics of the created target group: ``aws elbv2 describe-target-groups --names <target-group-name> --region us-east-2``  **NOTE** Insert the name of the target group - this name is current not possible to be set during creation, therefore it has to be adjusted each time. (AWS Console: EC2 - target group ).
2. Apply the changes:   
ALB:   
`` aws elbv2 modify-target-group --target-group-arn <TARGET-GROUP-ARN> --health-check-protocol HTTP --health-check-port 8080 --health-check-path /tools.descartes.teastore.webui/status --health-check-interval-seconds 22 --health-check-timeout-seconds 12 --healthy-threshold-count 7 --unhealthy-threshold-count 7 --region us-east-2``    
NLB:   
`` aws elbv2 modify-target-group --target-group-arn <TARGET-GROUP-ARN> --health-check-protocol TCP --health-check-port 8080 --health-check-path /tools.descartes.teastore.webui/status --health-check-interval-seconds 22 --health-check-timeout-seconds 12 --healthy-threshold-count 7 --unhealthy-threshold-count 7 --region us-east-2``  

**Note** From the command above (or the AWS Console), obtain the ARN and insert it here, so that the command looks like the following:   
``aws elbv2 modify-target-group --target-group-arn "arn:aws:elasticloadbalancing:us-east-2:800985650215:targetgroup/k8s-teastore-teastore-80b2abc0db/e5b875dbf657c6a2" --health-check-protocol HTTP --health-check-port 8080 --health-check-path /tools.descartes.teastore.webui/status --health-check-interval-seconds 15 --health-check-timeout-seconds 7 --healthy-threshold-count 3 --unhealthy-threshold-count 3 --region us-east-2``   
3. Describe to see the changes: ``aws elbv2 describe-target-group-attributes --target-group-arn <TARGET-GROUP-ARN> --region us-east-2``     
**NOTE:** adjust the target group arn within the command.


### Clean-Up

1. Remove the application from the cluster: `` kubectl delete -f  TeaStore\teastore-health.yaml ``. This removes the TeaStore from the cluster. (Within this directory).
2. Run ``terraform destroy`` to destroy the cluster and confirm with ``yes``. (Within the cluster directory)