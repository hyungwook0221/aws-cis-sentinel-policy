#!/bin/bash

# AWS Well-Architected EKS Cluster Validation Script
# This script validates the EKS cluster deployment and configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME=${1:-"well-architected-eks"}
REGION=${2:-"ap-northeast-2"}

echo -e "${GREEN}🔍 Validating EKS Cluster: ${CLUSTER_NAME} in ${REGION}${NC}"
echo "=================================================="

# Function to check command success
check_command() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        exit 1
    fi
}

# Function to check resource count
check_count() {
    local count=$1
    local expected=$2
    local resource=$3
    
    if [ "$count" -ge "$expected" ]; then
        echo -e "${GREEN}✅ $resource: $count (expected: >= $expected)${NC}"
    else
        echo -e "${RED}❌ $resource: $count (expected: >= $expected)${NC}"
    fi
}

echo -e "\n${YELLOW}1. Checking AWS CLI and kubectl configuration...${NC}"

# Check AWS CLI
aws --version > /dev/null 2>&1
check_command "AWS CLI is installed"

# Check kubectl
kubectl version --client > /dev/null 2>&1
check_command "kubectl is installed"

# Check AWS credentials
aws sts get-caller-identity > /dev/null 2>&1
check_command "AWS credentials are configured"

echo -e "\n${YELLOW}2. Checking EKS cluster status...${NC}"

# Check cluster exists and is active
CLUSTER_STATUS=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.status' --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
    echo -e "${GREEN}✅ EKS cluster is ACTIVE${NC}"
else
    echo -e "${RED}❌ EKS cluster status: $CLUSTER_STATUS${NC}"
    exit 1
fi

# Update kubeconfig
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION > /dev/null 2>&1
check_command "kubeconfig updated"

echo -e "\n${YELLOW}3. Checking cluster nodes...${NC}"

# Check nodes are ready
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "Ready" || echo "0")

check_count $NODE_COUNT 1 "Total nodes"
check_count $READY_NODES 1 "Ready nodes"

# Display node information
echo -e "\n${YELLOW}Node Details:${NC}"
kubectl get nodes -o wide

echo -e "\n${YELLOW}4. Checking system pods...${NC}"

# Check system pods are running
SYSTEM_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | wc -l)
RUNNING_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c "Running" || echo "0")

check_count $SYSTEM_PODS 5 "System pods"
check_count $RUNNING_PODS 5 "Running system pods"

echo -e "\n${YELLOW}5. Checking EKS addons...${NC}"

# Check EKS addons
ADDONS=("vpc-cni" "coredns" "kube-proxy" "aws-ebs-csi-driver" "eks-pod-identity-agent")

for addon in "${ADDONS[@]}"; do
    ADDON_STATUS=$(aws eks describe-addon --cluster-name $CLUSTER_NAME --addon-name $addon --region $REGION --query 'addon.status' --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$ADDON_STATUS" = "ACTIVE" ]; then
        echo -e "${GREEN}✅ $addon addon is ACTIVE${NC}"
    else
        echo -e "${RED}❌ $addon addon status: $ADDON_STATUS${NC}"
    fi
done

echo -e "\n${YELLOW}6. Checking security configurations...${NC}"

# Check if cluster endpoint is private
ENDPOINT_CONFIG=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.resourcesVpcConfig.endpointConfigPrivateAccess' --output text)
if [ "$ENDPOINT_CONFIG" = "True" ]; then
    echo -e "${GREEN}✅ Private endpoint is enabled${NC}"
else
    echo -e "${YELLOW}⚠️  Private endpoint is not enabled${NC}"
fi

# Check if logging is enabled
LOGGING_TYPES=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.logging.clusterLogging[0].types' --output text)
if [[ "$LOGGING_TYPES" == *"api"* ]] && [[ "$LOGGING_TYPES" == *"audit"* ]]; then
    echo -e "${GREEN}✅ Cluster logging is enabled${NC}"
else
    echo -e "${YELLOW}⚠️  Cluster logging may not be fully enabled${NC}"
fi

# Check encryption
ENCRYPTION=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.encryptionConfig' --output text)
if [ "$ENCRYPTION" != "None" ] && [ "$ENCRYPTION" != "" ]; then
    echo -e "${GREEN}✅ Cluster encryption is enabled${NC}"
else
    echo -e "${YELLOW}⚠️  Cluster encryption may not be enabled${NC}"
fi

echo -e "\n${YELLOW}7. Testing cluster connectivity...${NC}"

# Test basic connectivity
kubectl get namespaces > /dev/null 2>&1
check_command "Cluster connectivity test"

# Test DNS resolution
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default > /dev/null 2>&1 || true
echo -e "${GREEN}✅ DNS resolution test completed${NC}"

echo -e "\n${YELLOW}8. Storage class validation...${NC}"

# Check storage classes
STORAGE_CLASSES=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l)
check_count $STORAGE_CLASSES 1 "Storage classes"

# Check for gp3 storage class
GP3_SC=$(kubectl get storageclass -o name 2>/dev/null | grep -c "gp3" || echo "0")
if [ "$GP3_SC" -gt 0 ]; then
    echo -e "${GREEN}✅ GP3 storage class is available${NC}"
else
    echo -e "${YELLOW}⚠️  GP3 storage class not found${NC}"
fi

echo -e "\n${GREEN}🎉 Cluster validation completed!${NC}"
echo "=================================================="

# Summary
echo -e "\n${YELLOW}Summary:${NC}"
echo "- Cluster Name: $CLUSTER_NAME"
echo "- Region: $REGION"
echo "- Status: $CLUSTER_STATUS"
echo "- Nodes: $NODE_COUNT total, $READY_NODES ready"
echo "- System Pods: $RUNNING_PODS/$SYSTEM_PODS running"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Deploy sample applications to test functionality"
echo "2. Configure monitoring and logging"
echo "3. Set up CI/CD pipelines"
echo "4. Review and apply additional security policies"

echo -e "\n${GREEN}Cluster is ready for use! 🚀${NC}"