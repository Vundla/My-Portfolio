# Step-by-Step Implementation Guide
## Social Grants Pilot System

### Executive Summary

This comprehensive implementation guide provides detailed, step-by-step instructions for deploying the Social Grants pilot system. It includes commands, code snippets, configuration examples, and troubleshooting procedures for a complete end-to-end deployment.

**Implementation Timeline**: 16-20 weeks  
**Resource Requirements**: 25-30 technical staff  
**Budget Estimate**: R 15-25 million  
**Target Go-Live**: 6 months from project start

## Table of Contents

1. [Pre-Implementation Setup](#1-pre-implementation-setup)
2. [Infrastructure Deployment](#2-infrastructure-deployment)
3. [Database Setup](#3-database-setup)
4. [Application Deployment](#4-application-deployment)
5. [Security Configuration](#5-security-configuration)
6. [Integration Setup](#6-integration-setup)
7. [Testing and Validation](#7-testing-and-validation)
8. [Go-Live Preparation](#8-go-live-preparation)
9. [Post-Implementation](#9-post-implementation)
10. [Troubleshooting Guide](#10-troubleshooting-guide)

## 1. Pre-Implementation Setup

### 1.1 Environment Preparation

#### 1.1.1 Development Environment Setup

**Prerequisites:**
- Ubuntu 20.04 LTS or later
- Docker and Docker Compose
- Node.js 18.x LTS
- PostgreSQL 14+
- Git and SSH access
- Helm 3.x
- kubectl CLI

```bash
#!/bin/bash
# Development Environment Setup Script

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Node.js 18.x LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Docker
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install PostgreSQL client
sudo apt-get install -y postgresql-client

# Install additional tools
sudo apt-get install -y git curl wget unzip jq

echo "Development environment setup complete!"
echo "Please log out and log back in for Docker group changes to take effect."
```

#### 1.1.2 Project Repository Setup

```bash
# Clone the project repository
git clone https://github.com/government/social-grants-pilot.git
cd social-grants-pilot

# Set up development environment
cp .env.example .env.development
cp .env.example .env.staging
cp .env.example .env.production

# Install dependencies
npm install

# Set up Git hooks for development
npm run setup:hooks

# Verify setup
npm run verify:setup
```

#### 1.1.3 Required Accounts and Access

**Cloud Services:**
- AWS/Azure/GCP account with admin access
- Domain registration and DNS management
- SSL certificate provider access
- SMS gateway provider account
- Payment gateway sandbox access

**Development Tools:**
- GitHub/GitLab repository access
- Container registry access
- Monitoring service accounts (DataDog, New Relic)
- Error tracking service (Sentry)

### 1.2 Configuration Management

#### 1.2.1 Environment Variables Template

```bash
# .env.production template
NODE_ENV=production
PORT=3000

# Database Configuration
DB_HOST=social-grants-db-prod.c9xx9xx9xx9x.af-south-1.rds.amazonaws.com
DB_PORT=5432
DB_NAME=social_grants_prod
DB_USER=sg_app_user
DB_PASSWORD=<SECURE_PASSWORD>
DB_SSL=true
DB_POOL_MIN=5
DB_POOL_MAX=30

# Redis Configuration
REDIS_HOST=social-grants-redis-prod.xxx.cache.amazonaws.com
REDIS_PORT=6379
REDIS_PASSWORD=<SECURE_PASSWORD>
REDIS_DB=0

# Security Configuration
JWT_SECRET=<SECURE_JWT_SECRET>
ENCRYPTION_KEY=<AES_256_KEY>
SESSION_SECRET=<SECURE_SESSION_SECRET>
BCRYPT_ROUNDS=12

# Keycloak Configuration
KEYCLOAK_URL=https://auth.socialgrants.gov.za
KEYCLOAK_REALM=social-grants
KEYCLOAK_CLIENT_ID=social-grants-app
KEYCLOAK_CLIENT_SECRET=<KEYCLOAK_CLIENT_SECRET>

# Payment Gateway Configuration
PAYMENT_ENV=production
SASWITCH_API_URL=https://api.saswitch.co.za/v1
SASWITCH_INSTITUTION_ID=<INSTITUTION_ID>
SASWITCH_API_KEY=<API_KEY>
SASWITCH_SECRET_KEY=<SECRET_KEY>

# SMS Gateway Configuration
SMS_PROVIDER=bulksms
SMS_API_URL=https://api.bulksms.com/v1/messages
SMS_USERNAME=<SMS_USERNAME>
SMS_PASSWORD=<SMS_PASSWORD>
SMS_SENDER_ID=SASSA

# Monitoring Configuration
SENTRY_DSN=<SENTRY_DSN>
DATADOG_API_KEY=<DATADOG_API_KEY>
PROMETHEUS_ENABLED=true
METRICS_PORT=9090

# File Storage Configuration
S3_BUCKET=social-grants-documents-prod
S3_REGION=af-south-1
AWS_ACCESS_KEY_ID=<ACCESS_KEY>
AWS_SECRET_ACCESS_KEY=<SECRET_KEY>

# Logging Configuration
LOG_LEVEL=info
LOG_FORMAT=json
LOG_DESTINATION=file
AUDIT_LOG_RETENTION_DAYS=2555 # 7 years for POPIA compliance
```

## 2. Infrastructure Deployment

### 2.1 Terraform Infrastructure Setup

#### 2.1.1 Initialize Terraform

```bash
# Navigate to terraform directory
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Create workspace for environment
terraform workspace new production

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var-file="environments/production.tfvars" -out=production.tfplan

# Review the plan carefully before applying
terraform show production.tfplan
```

#### 2.1.2 Deploy Core Infrastructure

```bash
# Deploy infrastructure
terraform apply production.tfplan

# Save important outputs
terraform output -json > terraform-outputs.json

# Get RDS endpoint
export DB_ENDPOINT=$(terraform output -raw rds_endpoint)

# Get EKS cluster name
export CLUSTER_NAME=$(terraform output -raw eks_cluster_name)

# Get Load Balancer DNS
export LB_DNS=$(terraform output -raw load_balancer_dns)
```

#### 2.1.3 Configure Kubernetes Access

```bash
# Configure kubectl for EKS
aws eks update-kubeconfig --region af-south-1 --name $CLUSTER_NAME

# Verify cluster access
kubectl get nodes

# Install AWS Load Balancer Controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# Create IAM role for service account
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve

# Install AWS Load Balancer Controller via Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 2.2 Kubernetes Cluster Setup

#### 2.2.1 Create Namespaces

```bash
# Create namespaces for different environments
kubectl create namespace social-grants-prod
kubectl create namespace social-grants-staging
kubectl create namespace monitoring
kubectl create namespace ingress-nginx

# Set default namespace
kubectl config set-context --current --namespace=social-grants-prod
```

#### 2.2.2 Install Core Kubernetes Components

```bash
# Install NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.admissionWebhooks.enabled=false

# Install cert-manager for SSL certificates
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

# Create ClusterIssuer for Let's Encrypt
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@socialgrants.gov.za
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## 3. Database Setup

### 3.1 PostgreSQL Configuration

#### 3.1.1 Connect to Database

```bash
# Connect to RDS PostgreSQL instance
psql -h $DB_ENDPOINT -U postgres -d postgres

# Create application database and user
CREATE DATABASE social_grants_prod;
CREATE USER sg_app_user WITH ENCRYPTED PASSWORD '<SECURE_PASSWORD>';
GRANT ALL PRIVILEGES ON DATABASE social_grants_prod TO sg_app_user;

# Create read-only user for reporting
CREATE USER sg_read_user WITH ENCRYPTED PASSWORD '<SECURE_PASSWORD>';
GRANT CONNECT ON DATABASE social_grants_prod TO sg_read_user;
GRANT USAGE ON SCHEMA public TO sg_read_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO sg_read_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO sg_read_user;

# Exit psql
\q
```

#### 3.1.2 Database Schema Creation

```bash
# Run database migrations
cd ../.. # Return to project root
npm run db:migrate:prod

# Verify migration status
npm run db:migrate:status

# Create initial seed data (admin users, grant types, etc.)
npm run db:seed:prod

# Create database indexes for performance
psql -h $DB_ENDPOINT -U sg_app_user -d social_grants_prod -f scripts/create-indexes.sql

# Set up database monitoring
psql -h $DB_ENDPOINT -U sg_app_user -d social_grants_prod -f scripts/monitoring-setup.sql
```

#### 3.1.3 Database Security Configuration

```sql
-- Connect as superuser to configure security
-- Run these commands in psql as postgres user

-- Enable row-level security
ALTER TABLE citizens ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY citizen_policy ON citizens
FOR ALL TO sg_app_user
USING (true); -- Application handles access control

CREATE POLICY application_policy ON applications
FOR ALL TO sg_app_user
USING (true);

CREATE POLICY payment_policy ON payments
FOR ALL TO sg_app_user
USING (true);

-- Configure audit logging
CREATE EXTENSION IF NOT EXISTS pgaudit;
ALTER SYSTEM SET pgaudit.log = 'write, ddl';
ALTER SYSTEM SET pgaudit.log_catalog = off;
ALTER SYSTEM SET pgaudit.log_parameter = on;
SELECT pg_reload_conf();

-- Set up backup configuration
ALTER SYSTEM SET archive_mode = on;
ALTER SYSTEM SET archive_command = 'aws s3 cp %p s3://social-grants-backups/wal/%f';
SELECT pg_reload_conf();
```

### 3.2 Redis Setup

```bash
# Test Redis connection
redis-cli -h $REDIS_HOST -p 6379 -a "<REDIS_PASSWORD>" ping

# Configure Redis for session storage
redis-cli -h $REDIS_HOST -p 6379 -a "<REDIS_PASSWORD>" <<EOF
CONFIG SET maxmemory-policy allkeys-lru
CONFIG SET timeout 300
CONFIG SET save "900 1 300 10 60 10000"
CONFIG REWRITE
EOF
```

## 4. Application Deployment

### 4.1 Container Image Build and Push

#### 4.1.1 Build Docker Images

```bash
# Build application images
docker build -t social-grants-api:latest -f docker/api/Dockerfile .
docker build -t social-grants-web:latest -f docker/web/Dockerfile .
docker build -t social-grants-worker:latest -f docker/worker/Dockerfile .

# Tag images for registry
docker tag social-grants-api:latest $ECR_REGISTRY/social-grants-api:latest
docker tag social-grants-web:latest $ECR_REGISTRY/social-grants-web:latest
docker tag social-grants-worker:latest $ECR_REGISTRY/social-grants-worker:latest

# Push to ECR
aws ecr get-login-password --region af-south-1 | docker login --username AWS --password-stdin $ECR_REGISTRY
docker push $ECR_REGISTRY/social-grants-api:latest
docker push $ECR_REGISTRY/social-grants-web:latest
docker push $ECR_REGISTRY/social-grants-worker:latest
```

#### 4.1.2 Create Kubernetes Secrets

```bash
# Create database connection secret
kubectl create secret generic db-credentials \
  --from-literal=host=$DB_ENDPOINT \
  --from-literal=username=sg_app_user \
  --from-literal=password="<SECURE_PASSWORD>" \
  --from-literal=database=social_grants_prod

# Create Redis connection secret
kubectl create secret generic redis-credentials \
  --from-literal=host=$REDIS_HOST \
  --from-literal=password="<REDIS_PASSWORD>"

# Create JWT secret
kubectl create secret generic jwt-secret \
  --from-literal=secret="<JWT_SECRET>"

# Create payment gateway secrets
kubectl create secret generic payment-secrets \
  --from-literal=saswitch-api-key="<API_KEY>" \
  --from-literal=saswitch-secret-key="<SECRET_KEY>"

# Create SMS gateway secrets
kubectl create secret generic sms-secrets \
  --from-literal=username="<SMS_USERNAME>" \
  --from-literal=password="<SMS_PASSWORD>"
```

### 4.2 Helm Chart Deployment

#### 4.2.1 Deploy Application Components

```bash
# Navigate to Helm charts directory
cd infrastructure/helm

# Update Helm dependencies
helm dependency update socialgrants

# Deploy to production
helm install social-grants-prod socialgrants \
  --namespace social-grants-prod \
  --values values-production.yaml \
  --set image.tag=latest \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=socialgrants.gov.za \
  --set ingress.tls[0].secretName=social-grants-tls \
  --set ingress.tls[0].hosts[0]=socialgrants.gov.za

# Verify deployment
kubectl get pods -n social-grants-prod
kubectl get services -n social-grants-prod
kubectl get ingress -n social-grants-prod
```

#### 4.2.2 Configure Auto-scaling

```bash
# Create Horizontal Pod Autoscaler for API
kubectl autoscale deployment social-grants-api \
  --cpu-percent=70 \
  --min=3 \
  --max=20 \
  -n social-grants-prod

# Create HPA for web frontend
kubectl autoscale deployment social-grants-web \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n social-grants-prod

# Verify autoscalers
kubectl get hpa -n social-grants-prod
```

## 5. Security Configuration

### 5.1 Keycloak Identity Provider Setup

#### 5.1.1 Deploy Keycloak

```bash
# Add Bitnami Helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy Keycloak
helm install keycloak bitnami/keycloak \
  --namespace social-grants-prod \
  --set auth.adminUser=admin \
  --set auth.adminPassword="<SECURE_ADMIN_PASSWORD>" \
  --set postgresql.enabled=false \
  --set externalDatabase.host=$DB_ENDPOINT \
  --set externalDatabase.user=keycloak_user \
  --set externalDatabase.password="<KEYCLOAK_DB_PASSWORD>" \
  --set externalDatabase.database=keycloak \
  --set ingress.enabled=true \
  --set ingress.hostname=auth.socialgrants.gov.za \
  --set ingress.tls=true

# Wait for Keycloak to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=keycloak -n social-grants-prod --timeout=600s
```

#### 5.1.2 Configure Keycloak Realm

```bash
# Get Keycloak admin credentials
export KEYCLOAK_ADMIN_PASSWORD=$(kubectl get secret keycloak -o jsonpath="{.data.admin-password}" | base64 -d)

# Import realm configuration
curl -X POST "https://auth.socialgrants.gov.za/admin/realms" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d @keycloak/social-grants-realm.json

# Create client for application
curl -X POST "https://auth.socialgrants.gov.za/admin/realms/social-grants/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d @keycloak/social-grants-client.json
```

### 5.2 SSL/TLS Configuration

#### 5.2.1 Request SSL Certificates

```bash
# SSL certificates will be automatically requested by cert-manager
# Verify certificate status
kubectl get certificate -n social-grants-prod

# Check certificate details
kubectl describe certificate social-grants-tls -n social-grants-prod

# If certificate is not ready, check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

### 5.3 Network Security

#### 5.3.1 Configure Network Policies

```yaml
# Create network-policies.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: social-grants-network-policy
  namespace: social-grants-prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 5432  # PostgreSQL
    - protocol: TCP
      port: 6379  # Redis
    - protocol: TCP
      port: 443   # HTTPS
    - protocol: TCP
      port: 53    # DNS
    - protocol: UDP
      port: 53    # DNS
```

```bash
# Apply network policies
kubectl apply -f network-policies.yaml
```

## 6. Integration Setup

### 6.1 Payment Gateway Integration

#### 6.1.1 SA Switch Integration Setup

```bash
# Test SA Switch connectivity
curl -X POST "https://sandbox.saswitch.co.za/api/v1/health" \
  -H "X-Institution-Id: $SASWITCH_INSTITUTION_ID" \
  -H "X-API-Key: $SASWITCH_API_KEY"

# Configure payment service
kubectl create configmap payment-config \
  --from-literal=provider=saswitch \
  --from-literal=environment=production \
  --from-literal=api-url=https://api.saswitch.co.za/v1

# Deploy payment service
kubectl apply -f deployments/payment-service.yaml
```

### 6.2 SMS Gateway Integration

#### 6.2.1 BulkSMS Integration

```bash
# Test SMS gateway
curl -X POST "https://api.bulksms.com/v1/messages" \
  -u "$SMS_USERNAME:$SMS_PASSWORD" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "+27123456789",
    "body": "Test message from Social Grants system"
  }'

# Deploy SMS service
kubectl apply -f deployments/sms-service.yaml
```

### 6.3 External System Integrations

#### 6.3.1 Home Affairs Integration

```bash
# Configure Home Affairs integration
kubectl create secret generic home-affairs-credentials \
  --from-literal=api-key="<HOME_AFFAIRS_API_KEY>" \
  --from-literal=certificate="<CLIENT_CERTIFICATE>"

# Deploy integration service
kubectl apply -f deployments/home-affairs-integration.yaml
```

## 7. Testing and Validation

### 7.1 Automated Testing

#### 7.1.1 Run Test Suites

```bash
# Run unit tests
npm run test:unit

# Run integration tests
npm run test:integration

# Run end-to-end tests
npm run test:e2e

# Run security tests
npm run test:security

# Generate test coverage report
npm run test:coverage
```

#### 7.1.2 Performance Testing

```bash
# Install k6 for load testing
sudo apt install k6

# Run API load tests
k6 run tests/load/api-load-test.js

# Run database performance tests
k6 run tests/load/db-performance-test.js

# Run full system load test
k6 run tests/load/system-load-test.js
```

### 7.2 Security Testing

#### 7.2.1 Security Scans

```bash
# Install security scanning tools
npm install -g snyk
npm install -g retire

# Run dependency vulnerability scan
snyk test

# Scan for known vulnerabilities
retire

# Run OWASP ZAP security scan
docker run -v $(pwd):/zap/wrk/:rw \
  -t owasp/zap2docker-stable zap-baseline.py \
  -t https://socialgrants.gov.za \
  -r security-report.html
```

#### 7.2.2 Penetration Testing

```bash
# Run Nmap scan
nmap -sS -O socialgrants.gov.za

# Run SSL Labs test
curl -s "https://api.ssllabs.com/api/v3/analyze?host=socialgrants.gov.za" | jq

# Test for common vulnerabilities
nikto -h https://socialgrants.gov.za
```

### 7.3 Functional Testing

#### 7.3.1 User Acceptance Testing

```bash
# Deploy to staging environment for UAT
helm upgrade social-grants-staging socialgrants \
  --namespace social-grants-staging \
  --values values-staging.yaml

# Create test data
npm run test:create-data

# Run automated UI tests
npm run test:ui

# Generate test report
npm run test:report
```

## 8. Go-Live Preparation

### 8.1 Production Readiness Checklist

#### 8.1.1 System Verification

```bash
#!/bin/bash
# Production readiness check script

echo "=== Production Readiness Check ==="

# Check application health
echo "Checking application health..."
curl -f https://socialgrants.gov.za/health || echo "❌ Application health check failed"

# Check database connectivity
echo "Checking database connectivity..."
kubectl exec -it deployment/social-grants-api -- npm run db:check || echo "❌ Database check failed"

# Check Redis connectivity
echo "Checking Redis connectivity..."
kubectl exec -it deployment/social-grants-api -- npm run redis:check || echo "❌ Redis check failed"

# Check SSL certificate
echo "Checking SSL certificate..."
echo | openssl s_client -servername socialgrants.gov.za -connect socialgrants.gov.za:443 2>/dev/null | openssl x509 -noout -dates

# Check ingress controller
echo "Checking ingress controller..."
kubectl get pods -n ingress-nginx | grep -E "(Running|Ready)" || echo "❌ Ingress controller not ready"

# Check autoscaling
echo "Checking autoscaling configuration..."
kubectl get hpa -n social-grants-prod || echo "❌ HPA not configured"

# Check monitoring
echo "Checking monitoring..."
curl -f https://monitoring.socialgrants.gov.za/health || echo "❌ Monitoring not accessible"

echo "=== Production Readiness Check Complete ==="
```

#### 8.1.2 Backup and Recovery Verification

```bash
# Test database backup
kubectl exec -it deployment/postgres-backup -- pg_dump -h $DB_ENDPOINT -U sg_app_user social_grants_prod > test-backup.sql

# Test backup restoration (on test database)
kubectl exec -it deployment/postgres-backup -- psql -h $TEST_DB_ENDPOINT -U test_user -d test_db < test-backup.sql

# Test disaster recovery
kubectl create namespace disaster-recovery-test
helm install social-grants-dr socialgrants \
  --namespace disaster-recovery-test \
  --values values-disaster-recovery.yaml

# Verify DR deployment
kubectl get pods -n disaster-recovery-test
```

### 8.2 Go-Live Process

#### 8.2.1 Blue-Green Deployment

```bash
# Deploy green environment
helm install social-grants-green socialgrants \
  --namespace social-grants-prod \
  --values values-production.yaml \
  --set image.tag=v1.0.0 \
  --set service.selector.version=green

# Test green environment
curl -H "Host: green.socialgrants.gov.za" https://socialgrants.gov.za/health

# Switch traffic to green (update ingress)
kubectl patch ingress social-grants-ingress -p '{"spec":{"rules":[{"host":"socialgrants.gov.za","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"social-grants-green","port":{"number":80}}}}]}}]}}'

# Monitor for issues
kubectl logs -f deployment/social-grants-green

# If successful, remove blue environment
helm uninstall social-grants-blue
```

#### 8.2.2 DNS Cutover

```bash
# Update DNS records to point to new load balancer
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch '{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "socialgrants.gov.za",
      "Type": "A",
      "AliasTarget": {
        "DNSName": "'$LB_DNS'",
        "EvaluateTargetHealth": true,
        "HostedZoneId": "'$LB_HOSTED_ZONE_ID'"
      }
    }
  }]
}'

# Verify DNS propagation
dig socialgrants.gov.za
nslookup socialgrants.gov.za
```

## 9. Post-Implementation

### 9.1 Monitoring Setup

#### 9.1.1 Deploy Monitoring Stack

```bash
# Add monitoring repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Deploy Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring/prometheus-values.yaml

# Deploy Grafana
helm install grafana grafana/grafana \
  --namespace monitoring \
  --values monitoring/grafana-values.yaml

# Deploy application monitoring
kubectl apply -f monitoring/servicemonitor.yaml
kubectl apply -f monitoring/grafana-dashboards.yaml
```

#### 9.1.2 Configure Alerting

```bash
# Configure Slack alerting
kubectl create secret generic alertmanager-slack \
  --from-literal=webhook-url="$SLACK_WEBHOOK_URL"

# Apply alerting rules
kubectl apply -f monitoring/alert-rules.yaml

# Test alerting
kubectl create job test-alert --image=curlimages/curl -- \
  curl -X POST http://alertmanager:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d @monitoring/test-alert.json
```

### 9.2 Log Management

#### 9.2.1 Deploy Elasticsearch Stack

```bash
# Deploy Elasticsearch
helm install elasticsearch elastic/elasticsearch \
  --namespace monitoring \
  --values monitoring/elasticsearch-values.yaml

# Deploy Kibana
helm install kibana elastic/kibana \
  --namespace monitoring \
  --values monitoring/kibana-values.yaml

# Deploy Filebeat for log collection
kubectl apply -f monitoring/filebeat-daemonset.yaml
```

### 9.3 Backup Configuration

#### 9.3.1 Automated Database Backups

```bash
# Create backup CronJob
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: social-grants-prod
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: postgres-backup
            image: postgres:14
            command:
            - /bin/bash
            - -c
            - |
              pg_dump -h \$DB_HOST -U \$DB_USER -d \$DB_NAME | gzip > /backup/social-grants-\$(date +%Y%m%d-%H%M%S).sql.gz
              aws s3 cp /backup/social-grants-\$(date +%Y%m%d-%H%M%S).sql.gz s3://social-grants-backups/daily/
            env:
            - name: DB_HOST
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: host
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: username
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: password
            - name: DB_NAME
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: database
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: backup-storage
            emptyDir: {}
          restartPolicy: OnFailure
EOF
```

## 10. Troubleshooting Guide

### 10.1 Common Issues and Solutions

#### 10.1.1 Application Won't Start

**Symptoms**: Pods in CrashLoopBackOff state

**Diagnosis**:
```bash
# Check pod status
kubectl get pods -n social-grants-prod

# Check pod logs
kubectl logs <pod-name> -n social-grants-prod

# Describe pod for events
kubectl describe pod <pod-name> -n social-grants-prod
```

**Common Causes and Solutions**:

1. **Database Connection Issues**:
```bash
# Test database connectivity
kubectl exec -it <pod-name> -- psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT 1;"

# Check database credentials
kubectl get secret db-credentials -o yaml
```

2. **Environment Variables Missing**:
```bash
# Check configmap
kubectl get configmap app-config -o yaml

# Check secrets
kubectl get secrets
```

3. **Health Check Failures**:
```bash
# Check health endpoint
kubectl exec -it <pod-name> -- curl localhost:8080/health

# Adjust health check settings
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","livenessProbe":{"initialDelaySeconds":60}}]}}}}'
```

#### 10.1.2 Database Performance Issues

**Symptoms**: Slow response times, high CPU usage

**Diagnosis**:
```bash
# Check database metrics
kubectl exec -it deployment/social-grants-api -- npm run db:metrics

# Check slow queries
psql -h $DB_ENDPOINT -U sg_app_user -d social_grants_prod -c "
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;"
```

**Solutions**:
```bash
# Add missing indexes
psql -h $DB_ENDPOINT -U sg_app_user -d social_grants_prod -f scripts/performance-indexes.sql

# Update table statistics
psql -h $DB_ENDPOINT -U sg_app_user -d social_grants_prod -c "ANALYZE;"

# Scale up RDS instance if needed
aws rds modify-db-instance --db-instance-identifier social-grants-prod --db-instance-class db.r5.xlarge --apply-immediately
```

#### 10.1.3 SSL Certificate Issues

**Symptoms**: SSL warnings, certificate errors

**Diagnosis**:
```bash
# Check certificate status
kubectl get certificate -n social-grants-prod

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Test SSL
openssl s_client -servername socialgrants.gov.za -connect socialgrants.gov.za:443
```

**Solutions**:
```bash
# Delete and recreate certificate
kubectl delete certificate social-grants-tls -n social-grants-prod
kubectl apply -f ssl/certificate.yaml

# Check DNS settings
dig _acme-challenge.socialgrants.gov.za TXT
```

#### 10.1.4 High Traffic Issues

**Symptoms**: Slow response times, 503 errors

**Diagnosis**:
```bash
# Check pod CPU and memory usage
kubectl top pods -n social-grants-prod

# Check HPA status
kubectl get hpa -n social-grants-prod

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

**Solutions**:
```bash
# Scale horizontally
kubectl scale deployment social-grants-api --replicas=10 -n social-grants-prod

# Adjust HPA settings
kubectl patch hpa social-grants-api -p '{"spec":{"maxReplicas":50}}'

# Scale vertically
kubectl patch deployment social-grants-api -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","resources":{"requests":{"cpu":"500m","memory":"1Gi"}}}]}}}}'
```

### 10.2 Emergency Procedures

#### 10.2.1 Emergency Rollback

```bash
#!/bin/bash
# Emergency rollback script

echo "=== EMERGENCY ROLLBACK INITIATED ==="

# Get current deployment
CURRENT_REVISION=$(kubectl rollout history deployment/social-grants-api -n social-grants-prod | tail -n 1 | awk '{print $1}')
echo "Current revision: $CURRENT_REVISION"

# Rollback to previous version
kubectl rollout undo deployment/social-grants-api -n social-grants-prod
kubectl rollout undo deployment/social-grants-web -n social-grants-prod
kubectl rollout undo deployment/social-grants-worker -n social-grants-prod

# Wait for rollback to complete
kubectl rollout status deployment/social-grants-api -n social-grants-prod --timeout=600s
kubectl rollout status deployment/social-grants-web -n social-grants-prod --timeout=600s
kubectl rollout status deployment/social-grants-worker -n social-grants-prod --timeout=600s

# Verify health
kubectl get pods -n social-grants-prod
curl -f https://socialgrants.gov.za/health

echo "=== ROLLBACK COMPLETE ==="
```

#### 10.2.2 Database Recovery

```bash
#!/bin/bash
# Database recovery script

echo "=== DATABASE RECOVERY INITIATED ==="

# Stop application to prevent data corruption
kubectl scale deployment social-grants-api --replicas=0 -n social-grants-prod
kubectl scale deployment social-grants-worker --replicas=0 -n social-grants-prod

# Get latest backup
LATEST_BACKUP=$(aws s3 ls s3://social-grants-backups/daily/ --recursive | sort | tail -n 1 | awk '{print $4}')
echo "Latest backup: $LATEST_BACKUP"

# Download backup
aws s3 cp s3://social-grants-backups/$LATEST_BACKUP /tmp/recovery.sql.gz

# Restore database (after creating backup of current state)
pg_dump -h $DB_ENDPOINT -U sg_app_user social_grants_prod > /tmp/current-state-backup.sql
gunzip -c /tmp/recovery.sql.gz | psql -h $DB_ENDPOINT -U sg_app_user social_grants_prod

# Restart applications
kubectl scale deployment social-grants-api --replicas=3 -n social-grants-prod
kubectl scale deployment social-grants-worker --replicas=2 -n social-grants-prod

echo "=== DATABASE RECOVERY COMPLETE ==="
```

### 10.3 Performance Optimization

#### 10.3.1 Database Optimization

```sql
-- Performance optimization queries
-- Run these during maintenance windows

-- Update statistics
ANALYZE;

-- Reindex if needed
REINDEX DATABASE social_grants_prod;

-- Check for missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation 
FROM pg_stats 
WHERE tablename IN ('citizens', 'applications', 'payments')
ORDER BY n_distinct DESC;

-- Vacuum to reclaim space
VACUUM FULL;
```

#### 10.3.2 Application Optimization

```bash
# Enable connection pooling
kubectl patch deployment social-grants-api -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","env":[{"name":"DB_POOL_SIZE","value":"20"}]}]}}}}'

# Enable caching
kubectl patch deployment social-grants-api -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","env":[{"name":"REDIS_CACHE_TTL","value":"3600"}]}]}}}}'

# Optimize memory settings
kubectl patch deployment social-grants-api -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","env":[{"name":"NODE_OPTIONS","value":"--max-old-space-size=2048"}]}]}}}}'
```

---

## Implementation Support

For additional support during implementation:

**Technical Support**: tech-support@socialgrants.gov.za  
**Emergency Hotline**: +27-11-xxx-xxxx  
**Documentation**: https://docs.socialgrants.gov.za  

**Escalation Path**:
1. Team Lead (Response: 2 hours)
2. Technical Manager (Response: 4 hours)
3. Project Manager (Response: 8 hours)
4. Program Director (Response: 24 hours)

This implementation guide provides comprehensive instructions for deploying the Social Grants pilot system. Follow each section carefully and ensure all tests pass before proceeding to the next phase.