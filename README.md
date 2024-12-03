# K3s Runner Terraform Configuration
This repository contains Terraform configurations for setting up self-hosted GitHub Actions runners on a K3s cluster. The setup automates the deployment of runners using Infrastructure as Code (IaC) principles.

## Prerequisites

- Terraform installed
- GitHub account with repository access
- GitHub Runner Token

## Features

- Automated deployment of GitHub Actions runners
- K3s cluster integration
- Configurable runner specifications
- Infrastructure as Code approach using Terraform

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/rek3000/runner-k3s-terraform.git
cd runner-k3s-terraform
```

2. Configure your variables:
   - Copy `terraform.tfvars.example` to `terraform.tfvars`
   - Fill in your specific values:
     - GitHub Runner Token
     - Organization name

3. Initialize Terraform:
```bash
terraform init
```

4. Review the planned changes:
```bash
terraform plan
```

5. Apply the configuration:
```bash
terraform apply
```

6. Destroy the configuration:
```bash
terraform destroy
```

## Configuration Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `github_runner_token` | GitHub Runner Token | Yes |
| `github_org` | Target GitHub organization Name only | Yes |
| `github_runner_labels` | Labels to assign to runners | No |
| `github_runner_count` | Number of Runners | No |


For more information about variables: `variables.tf`
