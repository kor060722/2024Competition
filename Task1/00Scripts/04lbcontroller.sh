#!/bin/bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash # helm install

eksctl utils associate-iam-oidc-provider --cluster skills-cluster --approve # Create a OIDC

curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json # IAM Policy download about AWS Load Balancer Controller

# Create a IAM Polic using the downloaded policy
aws iam create-policy \ 
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
### ### ### ### ### ### ### ### ### ### ### ### ### ###

# Create a Serviceaccount using a created policy
eksctl create iamserviceaccount \
  --cluster=skills-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::073762821266:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 

helm repo add eks https://aws.github.io/eks-charts # Add to Repository about EKS Chart

helm repo update # Update to Local Repository

# Install a Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=skills-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

echo "--------------------------------------------------"
kubectl get deployment -n kube-system aws-load-balancer-controller # Check to install aws-load-balancer-controller
echo "--------------------------------------------------"
