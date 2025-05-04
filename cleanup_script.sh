#!/bin/bash
# This script cleans up the GKE clusters and resources created for the Anthos Service Mesh demo

set -e

# Variables
PROJECT_ID=$(gcloud config get-value project)
REGION1="us-east4"
REGION2="europe-west1"
CLUSTER1="gke-region1"
CLUSTER2="gke-region2"

# Confirm before proceeding
echo "⚠️  WARNING: This will delete the following resources:"
echo "  - GKE cluster: ${CLUSTER1} in ${REGION1}"
echo "  - GKE cluster: ${CLUSTER2} in ${REGION2}"
echo "  - Any SLOs created for the frontend service"
echo ""
read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Cleanup aborted."
    exit 0
fi

# Delete SLOs
echo "Deleting SLOs..."
gcloud alpha monitoring slos delete frontend --service=frontend --project=${PROJECT_ID} --quiet || true

# Delete GKE clusters
echo "Deleting cluster ${CLUSTER1}..."
gcloud container clusters delete ${CLUSTER1} \
  --region=${REGION1} \
  --project=${PROJECT_ID} \
  --quiet \
  --async

echo "Deleting cluster ${CLUSTER2}..."
gcloud container clusters delete ${CLUSTER2} \
  --region=${REGION2} \
  --project=${PROJECT_ID} \
  --quiet

echo "✅ Cleanup completed!"