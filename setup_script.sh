#!/bin/bash
# This script sets up two GKE clusters with Anthos Service Mesh and deploys the Bank of Anthos application

set -e

# Variables
PROJECT_ID=$(gcloud config get-value project)
REGION1="us-east4"
REGION2="europe-west1"
CLUSTER1="gke-region1"
CLUSTER2="gke-region2"

# Create GKE clusters
echo "Creating GKE cluster in $REGION1..."
gcloud container clusters create $CLUSTER1 \
  --project=$PROJECT_ID \
  --region=$REGION1 \
  --machine-type=e2-standard-4 \
  --num-nodes=3 \
  --workload-pool=$PROJECT_ID.svc.id.goog \
  --enable-stackdriver-kubernetes \
  --async

echo "Creating GKE cluster in $REGION2..."
gcloud container clusters create $CLUSTER2 \
  --project=$PROJECT_ID \
  --region=$REGION2 \
  --machine-type=e2-standard-4 \
  --num-nodes=3 \
  --workload-pool=$PROJECT_ID.svc.id.goog \
  --enable-stackdriver-kubernetes

# Wait for first cluster to be ready
echo "Waiting for $CLUSTER1 to be ready..."
gcloud container clusters list --filter="name=$CLUSTER1" --format="value(status)" | grep -q "RUNNING"

# Get credentials for both clusters
gcloud container clusters get-credentials $CLUSTER1 --region=$REGION1 --project=$PROJECT_ID
gcloud container clusters get-credentials $CLUSTER2 --region=$REGION2 --project=$PROJECT_ID

# Create contexts for kubectl
kubectl config rename-context gke_${PROJECT_ID}_${REGION1}_${CLUSTER1} ${CLUSTER1}
kubectl config rename-context gke_${PROJECT_ID}_${REGION2}_${CLUSTER2} ${CLUSTER2}

# Install Anthos Service Mesh on both clusters
echo "Installing Anthos Service Mesh..."
curl -sL https://storage.googleapis.com/gke-release/asm/asmcli > asmcli
chmod +x asmcli

./asmcli install \
  --project_id $PROJECT_ID \
  --cluster_name $CLUSTER1 \
  --cluster_location $REGION1 \
  --option multicluster \
  --ca citadel \
  --output_dir ./asm_output \
  --enable_registration \
  --enable_all

./asmcli install \
  --project_id $PROJECT_ID \
  --cluster_name $CLUSTER2 \
  --cluster_location $REGION2 \
  --option multicluster \
  --ca citadel \
  --output_dir ./asm_output \
  --enable_registration \
  --enable_all

# Create namespace and enable injection in both clusters
for CTX in ${CLUSTER1} ${CLUSTER2}
do
  kubectl --context=${CTX} create namespace bank-of-anthos
  kubectl --context=${CTX} label namespace bank-of-anthos istio-injection=enabled --overwrite
done

# Apply the service mesh configuration
kubectl --context=${CLUSTER1} apply -f ../config/service-mesh-config.yaml
kubectl --context=${CLUSTER2} apply -f ../config/service-mesh-config.yaml

# Deploy Bank of Anthos application to both clusters
kubectl --context=${CLUSTER1} apply -f ../deployment/deployment.yaml -n bank-of-anthos

# Deploy only the application services (not databases) to the second cluster
cat ../deployment/deployment.yaml | grep -v "accounts-db\|ledger-db" | kubectl --context=${CLUSTER2} apply -f - -n bank-of-anthos

# Wait for deployments to be ready
echo "Waiting for deployments to be ready..."
kubectl --context=${CLUSTER1} wait --for=condition=available --timeout=300s deployment --all -n bank-of-anthos
kubectl --context=${CLUSTER2} wait --for=condition=available --timeout=300s deployment --all -n bank-of-anthos

# Get the external IPs of ingress gateways
INGRESS_IP_1=$(kubectl --context=${CLUSTER1} -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
INGRESS_IP_2=$(kubectl --context=${CLUSTER2} -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "===================================================="
echo "Bank of Anthos deployment complete!"
echo "Access the application at the following URLs:"
echo "Region 1 (${REGION1}): http://${INGRESS_IP_1}"
echo "Region 2 (${REGION2}): http://${INGRESS_IP_2}"
echo "===================================================="