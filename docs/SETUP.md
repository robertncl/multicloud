# Multi-Cloud Kubernetes Cluster Management Setup Guide

This guide explains how to set up and configure the GitHub Actions workflow for managing Kubernetes clusters across multiple cloud platforms (AKS, EKS, GKE, OpenShift).

## Prerequisites

Before using this workflow, ensure you have:

1. **GitHub Repository**: A GitHub repository with Actions enabled
2. **Cloud Platform Accounts**: Active accounts on Azure, AWS, and/or Google Cloud
3. **On-Premises OpenShift Cluster**: Access to an OpenShift cluster with API access
4. **Required Permissions**: Appropriate permissions to create/manage Kubernetes clusters

## Required GitHub Secrets

You need to configure the following secrets in your GitHub repository:

### Azure (AKS) Secrets
- `AZURE_CREDENTIALS`: Service principal credentials in JSON format
- `AZURE_RESOURCE_GROUP`: Name of the Azure resource group

### AWS (EKS) Secrets
- `AWS_ACCESS_KEY_ID`: AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key

### Google Cloud (GKE) Secrets
- `GCP_SA_KEY`: Service account key in JSON format

### On-Premises OpenShift Secrets
- `OPENSHIFT_SERVER`: OpenShift cluster server URL (e.g., https://api.openshift.example.com:6443)
- `OPENSHIFT_TOKEN`: OpenShift authentication token
- `OPENSHIFT_PROJECT`: Default project name for operations

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

### On-Premises OpenShift Setup
1. Access your OpenShift cluster and generate a token:
```bash
oc login --username=<your-username> --password=<your-password> --server=<your-server>
oc whoami --show-token
```

2. Add the server URL and token as secrets:
   - `OPENSHIFT_SERVER`: Your OpenShift API server URL
   - `OPENSHIFT_TOKEN`: The token from the previous step
   - `OPENSHIFT_PROJECT`: Default project name (e.g., "default")

## GitHub Environments

Create the following environments in your repository:
- `azure`
- `aws` 
- `gcp`
- `openshift`

Each environment can have additional protection rules and secrets if needed.

## Using the Workflow

### Manual Trigger
1. Go to the "Actions" tab in your repository
2. Select "Kubernetes Cluster Management"
3. Click "Run workflow"
4. Fill in the required parameters:
   - **Operation**: create, update, or delete
   - **Cloud Platform**: aks, eks, gke, openshift, or all
   - **Cluster Name**: Name for your cluster/project
   - **Region**: Cloud region (not applicable for OpenShift)
   - **Node Count**: Number of nodes/replicas
   - **Node Size**: VM/instance type (not applicable for OpenShift)

### Example Usage

#### Create a development cluster on all platforms:
- Operation: `create`
- Cloud Platform: `all`
- Cluster Name: `dev-cluster`
- Region: `us-east-1`
- Node Count: `2`
- Node Size: `Standard_DS2_v2`

#### Create an OpenShift project:
- Operation: `create`
- Cloud Platform: `openshift`
- Cluster Name: `openshift-project`
- Node Count: `3`

#### Update production cluster on EKS only:
- Operation: `update`
- Cloud Platform: `eks`
- Cluster Name: `prod-cluster`
- Node Count: `5`

#### Delete staging cluster on GKE:
- Operation: `delete`
- Cloud Platform: `gke`
- Cluster Name: `staging-cluster`

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

1. **Authentication Errors**: Verify your cloud credentials are correct and have sufficient permissions
2. **Resource Quotas**: Check if you have sufficient quota in your cloud accounts
3. **Region Availability**: Ensure the selected region supports the requested VM types
4. **Network Issues**: Verify network connectivity and firewall rules
5. **OpenShift Access**: Ensure OpenShift server URL and token are correct

### Logs and Debugging

- Check the workflow logs in GitHub Actions
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