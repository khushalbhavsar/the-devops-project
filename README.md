# DevOps Project - Flask App with Complete CI/CD Pipeline

This project demonstrates a complete DevOps pipeline with:
- Python Flask web application with UI
- Docker containerization
- AWS ECR for container registry
- Amazon EKS deployment using Terraform
- Jenkins CI/CD pipeline using Terraform
- Monitoring with Grafana & Prometheus
- Kubernetes YAML templates

## Project Structure

```
the-devops-project/
├── app/                    # Flask application
├── docker/                 # Docker configurations
├── k8s/                    # Kubernetes YAML templates
├── terraform/              # Infrastructure as Code
│   ├── eks/               # EKS cluster
│   ├── jenkins/           # Jenkins setup
│   └── monitoring/        # Grafana & Prometheus
├── jenkins/               # Jenkins pipeline configurations
└── monitoring/            # Monitoring configurations
```

## Quick Start

1. **Setup Infrastructure**: Deploy EKS, Jenkins, and monitoring with Terraform
2. **Build & Deploy**: Use Jenkins pipeline to build and deploy the Flask app
3. **Monitor**: Access Grafana dashboards for application and infrastructure monitoring

## Prerequisites

- AWS CLI configured
- Terraform installed
- Docker installed
- kubectl configured

## Deployment Steps

See individual README files in each directory for detailed instructions.