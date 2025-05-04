# Anthos Service Mesh 

## Project Overview
This repository documents a hands-on walkthrough of implementing and testing Anthos Service Mesh with a microservices-based application (Bank of Anthos) deployed across multiple GKE clusters. The walkthrough demonstrates key service mesh capabilities including cross-cluster service discovery, secure routing, observability, and security features.

## Architecture
The implementation consists of:
- Two GKE clusters: `gke-region1` (us-east4) and `gke-region2` (europe-west1)
- Anthos Service Mesh configured across both clusters
- Bank of Anthos application deployed across both clusters
- Service mesh components enabling cross-cluster communication

![Architecture Diagram](images/architecture.png)

## Prerequisites
- Google Cloud Platform account with sufficient privileges
- Google Kubernetes Engine (GKE) enabled
- Anthos Service Mesh installed and configured

## Walkthrough Steps

### 1. Exploring the Application Deployment
- Verified two Anthos clusters are registered in GKE
- Confirmed all microservices deployed across both clusters
- Note: Database services (accounts-db and ledger-db) only run in gke-region1
- Verified istio-ingressgateway providing external access to the application
- Tested application functionality across both clusters

### 2. Testing Cross-Cluster Traffic Routing
- Demonstrated east-west routing capabilities by scaling frontend deployment to zero in gke-region2
- Verified application continues to function without interruption
- Confirmed traffic automatically routed to available service instances in other cluster
- Restored original deployment configuration

### 3. Observing Distributed Services
- Explored the Anthos Service Mesh dashboard Topology View
- Examined service dependencies and communication patterns
- Viewed detailed metrics for the frontend service
- Created a Service Level Objective (SLO) for frontend latency:
  - Metric: Latency
  - Threshold: 350ms
  - Period: Calendar day
  - Goal: 99.5%

### 4. Verifying Service Mesh Security
- Confirmed mutual TLS (mTLS) encryption between all services
- Observed authentication status for different traffic sources
- Reviewed HTTP operation permissions for the frontend service
- Noted automatic mTLS implementation across the mesh

## Key Benefits Demonstrated
1. **Resiliency**: Application remains available despite cluster-level failures
2. **Scalability**: Services can run across multiple clusters, regions, and zones
3. **Security**: All inter-service traffic encrypted with mTLS
4. **Observability**: Comprehensive metrics, topology views, and SLO capabilities
5. **Traffic Management**: Seamless cross-cluster routing

## Implementation Files
This repository includes:
- [deployment.yaml](deployment/deployment.yaml): Kubernetes manifests for application deployment
- [service-mesh-config.yaml](config/service-mesh-config.yaml): Anthos Service Mesh configuration
- [slo-definition.json](observability/slo-definition.json): Example SLO definition for frontend service

## References
- [Anthos Service Mesh Documentation](https://cloud.google.com/anthos/service-mesh/docs)
- [Bank of Anthos Sample Application](https://github.com/GoogleCloudPlatform/bank-of-anthos)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
