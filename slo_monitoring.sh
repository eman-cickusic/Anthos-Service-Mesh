#!/bin/bash
# This script creates Service Level Objectives (SLOs) for the frontend service

set -e

# Variables
PROJECT_ID=$(gcloud config get-value project)
SLO_JSON_FILE="../observability/slo-definition.json"

# Create the SLO using gcloud CLI
echo "Creating SLO for frontend service..."
gcloud alpha monitoring slos create \
  --service=frontend \
  --json-from-file="${SLO_JSON_FILE}" \
  --project="${PROJECT_ID}"

echo "✅ SLO creation completed!"
echo "You can view your SLO in the Google Cloud Console:"
echo "https://console.cloud.google.com/monitoring/services"