# Multi-Cloud Kubernetes Cluster Management

A comprehensive solution for managing Kubernetes clusters across multiple cloud platforms (AKS, EKS, GKE) using GitHub Actions and Terraform.

## 🚀 Features

- **Multi-Cloud Support**: Manage Kubernetes clusters on Azure (AKS), AWS (EKS), Google Cloud (GKE), and Azure Red Hat OpenShift (ARO)
- **GitHub Actions Workflows**: Automated cluster operations with manual triggers
- **Terraform Infrastructure as Code**: Declarative infrastructure management
- **Environment-Based Configurations**: Predefined configurations for development, staging, and production
- **Security Best Practices**: Service principals, IAM roles, and least privilege access
- **Cost Optimization**: Auto-scaling, right-sizing, and resource monitoring

## 📁 Project Structure

```
multicloud/
├── .github/
│   └── workflows/
│       ├── kubernetes-cluster-management.yml    # GitHub Actions for cluster operations
│       └── kubernetes-version-upgrade.yml      # GitHub Actions for version upgrades
│       └── terraform-deploy.yml                 # Terraform deployment workflow
├── config/
│   └── cluster-configs.yml                      # Cluster configurations
├── docs/
│   └── SETUP.md                                 # Detailed setup guide
├── terraform/
│   └── main.tf                                  # Terraform infrastructure code
└── README.md                                    # This file
```

## 🛠️ Quick Start

### 1. Prerequisites

- GitHub repository with Actions enabled
- Cloud platform accounts (Azure, AWS, Google Cloud)
- Appropriate permissions for Kubernetes cluster management

### 2. Setup Cloud Credentials

#### Azure (AKS)
```bash
az ad sp create-for-rbac --name "github-actions" --role contributor \
    --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
    --sdk-auth
```

#### AWS (EKS)
Create IAM user with EKS permissions and generate access keys.

#### Google Cloud (GKE)
Create service account with GKE permissions and download the key.

### 3. Configure GitHub Secrets

Add the following secrets to your repository:

**Azure:**
- `AZURE_CREDENTIALS`: Service principal credentials (JSON)
- `AZURE_RESOURCE_GROUP`: Resource group name

**AWS:**
- `AWS_ACCESS_KEY_ID`: Access key ID
- `AWS_SECRET_ACCESS_KEY`: Secret access key
- `AWS_REGION`: AWS region

**Google Cloud:**
- `GCP_SA_KEY`: Service account key (JSON)
- `GCP_PROJECT_ID`: Project ID

**Terraform (Optional):**
- `TF_API_TOKEN`: Terraform Cloud API token
- `TF_STATE_BUCKET`: S3 bucket for Terraform state
- `TF_STATE_REGION`: S3 bucket region

### 4. Create GitHub Environments

Create environments in your repository:
- `azure`
- `aws`
- `gcp`

## 🎯 Usage

### GitHub Actions Workflow

1. Go to **Actions** tab in your repository
2. Select **Kubernetes Cluster Management**
3. Click **Run workflow**
4. Configure parameters:
   - **Operation**: create, update, delete
   - **Cloud Platform**: aks, eks, gke, aro, all
   - **Cluster Name**: Name for your cluster
   - **Region**: Cloud region
   - **Node Count**: Number of nodes
   - **Node Size**: VM/instance type

### Terraform Workflow

1. Go to **Actions** tab in your repository
2. Select **Terraform Multi-Cloud Deployment**
3. Click **Run workflow**
4. Configure parameters:
   - **Operation**: plan, apply, destroy
   - **Environment**: development, staging, production
   - **Cloud Platforms**: aks, eks, gke, all
   - **Cluster Name**: Name for your cluster
   - **Node Count**: Number of nodes

## 📋 Example Operations

### Create Development Clusters on All Platforms
```yaml
Operation: create
Cloud Platform: all (includes aro)
Cluster Name: dev-cluster
Region: us-east-1
Node Count: 2
Node Size: Standard_DS2_v2
```

### Create an ARO Cluster
```yaml
Operation: create
Cloud Platform: aro
Cluster Name: aro-cluster
Region: eastus
Node Count: 3
Node Size: Standard_D4s_v3
```

### Update Production EKS Cluster
```yaml
Operation: update
Cloud Platform: eks
Cluster Name: prod-cluster
Node Count: 5
```

### Delete Staging GKE Cluster
```yaml
Operation: delete
Cloud Platform: gke
Cluster Name: staging-cluster
```

## 🔧 Configuration

### Cluster Configurations

The `config/cluster-configs.yml` file contains predefined configurations:

- **Development**: 2 nodes, smaller instance types
- **Staging**: 3 nodes, medium instance types
- **Production**: 5+ nodes, larger instance types with additional features
- **ARO**: Uses Azure CLI and supports similar node/region parameters

### Customization

You can customize:
- Node counts and types
- Regions and availability zones
- Auto-scaling parameters
- Security features
- Monitoring and logging

## 🔒 Security

### Best Practices Implemented

- Service principals/service accounts (no personal credentials)
- Principle of least privilege
- Private subnets and security groups
- Audit logging enabled
- Network policies (where supported)

### Required Permissions

**Azure:**
- Contributor role on resource group
- AKS cluster management permissions

**AWS:**
- EKS cluster management
- EC2 instance management
- IAM role management

**Google Cloud:**
- Container Admin role
- Compute Engine permissions

## 💰 Cost Optimization

### Features

- **Auto-scaling**: Automatic node scaling based on demand
- **Right-sizing**: Appropriate instance types for workloads
- **Spot Instances**: Cost-effective instances for non-critical workloads
- **Resource Monitoring**: Track usage and costs

### Recommendations

1. Use development configurations for testing
2. Enable auto-scaling in production
3. Monitor resource usage regularly
4. Consider spot instances for batch workloads

## 🚨 Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify credentials are correct
   - Check permissions and roles
   - Ensure service accounts are active

2. **Resource Quotas**
   - Check cloud platform quotas
   - Request quota increases if needed
   - Use smaller instance types for testing

3. **Network Issues**
   - Verify VPC/subnet configurations
   - Check security group rules
   - Ensure DNS resolution works

### Getting Help

- Check workflow logs in GitHub Actions
- Review the summary step for operation results
- Verify cluster status in cloud consoles
- Consult platform-specific documentation

## 📚 Documentation

- [Setup Guide](docs/SETUP.md): Detailed setup instructions
- [Cluster Configurations](config/cluster-configs.yml): Configuration examples
- [Terraform Documentation](terraform/): Infrastructure as Code

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- GitHub Actions for CI/CD automation
- HashiCorp Terraform for infrastructure as code
- Cloud providers for managed Kubernetes services
- Open source community for tools and libraries