# Social Grants Digital Pilot - Implementation Plan
## Comprehensive 2,500-Word Step-by-Step Guide

### Executive Overview

The Social Grants Digital Pilot represents a transformative initiative to modernize South Africa's social welfare system through digital innovation. This implementation plan provides detailed, actionable steps for deploying a secure, accessible, and POPIA-compliant digital platform that serves citizens, caseworkers, and Digital Transformation Office (DTO) personnel across one pilot province.

### Project Scope and Objectives

**Target Province**: Gauteng  
**Duration**: 6 months  
**Budget**: R15 million  
**Beneficiaries**: 50,000+ citizens, 200+ caseworkers, 50+ DTO staff

**Primary Objectives**:
- Reduce application processing time from 30 days to 7 days
- Achieve 95% digital adoption rate among eligible citizens
- Implement end-to-end audit trail for compliance
- Establish foundation for national rollout

---

## Phase 1: Foundation Setup (Weeks 1-8)

### 1.1 Infrastructure Provisioning

**Week 1: Azure Environment Setup**

Begin by establishing the core cloud infrastructure on Microsoft Azure:

```bash
# Login to Azure CLI
az login

# Create resource group
az group create --name rg-socialgrants-pilot --location southafricanorth

# Create virtual network
az network vnet create \
  --resource-group rg-socialgrants-pilot \
  --name vnet-socialgrants \
  --address-prefix 10.0.0.0/16 \
  --subnet-name subnet-app \
  --subnet-prefix 10.0.1.0/24
```

Deploy the Terraform infrastructure skeleton:

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="environment=pilot" -var="location=southafricanorth"

# Apply infrastructure
terraform apply -auto-approve
```

**Week 2: Security Foundation**

Implement Azure Key Vault for secrets management:

```bash
# Create Key Vault
az keyvault create \
  --name kv-socialgrants-pilot \
  --resource-group rg-socialgrants-pilot \
  --location southafricanorth \
  --enable-soft-delete \
  --enable-purge-protection
```

Configure database encryption:

```sql
-- Enable Transparent Data Encryption
ALTER DATABASE socialgrants SET ENCRYPTION ON;

-- Create master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!';

-- Create certificate
CREATE CERTIFICATE SocialGrantsCert WITH SUBJECT = 'Social Grants Encryption';

-- Create symmetric key
CREATE SYMMETRIC KEY SocialGrantsKey 
WITH ALGORITHM = AES_256 
ENCRYPTION BY CERTIFICATE SocialGrantsCert;
```

### 1.2 Authentication System Implementation

**Week 3: Keycloak Deployment**

Deploy Keycloak on Azure Container Instances:

```yaml
# keycloak-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
spec:
  replicas: 2
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
      - name: keycloak
        image: quay.io/keycloak/keycloak:21.1
        env:
        - name: KEYCLOAK_ADMIN
          value: admin
        - name: KEYCLOAK_ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: keycloak-secret
              key: admin-password
        - name: KC_DB
          value: postgres
        - name: KC_DB_URL
          value: jdbc:postgresql://postgres:5432/keycloak
        ports:
        - containerPort: 8080
```

Configure realm and client settings:

```bash
# Create realm
curl -X POST "https://auth.socialgrants.gov.za/auth/admin/realms" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "social-grants-za",
    "enabled": true,
    "sslRequired": "external",
    "bruteForceProtected": true
  }'
```

**Week 4: eKYC Integration**

Integrate with Home Affairs National Identification System:

```javascript
// ekyc-service.js
class EKYCService {
  async verifyIdentity(idNumber, biometricData) {
    const verification = await fetch('https://api.dha.gov.za/verify', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.DHA_API_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        id_number: idNumber,
        biometric_hash: biometricData,
        requesting_entity: 'SASSA'
      })
    });
    
    return verification.json();
  }
  
  async performLivenessCheck(imageData) {
    const response = await fetch('https://api.azure.microsoft.com/face/v1.0/detect', {
      method: 'POST',
      headers: {
        'Ocp-Apim-Subscription-Key': process.env.AZURE_FACE_API_KEY,
        'Content-Type': 'application/octet-stream'
      },
      body: imageData
    });
    
    const faces = await response.json();
    return faces.length === 1 && faces[0].faceAttributes.blur.value < 0.3;
  }
}
```

### 1.3 Database Implementation

**Week 5: Database Schema Deployment**

Execute the encrypted database schema:

```sql
-- Create application with encryption
CREATE TABLE applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    application_type ENUM('child_support', 'disability', 'old_age', 'care_dependency'),
    status ENUM('draft', 'submitted', 'under_review', 'approved', 'rejected'),
    
    -- Encrypted personal data
    applicant_name BYTEA, -- Encrypted with app-level encryption
    id_number BYTEA,      -- Encrypted with app-level encryption
    bank_details BYTEA,   -- Encrypted with app-level encryption
    
    -- Non-sensitive metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    submission_ip INET,
    processing_notes TEXT
);

-- Create audit table for POPIA compliance
CREATE TABLE audit_trail (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(50) NOT NULL,
    record_id UUID NOT NULL,
    action_type ENUM('INSERT', 'UPDATE', 'DELETE', 'SELECT') NOT NULL,
    user_id UUID REFERENCES users(id),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    changes JSONB,
    legal_basis VARCHAR(100)
);
```

Implement application-level encryption functions:

```javascript
// encryption-service.js
const crypto = require('crypto');

class EncryptionService {
  constructor() {
    this.algorithm = 'aes-256-gcm';
    this.keyLength = 32;
  }
  
  encrypt(text, key) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipher(this.algorithm, key, iv);
    
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const authTag = cipher.getAuthTag();
    
    return {
      iv: iv.toString('hex'),
      encryptedData: encrypted,
      authTag: authTag.toString('hex')
    };
  }
  
  decrypt(encryptedData, key) {
    const decipher = crypto.createDecipher(
      this.algorithm, 
      key, 
      Buffer.from(encryptedData.iv, 'hex')
    );
    
    decipher.setAuthTag(Buffer.from(encryptedData.authTag, 'hex'));
    
    let decrypted = decipher.update(encryptedData.encryptedData, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  }
}
```

**Week 6: API Development**

Implement core API endpoints with security middleware:

```javascript
// app.js
const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const app = express();

// Security middleware
app.use(helmet({
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
});
app.use('/api', limiter);

// Application endpoints
app.post('/api/v1/applications', async (req, res) => {
  try {
    // Validate POPIA consent
    const consentValid = await validateConsent(req.body.consentData);
    if (!consentValid) {
      return res.status(400).json({ error: 'Valid consent required' });
    }
    
    // Encrypt sensitive data
    const encryptedData = await encryptService.encrypt(
      JSON.stringify(req.body.personalData),
      process.env.ENCRYPTION_KEY
    );
    
    // Create application record
    const application = await db.applications.create({
      user_id: req.user.id,
      application_type: req.body.type,
      encrypted_data: encryptedData,
      status: 'draft'
    });
    
    // Log audit trail
    await auditLogger.log({
      action: 'APPLICATION_CREATED',
      user_id: req.user.id,
      resource_id: application.id,
      ip_address: req.ip,
      legal_basis: 'consent'
    });
    
    res.status(201).json({ application_id: application.id });
  } catch (error) {
    console.error('Application creation error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

### 1.4 Communication Channels Setup

**Week 7: USSD/SMS Implementation**

Configure Africa's Talking API for USSD services:

```javascript
// ussd-service.js
const AfricasTalking = require('africastalking');

class USSDService {
  constructor() {
    this.client = AfricasTalking({
      apiKey: process.env.AFRICAS_TALKING_API_KEY,
      username: process.env.AFRICAS_TALKING_USERNAME
    });
  }
  
  async handleUSSDRequest(sessionId, serviceCode, phoneNumber, text) {
    let response = '';
    
    if (text === '') {
      // Main menu
      response = `CON Welcome to Social Grants
1. Check Application Status
2. Apply for Grant
3. Update Bank Details
4. Contact Support`;
    } else if (text === '1') {
      // Check status
      response = `CON Enter your ID number:`;
    } else if (text.startsWith('1*')) {
      const idNumber = text.split('*')[1];
      const status = await this.getApplicationStatus(idNumber);
      response = `END Your application status: ${status}`;
    }
    
    return response;
  }
  
  async sendSMSNotification(phoneNumber, message) {
    return this.client.SMS.send({
      to: phoneNumber,
      message: message,
      from: 'SASSA'
    });
  }
}
```

**Week 8: Payment Integration**

Integrate with PayFast and banking APIs:

```javascript
// payment-service.js
class PaymentService {
  async initiatePayment(applicationId, amount, bankDetails) {
    const payment = {
      merchant_id: process.env.PAYFAST_MERCHANT_ID,
      merchant_key: process.env.PAYFAST_MERCHANT_KEY,
      amount: amount,
      item_name: `Social Grant Payment - ${applicationId}`,
      return_url: `${process.env.BASE_URL}/payments/success`,
      cancel_url: `${process.env.BASE_URL}/payments/cancel`,
      notify_url: `${process.env.BASE_URL}/payments/notify`
    };
    
    // Generate signature for security
    payment.signature = this.generateSignature(payment);
    
    // Log payment initiation
    await auditLogger.log({
      action: 'PAYMENT_INITIATED',
      resource_id: applicationId,
      amount: amount,
      timestamp: new Date()
    });
    
    return payment;
  }
  
  async processCallback(paymentData) {
    // Verify payment authenticity
    if (!this.verifyPaymentSignature(paymentData)) {
      throw new Error('Invalid payment signature');
    }
    
    // Update application status
    await db.applications.update({
      status: 'paid',
      payment_reference: paymentData.pf_payment_id
    }, {
      where: { id: paymentData.item_name.split(' - ')[1] }
    });
    
    // Send SMS notification
    await smsService.sendSMSNotification(
      paymentData.phone_number,
      `Your social grant payment has been processed. Reference: ${paymentData.pf_payment_id}`
    );
  }
}
```

---

## Phase 2: User Interface Development (Weeks 9-16)

### 2.1 Citizen Portal Development

**Week 9-10: Responsive Web Application**

Create an accessible, mobile-first citizen portal:

```html
<!-- citizen-portal.html -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Social Grants - Citizen Portal</title>
    <link rel="stylesheet" href="styles/accessibility.css">
</head>
<body>
    <header role="banner">
        <nav aria-label="Main navigation">
            <ul>
                <li><a href="#applications" aria-current="page">My Applications</a></li>
                <li><a href="#profile">Profile</a></li>
                <li><a href="#help">Help</a></li>
                <li><a href="#language">Language</a></li>
            </ul>
        </nav>
    </header>
    
    <main role="main">
        <section id="applications" aria-labelledby="applications-heading">
            <h1 id="applications-heading">My Grant Applications</h1>
            
            <form id="grant-application" novalidate>
                <fieldset>
                    <legend>Personal Information</legend>
                    
                    <div class="form-group">
                        <label for="id-number">
                            Identity Number
                            <span aria-label="required">*</span>
                        </label>
                        <input 
                            type="text" 
                            id="id-number" 
                            name="idNumber"
                            pattern="[0-9]{13}"
                            aria-describedby="id-number-help id-number-error"
                            aria-required="true"
                            autocomplete="off"
                        >
                        <div id="id-number-help" class="help-text">
                            Enter your 13-digit South African ID number
                        </div>
                        <div id="id-number-error" class="error-text" role="alert" aria-live="polite"></div>
                    </div>
                    
                    <div class="form-group">
                        <label for="grant-type">Grant Type</label>
                        <select id="grant-type" name="grantType" aria-required="true">
                            <option value="">Please select a grant type</option>
                            <option value="child_support">Child Support Grant</option>
                            <option value="disability">Disability Grant</option>
                            <option value="old_age">Old Age Grant</option>
                            <option value="care_dependency">Care Dependency Grant</option>
                        </select>
                    </div>
                </fieldset>
                
                <fieldset>
                    <legend>Consent and Privacy</legend>
                    <div class="checkbox-group">
                        <input type="checkbox" id="consent-processing" name="consent" value="processing" required>
                        <label for="consent-processing">
                            I consent to the processing of my personal information for the purpose of assessing my grant application, in accordance with POPIA
                        </label>
                    </div>
                    
                    <div class="checkbox-group">
                        <input type="checkbox" id="consent-verification" name="consent" value="verification" required>
                        <label for="consent-verification">
                            I consent to verification of my information with relevant government departments
                        </label>
                    </div>
                </fieldset>
                
                <div class="form-actions">
                    <button type="submit" class="btn-primary">Submit Application</button>
                    <button type="button" class="btn-secondary" onclick="saveAsDraft()">Save as Draft</button>
                </div>
            </form>
        </section>
    </main>
    
    <script src="js/form-validation.js"></script>
    <script src="js/accessibility.js"></script>
</body>
</html>
```

Implement comprehensive form validation:

```javascript
// form-validation.js
class FormValidator {
  constructor() {
    this.rules = {
      idNumber: {
        required: true,
        pattern: /^[0-9]{13}$/,
        validator: this.validateSouthAfricanID
      },
      phoneNumber: {
        required: true,
        pattern: /^(?:\+27|0)[1-9][0-9]{8}$/
      },
      email: {
        required: false,
        pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      }
    };
  }
  
  validateSouthAfricanID(idNumber) {
    // Luhn algorithm validation for SA ID numbers
    const digits = idNumber.split('').map(Number);
    const checkDigit = digits.pop();
    
    let sum = 0;
    for (let i = 0; i < digits.length; i++) {
      let digit = digits[i];
      if (i % 2 === 1) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
    }
    
    const calculatedCheck = (10 - (sum % 10)) % 10;
    return calculatedCheck === checkDigit;
  }
  
  validateField(fieldName, value) {
    const rule = this.rules[fieldName];
    if (!rule) return { valid: true };
    
    // Required field validation
    if (rule.required && (!value || value.trim() === '')) {
      return { 
        valid: false, 
        message: `${fieldName} is required` 
      };
    }
    
    // Pattern validation
    if (value && rule.pattern && !rule.pattern.test(value)) {
      return { 
        valid: false, 
        message: `${fieldName} format is invalid` 
      };
    }
    
    // Custom validator
    if (value && rule.validator && !rule.validator(value)) {
      return { 
        valid: false, 
        message: `${fieldName} is invalid` 
      };
    }
    
    return { valid: true };
  }
}
```

### 2.2 Caseworker Dashboard

**Week 11-12: Workflow Management Interface**

Build the caseworker interface for application processing:

```javascript
// caseworker-dashboard.js
class CaseworkerDashboard {
  constructor() {
    this.applications = [];
    this.filters = {
      status: 'all',
      priority: 'all',
      assignedTo: 'me'
    };
  }
  
  async loadApplicationQueue() {
    try {
      const response = await fetch('/api/v1/casework/queue', {
        headers: {
          'Authorization': `Bearer ${this.getAuthToken()}`,
          'Content-Type': 'application/json'
        }
      });
      
      this.applications = await response.json();
      this.renderApplicationList();
    } catch (error) {
      this.showError('Failed to load application queue');
    }
  }
  
  renderApplicationList() {
    const container = document.getElementById('application-queue');
    container.innerHTML = this.applications.map(app => `
      <div class="application-card" data-id="${app.id}">
        <div class="application-header">
          <h3>Application #${app.reference_number}</h3>
          <span class="status-badge status-${app.status}">${app.status}</span>
        </div>
        
        <div class="application-details">
          <p><strong>Type:</strong> ${app.grant_type}</p>
          <p><strong>Submitted:</strong> ${new Date(app.submitted_at).toLocaleDateString()}</p>
          <p><strong>Priority:</strong> ${app.priority}</p>
        </div>
        
        <div class="application-actions">
          <button onclick="this.reviewApplication('${app.id}')" class="btn-primary">
            Review
          </button>
          <button onclick="this.viewHistory('${app.id}')" class="btn-secondary">
            History
          </button>
        </div>
      </div>
    `).join('');
  }
  
  async reviewApplication(applicationId) {
    const application = await this.loadApplicationDetails(applicationId);
    
    // Open review modal
    const modal = document.getElementById('review-modal');
    modal.querySelector('#review-application-id').value = applicationId;
    modal.querySelector('#applicant-name').textContent = application.applicant_name;
    modal.querySelector('#application-type').textContent = application.grant_type;
    
    // Load required documents checklist
    this.loadDocumentChecklist(application);
    
    modal.style.display = 'block';
  }
  
  async approveApplication(applicationId, comments) {
    try {
      await fetch(`/api/v1/casework/applications/${applicationId}/approve`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.getAuthToken()}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          comments: comments,
          reviewer_id: this.getCurrentUserId()
        })
      });
      
      // Log audit trail
      await this.logAction('APPLICATION_APPROVED', applicationId);
      
      // Refresh queue
      await this.loadApplicationQueue();
      
      this.showSuccess('Application approved successfully');
    } catch (error) {
      this.showError('Failed to approve application');
    }
  }
}
```

### 2.3 Administrative Console

**Week 13-14: System Management Interface**

Create administrative dashboards for system oversight:

```javascript
// admin-console.js
class AdminConsole {
  constructor() {
    this.dashboardData = {};
    this.initializeCharts();
  }
  
  async loadDashboard() {
    const [applications, users, payments, compliance] = await Promise.all([
      this.fetchApplicationMetrics(),
      this.fetchUserMetrics(),
      this.fetchPaymentMetrics(),
      this.fetchComplianceMetrics()
    ]);
    
    this.renderApplicationChart(applications);
    this.renderUserStats(users);
    this.renderPaymentSummary(payments);
    this.renderComplianceStatus(compliance);
  }
  
  renderApplicationChart(data) {
    const ctx = document.getElementById('applications-chart').getContext('2d');
    
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.dates,
        datasets: [{
          label: 'Applications Submitted',
          data: data.submitted,
          borderColor: '#3498db',
          backgroundColor: 'rgba(52, 152, 219, 0.1)'
        }, {
          label: 'Applications Processed',
          data: data.processed,
          borderColor: '#2ecc71',
          backgroundColor: 'rgba(46, 204, 113, 0.1)'
        }]
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'Application Processing Trends'
          }
        },
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });
  }
  
  async generateComplianceReport() {
    const reportData = {
      period: 'monthly',
      metrics: {
        data_breaches: 0,
        access_requests_fulfilled: 47,
        consent_withdrawals: 3,
        retention_policy_compliance: 98.5,
        encryption_coverage: 100,
        audit_trail_completeness: 99.8
      }
    };
    
    // Generate PDF report
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();
    
    doc.setFontSize(16);
    doc.text('POPIA Compliance Report', 20, 20);
    
    doc.setFontSize(12);
    doc.text(`Report Period: ${reportData.period}`, 20, 40);
    doc.text(`Data Breaches: ${reportData.metrics.data_breaches}`, 20, 60);
    doc.text(`Access Requests Fulfilled: ${reportData.metrics.access_requests_fulfilled}`, 20, 80);
    
    doc.save('popia-compliance-report.pdf');
  }
}
```

### 2.4 Mobile Optimization

**Week 15-16: Progressive Web App Features**

Implement PWA capabilities for offline functionality:

```javascript
// service-worker.js
const CACHE_NAME = 'social-grants-v1';
const urlsToCache = [
  '/',
  '/css/styles.css',
  '/js/app.js',
  '/images/logo.png',
  '/pages/offline.html'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        // Return cached version or fetch from network
        return response || fetch(event.request);
      })
      .catch(() => {
        // Show offline page for navigation requests
        if (event.request.mode === 'navigate') {
          return caches.match('/pages/offline.html');
        }
      })
  );
});

// Background sync for form submissions
self.addEventListener('sync', (event) => {
  if (event.tag === 'submit-application') {
    event.waitUntil(submitPendingApplications());
  }
});

async function submitPendingApplications() {
  const applications = await getStoredApplications();
  
  for (const app of applications) {
    try {
      await fetch('/api/v1/applications', {
        method: 'POST',
        body: JSON.stringify(app),
        headers: { 'Content-Type': 'application/json' }
      });
      
      await removeStoredApplication(app.id);
    } catch (error) {
      console.error('Failed to submit application:', error);
    }
  }
}
```

---

## Phase 3: Testing and Quality Assurance (Weeks 17-20)

### 3.1 Security Testing

Implement comprehensive security testing protocols:

```bash
# OWASP ZAP security scan
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t https://pilot.socialgrants.gov.za \
  -r baseline-report.html

# Nmap network scanning
nmap -sV -sC pilot.socialgrants.gov.za

# SSL/TLS testing
testssl.sh --severity MEDIUM pilot.socialgrants.gov.za
```

### 3.2 Performance Testing

Execute load testing scenarios:

```javascript
// load-test.js using Artillery
module.exports = {
  config: {
    target: 'https://api.socialgrants.gov.za',
    phases: [
      { duration: 60, arrivalRate: 10 },
      { duration: 120, arrivalRate: 50 },
      { duration: 60, arrivalRate: 100 }
    ]
  },
  scenarios: [
    {
      name: 'Application Submission',
      weight: 60,
      flow: [
        { post: '/auth/login', json: { username: 'test@example.com', password: 'password' } },
        { post: '/applications', json: { type: 'child_support', data: '{{applicationData}}' } }
      ]
    },
    {
      name: 'Status Check',
      weight: 40,
      flow: [
        { get: '/applications/{{applicationId}}/status' }
      ]
    }
  ]
};
```

### 3.3 Accessibility Testing

Automated accessibility validation:

```javascript
// accessibility-test.js
const axe = require('@axe-core/puppeteer');
const puppeteer = require('puppeteer');

async function runAccessibilityTests() {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  await page.goto('https://pilot.socialgrants.gov.za');
  
  const results = await axe.analyze(page);
  
  console.log('Accessibility Violations:', results.violations.length);
  
  results.violations.forEach(violation => {
    console.log(`${violation.id}: ${violation.description}`);
    violation.nodes.forEach(node => {
      console.log(`  - ${node.html}`);
    });
  });
  
  await browser.close();
}
```

---

## Phase 4: Deployment and Monitoring (Weeks 21-24)

### 4.1 Production Deployment

Deploy to production environment with zero-downtime strategies:

```bash
# Blue-green deployment script
#!/bin/bash

# Deploy to green environment
az containerapp update \
  --name ca-api-green \
  --resource-group rg-socialgrants-prod \
  --image socialgrants.azurecr.io/api:latest

# Run health checks
curl -f https://api-green.socialgrants.gov.za/health

# Switch traffic to green
az containerapp ingress traffic set \
  --name ca-api \
  --resource-group rg-socialgrants-prod \
  --revision-weight green=100 blue=0

# Monitor for 15 minutes
sleep 900

# Verify success
if [ $? -eq 0 ]; then
  echo "Deployment successful"
  # Decommission blue environment
  az containerapp revision deactivate \
    --name ca-api \
    --resource-group rg-socialgrants-prod \
    --revision blue
else
  echo "Deployment failed - rolling back"
  # Rollback to blue
  az containerapp ingress traffic set \
    --name ca-api \
    --resource-group rg-socialgrants-prod \
    --revision-weight blue=100 green=0
fi
```

### 4.2 Monitoring Implementation

Configure comprehensive monitoring with Azure Application Insights:

```javascript
// monitoring-setup.js
const appInsights = require('applicationinsights');

appInsights.setup(process.env.APPLICATIONINSIGHTS_CONNECTION_STRING)
  .setAutoDependencyCorrelation(true)
  .setAutoCollectRequests(true)
  .setAutoCollectPerformance(true, true)
  .setAutoCollectExceptions(true)
  .setAutoCollectDependencies(true)
  .setAutoCollectConsole(true)
  .setUseDiskRetryCaching(true)
  .setSendLiveMetrics(true)
  .start();

const client = appInsights.defaultClient;

// Custom metrics tracking
function trackCustomMetrics() {
  // Track application processing time
  client.trackMetric({
    name: 'ApplicationProcessingTime',
    value: processingTime,
    properties: { grantType: 'child_support' }
  });
  
  // Track user satisfaction
  client.trackMetric({
    name: 'UserSatisfactionScore',
    value: satisfactionScore
  });
  
  // Track POPIA compliance events
  client.trackEvent({
    name: 'ConsentGiven',
    properties: { 
      consentType: 'data_processing',
      userId: userId,
      timestamp: new Date().toISOString()
    }
  });
}
```

This comprehensive implementation plan provides detailed, actionable steps for successfully deploying the Social Grants digital pilot, ensuring security, accessibility, compliance, and user satisfaction throughout the 6-month pilot period.