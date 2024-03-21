# Create AWS WAF for implementing load shedding

This script provisions an AWS WAF to an existing AWS EKS cluster, exposing its endpoints via an AWS ALB. 
The AWS WAF applies a load shedding of 100 requests for the path: /login (per IP and across different IPs).

## Initializes the repo

Initialize the repo: ``Terraform init``. This initializes the working directory by installing plugins and the modules created in the project structure. 

## Deploy the AWS WAF Config

Run ``Terraform apply`` confirm with ``yes``.
Note: Sometimes there is an error in binding the correct association when running terraform apply. Simply rerun the script or destroy in advance.

## Test WAF - Alternative 1

1. Adjust the URL to the TeaStore URL (DNS of ALB).
2. Execute the python test script via ``python test.py`` (ensure to be in the correct directory).
3. The error status code 403 should be received (Alternatively: 403 Forbidden is displayed when entering the URL into the browser).

During testing we encountered a delay: Setting a limit to 100 and executing the test script, the 403 status code will be sent after around 200 requests. 

## Test WAF - ALternative 2

1. Download and install [Apache JMeter](https://jmeter.apache.org/download_jmeter.cgi).
2. Adjust the URL within the [test.jmx](https://github.com/frankakn/reliability-deployment/blob/main/Deployment/Reliability/GuardedIngress/JMeter/teastore_browse.jmx) (similar to: alb-eks-1401051952.us-east-2.elb.amazonaws.com - without http://).
3. Execute the Rate Limiting Thread Group and watch the Results Tree (Load Shedding will be blocked after a while, while Home is still serving requests.).

## Clean Up

1. Run ``Terraform destroy`` and confirm with ``yes``. (run within Load Shedding folder to only destroy WAF resource.).
1. Within the Baseline Architecture Repo run:`` kubectl delete -f  TeaStore\teastore-haproxy.yaml ``. This removes the TeaStore from the cluster. 
2. ``Terraform destroy`` confirm with ``yes``. This may take up to 20 min. (run within Baseline Architecture folder to destrox cluster).

