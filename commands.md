```
cd terraform 
cd eks 
terraform init -upgrade 



// create bucket 

aws s3 mb s3://mybucket98600676575 --region us-east-1

aws s3 mb s3://mybucket98600676575-us-east-1 --region us-east-1

// ecr 

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 535002879962.dkr.ecr.us-east-1.amazonaws.com

docker build -t cloudnautic/atulkamble .

docker tag cloudnautic/atulkamble:latest 535002879962.dkr.ecr.us-east-1.amazonaws.com/cloudnautic/atulkamble:latest

docker push 535002879962.dkr.ecr.us-east-1.amazonaws.com/cloudnautic/atulkamble:latest

// repo URL 

535002879962.dkr.ecr.us-east-1.amazonaws.com/cloudnautic/atulkamble:latest

// scripts - create eks cluster 


chmod +x ./create-cluster.sh
./create-cluster.sh


// jenkins 

plugins - docker, docker pipeline, aws credentials, blue ocean 

tools - myDocker, myMaven 


eksctl get cluster
aws eks list-clusters --region us-east-1
aws sts get-caller-identity

aws eks update-kubeconfig --region us-east-1 --name mycluster

kubectl get nodes

aws eks list-nodegroups --cluster-name m
ycluster --region us-east-1



















```
