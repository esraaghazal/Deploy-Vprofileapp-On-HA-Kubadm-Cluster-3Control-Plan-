#  High Availability Kubernetes Cluster on AWS

## Overview
This project demonstrates building a **Highly Available Kubernetes cluster** on **AWS** using **Terraform**, **kubeadm**, and **HAProxy**. The infrastructure is provisioned with Terraform, the Kubernetes control plane is manually bootstrapped, and a containerized **3-tier VProfile application** is deployed.

### Architecture
- 1 HAProxy Load Balancer
- 3 Kubernetes Control Plane nodes
- 2 Kubernetes Worker nodes
- Calico CNI
- containerd runtime
- Amazon Linux 2023
  
  <img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/f9b6f3d5-dcd3-469d-99c7-cbec816f2781" />


HAProxy exposes a single Kubernetes API endpoint and distributes requests across all control plane nodes.

## Technology Stack
- AWS (EC2, VPC, IGW, Security Groups)
- Terraform
- Kubernetes (kubeadm, kubelet, kubectl)
- HAProxy
- Docker
- Docker Hub
- Calico CNI
- Apache Tomcat
- MySQL
- RabbitMQ
- Memcached

## Infrastructure Provisioning
Terraform provisions:
- VPC
- Public Subnet
- Internet Gateway
- Route Table
- Security Group
- HAProxy instance
- 3 Control Plane instances
- 2 Worker instances

Typical workflow:
```bash
terraform init
terraform validate
terraform plan
terraform apply
```

## Building the HA Kubernetes Cluster

### 1. Configure HAProxy
- Install HAProxy
- Configure frontend on port **6443**
- Add all three control plane nodes as backend servers
- Enable and start the HAProxy service

### 2. Prepare All Nodes
- Update the OS
- Disable swap
- Enable kernel modules and sysctl settings
- Install containerd
- Install kubeadm, kubelet and kubectl

### 3. Initialize the Cluster
Initialize **Master-1** using the HAProxy endpoint:
```bash
kubeadm init --control-plane-endpoint "<HAPROXY-IP>:6443" --upload-certs
```

### 4. Install Calico
```bash
kubectl apply -f calico.yaml
```

### 5. Join Additional Control Planes
Use the generated join command with:
- `--control-plane`
- `--certificate-key`

### 6. Join Worker Nodes
Run the standard `kubeadm join` command on both workers.

### 7. Verify
```bash
kubectl get nodes
kubectl get pods -A
```

## Dockerizing the Application

The VProfile application consists of:
- Apache Tomcat
- MySQL
- RabbitMQ
- Memcached

Each component is containerized independently.

### Build Images
```bash
docker build -t vprofile-app .
docker build -t vprofile-db .
docker build -t vprofile-rabbitmq .
docker build -t vprofile-memcached .
```

### Docker Security Best Practices
- Use minimal base images
- Use multi-stage builds
- Run containers as a non-root user
- Reduce image layers
- Pin image versions
- Remove unnecessary packages
- Use `.dockerignore`
- Avoid embedding secrets
- Scan images before deployment

### Multi-Stage Build
The application image uses a multi-stage Dockerfile:
1. Build the Java application.
2. Copy only the final artifact into the runtime image.
3. Produce a smaller and more secure image.

### Push Images
```bash
docker tag IMAGE <dockerhub-user>/IMAGE:latest
docker push <dockerhub-user>/IMAGE:latest
```

## Deploying the 3-Tier Application

Deploy in the following order:
1. MySQL
2. RabbitMQ
3. Memcached
4. Tomcat


Resources used:
- Namespace
- Deployment
- Service
- ConfigMap (if required)
- Secret (if required)
- PersistentVolume / PVC (if required)

Verify:
```bash
kubectl get deployments
kubectl get pods
kubectl get svc
```
<img width="951" height="340" alt="image" src="https://github.com/user-attachments/assets/7af60d63-7ffd-40f9-a301-a3177c042a25" />



## Deployment YAML Overview

### Namespace
Provides logical isolation.

### Deployment
- Replica management
- Rolling updates
- Self-healing
- Pod template

### Service
Provides stable networking and service discovery.

### ConfigMap
Stores non-sensitive configuration.

### Secret
Stores sensitive values such as credentials.

### Persistent Volume
Persists database data across pod restarts.

## High Availability Validation

After deployment:
1. Stop one control plane node.
2. Access the cluster through HAProxy.
3. Verify:
```bash
kubectl get nodes
kubectl get pods -A
```
<img width="1220" height="587" alt="Screenshot 2026-07-15 142336" src="https://github.com/user-attachments/assets/7b579315-59e7-4e43-9bc2-05325e260920" />


The Kubernetes API remains available through the remaining control plane nodes, demonstrating control plane high availability.

## Repository Structure

```text
terraform/
docker/
kubernetes/
screenshots/
README.md
```

## Troubleshooting
- Invalid AMI ID → Verify the AMI exists in the selected region.
- InvalidKeyPair → Ensure the EC2 Key Pair exists in AWS.
- Nodes NotReady → Check kubelet, containerd and Calico.
- API unreachable → Verify HAProxy backend configuration and health checks.

## Key Learnings
- Infrastructure as Code with Terraform
- Manual Kubernetes cluster bootstrapping
- HAProxy-based API load balancing
- Docker image optimization
- Secure containerization
- Kubernetes workload deployment
- High Availability validation
