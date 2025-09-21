# South Africa Social Grants Pilot System

## Overview

This is a comprehensive, end-to-end digital Social Grants pilot system designed for the South African government. The system provides secure, accessible, and POPIA-compliant grant management for citizens, caseworkers, and Department of Social Development (DSD) staff.

## System Architecture

The system follows a microservices architecture deployed on Kubernetes with the following key components:

- **API Gateway**: Kong/Istio for routing and security
- **Identity Provider**: Keycloak for OIDC authentication
- **Application Services**: Node.js/Express microservices
- **Database**: PostgreSQL with encryption at rest
- **Message Queue**: Redis for real-time notifications
- **Monitoring**: Prometheus + Grafana stack
- **Alternative Access**: USSD/SMS gateway integration

## Key Features

### For Citizens
- Online grant applications with document upload
- Application status tracking and notifications
- Payment history and statements
- Multi-language support (EN, AF, ZU, XH)
- USSD access for feature phones
- SMS notifications and updates

### For Caseworkers
- Application review and processing workflows
- Document verification tools
- Citizen communication portal
- Workload management dashboard
- Mobile-responsive interface

### For DSD Staff
- System administration and configuration
- Reporting and analytics dashboards
- Audit trail management
- Policy configuration tools
- User management and permissions

## Compliance & Security

- **POPIA Compliance**: Full data protection compliance
- **WCAG 2.1 AA**: Accessibility standards adherence
- **ISO 27001**: Security management standards
- **Audit Logging**: Immutable audit trails
- **Data Encryption**: End-to-end encryption
- **Multi-factor Authentication**: SMS and authenticator app support

## Quick Start

### Prerequisites
- Docker 20.10+
- Kubernetes 1.24+
- Helm 3.0+
- Terraform 1.0+

### Local Development Setup
```bash
# Clone the repository
git clone https://github.com/Vundla/My-Portfolio.git
cd My-Portfolio/social-grants-pilot

# Start local development environment
docker-compose up -d

# Apply database migrations
npm run migrate

# Seed test data
npm run seed

# Start the application
npm run dev
```

The application will be available at:
- Web Interface: http://localhost:3000
- API Documentation: http://localhost:3000/api/docs
- Admin Panel: http://localhost:3000/admin

## Documentation Structure

```
social-grants-pilot/
├── docs/                          # Comprehensive documentation
│   ├── api/                       # API documentation and OpenAPI specs
│   ├── deployment/                # Deployment guides and infrastructure
│   ├── training/                  # Staff training materials
│   ├── compliance/                # POPIA and accessibility compliance
│   └── operations/                # Operational procedures
├── src/                           # Application source code
├── infrastructure/                # Terraform and Kubernetes manifests
├── monitoring/                    # Prometheus and Grafana configurations
├── scripts/                       # Deployment and utility scripts
└── tests/                         # Test suites and test data
```

## Deployment Options

### Cloud Providers
- **AWS**: EKS with RDS PostgreSQL
- **Azure**: AKS with Azure Database for PostgreSQL
- **Google Cloud**: GKE with Cloud SQL PostgreSQL
- **On-Premise**: Kubernetes with local PostgreSQL cluster

### Environment Types
- **Development**: Single-node setup with minimal resources
- **Staging**: Multi-node setup mirroring production
- **Production**: High-availability setup with auto-scaling

## Pilot Rollout Plan

The system is designed for a 6-month pilot in one South African province:

### Phase 1 (Weeks 1-4): Infrastructure Setup
- Deploy core infrastructure
- Configure identity management
- Setup monitoring and logging
- Conduct security assessments

### Phase 2 (Weeks 5-8): Staff Training
- Train 50+ staff members
- Conduct certification programs
- Setup support processes
- Validate operational procedures

### Phase 3 (Weeks 9-16): Limited Rollout
- Onboard 1,000 pilot users
- Process initial grant applications
- Monitor system performance
- Collect user feedback

### Phase 4 (Weeks 17-24): Full Pilot
- Scale to full province capacity
- Implement feedback improvements
- Conduct final assessments
- Prepare for national rollout

## Support and Maintenance

### 24/7 Support Tiers
- **Tier 1**: User support via call center and chat
- **Tier 2**: Technical support for caseworkers
- **Tier 3**: System administration and escalation

### Maintenance Windows
- **Regular**: Sunday 02:00-04:00 SAST
- **Emergency**: As needed with 4-hour notification
- **Major Updates**: Quarterly scheduled maintenance

## Contact Information

### Technical Support
- Email: tech-support@socialgrants.gov.za
- Phone: +27 12 123 4567
- Emergency: +27 82 123 4567

### Project Team
- **Project Manager**: [Name] - project-manager@socialgrants.gov.za
- **Technical Lead**: [Name] - tech-lead@socialgrants.gov.za
- **Security Officer**: [Name] - security@socialgrants.gov.za

## License

This software is proprietary to the South African Government and is not licensed for public use or distribution.

© 2025 Department of Social Development, South Africa. All rights reserved.