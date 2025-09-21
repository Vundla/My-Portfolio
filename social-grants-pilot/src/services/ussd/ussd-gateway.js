/**
 * USSD Gateway Service for Social Grants System
 * Provides USSD interface for feature phone access
 * 
 * Author: Social Grants Development Team
 * Date: 2025
 * License: Government Use Only
 */

const express = require('express');
const redis = require('redis');
const crypto = require('crypto');
const { Pool } = require('pg');

class USSDGateway {
    constructor() {
        this.app = express();
        this.redisClient = redis.createClient({
            host: process.env.REDIS_HOST || 'localhost',
            port: process.env.REDIS_PORT || 6379,
            password: process.env.REDIS_PASSWORD
        });
        
        this.dbPool = new Pool({
            host: process.env.DB_HOST,
            port: process.env.DB_PORT,
            database: process.env.DB_NAME,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            ssl: { rejectUnauthorized: false }
        });
        
        this.setupRoutes();
        this.setupLanguages();
    }

    setupLanguages() {
        this.languages = {
            'en': {
                welcome: 'Welcome to Social Grants\n1. Check Status\n2. Apply\n3. Help\n0. Exit',
                checkStatus: 'Enter ID Number:',
                apply: 'Grant Applications:\n1. Old Age\n2. Disability\n3. Child Support\n4. Care Dependency\n0. Back',
                help: 'For help call: 0800 60 10 11\nOffice hours: 8AM-4PM\n0. Back',
                invalidId: 'Invalid ID number. Try again:',
                noApplication: 'No application found',
                applicationFound: 'Status: {status}\nRef: {ref}\nDate: {date}\n0. Back',
                invalidOption: 'Invalid option. Try again:',
                sessionExpired: 'Session expired. Dial *120*3232# again',
                thankYou: 'Thank you for using Social Grants'
            },
            'af': {
                welcome: 'Welkom by Maatskaplike Toelaes\n1. Kontroleer Status\n2. Aansoek\n3. Hulp\n0. Uitgang',
                checkStatus: 'Voer ID Nommer in:',
                apply: 'Toelaag Aansoeke:\n1. Ouderdom\n2. Gestremdheid\n3. Kinderondersteuning\n4. Sorg Afhanklikheid\n0. Terug',
                help: 'Vir hulp bel: 0800 60 10 11\nKantoorure: 8VM-4NM\n0. Terug',
                invalidId: 'Ongeldige ID nommer. Probeer weer:',
                noApplication: 'Geen aansoek gevind nie',
                applicationFound: 'Status: {status}\nVerwysing: {ref}\nDatum: {date}\n0. Terug',
                invalidOption: 'Ongeldige opsie. Probeer weer:',
                sessionExpired: 'Sessie verval. Skakel *120*3232# weer',
                thankYou: 'Dankie dat u Maatskaplike Toelaes gebruik'
            },
            'zu': {
                welcome: 'Siyakwamukela ku-Social Grants\n1. Hlola Isimo\n2. Faka Isicelo\n3. Usizo\n0. Phuma',
                checkStatus: 'Faka Inombolo ye-ID:',
                apply: 'Izicelo Zezibonelelo:\n1. Ubudala\n2. Ukukhubazeka\n3. Ukusekela Ingane\n4. Ukunakekela\n0. Buyela',
                help: 'Ukuze uthole usizo shayela: 0800 60 10 11\nIhora lomsebenzi: 8AM-4PM\n0. Buyela',
                invalidId: 'Inombolo ye-ID engalungile. Zama futhi:',
                noApplication: 'Asikho isicelo esitholiwe',
                applicationFound: 'Isimo: {status}\nInkomba: {ref}\nUsuku: {date}\n0. Buyela',
                invalidOption: 'Inketho engalungile. Zama futhi:',
                sessionExpired: 'Isikhathi siphelelile. Shayela *120*3232# futhi',
                thankYou: 'Siyabonga ngokusebenzisa i-Social Grants'
            },
            'xh': {
                welcome: 'Wamkelekile kwi-Social Grants\n1. Jonga Imeko\n2. Faka Isicelo\n3. Uncedo\n0. Phuma',
                checkStatus: 'Faka Inombolo ye-ID:',
                apply: 'Izicelo Zezibonelelo:\n1. Ubudala\n2. Ukukhubazeka\n3. Inkxaso Yomntwana\n4. Ukhathalelo\n0. Buyela',
                help: 'Ukufumana uncedo cofa: 0800 60 10 11\nIixesha zomsebenzi: 8AM-4PM\n0. Buyela',
                invalidId: 'Inombolo ye-ID engahambiyo. Zama kwakhona:',
                noApplication: 'Akukho sicelo sifunyenweyo',
                applicationFound: 'Imeko: {status}\nReferensi: {ref}\nUmhla: {date}\n0. Buyela',
                invalidOption: 'Ukukhetha okungahambiyo. Zama kwakhona:',
                sessionExpired: 'Ixesha liphelile. Cofa *120*3232# kwakhona',
                thankYou: 'Enkosi ngokusebenzisa i-Social Grants'
            }
        };
    }

    setupRoutes() {
        this.app.use(express.urlencoded({ extended: true }));
        this.app.use(express.json());

        // Main USSD endpoint
        this.app.post('/ussd', async (req, res) => {
            try {
                const { sessionId, serviceCode, phoneNumber, text } = req.body;
                
                // Log request for audit
                await this.logUSSDRequest(sessionId, phoneNumber, text);
                
                const response = await this.processUSSDRequest(sessionId, phoneNumber, text);
                
                res.setHeader('Content-Type', 'text/plain');
                res.send(response);
            } catch (error) {
                console.error('USSD processing error:', error);
                res.status(500).send('END Service temporarily unavailable. Please try again later.');
            }
        });

        // Health check endpoint
        this.app.get('/health', (req, res) => {
            res.json({ status: 'healthy', timestamp: new Date().toISOString() });
        });
    }

    async processUSSDRequest(sessionId, phoneNumber, text) {
        const session = await this.getSession(sessionId);
        const inputArray = text.split('*').filter(input => input.length > 0);
        const currentInput = inputArray[inputArray.length - 1] || '';
        
        // Determine language preference
        const language = session.language || await this.detectLanguage(phoneNumber) || 'en';
        const texts = this.languages[language];

        if (text === '') {
            // Initial menu
            await this.updateSession(sessionId, { 
                step: 'main_menu', 
                language: language,
                phoneNumber: phoneNumber 
            });
            return `CON ${texts.welcome}`;
        }

        switch (session.step) {
            case 'main_menu':
                return await this.handleMainMenu(sessionId, currentInput, texts, session);
                
            case 'check_status':
                return await this.handleStatusCheck(sessionId, currentInput, texts, session);
                
            case 'apply_grant':
                return await this.handleGrantApplication(sessionId, currentInput, texts, session);
                
            case 'help':
                if (currentInput === '0') {
                    await this.updateSession(sessionId, { step: 'main_menu' });
                    return `CON ${texts.welcome}`;
                }
                return `END ${texts.help}`;
                
            default:
                return `END ${texts.sessionExpired}`;
        }
    }

    async handleMainMenu(sessionId, input, texts, session) {
        switch (input) {
            case '1':
                await this.updateSession(sessionId, { step: 'check_status' });
                return `CON ${texts.checkStatus}`;
                
            case '2':
                await this.updateSession(sessionId, { step: 'apply_grant' });
                return `CON ${texts.apply}`;
                
            case '3':
                await this.updateSession(sessionId, { step: 'help' });
                return `CON ${texts.help}`;
                
            case '0':
                await this.clearSession(sessionId);
                return `END ${texts.thankYou}`;
                
            default:
                return `CON ${texts.invalidOption}\n${texts.welcome}`;
        }
    }

    async handleStatusCheck(sessionId, input, texts, session) {
        if (input === '0') {
            await this.updateSession(sessionId, { step: 'main_menu' });
            return `CON ${texts.welcome}`;
        }

        // Validate South African ID number
        if (!this.validateSAID(input)) {
            return `CON ${texts.invalidId}`;
        }

        try {
            const application = await this.getApplicationStatus(input);
            if (application) {
                const statusText = texts.applicationFound
                    .replace('{status}', application.status)
                    .replace('{ref}', application.reference)
                    .replace('{date}', application.lastUpdated);
                return `END ${statusText}`;
            } else {
                return `END ${texts.noApplication}`;
            }
        } catch (error) {
            console.error('Error checking application status:', error);
            return `END Service error. Please try again later.`;
        }
    }

    async handleGrantApplication(sessionId, input, texts, session) {
        if (input === '0') {
            await this.updateSession(sessionId, { step: 'main_menu' });
            return `CON ${texts.welcome}`;
        }

        const grantTypes = {
            '1': 'OLD_AGE',
            '2': 'DISABILITY',
            '3': 'CHILD_SUPPORT',
            '4': 'CARE_DEPENDENCY'
        };

        if (grantTypes[input]) {
            // In a full implementation, this would start the application process
            // For now, we'll direct them to visit an office
            const message = this.getApplicationInstructions(grantTypes[input], texts.language);
            return `END ${message}`;
        } else {
            return `CON ${texts.invalidOption}\n${texts.apply}`;
        }
    }

    getApplicationInstructions(grantType, language) {
        const instructions = {
            'en': {
                OLD_AGE: 'To apply for Old Age Grant:\n1. Visit nearest SASSA office\n2. Bring ID, bank details\n3. Complete form\nCall 0800 60 10 11 for info',
                DISABILITY: 'To apply for Disability Grant:\n1. Get medical assessment\n2. Visit SASSA office\n3. Bring ID, medical report\nCall 0800 60 10 11 for info',
                CHILD_SUPPORT: 'To apply for Child Support:\n1. Visit SASSA office\n2. Bring child\'s birth cert\n3. Bring your ID\nCall 0800 60 10 11 for info',
                CARE_DEPENDENCY: 'To apply for Care Dependency:\n1. Get medical assessment\n2. Visit SASSA office\n3. Bring all documents\nCall 0800 60 10 11 for info'
            }
            // Add other languages as needed
        };

        return instructions[language]?.[grantType] || instructions['en'][grantType];
    }

    validateSAID(idNumber) {
        if (!idNumber || idNumber.length !== 13) return false;
        
        // Basic South African ID validation using Luhn algorithm
        const digits = idNumber.split('').map(Number);
        let sum = 0;
        
        for (let i = 0; i < 12; i++) {
            if (i % 2 === 0) {
                sum += digits[i];
            } else {
                let doubled = digits[i] * 2;
                sum += doubled > 9 ? doubled - 9 : doubled;
            }
        }
        
        const checkDigit = (10 - (sum % 10)) % 10;
        return checkDigit === digits[12];
    }

    async getApplicationStatus(idNumber) {
        try {
            const query = `
                SELECT 
                    reference_number,
                    status,
                    TO_CHAR(updated_at, 'DD/MM/YYYY') as last_updated
                FROM applications 
                WHERE citizen_id_number = $1 
                AND status != 'CANCELLED'
                ORDER BY created_at DESC 
                LIMIT 1
            `;
            
            const result = await this.dbPool.query(query, [idNumber]);
            
            if (result.rows.length > 0) {
                return {
                    reference: result.rows[0].reference_number,
                    status: this.translateStatus(result.rows[0].status),
                    lastUpdated: result.rows[0].last_updated
                };
            }
            
            return null;
        } catch (error) {
            console.error('Database error:', error);
            throw error;
        }
    }

    translateStatus(status) {
        const statusMap = {
            'PENDING': 'Pending Review',
            'UNDER_REVIEW': 'Under Review',
            'APPROVED': 'Approved',
            'REJECTED': 'Rejected',
            'REQUIRES_INFO': 'More Info Needed'
        };
        
        return statusMap[status] || status;
    }

    async detectLanguage(phoneNumber) {
        // Simple language detection based on phone number area codes
        // This is a simplified implementation
        const areaCode = phoneNumber.substring(0, 3);
        
        const languageMap = {
            '072': 'zu', // KZN area
            '073': 'zu',
            '074': 'xh', // Eastern Cape
            '075': 'af', // Western Cape
            // Add more mappings
        };
        
        return languageMap[areaCode] || 'en';
    }

    async getSession(sessionId) {
        try {
            const session = await this.redisClient.get(`ussd_session:${sessionId}`);
            return session ? JSON.parse(session) : {};
        } catch (error) {
            console.error('Redis error:', error);
            return {};
        }
    }

    async updateSession(sessionId, data) {
        try {
            const session = await this.getSession(sessionId);
            const updatedSession = { ...session, ...data, lastActivity: Date.now() };
            
            await this.redisClient.setex(
                `ussd_session:${sessionId}`, 
                300, // 5 minute expiry
                JSON.stringify(updatedSession)
            );
        } catch (error) {
            console.error('Redis update error:', error);
        }
    }

    async clearSession(sessionId) {
        try {
            await this.redisClient.del(`ussd_session:${sessionId}`);
        } catch (error) {
            console.error('Redis delete error:', error);
        }
    }

    async logUSSDRequest(sessionId, phoneNumber, text) {
        try {
            const query = `
                INSERT INTO ussd_audit_log 
                (session_id, phone_number, request_text, timestamp, ip_address)
                VALUES ($1, $2, $3, NOW(), $4)
            `;
            
            await this.dbPool.query(query, [
                sessionId,
                this.hashPhoneNumber(phoneNumber),
                text,
                'USSD_GATEWAY'
            ]);
        } catch (error) {
            console.error('Audit log error:', error);
        }
    }

    hashPhoneNumber(phoneNumber) {
        return crypto.createHash('sha256').update(phoneNumber).digest('hex');
    }

    start(port = 3000) {
        this.app.listen(port, () => {
            console.log(`USSD Gateway running on port ${port}`);
        });
    }
}

module.exports = USSDGateway;

// If running directly
if (require.main === module) {
    const gateway = new USSDGateway();
    gateway.start(process.env.PORT || 3000);
}