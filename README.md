# Evaluating Cloud-native Deployment Options with a Focus on Reliability Aspects

This repository contains the deployment of a microservice application with a focus on the reliability aspects for cloud-native applications defined by Lichtenthäler and Wirtz ([Paper](https://link.springer.com/chapter/10.1007/978-3-031-04718-3_7), [Model](https://r0light.github.io/cna-quality-model/), [Tool with modeling approach](https://github.com/r0light/cna-quality-tool)).
Based on these investigated deployment options, the software architecture modeling approach accompanying the quality model has been extended and refined.
The architectural models can be opened in the corresponding tool: <https://clounaq.de>.

## Cloud-native Deployment Options

The product factors of the quality aspect *Reliability* from the cloud-native quality model by Lichtenthäler and Wirtz were implemented using the microservice reference application [Teastore](https://github.com/DescartesResearch/TeaStore).  
The [baseline architecture](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/BaselineArchitecture) of the cloud-native application deployment was implemented using AWS EKS.  
In addition, the implementation options for each product factor were added in a modular manner to complement the baseline architecture.  
The repository is structured as follows: Each directory of a product factor contains the options and solutions that contribute to the implementation of the reliability aspect. Corresponding implementation instructions are provided, as well as corresponding changes to the workload definition of the TeaStore.  
Furthermore, models representing the different architectural options are added as examples.
 
The following table shows a summary of implemented concepts: 

| Product Factor                       | Implementation Options              |                                 |                                   |                                 |                         |
|--------------------------------------|-------------------------------------|---------------------------------|-----------------------------------|---------------------------------|-------------------------|
| Built-In Autoscaling                 | [AWS Auto Scaling Groups & Policies](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/Autoscaling/AutoscalingGroups) | [Cluster Autoscaler](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/Autoscaling/ClusterAutoscaler)              | [Karpenter](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/Autoscaling/Karpenter)                         | [Horizontal Pod Autoscaler](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/Autoscaling/HPA)       | [Vertical Pod Autoscaler](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/Autoscaling/VPA) |
| Physical Data / Service Distribution | [StatefulSets and Persistent Volumes](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/Distribution/Data/StatefulSets) | [AWS Relational Database Service](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/Distribution/Data/RDS) | [Node / Pod (Anti-) Affinity Rules](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/Distribution/Service) | [Pod Topology Spread Constraints](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/Distribution/Service) |                         |
| Guarded Ingress                      | [AWS Web Application Firewall](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/GuardedIngress/AWSWAF)        | [Ingress Controller](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/GuardedIngress/IngressController)              | [(ModSecurity)](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/GuardedIngress/ModSecurity)                     |                                 |                         |
| Health and Readiness Checks          | [Liveness and Readiness Probes](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/HealthChecks)       | [AWS Load Balancer Health Checks](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/HealthChecks) |                                   |                                 |                         |
| Seamless Upgrades                    | [K8s Rolling Update Strategy](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/SeamlessUpgrade)         | [Blue-Green Update Strategy](https://github.com/frankakn/reliability-deployment/tree/main/Deployment/Reliability/SeamlessUpgrade)           |                                   |                                 |                         |

## Modeling Approach Extension

Based on the investigation of the mentioned different deployment options, the modeling approach corresponding to the proposed quality model for cloud-native software architectures has been extended in order to cover the different characteristics of the deployment options.
More specifically, the following extensions have been introduced and can be found in the corresponding exemplary models:

### Extensions for characterizing different deployment options

These extensions mainly cover basic deployment options, without a specific focus on reliability. Exemplary models for the TeaStore application can be found in [BasicDeploymentOptions](https://github.com/frankakn/reliability-deployment/tree/main/BasicDeploymentOptions/).

#### Infrastructure entity

* property **kind**: The kind of infrastructure: e.g. "physical hardware" | "virtual hardware" | "software platform" | "cloud service"
* property **environment_access**: To what extend it is possible to access the environment in which the infrastructure is running: "full" | "limited" | "none"
* property **maintenance**: How the infrastructure is maintained, e.g. how operating systems are upgraded: "manual" | "automated" | "transparent"
* property **provisioning**: How the infrastructure is provisioned, regarding the effort required from the user: e.g. "manual" | "automated coded" | "automated inferred" | "transparent"
* property **supported_artifacts**: list of supported artifact types
* property **assigned_networks**: list of networks the infrastructure is assigned to

#### Component entity

* property **artifact**: Which type of artifact is built for the specific component to deploy it: e.g. "OCI image" | "jar" | "VM image" | "Lambda function" | "native executable"
* property **assigned_networks**: list of networks the component is assigned to

#### Deployment Mapping entity

* property **deployment**: How the deployment is done from a developer perspective e.g. "manual" | "automated imperative" | "automated declarative"
* property **deployment_unit**: Which unit of deployment is used, e.g. Kubernetes Stateful Set, Lambda Function, Kubernetes Deployment, Container, Pod
* property **assigned_account**: The name of the account assigned to a component during deployment

### Extensions for characterizing implementations of different reliability concepts

These extensions are more specific to the implemented options and exemplary models can be found within each folder containing an implementation.

#### Infrastructure entity

* property **availability_zone**: name(s) of the availability zones in which this infrastructure runs.
* property **region**: name(s) of the region in which this infrastructure runs.
* property **deployed_entities_scaling**: e.g. "none" | "manual" | "automated built-in" | "automated separate", How components deployed on this infrastructure are scaled
* property **self_scaling**: e.g. "none" | "manual" | "automated built-in" | "automated separate", How the infrastructure itself is scaled.
* property **supported_update_strategies**: A list of which upgrade strategies are supported considering seamless upgrades.
* property **enforced_resource_bounds**: boolean: To specify whether the infrastructure enforces resource boundaries of deployed components

#### Component entity

* property: **load shedding**: boolean: Whether or not this component applies load shedding
* requirement: **proxied_by**: Reference to a backing service which acts as a proxy for all communication to this component

#### Deployment Mapping entity

* property: **update_strategy**: e.g. "replace" | "rolling" | "blue-green" The strategy used when updating the deployed component.
* property: **automated_restart_policy**: "never" | "onReboot" | "onProcessFailure" | "onHealthFailure" In which cases components are restarted by the infrastructure
* property: **resource_requirements** whether or not the required resources for a component are stated. Default is unstated. Otherwise requirements can be stated in a custom format.

#### Endpoint entity

* property: **rate limiting**: Whether for this endpoint a certain rate limit is enforced. If not it is "none", otherwise the limit can be stated, such as "100 requests per second"
* property: **Readiness Check**: boolean: Whether this endpoint can be used as a readiness check
* property: **Health Check**: boolean: Whether this endpoint can be used as a health check
