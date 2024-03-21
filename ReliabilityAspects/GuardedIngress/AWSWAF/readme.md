# AWS WAF
This part of the repository provides options to implement the product factor Guarded Ingress via an AWS WAF. The concepts of rate limiting and load shedding are realized to secure the application from incoming traffic.   
Both concepts are provided within two Terraform scripts, to adhere to the modularity of this repo and allow the interchangeable and cobinatory deployment of components. 


## Requirements:

1. Provisioned EKS Cluster: [Baseline Architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture).
2. Connection to the cluster (via ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster``).
2. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - A command line tool for interacting with AWS services.
3. [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - A command line tool for working with Kubernetes clusters.
4. [eksctl](https://eksctl.io/) - A command line tool for working with EKS clusters.
5. [Helm 3.7+](https://helm.sh/) - A tool for installing and managing Kubernetes applications.
6. TeaStore App deployed, here via the usage of the [ALB](https://github.com/frankakn/reliability-deployment/blob/main/Deployment/BaselineArchitecture/TeaStore/teastore-alb.yaml).


## Rate Limiting

The AWS WAF was used to set a rate limit (for testing purposes) of 100 requests per IP address or 200 requests in total within a five-minute period.  
Exceeding requests are blocked to avoid overloading the compute capacity. 


## Load Shedding

Load shedding was realized by applying a url-based request limit to the /login path. The goal is to realize a priority-based handling of requests and limit the amount of login-sessions but keeping the availability of the WebUI.



