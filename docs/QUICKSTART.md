# Flask App - Quick Start Guide

This guide will help you get the Flask application running locally and understand the complete DevOps pipeline.

## Prerequisites

- Python 3.11+
- Docker
- AWS CLI configured
- Terraform >= 1.5
- kubectl
- Git

## Local Development

### 1. Clone and Setup
```bash
git clone <your-repo-url>
cd the-devops-project
```

### 2. Run Flask App Locally
```bash
cd app
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

Visit: http://localhost:5000

### 3. Run with Docker
```bash
docker build -t flask-app .
docker run -p 5000:5000 flask-app
```

## Infrastructure Deployment

### Option 1: Automated Setup
```bash
./scripts/deploy.sh
```

### Option 2: Manual Setup

#### 1. Deploy Jenkins
```bash
cd terraform/jenkins
terraform init
terraform plan
terraform apply
```

#### 2. Deploy EKS Cluster
```bash
cd terraform/eks  
terraform init
terraform plan
terraform apply

# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name devops-flask-cluster
```

#### 3. Deploy Monitoring
```bash
cd terraform/monitoring
terraform init  
terraform plan
terraform apply
```

#### 4. Build and Deploy App
```bash
# Get ECR repo URL from Terraform output
ECR_REPO=$(cd terraform/eks && terraform output -raw ecr_repository_url)

# Build and push image
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${ECR_REPO%/*}
docker build -t ${ECR_REPO}:latest .
docker push ${ECR_REPO}:latest

# Deploy to Kubernetes
sed -i "s|\${ECR_REPOSITORY_URI}|${ECR_REPO}|g" k8s/flask-app-deployment.yaml
sed -i "s|\${IMAGE_TAG}|latest|g" k8s/flask-app-deployment.yaml
kubectl apply -f k8s/
```

## CI/CD Pipeline

### Jenkins Setup

1. **Access Jenkins:**
   ```bash
   # Get Jenkins IP
   JENKINS_IP=$(cd terraform/jenkins && terraform output -raw jenkins_public_ip)
   
   # Get initial password
   ssh -i ~/.ssh/jenkins-key ec2-user@${JENKINS_IP} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
   
   # Open in browser
   open http://${JENKINS_IP}:8080
   ```

2. **Configure Pipeline:**
   - Create new Pipeline job
   - Point to your Git repository
   - Use `jenkins/Jenkinsfile`
   - Configure webhooks for automatic builds

### GitHub Actions (Alternative)

The project includes GitHub Actions workflows in `.github/workflows/ci-cd.yml`:

1. **Setup Secrets:**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

2. **Push to trigger pipeline:**
   ```bash
   git push origin main
   ```

## Monitoring

### Access Grafana
```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
```
- URL: http://localhost:3000
- Username: admin
- Password: admin123

### Access Prometheus
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
- URL: http://localhost:9090

### Key Metrics

- **Application Metrics:** `/metrics` endpoint
- **Kubernetes Metrics:** Node Exporter, cAdvisor
- **Custom Dashboards:** Flask app performance, task statistics

## Testing the Application

### Health Checks
```bash
# Local
curl http://localhost:5000/health

# Kubernetes  
kubectl port-forward svc/flask-app-service 8080:80
curl http://localhost:8080/health
```

### Load Testing
```bash
# Install wrk (macOS)
brew install wrk

# Run load test
wrk -t12 -c400 -d30s http://localhost:5000/
```

## Troubleshooting

### Common Issues

1. **EKS Cluster Access:**
   ```bash
   aws eks update-kubeconfig --region us-west-2 --name devops-flask-cluster
   ```

2. **ECR Authentication:**
   ```bash
   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com
   ```

3. **Jenkins SSH Access:**
   ```bash
   # Make sure you have the right key
   ssh -i ~/.ssh/jenkins-key ec2-user@<jenkins-ip>
   ```

### Logs

```bash
# Application logs
kubectl logs -l app=flask-app -f

# Jenkins logs
ssh -i ~/.ssh/jenkins-key ec2-user@<jenkins-ip>
sudo journalctl -u jenkins -f

# EKS cluster events
kubectl get events --sort-by='.lastTimestamp'
```

## Cleanup

```bash
# Destroy infrastructure
cd terraform/monitoring && terraform destroy
cd terraform/eks && terraform destroy  
cd terraform/jenkins && terraform destroy

# Clean up Docker images
docker system prune -a
```

## Security Considerations

- Change default passwords (Grafana, Jenkins)
- Restrict security group access
- Use IAM roles instead of access keys when possible
- Enable CloudTrail for audit logging
- Regular security scans with Trivy/Snyk

## Cost Optimization

- Use Spot instances for non-production
- Implement cluster autoscaler
- Set up resource quotas and limits
- Monitor costs with AWS Cost Explorer