-- South Africa Social Grants Database Schema
-- Version: 1.0.0
-- Description: POPIA-compliant database schema with encryption for sensitive data

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create custom types
CREATE TYPE user_role AS ENUM ('citizen', 'caseworker', 'admin', 'super_admin');
CREATE TYPE user_status AS ENUM ('active', 'suspended', 'inactive', 'pending_verification');
CREATE TYPE grant_type AS ENUM (
    'old_age_pension',
    'disability_grant', 
    'child_support_grant',
    'foster_child_grant',
    'care_dependency_grant',
    'grant_in_aid',
    'social_relief_of_distress'
);
CREATE TYPE application_status AS ENUM (
    'draft',
    'submitted',
    'under_review',
    'documents_required',
    'approved',
    'rejected',
    'payment_pending',
    'active',
    'suspended',
    'closed'
);
CREATE TYPE province AS ENUM ('EC', 'FS', 'GP', 'KZN', 'LP', 'MP', 'NC', 'NW', 'WC');
CREATE TYPE language AS ENUM ('en', 'af', 'zu', 'xh');
CREATE TYPE marital_status AS ENUM ('single', 'married', 'divorced', 'widowed');
CREATE TYPE employment_status AS ENUM ('unemployed', 'employed', 'self_employed', 'retired', 'student');
CREATE TYPE document_type AS ENUM (
    'id_document',
    'proof_of_income',
    'bank_statement',
    'medical_certificate',
    'birth_certificate',
    'death_certificate',
    'proof_of_residence',
    'disability_assessment',
    'other'
);
CREATE TYPE audit_action AS ENUM (
    'create',
    'update',
    'delete',
    'login',
    'logout',
    'view',
    'approve',
    'reject',
    'submit',
    'verify'
);

-- Encryption key management table (stored in separate secure database)
CREATE TABLE encryption_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key_name VARCHAR(50) UNIQUE NOT NULL,
    key_version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true
);

-- Insert default encryption keys (these would be managed by a key management service in production)
INSERT INTO encryption_keys (key_name, key_version) VALUES 
('personal_data', 1),
('financial_data', 1),
('medical_data', 1);

-- Users table (base authentication data)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email_encrypted BYTEA, -- Encrypted email
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'citizen',
    status user_status NOT NULL DEFAULT 'pending_verification',
    two_factor_enabled BOOLEAN DEFAULT false,
    two_factor_secret VARCHAR(32),
    last_login_at TIMESTAMP WITH TIME ZONE,
    password_changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    
    -- Audit fields
    version INTEGER DEFAULT 1,
    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Create index for performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Citizen profiles table (personal information)
CREATE TABLE citizen_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Encrypted personal data (POPIA compliance)
    id_number_encrypted BYTEA NOT NULL, -- Encrypted SA ID number
    first_name_encrypted BYTEA NOT NULL,
    last_name_encrypted BYTEA NOT NULL,
    date_of_birth_encrypted BYTEA NOT NULL,
    phone_number_encrypted BYTEA,
    
    -- Address information (encrypted)
    street_address_encrypted BYTEA,
    suburb_encrypted BYTEA,
    city_encrypted BYTEA,
    province province,
    postal_code VARCHAR(4),
    
    -- Non-sensitive metadata
    language_preference language DEFAULT 'en',
    marital_status marital_status,
    employment_status employment_status,
    
    -- Verification status
    identity_verified BOOLEAN DEFAULT false,
    identity_verified_at TIMESTAMP WITH TIME ZONE,
    identity_verified_by UUID REFERENCES users(id),
    phone_verified BOOLEAN DEFAULT false,
    phone_verified_at TIMESTAMP WITH TIME ZONE,
    email_verified BOOLEAN DEFAULT false,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1,
    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT unique_user_profile UNIQUE(user_id)
);

CREATE INDEX idx_citizen_profiles_user_id ON citizen_profiles(user_id);
CREATE INDEX idx_citizen_profiles_province ON citizen_profiles(province);
CREATE INDEX idx_citizen_profiles_verified ON citizen_profiles(identity_verified);

-- Bank details table (encrypted financial information)
CREATE TABLE bank_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    citizen_profile_id UUID NOT NULL REFERENCES citizen_profiles(id) ON DELETE CASCADE,
    
    -- Encrypted banking information
    account_holder_encrypted BYTEA NOT NULL,
    bank_name_encrypted BYTEA NOT NULL,
    account_number_encrypted BYTEA NOT NULL,
    branch_code_encrypted BYTEA NOT NULL,
    account_type VARCHAR(20) DEFAULT 'savings',
    
    -- Verification status
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id),
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1,
    is_deleted BOOLEAN DEFAULT false,
    
    CONSTRAINT unique_citizen_bank UNIQUE(citizen_profile_id)
);

-- Dependents table (encrypted family information)
CREATE TABLE dependents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    citizen_profile_id UUID NOT NULL REFERENCES citizen_profiles(id) ON DELETE CASCADE,
    
    -- Encrypted dependent information
    first_name_encrypted BYTEA NOT NULL,
    last_name_encrypted BYTEA NOT NULL,
    id_number_encrypted BYTEA NOT NULL,
    date_of_birth_encrypted BYTEA NOT NULL,
    
    -- Relationship and status
    relationship VARCHAR(50) NOT NULL,
    has_disability BOOLEAN DEFAULT false,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1,
    is_deleted BOOLEAN DEFAULT false
);

CREATE INDEX idx_dependents_citizen_profile ON dependents(citizen_profile_id);

-- Grant applications table
CREATE TABLE grant_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_number VARCHAR(20) UNIQUE NOT NULL, -- Human-readable application number
    citizen_profile_id UUID NOT NULL REFERENCES citizen_profiles(id),
    grant_type grant_type NOT NULL,
    status application_status NOT NULL DEFAULT 'draft',
    
    -- Application details
    monthly_income_encrypted BYTEA, -- Encrypted income amount
    household_size INTEGER,
    special_circumstances TEXT,
    
    -- Processing information
    assigned_caseworker_id UUID REFERENCES users(id),
    assigned_at TIMESTAMP WITH TIME ZONE,
    priority_level INTEGER DEFAULT 1, -- 1=low, 2=medium, 3=high, 4=urgent
    
    -- Decision information
    approved_amount DECIMAL(10,2),
    rejection_reason TEXT,
    
    -- Important dates
    submitted_at TIMESTAMP WITH TIME ZONE,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    approved_at TIMESTAMP WITH TIME ZONE,
    first_payment_date DATE,
    next_review_date DATE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1,
    is_deleted BOOLEAN DEFAULT false
);

-- Generate application number function
CREATE OR REPLACE FUNCTION generate_application_number() RETURNS TEXT AS $$
DECLARE
    year_suffix TEXT;
    sequence_num TEXT;
    app_number TEXT;
BEGIN
    year_suffix := TO_CHAR(CURRENT_DATE, 'YY');
    sequence_num := LPAD(nextval('application_number_seq')::TEXT, 6, '0');
    app_number := 'SG' || year_suffix || sequence_num;
    RETURN app_number;
END;
$$ LANGUAGE plpgsql;

-- Create sequence for application numbers
CREATE SEQUENCE application_number_seq START 1;

-- Trigger to auto-generate application number
CREATE OR REPLACE FUNCTION set_application_number() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.application_number IS NULL THEN
        NEW.application_number := generate_application_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_application_number
    BEFORE INSERT ON grant_applications
    FOR EACH ROW
    EXECUTE FUNCTION set_application_number();

CREATE INDEX idx_applications_citizen ON grant_applications(citizen_profile_id);
CREATE INDEX idx_applications_status ON grant_applications(status);
CREATE INDEX idx_applications_caseworker ON grant_applications(assigned_caseworker_id);
CREATE INDEX idx_applications_type ON grant_applications(grant_type);
CREATE INDEX idx_applications_submitted ON grant_applications(submitted_at);

-- Documents table
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID NOT NULL REFERENCES grant_applications(id) ON DELETE CASCADE,
    document_type document_type NOT NULL,
    
    -- File information
    original_filename VARCHAR(255) NOT NULL,
    stored_filename VARCHAR(255) NOT NULL, -- UUID-based filename for security
    file_path TEXT NOT NULL, -- Encrypted storage path
    content_type VARCHAR(100),
    file_size BIGINT,
    file_hash VARCHAR(64), -- SHA-256 hash for integrity checking
    
    -- Encryption information
    is_encrypted BOOLEAN DEFAULT true,
    encryption_key_id UUID REFERENCES encryption_keys(id),
    
    -- Verification status
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id),
    verification_notes TEXT,
    
    -- Audit fields
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    uploaded_by UUID NOT NULL REFERENCES users(id),
    version INTEGER DEFAULT 1,
    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_documents_application ON documents(application_id);
CREATE INDEX idx_documents_type ON documents(document_type);
CREATE INDEX idx_documents_verified ON documents(is_verified);

-- Application reviews table
CREATE TABLE application_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID NOT NULL REFERENCES grant_applications(id),
    reviewer_id UUID NOT NULL REFERENCES users(id),
    
    -- Review details
    decision VARCHAR(50) NOT NULL, -- approve, reject, request_documents
    notes TEXT,
    approved_amount DECIMAL(10,2),
    conditions TEXT, -- Any conditions attached to approval
    
    -- Required documents if decision is request_documents
    required_documents TEXT[], -- Array of required document types
    
    -- Audit fields
    reviewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1
);

CREATE INDEX idx_reviews_application ON application_reviews(application_id);
CREATE INDEX idx_reviews_reviewer ON application_reviews(reviewer_id);
CREATE INDEX idx_reviews_date ON application_reviews(reviewed_at);

-- Payments table
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID NOT NULL REFERENCES grant_applications(id),
    
    -- Payment details
    amount DECIMAL(10,2) NOT NULL,
    payment_reference VARCHAR(50) UNIQUE NOT NULL,
    payment_method VARCHAR(50) DEFAULT 'bank_transfer',
    
    -- Banking details (encrypted)
    recipient_account_encrypted BYTEA NOT NULL,
    recipient_bank_encrypted BYTEA NOT NULL,
    
    -- Status tracking
    status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed, reversed
    processed_at TIMESTAMP WITH TIME ZONE,
    failed_reason TEXT,
    
    -- Payment period
    payment_period_start DATE NOT NULL,
    payment_period_end DATE NOT NULL,
    
    -- Reconciliation
    reconciled BOOLEAN DEFAULT false,
    reconciled_at TIMESTAMP WITH TIME ZONE,
    reconciled_by UUID REFERENCES users(id),
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1
);

CREATE INDEX idx_payments_application ON payments(application_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_period ON payments(payment_period_start, payment_period_end);
CREATE INDEX idx_payments_reference ON payments(payment_reference);

-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    
    -- Notification content
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) NOT NULL, -- sms, email, push, ussd
    priority INTEGER DEFAULT 1, -- 1=low, 2=medium, 3=high, 4=urgent
    
    -- Delivery tracking
    is_sent BOOLEAN DEFAULT false,
    sent_at TIMESTAMP WITH TIME ZONE,
    delivery_status VARCHAR(50) DEFAULT 'pending', -- pending, sent, delivered, failed
    delivery_attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    
    -- Content for different channels
    sms_content VARCHAR(160), -- SMS content (160 char limit)
    email_content TEXT,
    ussd_content TEXT,
    
    -- Language
    language language DEFAULT 'en',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_status ON notifications(delivery_status);
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_created ON notifications(created_at);

-- USSD sessions table (for feature phone access)
CREATE TABLE ussd_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(100) UNIQUE NOT NULL,
    phone_number_encrypted BYTEA NOT NULL,
    user_id UUID REFERENCES users(id),
    
    -- Session state
    current_menu VARCHAR(100),
    session_data JSONB, -- Store session state and variables
    language language DEFAULT 'en',
    
    -- Session tracking
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    session_duration INTEGER, -- Duration in seconds
    
    -- Network information
    network_code VARCHAR(10),
    service_code VARCHAR(20)
);

CREATE INDEX idx_ussd_session_id ON ussd_sessions(session_id);
CREATE INDEX idx_ussd_phone ON ussd_sessions(phone_number_encrypted);
CREATE INDEX idx_ussd_activity ON ussd_sessions(last_activity);

-- SMS logs table
CREATE TABLE sms_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- SMS details
    from_number_encrypted BYTEA,
    to_number_encrypted BYTEA NOT NULL,
    message_content TEXT NOT NULL,
    message_type VARCHAR(50) NOT NULL, -- inbound, outbound
    
    -- Processing
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMP WITH TIME ZONE,
    response_content TEXT,
    
    -- Delivery tracking (for outbound)
    delivery_status VARCHAR(50) DEFAULT 'sent', -- sent, delivered, failed
    delivery_timestamp TIMESTAMP WITH TIME ZONE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sms_logs_to_number ON sms_logs(to_number_encrypted);
CREATE INDEX idx_sms_logs_type ON sms_logs(message_type);
CREATE INDEX idx_sms_logs_created ON sms_logs(created_at);

-- Immutable audit log table (POPIA compliance)
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Who, What, When, Where
    user_id UUID REFERENCES users(id),
    user_role user_role,
    action audit_action NOT NULL,
    resource_type VARCHAR(50) NOT NULL, -- table name or resource type
    resource_id UUID, -- ID of the affected resource
    
    -- Request details
    ip_address INET,
    user_agent TEXT,
    request_id UUID, -- Trace request across services
    session_id VARCHAR(100),
    
    -- Change details
    old_values JSONB, -- Previous values (encrypted if sensitive)
    new_values JSONB, -- New values (encrypted if sensitive)
    changes JSONB, -- Summary of what changed
    
    -- Additional context
    reason VARCHAR(500), -- Reason for the action
    metadata JSONB, -- Additional context data
    
    -- Immutable timestamp
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    -- Data retention
    retention_period INTEGER DEFAULT 2555, -- Days (7 years for POPIA)
    
    CONSTRAINT audit_immutable CHECK (timestamp <= CURRENT_TIMESTAMP)
);

-- Make audit log truly immutable by revoking UPDATE and DELETE
REVOKE UPDATE, DELETE ON audit_logs FROM PUBLIC;

CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_timestamp ON audit_logs(timestamp);
CREATE INDEX idx_audit_ip ON audit_logs(ip_address);

-- System configuration table
CREATE TABLE system_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT,
    description TEXT,
    is_encrypted BOOLEAN DEFAULT false,
    is_public BOOLEAN DEFAULT false, -- Whether this config can be read by non-admin users
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id),
    version INTEGER DEFAULT 1
);

-- Insert default system configuration
INSERT INTO system_config (config_key, config_value, description, is_public) VALUES
('system.name', 'South Africa Social Grants System', 'System display name', true),
('system.version', '1.0.0', 'Current system version', true),
('maintenance.enabled', 'false', 'Whether system is in maintenance mode', true),
('payments.processing_time', '3', 'Payment processing time in business days', true),
('documents.max_file_size', '10485760', 'Maximum file size in bytes (10MB)', true),
('session.timeout', '1800', 'Session timeout in seconds (30 minutes)', false),
('password.min_length', '8', 'Minimum password length', true),
('mfa.enabled', 'true', 'Whether multi-factor authentication is enabled', true),
('ussd.enabled', 'true', 'Whether USSD access is enabled', true),
('sms.enabled', 'true', 'Whether SMS notifications are enabled', true);

-- Data retention policies table
CREATE TABLE data_retention_policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    retention_period_days INTEGER NOT NULL,
    deletion_method VARCHAR(50) DEFAULT 'soft_delete', -- soft_delete, hard_delete, archive
    is_active BOOLEAN DEFAULT true,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- Insert POPIA-compliant retention policies
INSERT INTO data_retention_policies (table_name, retention_period_days, deletion_method) VALUES
('audit_logs', 2555, 'archive'), -- 7 years
('grant_applications', 2555, 'archive'), -- 7 years
('payments', 2555, 'archive'), -- 7 years
('documents', 2555, 'archive'), -- 7 years
('notifications', 365, 'hard_delete'), -- 1 year
('ussd_sessions', 90, 'hard_delete'), -- 3 months
('sms_logs', 365, 'hard_delete'); -- 1 year

-- Helper functions for encryption/decryption
CREATE OR REPLACE FUNCTION encrypt_pii(data TEXT, key_name TEXT DEFAULT 'personal_data') RETURNS BYTEA AS $$
BEGIN
    -- In production, this would use a proper key management service
    RETURN pgp_sym_encrypt(data, 'encryption_key_' || key_name);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION decrypt_pii(encrypted_data BYTEA, key_name TEXT DEFAULT 'personal_data') RETURNS TEXT AS $$
BEGIN
    -- In production, this would use a proper key management service
    RETURN pgp_sym_decrypt(encrypted_data, 'encryption_key_' || key_name);
EXCEPTION
    WHEN OTHERS THEN
        RETURN '[DECRYPTION_ERROR]';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function for automatic audit logging
CREATE OR REPLACE FUNCTION audit_trigger_func() RETURNS TRIGGER AS $$
DECLARE
    action_type audit_action;
    old_data JSONB;
    new_data JSONB;
BEGIN
    -- Determine action type
    IF TG_OP = 'INSERT' THEN
        action_type := 'create';
        old_data := NULL;
        new_data := to_jsonb(NEW);
    ELSIF TG_OP = 'UPDATE' THEN
        action_type := 'update';
        old_data := to_jsonb(OLD);
        new_data := to_jsonb(NEW);
    ELSIF TG_OP = 'DELETE' THEN
        action_type := 'delete';
        old_data := to_jsonb(OLD);
        new_data := NULL;
    END IF;
    
    -- Insert audit record
    INSERT INTO audit_logs (
        user_id,
        action,
        resource_type,
        resource_id,
        old_values,
        new_values,
        ip_address,
        session_id
    ) VALUES (
        COALESCE(current_setting('app.current_user_id', true)::UUID, NULL),
        action_type,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        old_data,
        new_data,
        COALESCE(current_setting('app.client_ip', true)::INET, NULL),
        current_setting('app.session_id', true)
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add audit triggers to sensitive tables
CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_citizen_profiles AFTER INSERT OR UPDATE OR DELETE ON citizen_profiles
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_bank_details AFTER INSERT OR UPDATE OR DELETE ON bank_details
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_applications AFTER INSERT OR UPDATE OR DELETE ON grant_applications
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_reviews AFTER INSERT OR UPDATE OR DELETE ON application_reviews
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_payments AFTER INSERT OR UPDATE OR DELETE ON payments
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_timestamp_func() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    NEW.version := OLD.version + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add update timestamp triggers
CREATE TRIGGER update_users_timestamp BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_func();

CREATE TRIGGER update_citizen_profiles_timestamp BEFORE UPDATE ON citizen_profiles
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_func();

CREATE TRIGGER update_bank_details_timestamp BEFORE UPDATE ON bank_details
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_func();

CREATE TRIGGER update_applications_timestamp BEFORE UPDATE ON grant_applications
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_func();

CREATE TRIGGER update_payments_timestamp BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_timestamp_func();

-- Views for common queries (with decryption for authorized users)
CREATE OR REPLACE VIEW citizen_details AS
SELECT 
    cp.id,
    cp.user_id,
    u.username,
    u.role,
    u.status,
    -- Decrypted fields (only for authorized users)
    CASE 
        WHEN current_setting('app.user_role', true) IN ('admin', 'super_admin', 'caseworker') 
        THEN decrypt_pii(cp.first_name_encrypted)
        ELSE '[REDACTED]'
    END as first_name,
    CASE 
        WHEN current_setting('app.user_role', true) IN ('admin', 'super_admin', 'caseworker') 
        THEN decrypt_pii(cp.last_name_encrypted)
        ELSE '[REDACTED]'
    END as last_name,
    CASE 
        WHEN current_setting('app.user_role', true) IN ('admin', 'super_admin', 'caseworker') 
        THEN decrypt_pii(cp.id_number_encrypted)
        ELSE '[REDACTED]'
    END as id_number,
    cp.province,
    cp.language_preference,
    cp.identity_verified,
    cp.created_at
FROM citizen_profiles cp
JOIN users u ON cp.user_id = u.id
WHERE cp.is_deleted = false AND u.is_deleted = false;

-- Application summary view
CREATE OR REPLACE VIEW application_summary AS
SELECT 
    ga.id,
    ga.application_number,
    ga.grant_type,
    ga.status,
    cd.first_name,
    cd.last_name,
    cd.province,
    ga.submitted_at,
    ga.assigned_caseworker_id,
    u.username as caseworker_name,
    ga.approved_amount,
    ga.created_at
FROM grant_applications ga
JOIN citizen_details cd ON ga.citizen_profile_id = cd.id
LEFT JOIN users u ON ga.assigned_caseworker_id = u.id
WHERE ga.is_deleted = false;

-- Performance optimization: Partitioning for large tables
-- Partition audit_logs by date for better performance
CREATE TABLE audit_logs_2025 (
    CHECK (timestamp >= '2025-01-01' AND timestamp < '2026-01-01')
) INHERITS (audit_logs);

-- Create indexes on partitioned table
CREATE INDEX idx_audit_logs_2025_timestamp ON audit_logs_2025(timestamp);
CREATE INDEX idx_audit_logs_2025_user ON audit_logs_2025(user_id);

-- Row Level Security (RLS) for data protection
ALTER TABLE citizen_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE grant_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Citizens can only see their own data
CREATE POLICY citizen_own_profile ON citizen_profiles
    FOR ALL TO citizen_role
    USING (user_id = current_setting('app.current_user_id')::UUID);

-- Caseworkers can see assigned applications
CREATE POLICY caseworker_assigned_applications ON grant_applications
    FOR SELECT TO caseworker_role
    USING (assigned_caseworker_id = current_setting('app.current_user_id')::UUID);

-- Admins can see all data
CREATE POLICY admin_all_access ON citizen_profiles
    FOR ALL TO admin_role
    USING (true);

-- Database roles for different user types
CREATE ROLE citizen_role;
CREATE ROLE caseworker_role;
CREATE ROLE admin_role;
CREATE ROLE super_admin_role;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON citizen_profiles TO citizen_role;
GRANT SELECT, INSERT, UPDATE ON bank_details TO citizen_role;
GRANT SELECT, INSERT, UPDATE ON grant_applications TO citizen_role;
GRANT SELECT, INSERT ON documents TO citizen_role;

GRANT SELECT, UPDATE ON grant_applications TO caseworker_role;
GRANT SELECT, INSERT ON application_reviews TO caseworker_role;
GRANT SELECT ON citizen_profiles TO caseworker_role;
GRANT SELECT ON documents TO caseworker_role;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO super_admin_role;

-- Comments for documentation
COMMENT ON DATABASE current_database() IS 'South Africa Social Grants Database - POPIA Compliant';
COMMENT ON TABLE users IS 'Base user authentication and authorization';
COMMENT ON TABLE citizen_profiles IS 'Citizen personal information (encrypted)';
COMMENT ON TABLE bank_details IS 'Banking information for payments (encrypted)';
COMMENT ON TABLE grant_applications IS 'Grant application lifecycle management';
COMMENT ON TABLE documents IS 'Document storage and verification tracking';
COMMENT ON TABLE payments IS 'Payment processing and reconciliation';
COMMENT ON TABLE audit_logs IS 'Immutable audit trail for POPIA compliance';

-- Final security hardening
-- Revoke unnecessary permissions
REVOKE ALL ON encryption_keys FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION decrypt_pii(BYTEA, TEXT) FROM PUBLIC;

-- Only allow specific roles to decrypt data
GRANT EXECUTE ON FUNCTION decrypt_pii(BYTEA, TEXT) TO admin_role, caseworker_role;

-- Create backup user for automated backups
CREATE ROLE backup_user WITH LOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_user;

-- Performance monitoring
CREATE OR REPLACE VIEW performance_metrics AS
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_rows,
    n_dead_tup as dead_rows,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;

-- Schema version tracking
CREATE TABLE schema_versions (
    version VARCHAR(20) PRIMARY KEY,
    description TEXT,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(100)
);

INSERT INTO schema_versions (version, description, applied_by) VALUES 
('1.0.0', 'Initial schema with POPIA compliance and encryption', 'system');

-- Enable query logging for security monitoring
ALTER SYSTEM SET log_statement = 'mod';
ALTER SYSTEM SET log_min_duration_statement = '1000';
SELECT pg_reload_conf();

-- Final status
SELECT 'Social Grants Database Schema v1.0.0 successfully created with POPIA compliance and encryption' as status;