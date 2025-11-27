#!/bin/bash

# DevOps Project Setup Script
# This script sets up the complete infrastructure for the Flask DevOps project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="devops-flask-app"
AWS_REGION="us-west-2"
CLUSTER_NAME="devops-flask-cluster"

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command_exists aws; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check Terraform
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check kubectl
    if ! command_exists kubectl; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    # Check Docker
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS credentials are not configured. Please run 'aws configure'."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Function to create SSH key pair if it doesn't exist
setup_ssh_key() {
    print_status "Setting up SSH key pair..."
    
    if [ ! -f ~/.ssh/id_rsa ]; then
        print_warning "SSH key pair not found. Creating new key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
        print_success "SSH key pair created!"
    else
        print_success "SSH key pair already exists!"
    fi
}

# Function to initialize Terraform S3 backend (optional)
setup_terraform_backend() {
    print_status "Setting up Terraform backend..."
    
    # Create S3 bucket for Terraform state (optional)
    BUCKET_NAME="${PROJECT_NAME}-terraform-state-$(date +%s)"
    
    read -p "Do you want to create S3 bucket for Terraform state? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        aws s3 mb "s3://${BUCKET_NAME}" --region "${AWS_REGION}"
        aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" --versioning-configuration Status=Enabled
        aws s3api put-bucket-encryption --bucket "${BUCKET_NAME}" --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
        
        print_success "S3 bucket created: ${BUCKET_NAME}"
        print_warning "Update the backend configuration in Terraform files with bucket name: ${BUCKET_NAME}"
    fi
}

# Function to deploy Jenkins
deploy_jenkins() {
    print_status "Deploying Jenkins infrastructure..."
    
    cd terraform/jenkins
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -out=jenkins.tfplan
    
    # Apply deployment
    terraform apply jenkins.tfplan
    
    # Get Jenkins IP
    JENKINS_IP=$(terraform output -raw jenkins_public_ip)
    
    print_success "Jenkins deployed successfully!"
    print_status "Jenkins URL: http://${JENKINS_IP}:8080"
    print_status "SSH to Jenkins: ssh -i ~/.ssh/jenkins-key ec2-user@${JENKINS_IP}"
    
    cd ../..
}

# Function to deploy EKS cluster
deploy_eks() {
    print_status "Deploying EKS cluster..."
    
    cd terraform/eks
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -out=eks.tfplan
    
    # Apply deployment (this will take 15-20 minutes)
    print_warning "EKS deployment will take 15-20 minutes..."
    terraform apply eks.tfplan
    
    # Update kubeconfig
    aws eks update-kubeconfig --region "${AWS_REGION}" --name "${CLUSTER_NAME}"
    
    print_success "EKS cluster deployed successfully!"
    
    cd ../..
}

# Function to deploy monitoring
deploy_monitoring() {
    print_status "Deploying monitoring stack..."
    
    cd terraform/monitoring
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -out=monitoring.tfplan
    
    # Apply deployment
    terraform apply monitoring.tfplan
    
    print_success "Monitoring stack deployed successfully!"
    
    cd ../..
}

# Function to build and push initial Docker image
build_and_push_image() {
    print_status "Building and pushing initial Docker image..."
    
    # Get ECR repository URL
    cd terraform/eks
    ECR_REPO=$(terraform output -raw ecr_repository_url)
    cd ../..
    
    # Login to ECR
    aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REPO%/*}"
    
    # Build and push image
    docker build -t "${ECR_REPO}:latest" .
    docker push "${ECR_REPO}:latest"
    
    print_success "Docker image pushed to ECR!"
}

# Function to deploy Flask app to Kubernetes
deploy_flask_app() {
    print_status "Deploying Flask application to Kubernetes..."
    
    # Get ECR repository URL
    cd terraform/eks
    ECR_REPO=$(terraform output -raw ecr_repository_url)
    cd ../..
    
    # Update deployment manifests
    sed -i.bak "s|\${ECR_REPOSITORY_URI}|${ECR_REPO}|g" k8s/flask-app-deployment.yaml
    sed -i.bak "s|\${IMAGE_TAG}|latest|g" k8s/flask-app-deployment.yaml
    
    # Deploy to Kubernetes
    kubectl apply -f k8s/
    
    # Wait for deployment
    kubectl rollout status deployment/flask-app --timeout=300s
    
    print_success "Flask application deployed to Kubernetes!"
}

# Function to display access information
display_access_info() {
    print_success "Deployment completed successfully!"
    echo
    print_status "Access Information:"
    
    # Jenkins info
    cd terraform/jenkins
    JENKINS_IP=$(terraform output -raw jenkins_public_ip 2>/dev/null || echo "Not deployed")
    cd ../..
    
    if [ "$JENKINS_IP" != "Not deployed" ]; then
        echo "Jenkins URL: http://${JENKINS_IP}:8080"
        echo "Jenkins SSH: ssh -i ~/.ssh/jenkins-key ec2-user@${JENKINS_IP}"
        echo "Jenkins Initial Password: ssh -i ~/.ssh/jenkins-key ec2-user@${JENKINS_IP} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
    fi
    
    # Kubernetes info
    echo "Kubernetes Cluster: ${CLUSTER_NAME}"
    echo "Flask App Status: kubectl get pods -l app=flask-app"
    
    # Monitoring info
    GRAFANA_SERVICE=$(kubectl get service -n monitoring | grep grafana | awk '{print $1}' 2>/dev/null || echo "Not found")
    if [ "$GRAFANA_SERVICE" != "Not found" ]; then
        echo "Grafana: kubectl port-forward -n monitoring svc/${GRAFANA_SERVICE} 3000:80"
        echo "Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
    fi
    
    echo
    print_status "Next Steps:"
    echo "1. Configure Jenkins with your GitHub repository"
    echo "2. Set up Jenkins pipeline using the provided Jenkinsfile"
    echo "3. Access Grafana dashboards for monitoring"
    echo "4. Configure DNS for your domain in the ingress"
}

# Main execution
main() {
    echo "======================================"
    echo "DevOps Flask App Infrastructure Setup"
    echo "======================================"
    echo
    
    # Check what to deploy
    echo "Select deployment options:"
    echo "1. Full deployment (Jenkins + EKS + Monitoring + App)"
    echo "2. Jenkins only"
    echo "3. EKS only" 
    echo "4. Monitoring only"
    echo "5. App deployment only"
    
    read -p "Enter your choice (1-5): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            check_prerequisites
            setup_ssh_key
            setup_terraform_backend
            deploy_jenkins
            deploy_eks
            deploy_monitoring
            build_and_push_image
            deploy_flask_app
            display_access_info
            ;;
        2)
            check_prerequisites
            setup_ssh_key
            deploy_jenkins
            ;;
        3)
            check_prerequisites
            setup_ssh_key
            deploy_eks
            ;;
        4)
            check_prerequisites
            deploy_monitoring
            ;;
        5)
            check_prerequisites
            build_and_push_image
            deploy_flask_app
            ;;
        *)
            print_error "Invalid option selected"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"