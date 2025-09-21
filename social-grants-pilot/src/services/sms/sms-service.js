/**
 * SMS Service for Social Grants System
 * Handles SMS notifications and fallback functionality
 * 
 * Author: Social Grants Development Team
 * Date: 2025
 * License: Government Use Only
 */

const express = require('express');
const crypto = require('crypto');
const { Pool } = require('pg');
const axios = require('axios');

class SMSService {
    constructor() {
        this.app = express();
        this.dbPool = new Pool({
            host: process.env.DB_HOST,
            port: process.env.DB_PORT,
            database: process.env.DB_NAME,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            ssl: { rejectUnauthorized: false }
        });
        
        // SMS Gateway Configuration
        this.smsConfig = {
            provider: process.env.SMS_PROVIDER || 'bulksms', // bulksms, clickatell, etc.
            apiUrl: process.env.SMS_API_URL || 'https://api.bulksms.com/v1/messages',
            username: process.env.SMS_USERNAME,
            password: process.env.SMS_PASSWORD,
            senderId: process.env.SMS_SENDER_ID || 'SASSA'
        };
        
        this.setupRoutes();
        this.setupMessageTemplates();
        this.startScheduledJobs();
    }

    setupMessageTemplates() {
        this.templates = {
            en: {
                applicationReceived: 'Your Social Grant application {ref} has been received. You will be notified of any updates. Call 0800 60 10 11 for info.',
                applicationApproved: 'GOOD NEWS! Your Social Grant application {ref} has been APPROVED. Payment will start from {date}. SASSA',
                applicationRejected: 'Your Social Grant application {ref} was not approved. Reason: {reason}. You may reapply or appeal. Call 0800 60 10 11',
                paymentMade: 'Payment of R{amount} for {month} has been made to your account ending {account}. Ref: {ref}. SASSA',
                documentRequired: 'Additional documents needed for application {ref}: {documents}. Submit within 30 days. SASSA',
                appointmentReminder: 'Reminder: SASSA appointment on {date} at {time}, {office}. Bring ID and required documents. SASSA',
                otpCode: 'Your SASSA verification code is: {code}. Valid for 5 minutes. Do not share this code. SASSA',
                accountSuspended: 'URGENT: Your grant account has been suspended. Contact your nearest SASSA office immediately. Ref: {ref}',
                renewalDue: 'Your {grantType} grant expires on {date}. Visit SASSA office to renew before expiry. Ref: {ref}',
                statusUpdate: 'Status update for application {ref}: {status}. {action}. SASSA'
            },
            af: {
                applicationReceived: 'U Maatskaplike Toelaag aansoek {ref} is ontvang. U sal ingelig word van opdaterings. Bel 0800 60 10 11 vir inligting.',
                applicationApproved: 'GOEIE NUUS! U Maatskaplike Toelaag aansoek {ref} is GOEDGEKEUR. Betaling begin vanaf {date}. SASSA',
                applicationRejected: 'U Maatskaplike Toelaag aansoek {ref} is nie goedgekeur nie. Rede: {reason}. U kan herbesoek of appèl. Bel 0800 60 10 11',
                paymentMade: 'Betaling van R{amount} vir {month} is gemaak na u rekening eindig {account}. Verw: {ref}. SASSA',
                documentRequired: 'Addisionele dokumente benodig vir aansoek {ref}: {documents}. Indien binne 30 dae. SASSA',
                appointmentReminder: 'Herinnering: SASSA afspraak op {date} om {time}, {office}. Bring ID en vereiste dokumente. SASSA',
                otpCode: 'U SASSA verifikasiekode is: {code}. Geldig vir 5 minute. Deel nie hierdie kode nie. SASSA',
                accountSuspended: 'DRINGEND: U toelaag rekening is opgeskort. Kontak u naaste SASSA kantoor dadelik. Verw: {ref}',
                renewalDue: 'U {grantType} toelaag verval op {date}. Besoek SASSA kantoor om te vernuwe voor vervaldatum. Verw: {ref}',
                statusUpdate: 'Status opdatering vir aansoek {ref}: {status}. {action}. SASSA'
            },
            zu: {
                applicationReceived: 'Isicelo sakho se-Social Grant {ref} sitholiwe. Uzokwaziswa ngezinguquko. Shayela 0800 60 10 11 ukuze uthole ulwazi.',
                applicationApproved: 'IZINDABA EZINHLE! Isicelo sakho se-Social Grant {ref} SAMUKYELWA. Ukukhokha kuzoqala kusukela {date}. SASSA',
                applicationRejected: 'Isicelo sakho se-Social Grant {ref} asivunyiwe. Isizathu: {reason}. Ungacela futhi noma uphike. Shayela 0800 60 10 11',
                paymentMade: 'Inkokhelo ka-R{amount} ka-{month} yenziwe ku-akhawunti yakho egcina {account}. Ref: {ref}. SASSA',
                documentRequired: 'Amadokhumenti engeziwe adingeka esicetweni {ref}: {documents}. Nikeza phakathi kwamalanga angu-30. SASSA',
                appointmentReminder: 'Isikhumbuzo: Isikhathi se-SASSA ngo-{date} ngo-{time}, {office}. Letha i-ID namadokhumenti adingekayo. SASSA',
                otpCode: 'Ikhodi yakho yokuqinisekisa ye-SASSA ithi: {code}. Isebenza imizuzu emi-5. Ungabelani ngaleli khodi. SASSA',
                accountSuspended: 'OKUPHUTHUMAYO: I-akhawunti yakho yesibonelelo imisiwe. Xhumana nehhovisi le-SASSA eliseduze ngokushesha. Ref: {ref}',
                renewalDue: 'Isibonelelo sakho se-{grantType} siphela ngo-{date}. Vakashela ihhovisi le-SASSA ukuze uvuselelwe ngaphambi kokuphela. Ref: {ref}',
                statusUpdate: 'Ukubuyekezwa kwesimo sesicelo {ref}: {status}. {action}. SASSA'
            },
            xh: {
                applicationReceived: 'Isicelo sakho se-Social Grant {ref} samkelwe. Uya kwaziswa ngezintshintshiko. Biza 0800 60 10 11 ukufumana inkcazelo.',
                applicationApproved: 'IINDABA EZILUNGILEYO! Isicelo sakho se-Social Grant {ref} SAMKELWE. Ukuhlawula kuya kuqala ukusuka {date}. SASSA',
                applicationRejected: 'Isicelo sakho se-Social Grant {ref} asikhange samkelwe. Isizathu: {reason}. Ungafaka isicelo kwakhona okanye ufake izichaso. Biza 0800 60 10 11',
                paymentMade: 'Intlawulo ye-R{amount} ka-{month} yenziwe kwi-akhawunti yakho ephelela {account}. Ref: {ref}. SASSA',
                documentRequired: 'Amaxwebhu ongezelelweyo afuneka kwisicelo {ref}: {documents}. Zingenise kwiintsuku ezingama-30. SASSA',
                appointmentReminder: 'Isikhumbuzo: Idinga le-SASSA nge-{date} ngo-{time}, {office}. Zisa i-ID namaxwebhu afunekayo. SASSA',
                otpCode: 'Ikhowudi yakho yokuqinisekisa ye-SASSA ngu: {code}. Isebenza imizuzu emi-5. Ungabelani ngale khowudi. SASSA',
                accountSuspended: 'NGXAMISEKO: I-akhawunti yakho yesibonelelo inqunyaniisiwe. Qhagamshelana neofisi ye-SASSA ekufutshane ngokukhawuleza. Ref: {ref}',
                renewalDue: 'Isibonelelo sakho se-{grantType} siphelelwa ngo-{date}. Tyelela iofisi ye-SASSA ukuze sihlaziywe ngaphambi kokuphelelwa. Ref: {ref}',
                statusUpdate: 'Uhlaziyo lwemeko yesicelo {ref}: {status}. {action}. SASSA'
            }
        };
    }

    setupRoutes() {
        this.app.use(express.json());
        
        // Send SMS endpoint
        this.app.post('/send', async (req, res) => {
            try {
                const { phoneNumber, templateKey, variables, language = 'en', priority = 'normal' } = req.body;
                
                const result = await this.sendSMS(phoneNumber, templateKey, variables, language, priority);
                res.json({ success: true, messageId: result.messageId });
            } catch (error) {
                console.error('SMS send error:', error);
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // Bulk SMS endpoint
        this.app.post('/send-bulk', async (req, res) => {
            try {
                const { recipients, templateKey, variables, language = 'en' } = req.body;
                
                const results = await this.sendBulkSMS(recipients, templateKey, variables, language);
                res.json({ success: true, results });
            } catch (error) {
                console.error('Bulk SMS send error:', error);
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // SMS status webhook
        this.app.post('/webhook/status', async (req, res) => {
            try {
                await this.handleDeliveryStatus(req.body);
                res.json({ success: true });
            } catch (error) {
                console.error('Webhook error:', error);
                res.status(500).json({ success: false });
            }
        });

        // Incoming SMS handler (for two-way communication)
        this.app.post('/webhook/incoming', async (req, res) => {
            try {
                await this.handleIncomingSMS(req.body);
                res.json({ success: true });
            } catch (error) {
                console.error('Incoming SMS error:', error);
                res.status(500).json({ success: false });
            }
        });

        // Health check
        this.app.get('/health', (req, res) => {
            res.json({ status: 'healthy', timestamp: new Date().toISOString() });
        });
    }

    async sendSMS(phoneNumber, templateKey, variables = {}, language = 'en', priority = 'normal') {
        try {
            // Get message template
            const message = this.getMessageTemplate(templateKey, variables, language);
            
            // Validate phone number
            const validatedNumber = this.validateAndFormatPhoneNumber(phoneNumber);
            
            // Check for opt-out status
            const isOptedOut = await this.checkOptOutStatus(validatedNumber);
            if (isOptedOut) {
                throw new Error('User has opted out of SMS notifications');
            }

            // Check rate limiting
            const rateLimited = await this.checkRateLimit(validatedNumber);
            if (rateLimited) {
                throw new Error('Rate limit exceeded for this number');
            }

            // Send via SMS gateway
            const result = await this.sendViaSMSGateway(validatedNumber, message, priority);
            
            // Log the SMS
            await this.logSMS(validatedNumber, message, templateKey, result.messageId, 'SENT');
            
            return result;
        } catch (error) {
            await this.logSMS(phoneNumber, '', templateKey, null, 'FAILED', error.message);
            throw error;
        }
    }

    async sendBulkSMS(recipients, templateKey, variables = {}, language = 'en') {
        const results = [];
        const batchSize = 100; // Process in batches
        
        for (let i = 0; i < recipients.length; i += batchSize) {
            const batch = recipients.slice(i, i + batchSize);
            const batchPromises = batch.map(async (recipient) => {
                try {
                    const result = await this.sendSMS(
                        recipient.phoneNumber, 
                        templateKey, 
                        { ...variables, ...recipient.variables }, 
                        recipient.language || language
                    );
                    return { phoneNumber: recipient.phoneNumber, success: true, messageId: result.messageId };
                } catch (error) {
                    return { phoneNumber: recipient.phoneNumber, success: false, error: error.message };
                }
            });
            
            const batchResults = await Promise.all(batchPromises);
            results.push(...batchResults);
            
            // Small delay between batches to avoid overwhelming the gateway
            if (i + batchSize < recipients.length) {
                await new Promise(resolve => setTimeout(resolve, 1000));
            }
        }
        
        return results;
    }

    getMessageTemplate(templateKey, variables, language) {
        const template = this.templates[language]?.[templateKey] || this.templates['en'][templateKey];
        
        if (!template) {
            throw new Error(`Template not found: ${templateKey}`);
        }

        let message = template;
        
        // Replace variables in the template
        Object.keys(variables).forEach(key => {
            const regex = new RegExp(`{${key}}`, 'g');
            message = message.replace(regex, variables[key]);
        });

        return message;
    }

    validateAndFormatPhoneNumber(phoneNumber) {
        // Remove all non-digit characters
        const digits = phoneNumber.replace(/\D/g, '');
        
        // Handle South African phone numbers
        if (digits.startsWith('27')) {
            return '+' + digits;
        } else if (digits.startsWith('0')) {
            return '+27' + digits.substring(1);
        } else if (digits.length === 9) {
            return '+27' + digits;
        }
        
        throw new Error('Invalid South African phone number format');
    }

    async checkOptOutStatus(phoneNumber) {
        try {
            const query = 'SELECT opted_out FROM sms_preferences WHERE phone_number = $1';
            const result = await this.dbPool.query(query, [phoneNumber]);
            
            return result.rows.length > 0 && result.rows[0].opted_out;
        } catch (error) {
            console.error('Error checking opt-out status:', error);
            return false;
        }
    }

    async checkRateLimit(phoneNumber) {
        try {
            const query = `
                SELECT COUNT(*) as count 
                FROM sms_log 
                WHERE phone_number = $1 
                AND created_at > NOW() - INTERVAL '1 hour'
                AND status = 'SENT'
            `;
            
            const result = await this.dbPool.query(query, [phoneNumber]);
            const hourlyCount = parseInt(result.rows[0].count);
            
            // Limit to 10 SMS per hour per number
            return hourlyCount >= 10;
        } catch (error) {
            console.error('Error checking rate limit:', error);
            return false;
        }
    }

    async sendViaSMSGateway(phoneNumber, message, priority) {
        const messageId = crypto.randomUUID();
        
        try {
            let response;
            
            switch (this.smsConfig.provider) {
                case 'bulksms':
                    response = await this.sendViaBulkSMS(phoneNumber, message, messageId);
                    break;
                case 'clickatell':
                    response = await this.sendViaClickatell(phoneNumber, message, messageId);
                    break;
                default:
                    throw new Error(`Unsupported SMS provider: ${this.smsConfig.provider}`);
            }
            
            return { messageId, gatewayResponse: response };
        } catch (error) {
            console.error('SMS gateway error:', error);
            throw new Error(`Failed to send SMS: ${error.message}`);
        }
    }

    async sendViaBulkSMS(phoneNumber, message, messageId) {
        const payload = {
            to: phoneNumber,
            body: message,
            from: this.smsConfig.senderId,
            clientMessageId: messageId
        };

        const auth = Buffer.from(`${this.smsConfig.username}:${this.smsConfig.password}`).toString('base64');

        const response = await axios.post(this.smsConfig.apiUrl, payload, {
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Basic ${auth}`
            }
        });

        return response.data;
    }

    async sendViaClickatell(phoneNumber, message, messageId) {
        // Implement Clickatell SMS sending
        const payload = {
            messages: [{
                channel: 'sms',
                to: phoneNumber,
                content: message,
                clientMessageId: messageId
            }]
        };

        const response = await axios.post(this.smsConfig.apiUrl, payload, {
            headers: {
                'Content-Type': 'application/json',
                'Authorization': this.smsConfig.apiKey
            }
        });

        return response.data;
    }

    async logSMS(phoneNumber, message, templateKey, messageId, status, error = null) {
        try {
            const query = `
                INSERT INTO sms_log 
                (message_id, phone_number_hash, message_content, template_key, status, error_message, created_at)
                VALUES ($1, $2, $3, $4, $5, $6, NOW())
            `;
            
            const phoneHash = crypto.createHash('sha256').update(phoneNumber).digest('hex');
            
            await this.dbPool.query(query, [
                messageId,
                phoneHash,
                message.substring(0, 500), // Truncate long messages
                templateKey,
                status,
                error
            ]);
        } catch (dbError) {
            console.error('Error logging SMS:', dbError);
        }
    }

    async handleDeliveryStatus(statusData) {
        // Handle delivery status updates from SMS gateway
        try {
            const { messageId, status, timestamp } = statusData;
            
            const query = `
                UPDATE sms_log 
                SET delivery_status = $1, delivered_at = $2 
                WHERE message_id = $3
            `;
            
            await this.dbPool.query(query, [status, timestamp, messageId]);
            
            // Trigger any necessary follow-up actions based on delivery status
            if (status === 'FAILED') {
                await this.handleFailedDelivery(messageId);
            }
        } catch (error) {
            console.error('Error handling delivery status:', error);
        }
    }

    async handleIncomingSMS(incomingData) {
        // Handle incoming SMS messages (for two-way communication)
        try {
            const { from, message, timestamp } = incomingData;
            
            // Log incoming message
            await this.logIncomingSMS(from, message, timestamp);
            
            // Process commands
            const response = await this.processIncomingMessage(from, message.trim().toUpperCase());
            
            if (response) {
                await this.sendSMS(from, 'statusUpdate', { status: response }, 'en');
            }
        } catch (error) {
            console.error('Error handling incoming SMS:', error);
        }
    }

    async processIncomingMessage(phoneNumber, message) {
        switch (message) {
            case 'STOP':
            case 'UNSUBSCRIBE':
                await this.handleOptOut(phoneNumber);
                return 'You have been unsubscribed from SMS notifications. Send START to resubscribe.';
                
            case 'START':
            case 'SUBSCRIBE':
                await this.handleOptIn(phoneNumber);
                return 'You have been subscribed to SMS notifications. Send STOP to unsubscribe.';
                
            case 'STATUS':
                return await this.getStatusViaPhone(phoneNumber);
                
            case 'HELP':
                return 'Commands: STATUS (check application), STOP (unsubscribe), START (subscribe), HELP (this message)';
                
            default:
                return 'Unknown command. Send HELP for available commands.';
        }
    }

    async handleOptOut(phoneNumber) {
        const query = `
            INSERT INTO sms_preferences (phone_number, opted_out, updated_at)
            VALUES ($1, true, NOW())
            ON CONFLICT (phone_number) 
            DO UPDATE SET opted_out = true, updated_at = NOW()
        `;
        
        await this.dbPool.query(query, [phoneNumber]);
    }

    async handleOptIn(phoneNumber) {
        const query = `
            INSERT INTO sms_preferences (phone_number, opted_out, updated_at)
            VALUES ($1, false, NOW())
            ON CONFLICT (phone_number) 
            DO UPDATE SET opted_out = false, updated_at = NOW()
        `;
        
        await this.dbPool.query(query, [phoneNumber]);
    }

    async getStatusViaPhone(phoneNumber) {
        try {
            // Look up citizen by phone number and get their latest application status
            const query = `
                SELECT a.reference_number, a.status, a.grant_type
                FROM applications a
                JOIN citizens c ON a.citizen_id = c.id
                WHERE c.phone_number = $1
                ORDER BY a.created_at DESC
                LIMIT 1
            `;
            
            const result = await this.dbPool.query(query, [phoneNumber]);
            
            if (result.rows.length > 0) {
                const app = result.rows[0];
                return `Application ${app.reference_number} for ${app.grant_type}: ${app.status}`;
            } else {
                return 'No application found for this phone number.';
            }
        } catch (error) {
            console.error('Error getting status via phone:', error);
            return 'Unable to retrieve status. Please try again later.';
        }
    }

    async logIncomingSMS(phoneNumber, message, timestamp) {
        try {
            const query = `
                INSERT INTO incoming_sms_log 
                (phone_number_hash, message_content, received_at)
                VALUES ($1, $2, $3)
            `;
            
            const phoneHash = crypto.createHash('sha256').update(phoneNumber).digest('hex');
            
            await this.dbPool.query(query, [phoneHash, message, timestamp]);
        } catch (error) {
            console.error('Error logging incoming SMS:', error);
        }
    }

    async handleFailedDelivery(messageId) {
        // Implement retry logic or alternative delivery methods
        try {
            const query = 'SELECT * FROM sms_log WHERE message_id = $1';
            const result = await this.dbPool.query(query, [messageId]);
            
            if (result.rows.length > 0) {
                const smsRecord = result.rows[0];
                
                // Could implement alternative delivery methods here
                // For now, just log the failure
                console.log(`SMS delivery failed for message ${messageId}`);
            }
        } catch (error) {
            console.error('Error handling failed delivery:', error);
        }
    }

    startScheduledJobs() {
        // Cleanup old SMS logs (older than 2 years)
        setInterval(async () => {
            try {
                const query = `
                    DELETE FROM sms_log 
                    WHERE created_at < NOW() - INTERVAL '2 years'
                `;
                await this.dbPool.query(query);
            } catch (error) {
                console.error('Error cleaning up SMS logs:', error);
            }
        }, 24 * 60 * 60 * 1000); // Daily

        // Retry failed SMS (with exponential backoff)
        setInterval(async () => {
            try {
                const query = `
                    SELECT * FROM sms_log 
                    WHERE status = 'FAILED' 
                    AND retry_count < 3 
                    AND created_at > NOW() - INTERVAL '1 day'
                `;
                
                const result = await this.dbPool.query(query);
                
                for (const smsRecord of result.rows) {
                    // Implement retry logic here
                    console.log(`Retrying SMS ${smsRecord.message_id}`);
                }
            } catch (error) {
                console.error('Error retrying failed SMS:', error);
            }
        }, 15 * 60 * 1000); // Every 15 minutes
    }

    start(port = 3001) {
        this.app.listen(port, () => {
            console.log(`SMS Service running on port ${port}`);
        });
    }
}

module.exports = SMSService;

// If running directly
if (require.main === module) {
    const smsService = new SMSService();
    smsService.start(process.env.PORT || 3001);
}