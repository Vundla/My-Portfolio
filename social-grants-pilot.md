# Social Grants Digital Pilot - Technical Blueprint
## South Africa Government Digital Transformation Initiative

### Executive Summary

This document outlines a comprehensive technical blueprint for implementing a Social Grants digital pilot system in South Africa, targeting one province for a 6-month pilot program. The solution addresses the needs of citizens, caseworkers, and Digital Transformation Office (DTO) personnel while ensuring POPIA compliance, accessibility, and robust security.

### Target Province: Gauteng
**Pilot Duration:** 6 months  
**Target Users:** 50,000+ citizens, 200+ caseworkers, 50+ DTO staff

---

## 1. API Endpoints Architecture

### Core API Structure
```
Base URL: https://api.socialgrants.gov.za/v1/
```

#### Authentication Endpoints
```
POST /auth/login
POST /auth/logout  
POST /auth/refresh
POST /auth/verify-otp
GET  /auth/me
```

#### Citizen Services
```
GET    /citizens/profile
PUT    /citizens/profile
POST   /citizens/applications
GET    /citizens/applications
GET    /citizens/applications/{id}
PUT    /citizens/applications/{id}/status
POST   /citizens/documents/upload
GET    /citizens/payments/history
GET    /citizens/eligibility/check
```

#### Caseworker Operations
```
GET    /casework/queue
GET    /casework/applications/{id}
PUT    /casework/applications/{id}/review
POST   /casework/applications/{id}/approve
POST   /casework/applications/{id}/reject
GET    /casework/statistics
POST   /casework/notes
```

#### Administrative Functions
```
GET    /admin/users
POST   /admin/users
PUT    /admin/users/{id}
DELETE /admin/users/{id}
GET    /admin/reports
GET    /admin/audit-logs
POST   /admin/bulk-import
```

#### Payment Integration
```
POST   /payments/initiate
GET    /payments/status/{id}
POST   /payments/callback
GET    /payments/reconciliation
```

---

## 2. Database Schema with Encryption

### Core Tables

#### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    identity_number VARCHAR(13) ENCRYPTED,
    first_name VARCHAR(100) ENCRYPTED,
    last_name VARCHAR(100) ENCRYPTED,
    email VARCHAR(255) ENCRYPTED,
    phone_number VARCHAR(20) ENCRYPTED,
    address TEXT ENCRYPTED,
    role ENUM('citizen', 'caseworker', 'admin', 'dto'),
    status ENUM('active', 'inactive', 'suspended'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    keycloak_user_id VARCHAR(255) UNIQUE
);
```

#### Applications Table
```sql
CREATE TABLE applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    application_type ENUM('child_support', 'disability', 'old_age', 'care_dependency'),
    status ENUM('draft', 'submitted', 'under_review', 'approved', 'rejected', 'paid'),
    application_data JSONB ENCRYPTED,
    submitted_at TIMESTAMP,
    reviewed_at TIMESTAMP,
    reviewed_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    rejection_reason TEXT ENCRYPTED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Documents Table
```sql
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID REFERENCES applications(id),
    document_type VARCHAR(50),
    file_name VARCHAR(255) ENCRYPTED,
    file_path TEXT ENCRYPTED,
    file_size INTEGER,
    mime_type VARCHAR(100),
    checksum VARCHAR(64),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    virus_scan_status ENUM('pending', 'clean', 'infected'),
    verification_status ENUM('pending', 'verified', 'rejected')
);
```

#### Payments Table
```sql
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID REFERENCES applications(id),
    amount DECIMAL(10,2),
    payment_method VARCHAR(50),
    transaction_id VARCHAR(100) ENCRYPTED,
    status ENUM('pending', 'processing', 'completed', 'failed', 'reversed'),
    payment_date TIMESTAMP,
    bank_account VARCHAR(50) ENCRYPTED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Audit Logs Table
```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100),
    resource_type VARCHAR(50),
    resource_id UUID,
    ip_address INET,
    user_agent TEXT,
    request_data JSONB,
    response_data JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id VARCHAR(255)
);
```

### Encryption Strategy
- **Column-level encryption** for PII using AES-256
- **Transparent Data Encryption (TDE)** at database level
- **Key rotation** every 90 days
- **Hardware Security Module (HSM)** for key management

---

## 3. Keycloak OIDC Setup

### Configuration
```yaml
keycloak:
  realm: social-grants-za
  auth-server-url: https://auth.socialgrants.gov.za/auth
  resource: social-grants-client
  public-client: false
  ssl-required: external
  credentials:
    secret: ${KEYCLOAK_CLIENT_SECRET}
```

### Realm Configuration
```json
{
  "realm": "social-grants-za",
  "enabled": true,
  "sslRequired": "external",
  "registrationAllowed": false,
  "loginWithEmailAllowed": true,
  "bruteForceProtected": true,
  "permanentLockout": false,
  "maxFailureWaitSeconds": 900,
  "minimumQuickLoginWaitSeconds": 60,
  "waitIncrementSeconds": 60,
  "quickLoginCheckMilliSeconds": 1000,
  "maxDeltaTimeSeconds": 43200,
  "failureFactor": 30
}
```

### Client Roles
- **citizen**: Basic user access
- **caseworker**: Application review and processing
- **supervisor**: Team oversight and reporting
- **admin**: System administration
- **dto**: Strategic oversight and analytics

---

## 4. Terraform Infrastructure Skeleton

### Main Infrastructure
```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "social_grants" {
  name     = "rg-socialgrants-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "SocialGrants"
    Ministry    = "SASSA"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-socialgrants-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.social_grants.location
  resource_group_name = azurerm_resource_group.social_grants.name

  tags = local.common_tags
}

# Application Gateway Subnet
resource "azurerm_subnet" "app_gateway" {
  name                 = "subnet-appgateway"
  resource_group_name  = azurerm_resource_group.social_grants.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Application Subnet
resource "azurerm_subnet" "app" {
  name                 = "subnet-app"
  resource_group_name  = azurerm_resource_group.social_grants.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Database Subnet
resource "azurerm_subnet" "database" {
  name                 = "subnet-database"
  resource_group_name  = azurerm_resource_group.social_grants.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]

  service_endpoints = ["Microsoft.Sql"]
}
```

### Database Infrastructure
```hcl
# database.tf
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-socialgrants-${var.environment}"
  resource_group_name    = azurerm_resource_group.social_grants.name
  location               = azurerm_resource_group.social_grants.location
  version                = "14"
  delegated_subnet_id    = azurerm_subnet.database.id
  private_dns_zone_id    = azurerm_private_dns_zone.database.id
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  zone                   = "1"

  storage_mb = 32768
  sku_name   = "GP_Standard_D2s_v3"

  backup_retention_days        = 35
  geo_redundant_backup_enabled = true

  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  tags = local.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "social_grants" {
  name      = "socialgrants"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
```

### Container Apps
```hcl
# container-apps.tf
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-socialgrants-${var.environment}"
  location                   = azurerm_resource_group.social_grants.location
  resource_group_name        = azurerm_resource_group.social_grants.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = local.common_tags
}

resource "azurerm_container_app" "api" {
  name                         = "ca-api-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.social_grants.name
  revision_mode                = "Single"

  template {
    container {
      name   = "api"
      image  = "socialgrants.azurecr.io/api:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_admin_username}:${var.db_admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/socialgrants"
      }

      env {
        name        = "JWT_SECRET"
        secret_name = "jwt-secret"
      }
    }

    min_replicas = 2
    max_replicas = 10
  }

  secret {
    name  = "jwt-secret"
    value = var.jwt_secret
  }

  ingress {
    external_enabled = true
    target_port      = 8080

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = local.common_tags
}
```

---

## 5. CI/CD Pipeline Configuration

### GitHub Actions Workflow
```yaml
# .github/workflows/deploy.yml
name: Deploy Social Grants Application

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  AZURE_CONTAINER_REGISTRY: socialgrants.azurecr.io
  RESOURCE_GROUP: rg-socialgrants-prod
  
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run tests
        run: npm test
        
      - name: Run security scan
        run: npm audit
        
      - name: OWASP ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.7.0
        with:
          target: 'http://localhost:3000'

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
          
      - name: Build and push Docker image
        run: |
          az acr build --registry $AZURE_CONTAINER_REGISTRY \
                       --image api:${{ github.sha }} \
                       --image api:latest \
                       .
                       
  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
          
      - name: Deploy to Container Apps
        run: |
          az containerapp update \
            --name ca-api-prod \
            --resource-group $RESOURCE_GROUP \
            --image $AZURE_CONTAINER_REGISTRY/api:${{ github.sha }}
            
      - name: Run smoke tests
        run: |
          curl -f https://api.socialgrants.gov.za/health || exit 1
```

---

## 6. Monitoring and Dashboards

### Application Insights Configuration
```json
{
  "ApplicationInsights": {
    "ConnectionString": "InstrumentationKey=...",
    "EnableAdaptiveSampling": true,
    "EnableQuickPulseMetricStream": true,
    "EnableDependencyTrackingTelemetryModule": true,
    "EnableRequestTrackingTelemetryModule": true,
    "EnableEventCounterCollectionModule": true
  }
}
```

### Key Performance Indicators (KPIs)

#### Technical KPIs
- **API Response Time**: < 500ms (95th percentile)
- **System Availability**: 99.9% uptime
- **Error Rate**: < 0.1%
- **Database Query Performance**: < 100ms average
- **Authentication Success Rate**: > 99.5%

#### Business KPIs
- **Application Processing Time**: < 48 hours
- **Citizen Satisfaction Score**: > 4.0/5.0
- **Digital Adoption Rate**: 60% of eligible citizens
- **Caseworker Productivity**: 30% improvement
- **Document Verification Rate**: > 95%

#### Security KPIs
- **Failed Login Attempts**: < 1% of total attempts
- **Data Breach Incidents**: 0
- **Compliance Audit Score**: 100%
- **Vulnerability Remediation Time**: < 24 hours

### Grafana Dashboard Queries
```promql
# Application Response Time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Error Rate
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])

# Active Users
count(increase(user_login_total[1h]))

# Database Connections
pg_stat_database_numbackends
```

---

## 7. POPIA Compliance Framework

### Data Protection Principles

#### 1. Accountability
- **Data Protection Officer**: Appointed and certified
- **Privacy Policies**: Published and accessible
- **Staff Training**: Quarterly privacy training sessions
- **Compliance Monitoring**: Monthly assessments

#### 2. Processing Limitation
- **Purpose Specification**: Clear documentation of data use
- **Collection Limitation**: Minimum necessary data only
- **Use Limitation**: Data used only for specified purposes
- **Retention Schedules**: Automated data purging after 7 years

#### 3. Data Subject Rights
- **Access Requests**: Portal for citizens to view their data
- **Correction Rights**: Self-service data updates
- **Deletion Rights**: Right to be forgotten implementation
- **Objection Rights**: Opt-out mechanisms

#### 4. Security Safeguards
- **Encryption**: AES-256 for data at rest and in transit
- **Access Controls**: Role-based permissions
- **Audit Logging**: Comprehensive activity tracking
- **Incident Response**: 72-hour breach notification

### POPIA Compliance Checklist

#### Legal Basis (Section 11)
- [ ] Consent forms implemented and tracked
- [ ] Legal basis documented for each processing activity
- [ ] Withdrawal of consent mechanisms available
- [ ] Clear privacy notices provided

#### Collection (Section 12-13)
- [ ] Data minimization principles applied
- [ ] Direct collection from data subjects
- [ ] Third-party collection justified and documented
- [ ] Collection notices provided

#### Processing (Section 14-15)
- [ ] Purpose limitation enforced
- [ ] Compatible use documented
- [ ] Processing records maintained
- [ ] Data sharing agreements in place

#### Quality (Section 16)
- [ ] Data accuracy mechanisms implemented
- [ ] Regular data quality audits
- [ ] Data correction processes available
- [ ] Outdated data identification and removal

#### Openness (Section 17-18)
- [ ] Privacy policy published
- [ ] Processing information available
- [ ] Data subject notification procedures
- [ ] Transparency reports generated

#### Data Subject Rights (Section 19-25)
- [ ] Access request portal implemented
- [ ] Identity verification procedures
- [ ] Response time compliance (30 days)
- [ ] Fee structure documented

#### Cross-border Transfers (Section 72)
- [ ] Adequacy decisions verified
- [ ] Binding corporate rules implemented
- [ ] Standard contractual clauses used
- [ ] Transfer impact assessments conducted

---

## 8. Accessibility Standards (WCAG 2.1 AA)

### Implementation Guidelines

#### Perceivable
- **Alt Text**: All images have descriptive alternative text
- **Captions**: Video content includes accurate captions
- **Color Contrast**: Minimum 4.5:1 ratio for normal text
- **Responsive Design**: Adapts to 320px width minimum

#### Operable
- **Keyboard Navigation**: All functionality accessible via keyboard
- **Focus Indicators**: Clear visual focus indicators
- **Time Limits**: Adjustable or extendable time limits
- **Seizure Prevention**: No content causes seizures

#### Understandable
- **Language**: Page language identified programmatically
- **Predictable**: Consistent navigation and identification
- **Input Assistance**: Error identification and suggestions
- **Instructions**: Clear form labels and instructions

#### Robust
- **Valid Code**: HTML validates against standards
- **Compatible**: Works with assistive technologies
- **Future-proof**: Uses semantic markup

### Accessibility Features

#### Multi-language Support
```javascript
const languages = {
  'en': 'English',
  'af': 'Afrikaans', 
  'zu': 'isiZulu',
  'xh': 'isiXhosa',
  'st': 'Sesotho',
  'tn': 'Setswana',
  'ss': 'SiSwati',
  've': 'Tshivenda',
  'ts': 'Xitsonga',
  'nr': 'isiNdebele'
};
```

#### Screen Reader Support
```html
<form aria-labelledby="application-form-title">
  <h2 id="application-form-title">Social Grant Application</h2>
  
  <div class="form-group">
    <label for="id-number">Identity Number</label>
    <input 
      type="text" 
      id="id-number" 
      name="idNumber"
      aria-describedby="id-number-help"
      aria-required="true"
      pattern="[0-9]{13}"
    >
    <div id="id-number-help" class="help-text">
      Enter your 13-digit South African ID number
    </div>
  </div>
</form>
```

---

## 9. Rollout Timeline (6 Months)

### Phase 1: Foundation (Weeks 1-8)
**Weeks 1-2: Infrastructure Setup**
- Azure environment provisioning
- Keycloak deployment and configuration
- Database setup with encryption
- CI/CD pipeline implementation

**Weeks 3-4: Core Development**
- Authentication system implementation
- Basic CRUD operations for applications
- Document upload functionality
- Audit logging system

**Weeks 5-6: Integration Development**
- eKYC system integration
- Payment gateway connection
- USSD/SMS fallback systems
- Third-party service integrations

**Weeks 7-8: Security Implementation**
- Penetration testing
- Vulnerability assessments
- POPIA compliance validation
- Security controls implementation

### Phase 2: User Interfaces (Weeks 9-16)
**Weeks 9-10: Citizen Portal**
- Responsive web application
- Mobile-optimized interface
- Accessibility compliance
- Multi-language support

**Weeks 11-12: Caseworker Dashboard**
- Application review interface
- Workflow management
- Reporting capabilities
- Decision tracking

**Weeks 13-14: Admin Console**
- User management
- System configuration
- Analytics dashboards
- Audit trail viewing

**Weeks 15-16: Integration Testing**
- End-to-end testing
- Performance testing
- User acceptance testing
- Accessibility testing

### Phase 3: Deployment (Weeks 17-20)
**Weeks 17-18: Pilot Preparation**
- Staff training delivery
- Data migration
- System documentation
- Go-live preparation

**Weeks 19-20: Pilot Launch**
- Limited user rollout
- Real-time monitoring
- Issue resolution
- Feedback collection

### Phase 4: Optimization (Weeks 21-24)
**Weeks 21-22: Performance Tuning**
- System optimization
- Bug fixes
- Feature enhancements
- Security updates

**Weeks 23-24: Full Rollout**
- Complete user migration
- Process documentation
- Training completion
- Success measurement

---

## 10. Risk Assessment and Mitigation

### High-Risk Areas

#### 1. Data Security Breaches
**Risk Level**: High  
**Impact**: Legal, financial, reputational damage  
**Mitigation**:
- Multi-layer encryption implementation
- Regular security audits and penetration testing
- Employee training on data handling
- Incident response plan activation

#### 2. System Downtime
**Risk Level**: Medium  
**Impact**: Service disruption, citizen dissatisfaction  
**Mitigation**:
- High availability architecture with 99.9% SLA
- Automated failover mechanisms
- Regular disaster recovery testing
- Real-time monitoring and alerting

#### 3. Integration Failures
**Risk Level**: Medium  
**Impact**: Process delays, manual workarounds  
**Mitigation**:
- Comprehensive API testing
- Fallback procedures for critical integrations
- Service mesh implementation for resilience
- Circuit breaker patterns

#### 4. User Adoption Challenges
**Risk Level**: Medium  
**Impact**: Low pilot success, resistance to change  
**Mitigation**:
- Extensive user training programs
- Change management support
- Gradual rollout approach
- Continuous user feedback incorporation

### Compliance Risks

#### POPIA Compliance
- **Regular audits**: Quarterly compliance assessments
- **Staff training**: Mandatory privacy training
- **Documentation**: Comprehensive data processing records
- **Monitoring**: Automated compliance checking

#### Accessibility Compliance
- **Testing**: Regular accessibility audits
- **Standards**: WCAG 2.1 AA compliance verification
- **User feedback**: Accessibility user testing sessions
- **Continuous improvement**: Quarterly accessibility reviews

---

This technical blueprint provides a comprehensive foundation for implementing a successful Social Grants digital pilot in South Africa, ensuring security, compliance, accessibility, and user satisfaction while laying the groundwork for national scalability.