#!/bin/bash

# Multi-Cloud Kubernetes Cluster Management Utilities
# This script provides helper functions for managing clusters across AKS, EKS, and GKE

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-multicloud-cluster}"
ENVIRONMENT="${ENVIRONMENT:-development}"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    # Check az CLI for Azure
    if ! command -v az &> /dev/null; then
        missing_tools+=("azure-cli")
    fi
    
    # Check aws CLI for AWS
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    fi
    
    # Check gcloud CLI for Google Cloud
    if ! command -v gcloud &> /dev/null; then
        missing_tools+=("gcloud-cli")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install the missing tools and try again."
        exit 1
    fi
    
    log_success "All prerequisites are installed"
}

# Get cluster credentials for AKS
get_aks_credentials() {
    local resource_group="${AZURE_RESOURCE_GROUP:-${CLUSTER_NAME}-aks-rg}"
    local cluster_name="${CLUSTER_NAME}-aks"
    
    log_info "Getting AKS cluster credentials..."
    
    if az aks get-credentials --resource-group "$resource_group" --name "$cluster_name" --overwrite-existing; then
        log_success "AKS credentials retrieved successfully"
    else
        log_error "Failed to get AKS credentials"
        return 1
    fi
}

# Get cluster credentials for EKS
get_eks_credentials() {
    local cluster_name="${CLUSTER_NAME}-eks"
    local region="${AWS_REGION:-us-east-1}"
    
    log_info "Getting EKS cluster credentials..."
    
    if aws eks update-kubeconfig --name "$cluster_name" --region "$region"; then
        log_success "EKS credentials retrieved successfully"
    else
        log_error "Failed to get EKS credentials"
        return 1
    fi
}

# Get cluster credentials for GKE
get_gke_credentials() {
    local cluster_name="${CLUSTER_NAME}-gke"
    local zone="${GCP_ZONE:-us-east1-a}"
    local project="${GCP_PROJECT_ID}"
    
    if [ -z "$project" ]; then
        log_error "GCP_PROJECT_ID environment variable is required"
        return 1
    fi
    
    log_info "Getting GKE cluster credentials..."
    
    if gcloud container clusters get-credentials "$cluster_name" --zone "$zone" --project "$project"; then
        log_success "GKE credentials retrieved successfully"
    else
        log_error "Failed to get GKE credentials"
        return 1
    fi
}

# Get cluster credentials for ARO
get_aro_credentials() {
    local cluster_name="${CLUSTER_NAME}-aro"
    local resource_group="${AZURE_RESOURCE_GROUP:-${CLUSTER_NAME}-aro-rg}"
    
    log_info "Getting ARO cluster information..."
    
    if az aro show --resource-group "$resource_group" --name "$cluster_name" --query '{apiServer:apiserverProfile.url,console:consoleProfile.url,username:clusterProfile.username,password:clusterProfile.password}' -o json 2>/dev/null; then
        log_success "ARO cluster information retrieved successfully"
        log_info "Note: ARO uses different authentication method. Use the API server URL and credentials above."
    else
        log_error "Failed to get ARO cluster information"
        return 1
    fi
}

# Verify cluster health
verify_cluster() {
    local platform="$1"
    local context="$2"
    
    log_info "Verifying $platform cluster health..."
    
    # Switch to cluster context
    kubectl config use-context "$context" 2>/dev/null || {
        log_warning "Could not switch to context $context, using current context"
    }
    
    # Check cluster info
    log_info "Cluster information:"
    kubectl cluster-info
    
    # Check nodes
    log_info "Node status:"
    kubectl get nodes -o wide
    
    # Check system pods
    log_info "System pods status:"
    kubectl get pods -n kube-system
    
    # Check for any failed pods
    local failed_pods=$(kubectl get pods --all-namespaces --field-selector=status.phase=Failed -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
    
    if [ -n "$failed_pods" ]; then
        log_warning "Found failed pods: $failed_pods"
    else
        log_success "No failed pods found"
    fi
    
    # Check cluster capacity
    log_info "Cluster capacity:"
    kubectl top nodes 2>/dev/null || log_warning "Metrics server not available"
}

# Get cluster status for all platforms
get_all_cluster_status() {
    log_info "Getting status for all clusters..."
    
    # AKS
    if command -v az &> /dev/null; then
        local resource_group="${AZURE_RESOURCE_GROUP:-${CLUSTER_NAME}-aks-rg}"
        local aks_cluster="${CLUSTER_NAME}-aks"
        
        log_info "Checking AKS cluster status..."
        if az aks show --resource-group "$resource_group" --name "$aks_cluster" --query "{name:name,powerState:powerState.code,nodeCount:agentPoolProfiles[0].count}" -o table 2>/dev/null; then
            log_success "AKS cluster is accessible"
        else
            log_warning "AKS cluster not found or not accessible"
        fi
    fi
    
    # EKS
    if command -v aws &> /dev/null; then
        local eks_cluster="${CLUSTER_NAME}-eks"
        local region="${AWS_REGION:-us-east-1}"
        
        log_info "Checking EKS cluster status..."
        if aws eks describe-cluster --name "$eks_cluster" --region "$region" --query "cluster.{name:name,status:status,version:version}" --output table 2>/dev/null; then
            log_success "EKS cluster is accessible"
        else
            log_warning "EKS cluster not found or not accessible"
        fi
    fi
    
    # GKE
    if command -v gcloud &> /dev/null; then
        local gke_cluster="${CLUSTER_NAME}-gke"
        local zone="${GCP_ZONE:-us-east1-a}"
        local project="${GCP_PROJECT_ID}"
        
        if [ -n "$project" ]; then
            log_info "Checking GKE cluster status..."
            if gcloud container clusters describe "$gke_cluster" --zone "$zone" --project "$project" --format="table(name,status,currentMasterVersion)" 2>/dev/null; then
                log_success "GKE cluster is accessible"
            else
                log_warning "GKE cluster not found or not accessible"
            fi
        else
            log_warning "GCP_PROJECT_ID not set, skipping GKE check"
        fi
    fi
    
    # ARO
    if command -v az &> /dev/null; then
        local resource_group="${AZURE_RESOURCE_GROUP:-${CLUSTER_NAME}-aro-rg}"
        local aro_cluster="${CLUSTER_NAME}-aro"
        
        log_info "Checking ARO cluster status..."
        if az aro show --resource-group "$resource_group" --name "$aro_cluster" --query "{name:name,state:provisioningState,version:clusterProfile.version}" -o table 2>/dev/null; then
            log_success "ARO cluster is accessible"
        else
            log_warning "ARO cluster not found or not accessible"
        fi
    fi
}

# Scale cluster nodes
scale_cluster() {
    local platform="$1"
    local node_count="$2"
    
    log_info "Scaling $platform cluster to $node_count nodes..."
    
    case $platform in
        "aks")
            local resource_group="${AZURE_RESOURCE_GROUP:-${CLUSTER_NAME}-aks-rg}"
            local cluster_name="${CLUSTER_NAME}-aks"
            
            if az aks scale --resource-group "$resource_group" --name "$cluster_name" --node-count "$node_count"; then
                log_success "AKS cluster scaled successfully"
            else
                log_error "Failed to scale AKS cluster"
                return 1
            fi
            ;;
        "eks")
            local cluster_name="${CLUSTER_NAME}-eks"
            local region="${AWS_REGION:-us-east-1}"
            
            if eksctl scale nodegroup --cluster="$cluster_name" --region="$region" --name=standard-workers --nodes="$node_count"; then
                log_success "EKS cluster scaled successfully"
            else
                log_error "Failed to scale EKS cluster"
                return 1
            fi
            ;;
        "gke")
            local cluster_name="${CLUSTER_NAME}-gke"
            local zone="${GCP_ZONE:-us-east1-a}"
            local project="${GCP_PROJECT_ID}"
            
            if [ -z "$project" ]; then
                log_error "GCP_PROJECT_ID environment variable is required"
                return 1
            fi
            
            if gcloud container clusters resize "$cluster_name" --zone "$zone" --project "$project" --num-nodes "$node_count" --quiet; then
                log_success "GKE cluster scaled successfully"
            else
                log_error "Failed to scale GKE cluster"
                return 1
            fi
            ;;
        "aro")
            local resource_group="${AZURE_RESOURCE_GROUP:-${CLUSTER_NAME}-aro-rg}"
            local cluster_name="${CLUSTER_NAME}-aro"
            
            if az aro update --resource-group "$resource_group" --name "$cluster_name" --worker-count "$node_count"; then
                log_success "ARO cluster scaled successfully"
            else
                log_error "Failed to scale ARO cluster"
                return 1
            fi
            ;;
        *)
            log_error "Unsupported platform: $platform"
            return 1
            ;;
    esac
}

# Show usage information
show_usage() {
    cat << EOF
Multi-Cloud Kubernetes Cluster Management Utilities

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    check-prerequisites    Check if required tools are installed
    get-credentials [PLATFORM]  Get cluster credentials for specified platform (aks|eks|gke|aro|all)
    verify-cluster [PLATFORM]   Verify cluster health for specified platform
    get-status              Get status of all clusters
    scale [PLATFORM] [COUNT]    Scale cluster to specified node count

Options:
    -h, --help              Show this help message
    -c, --cluster-name      Specify cluster name (default: multicloud-cluster)
    -e, --environment       Specify environment (default: development)

Environment Variables:
    AZURE_RESOURCE_GROUP   Azure resource group name
    AWS_REGION            AWS region
    GCP_PROJECT_ID        Google Cloud project ID
    GCP_ZONE              Google Cloud zone

Examples:
    $0 check-prerequisites
    $0 get-credentials all
    $0 verify-cluster aks
    $0 scale eks 5
    $0 scale aro 3
    $0 get-status

EOF
}

# Main function
main() {
    case "${1:-}" in
        "check-prerequisites")
            check_prerequisites
            ;;
        "get-credentials")
            case "${2:-}" in
                "aks")
                    get_aks_credentials
                    ;;
                "eks")
                    get_eks_credentials
                    ;;
                "gke")
                    get_gke_credentials
                    ;;
                "aro")
                    get_aro_credentials
                    ;;
                "all")
                    get_aks_credentials || true
                    get_eks_credentials || true
                    get_gke_credentials || true
                    get_aro_credentials || true
                    ;;
                *)
                    log_error "Please specify platform: aks, eks, gke, aro, or all"
                    exit 1
                    ;;
            esac
            ;;
        "verify-cluster")
            case "${2:-}" in
                "aks")
                    get_aks_credentials
                    verify_cluster "AKS" "${CLUSTER_NAME}-aks"
                    ;;
                "eks")
                    get_eks_credentials
                    verify_cluster "EKS" "${CLUSTER_NAME}-eks"
                    ;;
                "gke")
                    get_gke_credentials
                    verify_cluster "GKE" "${CLUSTER_NAME}-gke"
                    ;;
                "aro")
                    get_aro_credentials
                    log_info "ARO verification: Use the API server URL and credentials from get-credentials to access the cluster"
                    ;;
                *)
                    log_error "Please specify platform: aks, eks, gke, or aro"
                    exit 1
                    ;;
            esac
            ;;
        "get-status")
            get_all_cluster_status
            ;;
        "scale")
            if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
                log_error "Please specify platform and node count"
                exit 1
            fi
            scale_cluster "$2" "$3"
            ;;
        "-h"|"--help"|"")
            show_usage
            ;;
        *)
            log_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--cluster-name)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# Run main function with remaining arguments
main "$@" 