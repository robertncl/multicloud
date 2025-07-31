# MultiCloud Node.js Application

A sample Node.js application designed for deployment across multiple cloud providers' managed Kubernetes clusters.

## Features

- **Express.js Web Server**: Lightweight and fast web framework
- **Health Check Endpoint**: `/health` for Kubernetes liveness/readiness probes
- **Security Headers**: Using Helmet.js for security
- **CORS Support**: Cross-origin resource sharing enabled
- **Request Logging**: Morgan middleware for HTTP request logging
- **Environment Awareness**: Displays cloud platform and cluster information
- **Docker Ready**: Containerized with multi-stage build
- **Kubernetes Ready**: Complete K8s manifests included

## Application Endpoints

- `GET /` - Main application endpoint with platform information
- `GET /health` - Health check endpoint for Kubernetes probes
- `GET /api/info` - Detailed application and cluster information

## Local Development

### Prerequisites

- Node.js 18+ 
- npm or yarn

### Installation

```bash
cd apps/nodejs-app
npm install
```

### Running Locally

```bash
npm start
# or for development with auto-reload
npm run dev
```

The application will be available at `http://localhost:3000`

### Docker

```bash
# Build the image
npm run docker:build

# Run the container
npm run docker:run
```

## Kubernetes Deployment

### Prerequisites

- Kubernetes cluster (AKS, EKS, GKE, or OpenShift)
- kubectl configured
- Container registry access

### Deployment Components

1. **Deployment** (`k8s/nodejs-app/deployment.yaml`)
   - Configurable replicas
   - Resource limits and requests
   - Health checks (liveness/readiness probes)
   - Security context
   - Environment variables

2. **Service** (`k8s/nodejs-app/service.yaml`)
   - ClusterIP service
   - Port mapping (80 -> 3000)

3. **Ingress** (`k8s/nodejs-app/ingress.yaml`)
   - External access configuration
   - TLS support
   - Host-based routing

4. **Horizontal Pod Autoscaler** (`k8s/nodejs-app/hpa.yaml`)
   - CPU and memory-based scaling
   - Configurable min/max replicas
   - Scaling policies

### Environment Variables

The application uses the following environment variables:

- `NODE_ENV`: Application environment (development/staging/production)
- `APP_VERSION`: Application version
- `CLOUD_PLATFORM`: Cloud provider (aks/eks/gke/openshift)
- `CLUSTER_REGION`: Cluster region
- `CLUSTER_NAME`: Cluster name

### Deployment via GitHub Actions

Use the `Node.js App Multi-Cloud Deployment` workflow:

1. Go to Actions tab in GitHub
2. Select "Node.js App Multi-Cloud Deployment"
3. Click "Run workflow"
4. Configure parameters:
   - **Cloud Platform**: Choose target platform(s)
   - **Cluster Name**: Your cluster name
   - **App Version**: Version to deploy
   - **Environment**: Development/staging/production
   - **Region**: Cluster region
   - **Replicas**: Number of replicas
   - **Enable Ingress**: Enable external access
   - **Enable HPA**: Enable auto-scaling

### Manual Deployment

```bash
# Create namespace
kubectl create namespace nodejs-app

# Apply manifests
kubectl apply -f k8s/nodejs-app/deployment.yaml -n nodejs-app
kubectl apply -f k8s/nodejs-app/service.yaml -n nodejs-app
kubectl apply -f k8s/nodejs-app/ingress.yaml -n nodejs-app
kubectl apply -f k8s/nodejs-app/hpa.yaml -n nodejs-app

# Verify deployment
kubectl get pods -n nodejs-app
kubectl get services -n nodejs-app
kubectl get ingress -n nodejs-app
```

## Monitoring and Health Checks

### Health Check Endpoint

The `/health` endpoint returns:

```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "environment": "production",
  "version": "v1.0.0"
}
```

### Kubernetes Probes

- **Liveness Probe**: Checks if the application is running
- **Readiness Probe**: Checks if the application is ready to serve traffic
- **Startup Probe**: Ensures the application has started successfully

## Security Features

- **Non-root User**: Container runs as non-root user (UID 1001)
- **Security Headers**: Helmet.js provides security headers
- **Resource Limits**: CPU and memory limits configured
- **Capability Dropping**: All Linux capabilities dropped
- **Privilege Escalation**: Disabled

## Scaling

### Horizontal Pod Autoscaler

The HPA automatically scales the deployment based on:

- **CPU Utilization**: Target 70%
- **Memory Utilization**: Target 80%
- **Min Replicas**: 2
- **Max Replicas**: 10

### Manual Scaling

```bash
kubectl scale deployment nodejs-app --replicas=5 -n nodejs-app
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n nodejs-app
kubectl describe pod <pod-name> -n nodejs-app
```

### Check Logs

```bash
kubectl logs <pod-name> -n nodejs-app
kubectl logs -f deployment/nodejs-app -n nodejs-app
```

### Check Service

```bash
kubectl get svc -n nodejs-app
kubectl describe svc nodejs-app-service -n nodejs-app
```

### Port Forward for Testing

```bash
kubectl port-forward svc/nodejs-app-service 8080:80 -n nodejs-app
```

Then access the application at `http://localhost:8080`

## Cloud Provider Specific Notes

### AKS (Azure Kubernetes Service)
- Uses Azure Container Registry or GitHub Container Registry
- Supports Azure Application Gateway Ingress Controller

### EKS (Amazon Elastic Kubernetes Service)
- Uses Amazon ECR or GitHub Container Registry
- Supports AWS Load Balancer Controller

### GKE (Google Kubernetes Engine)
- Uses Google Container Registry or GitHub Container Registry
- Supports Google Cloud Load Balancer

### OpenShift
- Uses OpenShift internal registry or external registry
- Uses Routes instead of Ingress for external access
- Supports OpenShift-specific security contexts 