```
// clone repo on project folder
//open in vs code 

https://github.com/atulkamble/the-devops-project

// prerequisites 
git, docker or docker desktop, k8s or minikube, aws cli, python, tree

// manually run 

cd app/
python app.py 

http://localhost:5000

// run with docker 

cd ..

sudo docker docker buildx build --platform linux/amd64,linux/arm64 -t docker.io/username/the-devops-project .
or
sudo docker build -t docker.io/username/the-devops-project .

sudo docker run -d -p 5000:5000 docker.io/username/the-devops-project

// run with eks 

// create cluster 

// on mac

eksctl create cluster \
  --name mycluster \
  --region us-east-1 \
  --nodegroup-name mynodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 2 \
  --managed

eksctl delete cluster --name mycluster --region us-east-1

//on windows 

eksctl create cluster --name mycluster --region us-east-1 --nodegroup-name mynodes --node-type t3.medium --nodes 2 --nodes-min 2 --nodes-max 2 --managed

// copy your docker image url to deployment.yaml 

example: docker.io/username/the-devops-project

kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml 

kubectl get all 

kubectl get nodes 
kubectl get services 
kubectl get pods 

kunectl get service  flask-app-service

// copy service url and paste in browser 

load-balancer-url

// on minikube 


minikube start driver=docker
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service-minikube.yaml 

minikube tunnel (keep running)
minikube stop 
minikube delete 

```
