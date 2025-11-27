# Flask App - DevOps Pipeline Architecture

## Overview

This project demonstrates a complete DevOps pipeline for a Python Flask web application with the following components:

## Architecture Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │   GitHub/Git    │    │     Jenkins     │
│                 │───▶│   Repository    │───▶│   CI/CD Server  │
│  Local Dev      │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      ECR        │◀───│     Build       │    │   Kubernetes    │
│ Container Reg   │    │   & Test        │───▶│   EKS Cluster   │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                        ┌─────────────────┐    ┌─────────────────┐
                        │   Prometheus    │◀───│   Flask App     │
                        │   Monitoring    │    │   Pods          │
                        │                 │    │                 │
                        └─────────────────┘    └─────────────────┘
                                 │                       │
                                 ▼                       ▼
                        ┌─────────────────┐    ┌─────────────────┐
                        │    Grafana      │    │  Load Balancer  │
                        │   Dashboards    │    │   & Ingress     │
                        │                 │    │                 │
                        └─────────────────┘    └─────────────────┘
```

## Components

### 1. Flask Application
- **Technology:** Python 3.11 + Flask
- **Features:**
  - REST API endpoints
  - Task management system
  - Health checks
  - Prometheus metrics
  - Bootstrap UI
- **Container:** Multi-stage Docker build
- **Security:** Non-root user, minimal base image

### 2. Infrastructure (Terraform)

#### EKS Cluster
- **Kubernetes Version:** 1.28
- **Node Groups:** Auto-scaling (2-10 nodes)
- **Instance Types:** t3.medium
- **Networking:** VPC with public/private subnets
- **Security:** Security groups, IAM roles

#### Jenkins Server
- **Instance:** EC2 t3.medium
- **Features:**
  - Docker support
  - AWS CLI, kubectl, Terraform
  - Pipeline as Code (Jenkinsfile)
  - ECR integration
- **Storage:** 50GB EBS volume
- **Security:** Security group, IAM role

#### Container Registry
- **Service:** Amazon ECR
- **Features:**
  - Image scanning
  - Lifecycle policies
  - IAM-based access control

### 3. CI/CD Pipeline

#### Jenkins Pipeline Stages
1. **Checkout:** Pull code from Git
2. **Build:** Install dependencies, create virtual environment
3. **Test:** Run unit tests, linting, security scans
4. **Docker Build:** Create container image
5. **Push to ECR:** Upload to container registry
6. **Deploy to K8s:** Update Kubernetes manifests
7. **Smoke Tests:** Verify deployment health

#### GitHub Actions (Alternative)
- Parallel test execution
- Security scanning (Trivy)
- Multi-environment deployments
- Artifact management

### 4. Kubernetes Deployment

#### Application Resources
- **Deployment:** 3 replicas with rolling updates
- **Service:** ClusterIP for internal communication
- **Ingress:** NGINX for external access
- **HPA:** Auto-scaling based on CPU/memory
- **PDB:** Pod disruption budget for availability

#### Configuration
- **ConfigMaps:** Application configuration
- **Secrets:** Sensitive data management
- **ServiceAccount:** RBAC permissions
- **NetworkPolicies:** Traffic restrictions

### 5. Monitoring Stack

#### Prometheus
- **Metrics Collection:** Application and infrastructure
- **Storage:** 50GB persistent volume
- **Retention:** 30 days
- **Alerting:** Custom rules and thresholds

#### Grafana
- **Dashboards:** Pre-built and custom
- **Data Sources:** Prometheus integration
- **Alerting:** Notification channels
- **Authentication:** Admin user setup

#### Key Metrics
- HTTP request rates and latency
- Application performance (task counts)
- Kubernetes cluster health
- Infrastructure utilization

## Security Features

### Container Security
- Multi-stage builds for minimal attack surface
- Non-root user execution
- Read-only root filesystem where possible
- Security scanning with Trivy

### Infrastructure Security
- IAM roles with least privilege
- Security groups with minimal access
- Encryption at rest and in transit
- VPC isolation

### Application Security
- Input validation
- Security headers
- Dependencies scanning (Safety, Bandit)
- Regular updates

## High Availability & Scalability

### Application Level
- Multiple replicas with anti-affinity rules
- Health checks and automatic restarts
- Horizontal Pod Autoscaler
- Rolling updates with zero downtime

### Infrastructure Level
- Multi-AZ deployment
- Auto Scaling Groups
- Load balancing
- Pod Disruption Budgets

## Cost Optimization

### Resource Management
- Resource requests and limits
- Cluster autoscaler
- Spot instances for non-critical workloads
- Efficient container images

### Monitoring
- Cost tracking with resource tags
- Rightsizing recommendations
- Unused resource identification

## Development Workflow

1. **Local Development:** Docker Compose for local testing
2. **Feature Branch:** Create branch for new features
3. **Pull Request:** Code review and automated tests
4. **CI Pipeline:** Automated testing and security scans
5. **Deployment:** Automatic deployment to staging/production
6. **Monitoring:** Real-time metrics and alerting

## Backup & Disaster Recovery

### Data Backup
- EBS snapshots for persistent volumes
- ECR image replication
- Configuration backup to S3

### Disaster Recovery
- Multi-region capability
- Infrastructure as Code for quick recovery
- Automated backup testing

## Future Enhancements

### Planned Improvements
- Service mesh (Istio) for advanced traffic management
- GitOps with ArgoCD
- Advanced security scanning (Falco)
- Multi-environment management
- Blue/Green deployments
- Chaos engineering tests

### Scalability Improvements
- Microservices architecture
- Event-driven communication
- Distributed tracing
- Advanced caching strategies