# USSD Integration for Social Grants System
**Enabling Feature Phone Access for Digital Inclusion**

## Overview

This USSD (Unstructured Supplementary Service Data) integration enables South African citizens with basic feature phones to access the Social Grants system without requiring internet connectivity or smartphones. This is crucial for digital inclusion as many grant beneficiaries may not have access to modern smartphones or reliable internet.

## USSD Service Design

### Service Code: *134*7777#

This memorable short code follows South African telecommunications standards and is easy for citizens to remember.

### Supported Languages
- **English** (en) - Primary
- **Afrikaans** (af) - Secondary  
- **Zulu** (zu) - IsiZulu
- **Xhosa** (xh) - IsiXhosa

### Session Management
- **Session Timeout**: 120 seconds of inactivity
- **Maximum Menu Depth**: 4 levels
- **Character Limit**: 160 characters per message
- **Response Time**: <3 seconds per interaction

## USSD Menu Structure

### Main Menu
```
*134*7777#

Sawubona! Welcome to Social Grants
Welkom by Maatskaplike Toelaes

1. Check Application Status
   Hlola Isimo Sesicelo
   
2. Apply for Grant
   Faka Isicelo Setulawa
   
3. Update Profile
   Buyekeza Iphrofayili
   
4. Payment Info
   Ulwazi Lweenkokhelo
   
5. Help & Support
   Usizo Nenkxaso
   
0. Language | Ulimi | Olulwimi
```

### 1. Check Application Status
```
Enter ID Number:
Faka Inombolo Yesazisi:
_____________ (13 digits)

Reply: 8001010000087
```

Response Options:
```
Status: APPROVED ✓
Isimo: SIVUNYIWE ✓

Grant: Child Support R480
Amount: Monthly payment
Next Payment: 2025-02-01

1. Payment Details
2. Back to Main Menu
0. Help
```

### 2. Apply for Grant (Simplified)
```
New Application:
Isicelo Esisha:

Select Grant Type:
1. Old Age Pension (60+)
2. Disability Grant  
3. Child Support Grant
4. Other Grants

Reply with number (1-4):
```

For each grant type:
```
Child Support Grant:

Requirements:
- Child under 18
- SA ID Document
- Proof of income
- Bank details

To continue, visit office with:
- Your SA ID
- Child's birth certificate
- Bank statement

Nearest Office:
Johannesburg DSD
123 Main St
Tel: 011-123-4567

1. Find Other Offices
2. Back to Menu
```

### 3. Update Profile
```
Update Profile:
Buyekeza Iphrofayili:

Enter ID Number:
_____________ (13 digits)

What to update:
1. Phone Number
2. Address
3. Bank Details
4. Emergency Contact

Reply with number (1-4):
```

### 4. Payment Information
```
Payment Info:
Ulwazi Lweenkokhelo:

Enter ID Number:
_____________

Last Payment: R480
Date: 2025-01-15
Method: Bank Transfer
Status: Successful ✓

Next Payment: 2025-02-15
Account: ****1234

1. Payment History
2. Update Bank Details
3. Report Problem
0. Back to Menu
```

### 5. Help & Support
```
Help & Support:
Usizo Nenkxaso:

1. Common Questions
2. Contact Information  
3. Office Locations
4. Emergency Contact
5. Language Help

Select option (1-5):
```

## Technical Implementation

### USSD Gateway Integration

```javascript
// USSD Service Handler
class USSDService {
    constructor() {
        this.sessions = new Map();
        this.translations = new TranslationService();
        this.grantService = new GrantService();
    }

    async handleUSSDRequest(req, res) {
        const { sessionId, phoneNumber, text, networkCode } = req.body;
        
        try {
            // Get or create session
            let session = this.getSession(sessionId);
            if (!session) {
                session = this.createSession(sessionId, phoneNumber, networkCode);
            }
            
            // Process user input
            const response = await this.processInput(session, text);
            
            // Update session
            this.updateSession(session, text, response);
            
            // Format response for USSD gateway
            const ussdResponse = this.formatResponse(response, session.language);
            
            res.setHeader('Content-Type', 'text/plain');
            res.send(ussdResponse);
            
        } catch (error) {
            console.error('USSD Error:', error);
            res.send('CON Service temporarily unavailable. Please try again later.');
        }
    }

    createSession(sessionId, phoneNumber, networkCode) {
        const session = {
            id: sessionId,
            phoneNumber: phoneNumber,
            networkCode: networkCode,
            language: 'en', // Default to English
            currentMenu: 'main',
            menuHistory: [],
            userData: {},
            createdAt: new Date(),
            lastActivity: new Date()
        };
        
        this.sessions.set(sessionId, session);
        return session;
    }

    async processInput(session, input) {
        session.lastActivity = new Date();
        
        // Handle language selection first
        if (session.currentMenu === 'language') {
            return this.handleLanguageSelection(session, input);
        }
        
        // Route to appropriate handler based on current menu
        switch (session.currentMenu) {
            case 'main':
                return this.handleMainMenu(session, input);
            case 'check_status':
                return this.handleCheckStatus(session, input);
            case 'apply_grant':
                return this.handleApplyGrant(session, input);
            case 'update_profile':
                return this.handleUpdateProfile(session, input);
            case 'payment_info':
                return this.handlePaymentInfo(session, input);
            case 'help':
                return this.handleHelp(session, input);
            default:
                return this.handleMainMenu(session, input);
        }
    }

    handleMainMenu(session, input) {
        if (!input || input === '') {
            // First interaction - show main menu
            return this.getMainMenu(session.language);
        }
        
        switch (input) {
            case '1':
                session.currentMenu = 'check_status';
                return this.getCheckStatusMenu(session.language);
            case '2':
                session.currentMenu = 'apply_grant';
                return this.getApplyGrantMenu(session.language);
            case '3':
                session.currentMenu = 'update_profile';
                return this.getUpdateProfileMenu(session.language);
            case '4':
                session.currentMenu = 'payment_info';
                return this.getPaymentInfoMenu(session.language);
            case '5':
                session.currentMenu = 'help';
                return this.getHelpMenu(session.language);
            case '0':
                session.currentMenu = 'language';
                return this.getLanguageMenu();
            default:
                return this.getErrorMessage(session.language, 'invalid_option');
        }
    }

    async handleCheckStatus(session, input) {
        // Validate SA ID number
        if (!this.isValidSAId(input)) {
            return this.getErrorMessage(session.language, 'invalid_id');
        }
        
        try {
            // Look up application status
            const applications = await this.grantService.getApplicationsByIdNumber(input);
            
            if (applications.length === 0) {
                return this.formatMessage(session.language, 'no_applications_found');
            }
            
            // Show most recent application
            const latest = applications[0];
            return this.formatApplicationStatus(latest, session.language);
            
        } catch (error) {
            console.error('Error checking status:', error);
            return this.getErrorMessage(session.language, 'service_error');
        }
    }

    formatResponse(response, language) {
        // USSD responses must start with CON (continue) or END (terminate)
        if (response.terminate) {
            return `END ${response.message}`;
        } else {
            return `CON ${response.message}`;
        }
    }

    getMainMenu(language = 'en') {
        const messages = {
            en: `Sawubona! Welcome to Social Grants

1. Check Application Status
2. Apply for Grant
3. Update Profile
4. Payment Info
5. Help & Support
0. Language`,
            
            af: `Welkom by Maatskaplike Toelaes

1. Kontroleer Aansoekstatus
2. Aansoek om Toelae
3. Dateer Profiel op
4. Betalinginligting
5. Hulp en Ondersteuning
0. Taal`,
            
            zu: `Sawubona! Siyakwamukela ku-Social Grants

1. Hlola Isimo Sesicelo
2. Faka Isicelo Setulawa
3. Buyekeza Iphrofayili
4. Ulwazi Lweenkokhelo
5. Usizo Nenkxaso
0. Ulimi`,
            
            xh: `Molo! Wamkelekile kwi-Social Grants

1. Khangela Imeko Yesicelo
2. Faka Isicelo Senkxaso
3. Hlaziya Iprofayile
4. Ulwazi Lweentlawulo
5. Uncedo Nenkxaso
0. Ulwimi`
        };
        
        return {
            message: messages[language] || messages.en,
            terminate: false
        };
    }

    getCheckStatusMenu(language = 'en') {
        const messages = {
            en: `Check Application Status

Enter your 13-digit SA ID number:`,
            af: `Kontroleer Aansoekstatus

Voer jou 13-syfer SA ID-nommer in:`,
            zu: `Hlola Isimo Sesicelo

Faka inombolo yakho ye-SA ID enemizuzu eyi-13:`,
            xh: `Khangela Imeko Yesicelo

Faka inombolo yakho ye-SA ID enemizuzu eyi-13:`
        };
        
        return {
            message: messages[language] || messages.en,
            terminate: false
        };
    }

    formatApplicationStatus(application, language = 'en') {
        const statusTranslations = {
            en: {
                'submitted': 'SUBMITTED',
                'under_review': 'UNDER REVIEW',
                'approved': 'APPROVED ✓',
                'rejected': 'REJECTED',
                'payment_pending': 'PAYMENT PENDING'
            },
            af: {
                'submitted': 'INGEDIEN',
                'under_review': 'ONDER HERSIENIG',
                'approved': 'GOEDGEKEUR ✓',
                'rejected': 'VERWERP',
                'payment_pending': 'BETALING HANGEND'
            },
            zu: {
                'submitted': 'KUTHUNYELWE',
                'under_review': 'KUBUYEKEZWA',
                'approved': 'KWAMUKELWA ✓',
                'rejected': 'KWENQATSHWA',
                'payment_pending': 'UKUKHOKHA KULINDILE'
            },
            xh: {
                'submitted': 'ITHUNYELWE',
                'under_review': 'IPHANTSI KOPHANDO',
                'approved': 'YAMKELWE ✓',
                'rejected': 'YALIWE',
                'payment_pending': 'INTLAWULO ILINDILE'
            }
        };
        
        const grantTypeTranslations = {
            en: {
                'old_age_pension': 'Old Age Pension',
                'disability_grant': 'Disability Grant',
                'child_support_grant': 'Child Support Grant'
            },
            af: {
                'old_age_pension': 'Ouderdomspensioen',
                'disability_grant': 'Gestremdheidstoelaag',
                'child_support_grant': 'Kinderondersteuningtoelaag'
            },
            zu: {
                'old_age_pension': 'Impesheni Yabantu Abadala',
                'disability_grant': 'Isibonelelo Sokukhubazeka',
                'child_support_grant': 'Isibonelelo Sokuseka Ingane'
            },
            xh: {
                'old_age_pension': 'Umhlala-phantsi Wabantu Abadala',
                'disability_grant': 'Isibonelelo Sokukhubazeka',
                'child_support_grant': 'Isibonelelo Senkxaso Yomntwana'
            }
        };
        
        const status = statusTranslations[language][application.status] || application.status;
        const grantType = grantTypeTranslations[language][application.grant_type] || application.grant_type;
        
        let message = '';
        
        if (language === 'en') {
            message = `Status: ${status}
Grant: ${grantType}
Amount: R${application.approved_amount || 'TBD'}

`;
            if (application.next_payment_date) {
                message += `Next Payment: ${application.next_payment_date}

`;
            }
            message += `1. Payment Details
2. Back to Main Menu
0. Help`;
        } else if (language === 'af') {
            message = `Status: ${status}
Toelae: ${grantType}
Bedrag: R${application.approved_amount || 'TBB'}

`;
            if (application.next_payment_date) {
                message += `Volgende Betaling: ${application.next_payment_date}

`;
            }
            message += `1. Betalingbesonderhede
2. Terug na Hoofkieslys
0. Hulp`;
        }
        // Add other language implementations...
        
        return {
            message: message,
            terminate: false
        };
    }

    isValidSAId(idNumber) {
        // Basic SA ID validation
        if (!idNumber || idNumber.length !== 13) return false;
        if (!/^\d{13}$/.test(idNumber)) return false;
        
        // Luhn algorithm check
        let sum = 0;
        for (let i = 0; i < 12; i++) {
            let digit = parseInt(idNumber[i]);
            if (i % 2 === 1) {
                digit *= 2;
                if (digit > 9) digit = Math.floor(digit / 10) + (digit % 10);
            }
            sum += digit;
        }
        
        const checkDigit = (10 - (sum % 10)) % 10;
        return checkDigit === parseInt(idNumber[12]);
    }

    // Session cleanup
    cleanupSessions() {
        const now = new Date();
        const timeout = 2 * 60 * 1000; // 2 minutes
        
        for (const [sessionId, session] of this.sessions) {
            if (now - session.lastActivity > timeout) {
                this.sessions.delete(sessionId);
            }
        }
    }
}
```

### SMS Fallback Integration

```javascript
// SMS Fallback Service
class SMSFallbackService {
    constructor() {
        this.smsGateway = new SMSGateway();
        this.grantService = new GrantService();
    }

    async handleIncomingSMS(from, to, message) {
        const phoneNumber = this.normalizePhoneNumber(from);
        const command = message.trim().toUpperCase();
        
        try {
            if (command.startsWith('STATUS')) {
                return await this.handleStatusCheck(phoneNumber, command);
            } else if (command.startsWith('HELP')) {
                return await this.handleHelp(phoneNumber);
            } else if (command.startsWith('LANG')) {
                return await this.handleLanguageChange(phoneNumber, command);
            } else {
                return await this.handleUnknownCommand(phoneNumber);
            }
        } catch (error) {
            console.error('SMS Error:', error);
            return this.sendErrorSMS(phoneNumber);
        }
    }

    async handleStatusCheck(phoneNumber, command) {
        // Extract ID number from command: "STATUS 8001010000087"
        const parts = command.split(' ');
        if (parts.length < 2) {
            return this.sendSMS(phoneNumber, 
                'To check status, SMS: STATUS [your 13-digit ID number]');
        }
        
        const idNumber = parts[1];
        if (!this.isValidSAId(idNumber)) {
            return this.sendSMS(phoneNumber, 
                'Invalid ID number. Please check and try again.');
        }
        
        const applications = await this.grantService.getApplicationsByIdNumber(idNumber);
        if (applications.length === 0) {
            return this.sendSMS(phoneNumber, 
                'No applications found for this ID number.');
        }
        
        const latest = applications[0];
        const message = `Status: ${latest.status.toUpperCase()}
Grant: ${latest.grant_type}
Amount: R${latest.approved_amount || 'TBD'}
Ref: ${latest.application_number}`;
        
        return this.sendSMS(phoneNumber, message);
    }

    async sendSMS(phoneNumber, message) {
        return await this.smsGateway.send({
            to: phoneNumber,
            message: message,
            from: 'SocialGrants'
        });
    }
}
```

### Database Integration

```sql
-- USSD Sessions Table
CREATE TABLE ussd_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(100) UNIQUE NOT NULL,
    phone_number_encrypted BYTEA NOT NULL,
    user_id UUID REFERENCES users(id),
    
    -- Session state
    current_menu VARCHAR(100),
    menu_history JSONB DEFAULT '[]',
    session_data JSONB DEFAULT '{}',
    language VARCHAR(5) DEFAULT 'en',
    
    -- Session tracking
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    session_duration INTEGER, -- Duration in seconds
    
    -- Network information
    network_code VARCHAR(10),
    service_code VARCHAR(20) DEFAULT '*134*7777#',
    
    -- Analytics
    total_interactions INTEGER DEFAULT 1,
    successful_completion BOOLEAN DEFAULT false,
    completion_reason VARCHAR(50), -- timeout, user_exit, completed, error
    
    CONSTRAINT valid_language CHECK (language IN ('en', 'af', 'zu', 'xh'))
);

-- USSD Analytics Table
CREATE TABLE ussd_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES ussd_sessions(id),
    
    -- Menu navigation tracking
    menu_path VARCHAR(500),
    time_spent_seconds INTEGER,
    user_selection VARCHAR(10),
    
    -- Performance metrics
    response_time_ms INTEGER,
    error_occurred BOOLEAN DEFAULT false,
    error_message TEXT,
    
    -- Demographic data (encrypted)
    province VARCHAR(5),
    network_operator VARCHAR(50),
    device_type VARCHAR(50),
    
    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- SMS Fallback Logs
CREATE TABLE sms_fallback_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- SMS details
    from_number_encrypted BYTEA NOT NULL,
    to_number VARCHAR(20) NOT NULL,
    message_content TEXT NOT NULL,
    command_type VARCHAR(50), -- status, help, lang, unknown
    
    -- Processing
    processed_successfully BOOLEAN DEFAULT false,
    response_sent BOOLEAN DEFAULT false,
    response_content TEXT,
    processing_time_ms INTEGER,
    
    -- Error handling
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- Analytics
    user_id UUID REFERENCES users(id),
    grant_type VARCHAR(50),
    
    -- Timestamps
    received_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    responded_at TIMESTAMP WITH TIME ZONE
);
```

### Load Testing Configuration

```javascript
// USSD Load Testing with K6
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
    stages: [
        { duration: '2m', target: 100 }, // Ramp up to 100 users
        { duration: '5m', target: 100 }, // Stay at 100 users
        { duration: '2m', target: 200 }, // Ramp up to 200 users
        { duration: '5m', target: 200 }, // Stay at 200 users
        { duration: '2m', target: 0 },   // Ramp down to 0 users
    ],
    thresholds: {
        http_req_duration: ['p(95)<3000'], // 95% of requests must complete below 3s
        http_req_failed: ['rate<0.1'],     // Error rate must be less than 10%
    },
};

export default function() {
    // Simulate USSD session
    const sessionId = `session_${Math.random().toString(36).substr(2, 9)}`;
    const phoneNumber = `+2782${Math.floor(Math.random() * 10000000).toString().padStart(7, '0')}`;
    
    // Initial USSD request
    let response = http.post('http://localhost:3000/ussd/session', {
        sessionId: sessionId,
        phoneNumber: phoneNumber,
        text: '',
        networkCode: 'MTN'
    });
    
    check(response, {
        'status is 200': (r) => r.status === 200,
        'response time < 3s': (r) => r.timings.duration < 3000,
        'contains menu': (r) => r.body.includes('Welcome to Social Grants'),
    });
    
    sleep(2); // User reading time
    
    // Select option 1 (Check Status)
    response = http.post('http://localhost:3000/ussd/session', {
        sessionId: sessionId,
        phoneNumber: phoneNumber,
        text: '1',
        networkCode: 'MTN'
    });
    
    check(response, {
        'status check option works': (r) => r.body.includes('Enter your 13-digit'),
    });
    
    sleep(5); // User thinking time
    
    // Enter ID number
    response = http.post('http://localhost:3000/ussd/session', {
        sessionId: sessionId,
        phoneNumber: phoneNumber,
        text: '8001010000087',
        networkCode: 'MTN'
    });
    
    check(response, {
        'ID lookup works': (r) => r.status === 200,
    });
    
    sleep(1);
}
```

## Accessibility Features

### Voice Support Integration
```javascript
// Text-to-Speech for visually impaired users
class VoiceUSSDService {
    constructor() {
        this.ttsService = new TextToSpeechService();
        this.voiceRecognition = new VoiceRecognitionService();
    }

    async handleVoiceUSSD(phoneNumber, audioInput) {
        // Convert speech to text
        const text = await this.voiceRecognition.transcribe(audioInput, 'zu');
        
        // Process as normal USSD
        const response = await this.processUSSDInput(phoneNumber, text);
        
        // Convert response to speech
        const audioResponse = await this.ttsService.synthesize(
            response.message, 
            'zu', 
            'female' // Preferred voice
        );
        
        return {
            text: response.message,
            audio: audioResponse,
            continue: !response.terminate
        };
    }
}
```

### Simplified Navigation
```javascript
// Simplified menu system for elderly users
class SimplifiedUSSDMenu {
    getSimplifiedMainMenu(language = 'en') {
        const messages = {
            en: `Social Grants Help

Press:
1 - Check my grant
2 - Get help
9 - Speak to someone

Choose 1, 2, or 9:`,

            zu: `Usizo lwe-Social Grants

Cindezela:
1 - Hlola isibonelelo sami
2 - Thola usizo
9 - Khuluma nomuntu

Khetha 1, 2, noma 9:`
        };
        
        return {
            message: messages[language] || messages.en,
            terminate: false
        };
    }
}
```

## Analytics and Reporting

### USSD Usage Analytics
```sql
-- USSD Usage Report View
CREATE VIEW ussd_usage_analytics AS
SELECT 
    DATE_TRUNC('day', started_at) as date,
    language,
    network_code,
    COUNT(*) as total_sessions,
    COUNT(CASE WHEN successful_completion = true THEN 1 END) as successful_sessions,
    AVG(session_duration) as avg_duration_seconds,
    AVG(total_interactions) as avg_interactions,
    COUNT(CASE WHEN completion_reason = 'timeout' THEN 1 END) as timeout_sessions,
    COUNT(CASE WHEN completion_reason = 'error' THEN 1 END) as error_sessions
FROM ussd_sessions 
WHERE started_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', started_at), language, network_code
ORDER BY date DESC;

-- Popular Menu Paths
CREATE VIEW ussd_popular_paths AS
SELECT 
    menu_path,
    COUNT(*) as usage_count,
    AVG(time_spent_seconds) as avg_time_spent,
    language
FROM ussd_analytics 
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY menu_path, language
ORDER BY usage_count DESC
LIMIT 20;
```

## Security Considerations

### Rate Limiting
```javascript
// USSD Rate Limiting
class USSDRateLimiter {
    constructor() {
        this.phoneNumberLimits = new Map();
        this.maxSessionsPerHour = 10;
        this.maxSessionsPerDay = 50;
    }

    checkRateLimit(phoneNumber) {
        const now = Date.now();
        const key = this.hashPhoneNumber(phoneNumber);
        
        if (!this.phoneNumberLimits.has(key)) {
            this.phoneNumberLimits.set(key, {
                hourlyCount: 0,
                dailyCount: 0,
                lastHourReset: now,
                lastDayReset: now
            });
        }
        
        const limits = this.phoneNumberLimits.get(key);
        
        // Reset hourly counter
        if (now - limits.lastHourReset > 3600000) { // 1 hour
            limits.hourlyCount = 0;
            limits.lastHourReset = now;
        }
        
        // Reset daily counter
        if (now - limits.lastDayReset > 86400000) { // 24 hours
            limits.dailyCount = 0;
            limits.lastDayReset = now;
        }
        
        // Check limits
        if (limits.hourlyCount >= this.maxSessionsPerHour) {
            return { allowed: false, reason: 'hourly_limit_exceeded' };
        }
        
        if (limits.dailyCount >= this.maxSessionsPerDay) {
            return { allowed: false, reason: 'daily_limit_exceeded' };
        }
        
        // Increment counters
        limits.hourlyCount++;
        limits.dailyCount++;
        
        return { allowed: true };
    }
    
    hashPhoneNumber(phoneNumber) {
        // Hash phone number for privacy
        return crypto.createHash('sha256').update(phoneNumber).digest('hex');
    }
}
```

### Input Validation
```javascript
// USSD Input Sanitization
class USSDInputValidator {
    sanitizeInput(input) {
        if (!input) return '';
        
        // Remove non-printable characters
        let sanitized = input.replace(/[^\x20-\x7E]/g, '');
        
        // Limit length
        sanitized = sanitized.substring(0, 160);
        
        // Remove potentially dangerous characters
        sanitized = sanitized.replace(/[<>&"']/g, '');
        
        return sanitized.trim();
    }
    
    validateSAIdNumber(idNumber) {
        // Already implemented above
        return this.isValidSAId(idNumber);
    }
    
    validateMenuSelection(selection, validOptions) {
        const sanitized = this.sanitizeInput(selection);
        return validOptions.includes(sanitized);
    }
}
```

## Testing Strategy

### Unit Tests
```javascript
// Jest tests for USSD service
describe('USSDService', () => {
    let ussdService;
    
    beforeEach(() => {
        ussdService = new USSDService();
    });
    
    test('should handle main menu correctly', async () => {
        const session = ussdService.createSession('test123', '+27821234567', 'MTN');
        const response = await ussdService.processInput(session, '');
        
        expect(response.message).toContain('Welcome to Social Grants');
        expect(response.terminate).toBe(false);
    });
    
    test('should validate SA ID numbers correctly', () => {
        expect(ussdService.isValidSAId('8001010000087')).toBe(true);
        expect(ussdService.isValidSAId('1234567890123')).toBe(false);
        expect(ussdService.isValidSAId('123')).toBe(false);
    });
    
    test('should handle language switching', async () => {
        const session = ussdService.createSession('test123', '+27821234567', 'MTN');
        await ussdService.processInput(session, '0'); // Language menu
        const response = await ussdService.processInput(session, '2'); // Afrikaans
        
        expect(session.language).toBe('af');
        expect(response.message).toContain('Welkom');
    });
});
```

### Integration Tests
```javascript
// Integration tests with real USSD gateway
describe('USSD Integration', () => {
    test('should handle complete status check flow', async () => {
        const sessionId = 'integration_test_' + Date.now();
        
        // Initial request
        let response = await request(app)
            .post('/ussd/session')
            .send({
                sessionId: sessionId,
                phoneNumber: '+27821234567',
                text: '',
                networkCode: 'MTN'
            });
        
        expect(response.status).toBe(200);
        expect(response.text).toContain('CON');
        
        // Select status check
        response = await request(app)
            .post('/ussd/session')
            .send({
                sessionId: sessionId,
                phoneNumber: '+27821234567',
                text: '1',
                networkCode: 'MTN'
            });
        
        expect(response.text).toContain('Enter your 13-digit SA ID');
        
        // Enter ID number
        response = await request(app)
            .post('/ussd/session')
            .send({
                sessionId: sessionId,
                phoneNumber: '+27821234567',
                text: '8001010000087',
                networkCode: 'MTN'
            });
        
        expect(response.text).toContain('Status:');
    });
});
```

## Deployment Configuration

### Docker Configuration
```dockerfile
# USSD Service Dockerfile
FROM node:18-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY src/ ./src/
COPY config/ ./config/

# Create non-root user
RUN addgroup -S ussd && adduser -S ussd -G ussd
USER ussd

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000

CMD ["node", "src/ussd-service.js"]
```

### Kubernetes Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ussd-service
  labels:
    app: socialgrants-ussd
spec:
  replicas: 3
  selector:
    matchLabels:
      app: socialgrants-ussd
  template:
    metadata:
      labels:
        app: socialgrants-ussd
    spec:
      containers:
      - name: ussd-service
        image: socialgrants/ussd-service:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: socialgrants-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: socialgrants-secrets
              key: redis-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: ussd-service
spec:
  selector:
    app: socialgrants-ussd
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
  type: ClusterIP
```

This comprehensive USSD integration ensures that South African citizens with basic feature phones can access essential Social Grants services, supporting true digital inclusion regardless of device capability or internet connectivity.