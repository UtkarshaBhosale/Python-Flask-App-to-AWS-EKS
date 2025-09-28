# Python-Flask-App-to-AWS-EKS-using-CI-CD

## Project Description

This project demonstrates a complete **CI/CD pipeline** for deploying a Python Flask web service to **Amazon Elastic Kubernetes Service (EKS)** using modern Infrastructure-as-Code and containerization practices.
The goal is to showcase how to build, test, package, and deploy a Flask application in a fully automated manner, leveraging AWS and open-source DevOps tools.

### Key Components

* **Flask Application**: A lightweight Python web service serving a RESTful API.
* **Infrastructure as Code (IaC)**:

  * **Terraform** provisions the entire AWS environment, including:

    * **VPC** with subnets, Internet gateway, and security groups.
    * **EKS Cluster** for Kubernetes workloads.
    * **ECR Repository** for container image storage.
* **Containerization**: A production-ready **Dockerfile** builds the Flask application into a portable container image.
* **CI/CD Pipeline**:

  * **Jenkins** orchestrates build, test, and deployment stages:

    1. **Build & Unit Test** – Install dependencies and run tests.
    2. **Docker Build & Push** – Build the image and push to Amazon ECR.
    3. **Deploy to EKS** – Apply Kubernetes manifests to update the running application.
* **Kubernetes Manifests**: YAML files define the Deployment, Service, and related resources for running the Flask app on EKS.

### Objectives

* Provide a reproducible workflow for deploying containerized Python web apps to AWS.
* Demonstrate end-to-end automation, from infrastructure provisioning to application deployment.
* Serve as a reference architecture for teams adopting cloud-native practices.

---

### Project Structure
├── Dockerfile
├── Jenkinsfile
├── README.md
├── app.py
├── deploy
│   └── deploy.sh
├── images/
├── k8s
│   ├── deployment.yaml
│   └── service.yaml
├── requirements.txt
├── terraform
│   ├── ecr.tf
│   ├── eks.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── variables.tf
│   └── vpc.tf
└── test_app.py

### 🐳 Steps to Deploy an Application on Docker
## Dockerfile:
``` bash
FROM python:3.13-slim AS builder

WORKDIR /app

COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --prefix=/install -r requirements.txt

COPY . .

FROM python:3.13-alpine

RUN apk add --no-cache libgcc libstdc++ musl

WORKDIR /app

COPY --from=builder /install /usr/local
COPY --from=builder /app /app

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]

```
### Local Testing & Validation
## Build the Docker image:
```bash
docker build --no-cache -t utkarsha0601/mern-application/utkarsha-flask-app:27.09 .
```

<img width="1916" height="676" alt="image" src="https://github.com/user-attachments/assets/e9378821-b891-4dfa-9f64-90e17d861233" />

```bash
docker container run -d -p 5000:5000 --name utkarsha-flask-app utkarsha0601/mern-application/utkarsha-flask-app:27.09
```

<img width="1107" height="322" alt="image" src="https://github.com/user-attachments/assets/5b562193-f48b-4957-8f0e-9e1f518add80" />


### 🛠 Terraform Infrastructure Provisioning

Terraform is used to provision AWS infrastructure for the application, including VPC, ECR, and EKS.

Project Directory Structure

coding-assignment-prt/
├── terraform/
│   ├── ecr.tf
│   ├── eks.tf
│   ├── outputs.tf
│   ├── vpc.tf
│   ├── backend.tf
│   ├── providers.tf
│   ├── user-data.sh


Define AWS Provider
File: terraform/providers.tf
```bash
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

Define Variables
File: terraform/variables.tf
```bash
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "utkarsha-eks-cluster"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "ecr_repo_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["utkarsha-app-repo"]
}
```

VPC
File: terraform/vpc.tf

```bash
# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(["ap-south-1a", "ap-south-1b"], count.index)  # Use the corrected AZs
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${element(["a", "b"], count.index)}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

```

<img width="1913" height="411" alt="image" src="https://github.com/user-attachments/assets/e5531bda-7afc-4a84-9cf3-760e0752be1a" />


ECR
File: terraform/ecr.tf

```bash
# Create ECR Repositories
resource "aws_ecr_repository" "repo" {
  for_each             = toset(var.ecr_repo_names)
  name                 = each.key
  image_tag_mutability = "MUTABLE" # Use "IMMUTABLE" for production

  image_scanning_configuration {
    scan_on_push = true # Enable automatic vulnerability scanning on push :cite[4]:cite[6]
  }

  encryption_configuration {
    encryption_type = "AES256" # Server-side encryption
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Optional: Lifecycle Policy to clean up old images
resource "aws_ecr_lifecycle_policy" "repo_policy" {
  for_each   = toset(var.ecr_repo_names)
  repository = aws_ecr_repository.repo[each.key].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }]
  })
}
```

EKS
File: terraform/eks.tf

```bash
# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AmazonEKSClusterPolicy to Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Create EKS Cluster
resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.30" # Specify your desired Kubernetes version

  vpc_config {
    subnet_ids = aws_subnet.public[*].id # Place control plane in private subnets
    # endpoint_private_access = true # Uncomment for private cluster
    # endpoint_public_access  = false # Uncomment for private cluster
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach necessary policies to Node Role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# Create EKS Managed Node Group
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "managed-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  # Ensure the IAM Role permissions are created before and deleted after the Node Group handling
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only_policy,
  ]
}

```


<img width="1919" height="531" alt="image" src="https://github.com/user-attachments/assets/80b6289a-151b-492d-ab18-19436e8319d3" />
<img width="1919" height="774" alt="image" src="https://github.com/user-attachments/assets/eef80f30-6610-474a-90b5-98d88aa0637d" />
<img width="1920" height="1358" alt="image" src="https://github.com/user-attachments/assets/fc0bfba6-72ce-4d31-b80c-4387a16a1e12" />
<img width="1916" height="448" alt="image" src="https://github.com/user-attachments/assets/d6c79972-12d4-47e2-b220-57fca0d3fbe3" />
<img width="1915" height="457" alt="image" src="https://github.com/user-attachments/assets/551a4ea0-ca6c-4447-b92a-024f31053ef9" />







🚀 Deployment Steps
Configure AWS Credentials: Ensure AWS credentials are set in ~/.aws/credentials or as environment variables.

Initialize Terraform

```bash
terraform init
```
<img width="1600" height="474" alt="image" src="https://github.com/user-attachments/assets/5f327ede-6f63-434d-8b12-d88315a50388" />



Format and Validate:
```bash
terraform fmt
terraform validate
```
<img width="1501" height="144" alt="image" src="https://github.com/user-attachments/assets/b61248af-4482-4e1f-9897-0f3811541145" />


Preview Changes:
```bash
terraform plan
```
<img width="1777" height="872" alt="image" src="https://github.com/user-attachments/assets/d9d5c4a3-816b-4306-b756-cb7f616dcef2" />

Apply Configuration:

```bash
terraform apply
```
<img width="1316" height="854" alt="image" src="https://github.com/user-attachments/assets/2b0fc302-1c62-45ed-bba8-818a848583c8" />

Destroy Infrastructure (when needed): You can use destroy

```bash
terraform destroy
```

<img width="1538" height="793" alt="image" src="https://github.com/user-attachments/assets/9bd90bb5-b0d6-4c19-a867-0e8880a9833d" />


☸️ Steps to Deploy an Application on Kubernetes
📄 Create Deployment

File: k8s/deployment.yaml

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-deployment
  namespace: default
  labels:
    app: flask
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flask
  template:
    metadata:
      labels:
        app: flask
    spec:
      containers:
      - name: flask-app
        image: <IMAGE_NAME>
        ports:
        - containerPort: 5000
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5

```

📌 Apply Deployment
```bash
kubectl apply -f k8s/deployment.yaml
```
🔍 Verify Pods

```bash
kubectl get pods
```

📄 Create Service
File: k8s/service.yaml

```bash
apiVersion: v1
kind: Service
metadata:
  name: flask-service
  namespace: default
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 5000
    protocol: TCP
  selector:
    app: flask
```


📌 Apply Service
```bash
kubectl apply -f k8s/service.yaml
```
🔍 Verify Service
```bash
kubectl get svc
```
🚀 Jenkins Pipeline Configuration for Coding assignment Prt
Log in to Jenkins
Click on “New Item”
This is usually located on the left-hand side of the Jenkins dashboard
Enter a name for your job
Example: Coding assignment Prt
Select “Pipeline” as the project type
Click “OK”
This will take you to the configuration page for the new pipeline job
📁 Pipeline Definition
Definition: Pipeline script from SCM
SCM: Git
Repository URL: https://github.com/psagar-dev/coding-assignment-prt.git
Credentials: psagar-dev/******
Branch Specifier: main
Script Path: Jenkinsfile
⚡ Trigger
 GitHub hook trigger for GITScm polling
📝 Notes
This configuration uses a declarative pipeline stored in the main branch under the file Jenkinsfile.
Ensure that the GitHub webhook is properly configured in your GitHub repository settings to trigger Jenkins jobs automatically.

```bash
pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO = '975050024946.dkr.ecr.ap-south-1.amazonaws.com/utkarsha-app-repo'
        IMAGE_TAG = "${BUILD_NUMBER}"
        EKS_CLUSTER_NAME = 'utkarsha-eks-cluster'
        DOCKER_IMAGE = "${ECR_REPO}:${IMAGE_TAG}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo 'Code checked out from Git'
            }
        }

        stage('Build') {
            steps {
                sh 'docker build --no-cache -t flask-app-repo .'
            }
        }

        stage('Push to ECR') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-credentials') {
                    sh """
                    # Authenticate Docker with ECR
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}

                    # Tag the local image with the full ECR repo path
                    docker tag flask-app-repo:latest ${DOCKER_IMAGE}

                    # Push the tagged image to ECR
                    docker push ${DOCKER_IMAGE}
                    """
                    echo '✅ Docker image pushed to ECR'
                }
            }
        }


        stage('Deploy to EKS') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-credentials') {
                    sh """
                    aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
                    sed "s|<IMAGE_NAME>|${DOCKER_IMAGE}|g" k8s/deployment.yaml > k8s/deployment-rendered.yaml

                    # Apply manifests
                    kubectl apply -f k8s/deployment-rendered.yaml
                    kubectl apply -f k8s/service.yaml
                    """
                    echo 'Deployed to EKS'
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully'
        }
        failure {
            echo 'Pipeline failed'
        }
        always {
            sh 'docker system prune -f'
            echo 'Cleaned up Docker resources'
        }
    }
}
```
<img width="1899" height="802" alt="image" src="https://github.com/user-attachments/assets/d14730f6-eedb-4b82-8ea6-4eb0ad6915ef" />



