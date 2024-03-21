# Seamless Updates

This part of the repository implements two strategies for updating the TeaStore application. Next to the rolling upgrade strategy, which is managed by K8s, a self-managed blue-green strategy is proposed. 

## Rolling Upgrade of WebUI

The rolling upgrade strategy managed by K8s iteratively updates the application. Via the parameters maxSurge and maxUnavailable the amount of additional and non-available pods at any time can be specified. In this example, only the TeaStore WebUI is updated to its latest image. Per default 3 replicas are created to visualize the update process. 

### Prerequisites

1. Provisioned EKS Cluster: [Baseline Architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture).
2. Connection to the cluster (via ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster``).
3. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - A command line tool for interacting with AWS services.
4. [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - A command line tool for working with Kubernetes clusters.

### Update steps

1. Deploy (here the outdated) version of TeaStore application via: ``kubectl apply -f TeaStore\teastore-upgrade.yaml``.
2. Set the image to ``:latest instead of :1.4.2``.
3. Run `` kubectl apply -f TeaStore\teasture-upgrade.yaml``.
4. Monitor Update process: During the update process, 4 isntead of 3 replicas should be created. Status should change from running to terminated for outdated pods one after another. AGE indicates which pods are newly created (with the latest version) and which ones are outdated.

Alternatively, explicitly update specific image via:

``kubectl set image -n teastore-namespace deployments/teastore-webui teastore-webui=descartesresearch/teastore-webui:latest``

### CleanUp

1. Remove application from the cluster: `` kubectl delete -f  TeaStore\teastore-upgrade.yaml ``. 
2. ``Terraform destroy`` confirm with ``yes``. This may take up to 20 min. (Conduct within cluster directory)


## Blue-green Upgrade of WebUI

For conducting updates based on the blue-green strategy, several mechanisms exist. Instead of recreating the whole application, this approach dupplicates the service to be updated and redirects traffic to the newer version. This method can easily be expanded to recreating all deployments.   
Outdated deployments are labelled as color:blue, while the latest version is labelled as color:green. Via the service component traffic is redirect to the latest version through adjsuting the selector to color:green.

### Prerequisites

1. Provisioned EKS Cluster: [Baseline Architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture).
2. Connection to the cluster (via ``aws eks --region us-east-2 update-kubeconfig --name eks-cluster``).
3. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - A command line tool for interacting with AWS services.
4. [kubectl](https://kubernetes.io/de/docs/tasks/tools/install-kubectl/) - A command line tool for working with Kubernetes clusters.

### Update steps

1. Deploy (here the outdated) version of TeaStore application via: ``kubectl apply -f TeaStore\teastore-bg.yaml``.
2. Set the image to ``:latest instead of :1.4.2``.
3. Update the webui deployment to ``color:green`` where #adjust (1).
3. Run `` kubectl apply -f TeaStore\teasture-bg.yaml``.
5. This creates a second deployment of the webui with the latest image (``kubectl -n teastore-namespace get deployments``).
6. Redirect traffic to the latest deployment by changing ``color:green`` for the WebUI service where #adjust (2).
7. Delete teastore-webui-blue `` kubectl -n teastore-namespace delete deployment teastore-webui-blue ``.

### CleanUp

1. Remove application from the cluster: `` kubectl delete -f  TeaStore\teastore-bg.yaml ``. 
2. ``Terraform destroy`` confirm with ``yes``. This may take up to 20 min. (Conduct within cluster directory)