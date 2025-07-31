#!/bin/bash

# Node.js Application Test Script
# This script helps test the Node.js application locally and in containers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to test local Node.js app
test_local_app() {
    print_status "Testing local Node.js application..."
    
    cd apps/nodejs-app
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        print_status "Installing dependencies..."
        npm install
    fi
    
    # Run tests
    print_status "Running tests..."
    npm test
    
    # Start the app in background
    print_status "Starting application..."
    npm start &
    APP_PID=$!
    
    # Wait for app to start
    sleep 3
    
    # Test endpoints
    print_status "Testing endpoints..."
    
    # Test health endpoint
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        print_success "Health endpoint is working"
    else
        print_error "Health endpoint failed"
    fi
    
    # Test main endpoint
    if curl -f http://localhost:3000/ > /dev/null 2>&1; then
        print_success "Main endpoint is working"
    else
        print_error "Main endpoint failed"
    fi
    
    # Test API endpoint
    if curl -f http://localhost:3000/api/info > /dev/null 2>&1; then
        print_success "API endpoint is working"
    else
        print_error "API endpoint failed"
    fi
    
    # Stop the app
    kill $APP_PID 2>/dev/null || true
    
    print_success "Local testing completed"
}

# Function to test Docker container
test_docker_app() {
    print_status "Testing Docker container..."
    
    cd apps/nodejs-app
    
    # Build Docker image
    print_status "Building Docker image..."
    docker build -t multicloud-nodejs-app:test .
    
    # Run container
    print_status "Running container..."
    docker run -d --name nodejs-app-test -p 3000:3000 multicloud-nodejs-app:test
    
    # Wait for container to start
    sleep 5
    
    # Test endpoints
    print_status "Testing container endpoints..."
    
    # Test health endpoint
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        print_success "Container health endpoint is working"
    else
        print_error "Container health endpoint failed"
    fi
    
    # Test main endpoint
    if curl -f http://localhost:3000/ > /dev/null 2>&1; then
        print_success "Container main endpoint is working"
    else
        print_error "Container main endpoint failed"
    fi
    
    # Clean up
    docker stop nodejs-app-test
    docker rm nodejs-app-test
    
    print_success "Docker testing completed"
}

# Function to validate Kubernetes manifests
validate_k8s_manifests() {
    print_status "Validating Kubernetes manifests..."
    
    # Check if kubectl is available
    if ! command_exists kubectl; then
        print_warning "kubectl not found, skipping manifest validation"
        return
    fi
    
    # Validate deployment
    if kubectl apply --dry-run=client -f k8s/nodejs-app/deployment.yaml > /dev/null 2>&1; then
        print_success "Deployment manifest is valid"
    else
        print_error "Deployment manifest validation failed"
    fi
    
    # Validate service
    if kubectl apply --dry-run=client -f k8s/nodejs-app/service.yaml > /dev/null 2>&1; then
        print_success "Service manifest is valid"
    else
        print_error "Service manifest validation failed"
    fi
    
    # Validate ingress
    if kubectl apply --dry-run=client -f k8s/nodejs-app/ingress.yaml > /dev/null 2>&1; then
        print_success "Ingress manifest is valid"
    else
        print_error "Ingress manifest validation failed"
    fi
    
    # Validate HPA
    if kubectl apply --dry-run=client -f k8s/nodejs-app/hpa.yaml > /dev/null 2>&1; then
        print_success "HPA manifest is valid"
    else
        print_error "HPA manifest validation failed"
    fi
    
    print_success "Kubernetes manifest validation completed"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  local     Test the Node.js application locally"
    echo "  docker    Test the Node.js application in Docker container"
    echo "  k8s       Validate Kubernetes manifests"
    echo "  all       Run all tests"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 local"
    echo "  $0 docker"
    echo "  $0 all"
}

# Main script logic
case "${1:-help}" in
    local)
        test_local_app
        ;;
    docker)
        test_docker_app
        ;;
    k8s)
        validate_k8s_manifests
        ;;
    all)
        test_local_app
        echo ""
        test_docker_app
        echo ""
        validate_k8s_manifests
        ;;
    help|*)
        show_usage
        exit 1
        ;;
esac

print_success "Test script completed successfully!" 