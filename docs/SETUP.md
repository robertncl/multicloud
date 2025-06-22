# Multi-Cloud Kubernetes Cluster Management Setup Guide

This guide explains how to set up and configure the GitHub Actions workflow for managing Kubernetes clusters across multiple cloud platforms (AKS, EKS, GKE).

## Prerequisites

Before using this workflow, ensure you have:

1. **GitHub Repository**: A GitHub repository with Actions enabled
2. **Cloud Platform Accounts**: Active accounts on Azure, AWS, Google Cloud, and/or Azure Red Hat OpenShift (ARO)
3. **Required Permissions**: Appropriate permissions to create/manage Kubernetes clusters (including ARO)

## Required GitHub Secrets

You need to configure the following secrets in your GitHub repository:

### Azure (AKS/ARO) Secrets
- `AZURE_CREDENTIALS`: Service principal credentials in JSON format
- `AZURE_RESOURCE_GROUP`: Name of the Azure resource group

### AWS (EKS) Secrets
- `AWS_ACCESS_KEY_ID`: AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key

### Google Cloud (GKE) Secrets
- `GCP_SA_KEY`: Service account key in JSON format

## Setting Up Cloud Credentials

### Azure Setup
1. Create a service principal:
```bash
az ad sp create-for-rbac --name "github-actions" --role contributor \
    --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
    --sdk-auth
```

2. Copy the JSON output and add it as `AZURE_CREDENTIALS` secret

### AWS Setup
1. Create an IAM user with EKS permissions:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*",
                "ec2:*",
                "iam:*",
                "cloudformation:*"
            ],
            "Resource": "*"
        }
    ]
}
```

2. Generate access keys and add them as secrets

### Google Cloud Setup
1. Create a service account with GKE permissions:
```bash
gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions"
```

2. Grant necessary roles:
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:github-actions@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.admin"
```

3. Download the key and add it as `GCP_SA_KEY` secret

## GitHub Environments

Create the following environments in your repository:
- `azure`
- `aws` 
- `gcp`

Each environment can have additional protection rules and secrets if needed.

## Using the Workflow

### Manual Trigger
1. Go to the "Actions" tab in your repository
2. Select "Kubernetes Cluster Management"
3. Click "Run workflow"
4. Fill in the required parameters:
   - **Operation**: create, update, or delete
   - **Cloud Platform**: aks, eks, gke, aro, or all
   - **Cluster Name**: Name for your cluster
   - **Region**: Cloud region
   - **Node Count**: Number of nodes
   - **Node Size**: VM/instance type

### Example Usage

#### Create a development cluster on all platforms:
- Operation: `create`
- Cloud Platform: `all`
- Cluster Name: `dev-cluster`
- Region: `us-east-1`
- Node Count: `2`
- Node Size: `Standard_DS2_v2`

#### Update production cluster on EKS only:
- Operation: `update`
- Cloud Platform: `eks`
- Cluster Name: `prod-cluster`
- Node Count: `5`

#### Delete staging cluster on GKE:
- Operation: `delete`
- Cloud Platform: `gke`
- Cluster Name: `staging-cluster`

#### Create an ARO cluster:
- Operation: `create`
- Cloud Platform: `aro`
- Cluster Name: `aro-cluster`
- Region: `eastus`
- Node Count: `3`
- Node Size: `Standard_D4s_v3`

## Configuration Files

The `config/cluster-configs.yml` file contains predefined configurations for different environments (development, staging, production) across all platforms.

## Monitoring and Verification

After cluster creation/update, the workflow will:
1. Get cluster credentials
2. Verify cluster health
3. Display node information
4. Show cluster information

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Verify your cloud credentials are correct and have sufficient permissions (including for ARO)
2. **Resource Quotas**: Check if you have sufficient quota in your cloud accounts
3. **Region Availability**: Ensure the selected region supports the requested VM types
4. **Network Issues**: Verify network connectivity and firewall rules

### Logs and Debugging

- Check the workflow logs in the Actions tab
- Review the summary step for operation results
- Verify cluster status using cloud console or CLI tools

## Security Best Practices

1. **Use Service Principals/Service Accounts**: Never use personal credentials
2. **Principle of Least Privilege**: Grant only necessary permissions
3. **Rotate Credentials**: Regularly rotate access keys and service account keys
4. **Enable Audit Logging**: Monitor cluster access and changes
5. **Network Security**: Use private subnets and security groups where possible

## Cost Optimization

1. **Right-size Clusters**: Use appropriate node types and counts
2. **Auto-scaling**: Enable auto-scaling to optimize resource usage
3. **Spot Instances**: Consider using spot instances for non-critical workloads
4. **Resource Monitoring**: Monitor resource usage and costs regularly

## Next Steps

After setting up the workflow:
1. Test with a small development cluster
2. Configure monitoring and logging
3. Set up CI/CD pipelines for your applications
4. Implement backup and disaster recovery strategies 