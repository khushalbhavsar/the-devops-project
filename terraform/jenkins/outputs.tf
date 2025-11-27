# Flask App Outputs
output "app_url" {
  description = "URL to access the Flask application"
  value = "http://${aws_eip.jenkins.public_ip}:8080"
}

output "ecr_repository_url" {
  description = "ECR repository URL for the Flask app"
  value = aws_ecr_repository.flask_app.repository_url
}

output "jenkins_public_ip" {
  description = "Public IP address of Jenkins server"
  value = aws_eip.jenkins.public_ip
}

output "jenkins_initial_password_command" {
  description = "Command to retrieve Jenkins initial admin password"
  value = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_eip.jenkins.public_ip} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
}