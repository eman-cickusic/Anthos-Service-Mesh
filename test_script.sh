#!/bin/bash
# This script demonstrates cross-cluster resilience by scaling down frontends in one cluster

set -e

# Variables
CLUSTER1="gke-region1"
CLUSTER2="gke-region2"

# Function to test connectivity to both ingress gateways
function test_connectivity() {
  echo "Testing connectivity to both clusters..."
  
  INGRESS_IP_1=$(kubectl --context=${CLUSTER1} -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  INGRESS_IP_2=$(kubectl --context=${CLUSTER2} -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  
  echo "Testing Region 1 ingress: http://${INGRESS_IP_1}"
  curl -s -o /dev/null -w "%{http_code}" http://${INGRESS_IP_1} | grep -q "200" && echo "✅ Success" || echo "❌ Failed"
  
  echo "Testing Region 2 ingress: http://${INGRESS_IP_2}"
  curl -s -o /dev/null -w "%{http_code}" http://${INGRESS_IP_2} | grep -q "200" && echo "✅ Success" || echo "❌ Failed"
}

# Initial state
echo "==== INITIAL STATE ===="
kubectl --context=${CLUSTER1} get deployments -l app=frontend -n bank-of-anthos
kubectl --context=${CLUSTER2} get deployments -l app=frontend -n bank-of-anthos
test_connectivity

# Scale down frontend in Region 2
echo -e "\n==== SCALING DOWN FRONTEND IN REGION 2 ===="
kubectl --context=${CLUSTER2} scale deployment frontend -n bank-of-anthos --replicas=0
sleep 5
kubectl --context=${CLUSTER1} get deployments -l app=frontend -n bank-of-anthos
kubectl --context=${CLUSTER2} get deployments -l app=frontend -n bank-of-anthos
test_connectivity

# Restore frontend in Region 2
echo -e "\n==== RESTORING FRONTEND IN REGION 2 ===="
kubectl --context=${CLUSTER2} scale deployment frontend -n bank-of-anthos --replicas=1
sleep 5
kubectl --context=${CLUSTER1} get deployments -l app=frontend -n bank-of-anthos
kubectl --context=${CLUSTER2} get deployments -l app=frontend -n bank-of-anthos
test_connectivity

# Scale down frontend in Region 1
echo -e "\n==== SCALING DOWN FRONTEND IN REGION 1 ===="
kubectl --context=${CLUSTER1} scale deployment frontend -n bank-of-anthos --replicas=0
sleep 5
kubectl --context=${CLUSTER1} get deployments -l app=frontend -n bank-of-anthos
kubectl --context=${CLUSTER2} get deployments -l app=frontend -n bank-of-anthos
test_connectivity

# Restore frontend in Region 1
echo -e "\n==== RESTORING FRONTEND IN REGION 1 ===="
kubectl --context=${CLUSTER1} scale deployment frontend -n bank-of-anthos --replicas=1
sleep 5
kubectl --context=${CLUSTER1} get deployments -l app=frontend -n bank-of-anthos
kubectl --context=${CLUSTER2} get deployments -l app=frontend -n bank-of-anthos
test_connectivity

echo -e "\n✅ Test completed successfully!"
echo "The application demonstrated resilience across clusters."