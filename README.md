# Evaluating Cloud-native Deployment Options with a Focus on Reliability Aspects

This repository contains the deployment of a microservice application with a focus on the reliability aspects for cloud-native applications defined by Lichtenthäler and Wirtz ([Paper](https://link.springer.com/chapter/10.1007/978-3-031-04718-3_7), [Model](https://r0light.github.io/cna-quality-model/), [Tool with modeling approach](https://github.com/r0light/cna-quality-tool)).
Based on these investigated deployment options, the software architecture modeling approach accompanying the quality model has been extended and refined.
The architectural models can be opened in the corresponding tool: <https://clounaq.de>.

## Cloud-native Deployment Options

The product factors of the quality aspect *Reliability* from the cloud-native quality model by Lichtenthäler and Wirtz were implemented using the microservice reference application [Teastore](https://github.com/DescartesResearch/TeaStore).  
The [baseline architecture](./DeploymentOptions/ManagedK8sManagedNodeGroup-BaselineArchitecture) of the cloud-native application deployment was implemented using AWS EKS.  
In addition, the implementation options for each product factor were added in a modular manner to complement the baseline architecture.  
The repository is structured as follows: Each directory of a product factor contains the options and solutions that contribute to the implementation of the reliability aspect. Corresponding implementation instructions are provided, as well as corresponding changes to the workload definition of the TeaStore.  
Furthermore, models representing the different architectural options are added as examples.
 
The following table shows a summary of implemented concepts: 

| Product Factor                       | Implementation Options              |                                 |                                   |                                 |                         |
|--------------------------------------|-------------------------------------|---------------------------------|-----------------------------------|---------------------------------|-------------------------|
| Built-In Autoscaling                 | [AWS Auto Scaling Groups & Policies](./ReliabilityAspects/Autoscaling/AutoscalingGroups) | [Cluster Autoscaler](./ReliabilityAspects/Autoscaling/ClusterAutoscaler)              | [Karpenter](./ReliabilityAspects/Autoscaling/Karpenter)                         | [Horizontal Pod Autoscaler](./ReliabilityAspects/Autoscaling/HPA)       | [Vertical Pod Autoscaler](./ReliabilityAspects/Autoscaling/VPA) |
| Physical Data / Service Distribution | [StatefulSets and Persistent Volumes](./ReliabilityAspects/Distribution/Data/StatefulSets) | [AWS Relational Database Service](./ReliabilityAspects/Distribution/Data/RDS) | [Node / Pod (Anti-) Affinity Rules](./ReliabilityAspects/Distribution/Service) | [Pod Topology Spread Constraints](./ReliabilityAspects/Distribution/Service) |                         |
| Guarded Ingress                      | [AWS Web Application Firewall](./ReliabilityAspects/GuardedIngress/AWSWAF)        | [Ingress Controller](./ReliabilityAspects/GuardedIngress/IngressController)              | [(ModSecurity)](./ReliabilityAspects/GuardedIngress/ModSecurity)                     |                                 |                         |
| Health and Readiness Checks          | [Liveness and Readiness Probes](./ReliabilityAspects/HealthChecks)       | [AWS Load Balancer Health Checks](./ReliabilityAspects/HealthChecks) |                                   |                                 |                         |
| Seamless Upgrades                    | [K8s Rolling Update Strategy](./ReliabilityAspects/SeamlessUpgrade)         | [Blue-Green Update Strategy](./ReliabilityAspects/SeamlessUpgrade)           |                                   |                                 |                         |

### Descriptions of the product factors

#### [Built-In Autoscaling](https://clounaq.de/quality-model/built-InAutoscaling)

Horizontal up- and down-scaling of components is automated and built into the infrastructure on which components run. Horizontal scaling means that component instances are replicated when the load increases and components instances are removed when load decreases. This autoscaling is based on rules which can be configured according to system needs.

#### [Physical data distribution](https://clounaq.de/quality-model/physicalDataDistribution)

Storage Backing Service instances where Data aggregates are persisted are distributed across physical locations (e.g. availability zones of a cloud vendor) so that even in the case of a failure of one physical location, another physical location is still useable.

#### [Physical service distribution](https://clounaq.de/quality-model/physicalServiceDistribution)

Components are distributed through replication across physical locations (e.g. availability zones of a cloud vendor) so that even in the case of a failure of one physical location, another physical location is still useable.

#### [Guarded ingress](https://clounaq.de/quality-model/guardedIngress)

Ingress communication, that means communication coming from outside of a system, needs to be guarded. It should be ensured that access to external endpoints is controlled by components offering these external endpoints. Control means for example that only authorized access is possible, maliciously large load is blocked, or secure communication protocols are ensured.

#### [Health and readiness Checks](https://clounaq.de/quality-model/healthAndReadinessChecks)

All components in a system offer health and readiness checks so that unhealthy components can be identified and communication can be restricted to happen only between healthy and ready components. Health and readiness checks can for example be dedicated endpoints of components which can be called regularly to check a component. That way, also an up-to-date holistic overview of the health of a system is enabled.

#### [Seamless upgrades](https://clounaq.de/quality-model/seamlessUpgrades)

Upgrades of services do not interfere with availability. There are different strategies, like rolling upgrades, to achieve this which should be provided as a capability by the infrastructure.

## Modeling Approach Extension

Based on the investigation of the mentioned different deployment options, the modeling approach corresponding to the proposed quality model for cloud-native software architectures has been extended in order to cover the different characteristics of the deployment options.
More specifically, the following extensions have been introduced and can be found in the corresponding exemplary models:

### Extensions for characterizing different deployment options

These extensions mainly cover basic deployment options, without a specific focus on reliability. Exemplary implementations and models for the TeaStore application can be found in [DeploymentOptions](https://github.com/frankakn/reliability-deployment/tree/main/DeploymentOptions/).

#### Infrastructure entity

* property **kind**: The kind of infrastructure: e.g. "physical hardware" | "virtual hardware" | "software platform" | "cloud service"
* property **environment_access**: To what extend it is possible to access the environment in which the infrastructure is running: "full" | "limited" | "none"
* property **maintenance**: How the infrastructure is maintained, e.g. how operating systems are upgraded: "manual" | "automated" | "transparent"
* property **provisioning**: How the infrastructure is provisioned, regarding the effort required from the user: e.g. "manual" | "automated coded" | "automated inferred" | "transparent"
* property **supported_artifacts**: list of supported artifact types
* property **assigned_networks**: list of networks the infrastructure is assigned to

#### Component entity

* property **assigned_networks**: list of networks the component is assigned to
* (The specification of artifacts which are used to deploy a component (e.g., OCI image, jar, VM image, Lambda function, native executable) is now supported through the **artifacts** attribute of the TOSCA Node Type; In a previous version, an additional property was used.)

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

* property: **load_shedding**: boolean: Whether or not this component applies load shedding
* requirement: **proxied_by**: Reference to a backing service which acts as a proxy for all communication to this component

#### Deployment Mapping entity

* property: **update_strategy**: e.g. "replace" | "rolling" | "blue-green" The strategy used when updating the deployed component.
* property: **automated_restart_policy**: "never" | "onReboot" | "onProcessFailure" | "onHealthFailure" In which cases components are restarted by the infrastructure
* property: **resource_requirements** whether or not the required resources for a component are stated. Default is unstated. Otherwise requirements can be stated in a custom format.
* property: **replicas**: How many replicas are configured to be executed for this deployment.

#### Endpoint entity

*Note: Endpoints are defined as Nodes although there are already capability type definitions for endpoints within the TOSCA Standard. The reason why an additional Node type for endpoints is used is the following: Based on the current TOSCA 2.0 standard, Capabilities can only be defined (see 5.3.5.2 Capability Definition) within Node Type definitions (see 5.3.1 Node Type) while in Node Templates (see 5.3.2 Node Template) it is only possible to use Capability Assignments (see 5.3.5.3 Capability Assignment) referring to capability types previously defined in the Node Type Definition.
Endpoints modeled with the inherent Endpoint Capability in Node Templates therefore do not have a unique key, but all have the symbolic name of a Capability definition as defined in the Node Type definition.
Specifying a relationship from one Service to a specific Endpoint of another Service is therefore not possible, because Endpoints cannot be uniquely identified. A definition of Endpoints as new Capabilities would only be possible through additional Node Type definitions which would increase the complexity since a new Node Type would need to be added for each modeled component.
Since a specification of communication links between components and endpoints of components is necessary for the quality model in question, a workaround has been chosen which is based on modeling Endpoints as Node templates (with a corresponding node type for endpoints)*

* property: **rate_limiting**: Whether for this endpoint a certain rate limit is enforced. If not it is "none", otherwise the limit can be stated, such as "100 requests per second"
* property: **readiness_check**: boolean: Whether this endpoint can be used as a readiness check
* property: **health_check**: boolean: Whether this endpoint can be used as a health check
* property: **idempotence**: boolean: To specify whether this endpoint is idempotent; Idempotent means that multiple calls to this endpoint with the same parameters always lead to the same state. This is for example helpful for retries, because idempotent endpoints can be retried repeatedly.

#### Link entity

* property **timeout**: Whether and how long a timeout has been set for this invocation to cancel invocations that are unresponsive.
* property **circuit_breaker**: Whether a circuit breaker is implemented and active for this invocation.
* property **retries**: Whether and how many retries are implemented if the first invocation fails.

#### Relation between Component and Data Aggregate

* property **usage_relation**: Describes how a component uses attached data, that means whether it just uses (reads) it for its functionality or if it also updates and persists (writes) it; possible values are usage, cached usage, and persistence