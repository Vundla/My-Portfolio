/**
 * Payment Integration Service for Social Grants System
 * Handles sandbox and production payment processing
 * 
 * Author: Social Grants Development Team
 * Date: 2025
 * License: Government Use Only
 */

const express = require('express');
const crypto = require('crypto');
const { Pool } = require('pg');
const axios = require('axios');

class PaymentService {
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
        
        // Payment Gateway Configuration
        this.paymentConfig = {
            environment: process.env.PAYMENT_ENV || 'sandbox', // sandbox, production
            providers: {
                saswitch: {
                    apiUrl: process.env.SASWITCH_API_URL || 'https://sandbox.saswitch.co.za/api/v1',
                    institutionId: process.env.SASWITCH_INSTITUTION_ID,
                    apiKey: process.env.SASWITCH_API_KEY,
                    secretKey: process.env.SASWITCH_SECRET_KEY
                },
                masterpass: {
                    apiUrl: process.env.MASTERPASS_API_URL || 'https://sandbox.masterpass.co.za/api',
                    merchantId: process.env.MASTERPASS_MERCHANT_ID,
                    apiKey: process.env.MASTERPASS_API_KEY
                },
                eft: {
                    bankingPartner: process.env.EFT_BANKING_PARTNER || 'ABSA',
                    apiUrl: process.env.EFT_API_URL,
                    clientId: process.env.EFT_CLIENT_ID,
                    clientSecret: process.env.EFT_CLIENT_SECRET
                }
            }
        };
        
        this.setupRoutes();
        this.setupFraudDetection();
        this.startScheduledJobs();
    }

    setupRoutes() {
        this.app.use(express.json());
        this.app.use(express.urlencoded({ extended: true }));

        // Process grant payment
        this.app.post('/process-payment', async (req, res) => {
            try {
                const { grantId, amount, paymentMethod, recipient } = req.body;
                
                const result = await this.processGrantPayment(grantId, amount, paymentMethod, recipient);
                res.json({ success: true, ...result });
            } catch (error) {
                console.error('Payment processing error:', error);
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // Batch payment processing
        this.app.post('/process-batch', async (req, res) => {
            try {
                const { payments, paymentRun } = req.body;
                
                const result = await this.processBatchPayments(payments, paymentRun);
                res.json({ success: true, ...result });
            } catch (error) {
                console.error('Batch payment error:', error);
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // Payment verification
        this.app.post('/verify-payment', async (req, res) => {
            try {
                const { paymentId, bankReference } = req.body;
                
                const result = await this.verifyPayment(paymentId, bankReference);
                res.json({ success: true, ...result });
            } catch (error) {
                console.error('Payment verification error:', error);
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // Payment reconciliation
        this.app.post('/reconcile', async (req, res) => {
            try {
                const { date, provider } = req.body;
                
                const result = await this.reconcilePayments(date, provider);
                res.json({ success: true, ...result });
            } catch (error) {
                console.error('Reconciliation error:', error);
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // Payment status webhook
        this.app.post('/webhook/payment-status', async (req, res) => {
            try {
                const signature = req.headers['x-payment-signature'];
                const isValid = await this.verifyWebhookSignature(req.body, signature);
                
                if (!isValid) {
                    return res.status(401).json({ error: 'Invalid signature' });
                }

                await this.handlePaymentStatusUpdate(req.body);
                res.json({ success: true });
            } catch (error) {
                console.error('Webhook error:', error);
                res.status(500).json({ success: false });
            }
        });

        // Fraud detection endpoint
        this.app.post('/fraud-check', async (req, res) => {
            try {
                const { payment } = req.body;
                
                const result = await this.performFraudCheck(payment);
                res.json({ success: true, ...result });
            } catch (error) {
                console.error('Fraud check error:', error);
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // Payment history
        this.app.get('/payment-history/:citizenId', async (req, res) => {
            try {
                const { citizenId } = req.params;
                const { page = 1, limit = 20 } = req.query;
                
                const result = await this.getPaymentHistory(citizenId, page, limit);
                res.json({ success: true, ...result });
            } catch (error) {
                console.error('Payment history error:', error);
                res.status(500).json({ success: false, error: error.message });
            }
        });

        // Health check
        this.app.get('/health', (req, res) => {
            res.json({ status: 'healthy', timestamp: new Date().toISOString() });
        });
    }

    async processGrantPayment(grantId, amount, paymentMethod = 'eft', recipient) {
        const paymentId = crypto.randomUUID();
        
        try {
            // Create payment record
            const payment = await this.createPaymentRecord(paymentId, grantId, amount, paymentMethod, recipient);
            
            // Perform fraud check
            const fraudCheck = await this.performFraudCheck(payment);
            if (fraudCheck.riskLevel === 'HIGH') {
                await this.flagPaymentForReview(paymentId, fraudCheck.reasons);
                throw new Error('Payment flagged for manual review due to fraud risk');
            }
            
            // Validate recipient bank details
            const bankValidation = await this.validateBankDetails(recipient.bankDetails);
            if (!bankValidation.valid) {
                throw new Error(`Invalid bank details: ${bankValidation.reason}`);
            }
            
            // Process payment based on method
            let result;
            switch (paymentMethod.toLowerCase()) {
                case 'eft':
                    result = await this.processEFTPayment(payment);
                    break;
                case 'card':
                    result = await this.processCardPayment(payment);
                    break;
                case 'cash':
                    result = await this.processCashPayment(payment);
                    break;
                default:
                    throw new Error(`Unsupported payment method: ${paymentMethod}`);
            }
            
            // Update payment status
            await this.updatePaymentStatus(paymentId, 'SUBMITTED', result.transactionId);
            
            // Log successful payment
            await this.logPaymentActivity(paymentId, 'PAYMENT_SUBMITTED', result);
            
            return {
                paymentId,
                transactionId: result.transactionId,
                status: 'SUBMITTED',
                estimatedSettlement: result.estimatedSettlement
            };
            
        } catch (error) {
            await this.updatePaymentStatus(paymentId, 'FAILED', null, error.message);
            await this.logPaymentActivity(paymentId, 'PAYMENT_FAILED', { error: error.message });
            throw error;
        }
    }

    async processBatchPayments(payments, paymentRun) {
        const batchId = crypto.randomUUID();
        const results = [];
        
        try {
            // Create batch record
            await this.createBatchRecord(batchId, paymentRun, payments.length);
            
            // Process payments in chunks
            const chunkSize = 100;
            for (let i = 0; i < payments.length; i += chunkSize) {
                const chunk = payments.slice(i, i + chunkSize);
                
                const chunkPromises = chunk.map(async (payment) => {
                    try {
                        const result = await this.processGrantPayment(
                            payment.grantId,
                            payment.amount,
                            payment.paymentMethod,
                            payment.recipient
                        );
                        return { ...payment, success: true, ...result };
                    } catch (error) {
                        return { ...payment, success: false, error: error.message };
                    }
                });
                
                const chunkResults = await Promise.all(chunkPromises);
                results.push(...chunkResults);
                
                // Update batch progress
                await this.updateBatchProgress(batchId, i + chunk.length, payments.length);
            }
            
            // Finalize batch
            const successCount = results.filter(r => r.success).length;
            const failureCount = results.length - successCount;
            
            await this.finalizeBatch(batchId, successCount, failureCount, results);
            
            return {
                batchId,
                totalPayments: payments.length,
                successCount,
                failureCount,
                results
            };
            
        } catch (error) {
            await this.updateBatchStatus(batchId, 'FAILED', error.message);
            throw error;
        }
    }

    async processEFTPayment(payment) {
        const { bankDetails, amount } = payment;
        
        try {
            // Use SA Switch for inter-bank transfers
            const payload = {
                transactionType: 'CREDIT_TRANSFER',
                amount: amount,
                currency: 'ZAR',
                creditorAccount: {
                    accountNumber: bankDetails.accountNumber,
                    branchCode: bankDetails.branchCode,
                    bankCode: bankDetails.bankCode,
                    accountType: bankDetails.accountType
                },
                debtorAccount: {
                    accountNumber: process.env.SASSA_ACCOUNT_NUMBER,
                    branchCode: process.env.SASSA_BRANCH_CODE,
                    bankCode: process.env.SASSA_BANK_CODE
                },
                remittanceInformation: `SASSA Grant Payment - ${payment.grantType}`,
                requestId: payment.paymentId
            };

            const response = await this.callSASwitch('/payments/credit-transfer', payload);
            
            return {
                transactionId: response.transactionId,
                bankReference: response.bankReference,
                status: response.status,
                estimatedSettlement: this.calculateSettlementDate()
            };
            
        } catch (error) {
            console.error('EFT payment error:', error);
            throw new Error(`EFT payment failed: ${error.message}`);
        }
    }

    async processCardPayment(payment) {
        // For card payments (less common for grants, but useful for emergency payments)
        try {
            const payload = {
                amount: payment.amount,
                currency: 'ZAR',
                cardToken: payment.cardDetails.token,
                description: `SASSA Grant Payment - ${payment.grantType}`,
                merchantReference: payment.paymentId
            };

            const response = await this.callMasterpass('/payments/process', payload);
            
            return {
                transactionId: response.transactionId,
                authCode: response.authorizationCode,
                status: response.status,
                estimatedSettlement: this.calculateSettlementDate()
            };
            
        } catch (error) {
            console.error('Card payment error:', error);
            throw new Error(`Card payment failed: ${error.message}`);
        }
    }

    async processCashPayment(payment) {
        // For cash payments via partner networks (ATMs, retail outlets)
        try {
            const payload = {
                amount: payment.amount,
                currency: 'ZAR',
                recipientId: payment.recipient.idNumber,
                recipientPhone: payment.recipient.phoneNumber,
                pickupLocation: payment.pickupLocation,
                reference: payment.paymentId,
                expiryDate: this.calculateCashExpiry()
            };

            // Use cash payment partner API
            const response = await this.callCashPartner('/cash-payments/create', payload);
            
            return {
                transactionId: response.transactionId,
                pinCode: response.pinCode,
                pickupReference: response.pickupReference,
                status: 'READY_FOR_PICKUP',
                estimatedSettlement: 'IMMEDIATE'
            };
            
        } catch (error) {
            console.error('Cash payment error:', error);
            throw new Error(`Cash payment failed: ${error.message}`);
        }
    }

    async validateBankDetails(bankDetails) {
        try {
            // Validate bank code
            const validBanks = await this.getValidBankCodes();
            if (!validBanks.includes(bankDetails.bankCode)) {
                return { valid: false, reason: 'Invalid bank code' };
            }

            // Validate branch code
            const branchValidation = await this.validateBranchCode(bankDetails.bankCode, bankDetails.branchCode);
            if (!branchValidation.valid) {
                return { valid: false, reason: 'Invalid branch code' };
            }

            // Validate account number format
            const accountValidation = this.validateAccountNumber(bankDetails.accountNumber, bankDetails.bankCode);
            if (!accountValidation.valid) {
                return { valid: false, reason: 'Invalid account number format' };
            }

            // Optional: Real-time account verification (if supported by bank)
            if (this.paymentConfig.environment === 'production') {
                const accountVerification = await this.verifyAccountExists(bankDetails);
                if (!accountVerification.exists) {
                    return { valid: false, reason: 'Account does not exist' };
                }
            }

            return { valid: true };
            
        } catch (error) {
            console.error('Bank validation error:', error);
            return { valid: false, reason: 'Validation service unavailable' };
        }
    }

    setupFraudDetection() {
        this.fraudRules = [
            {
                name: 'duplicate_payment',
                check: async (payment) => {
                    const query = `
                        SELECT COUNT(*) as count 
                        FROM payments 
                        WHERE grant_id = $1 
                        AND amount = $2 
                        AND status IN ('SUBMITTED', 'COMPLETED')
                        AND created_at > NOW() - INTERVAL '24 hours'
                    `;
                    const result = await this.dbPool.query(query, [payment.grantId, payment.amount]);
                    return parseInt(result.rows[0].count) > 0;
                }
            },
            {
                name: 'unusual_amount',
                check: async (payment) => {
                    // Check if amount is significantly different from historical payments
                    const query = `
                        SELECT AVG(amount) as avg_amount, STDDEV(amount) as std_amount
                        FROM payments 
                        WHERE grant_id = $1 
                        AND status = 'COMPLETED'
                        AND created_at > NOW() - INTERVAL '6 months'
                    `;
                    const result = await this.dbPool.query(query, [payment.grantId]);
                    
                    if (result.rows[0].avg_amount) {
                        const avgAmount = parseFloat(result.rows[0].avg_amount);
                        const stdAmount = parseFloat(result.rows[0].std_amount);
                        const threshold = avgAmount + (2 * stdAmount); // 2 standard deviations
                        
                        return payment.amount > threshold;
                    }
                    return false;
                }
            },
            {
                name: 'bank_details_changed',
                check: async (payment) => {
                    const query = `
                        SELECT bank_account_number, bank_code 
                        FROM payments 
                        WHERE grant_id = $1 
                        AND status = 'COMPLETED'
                        ORDER BY created_at DESC 
                        LIMIT 1
                    `;
                    const result = await this.dbPool.query(query, [payment.grantId]);
                    
                    if (result.rows.length > 0) {
                        const lastPayment = result.rows[0];
                        return (
                            lastPayment.bank_account_number !== payment.bankDetails.accountNumber ||
                            lastPayment.bank_code !== payment.bankDetails.bankCode
                        );
                    }
                    return false;
                }
            },
            {
                name: 'high_frequency_payments',
                check: async (payment) => {
                    const query = `
                        SELECT COUNT(*) as count 
                        FROM payments 
                        WHERE grant_id = $1 
                        AND created_at > NOW() - INTERVAL '1 hour'
                    `;
                    const result = await this.dbPool.query(query, [payment.grantId]);
                    return parseInt(result.rows[0].count) > 3;
                }
            }
        ];
    }

    async performFraudCheck(payment) {
        const flaggedRules = [];
        let riskScore = 0;

        for (const rule of this.fraudRules) {
            try {
                const isTriggered = await rule.check(payment);
                if (isTriggered) {
                    flaggedRules.push(rule.name);
                    riskScore += this.getRuleRiskScore(rule.name);
                }
            } catch (error) {
                console.error(`Fraud rule ${rule.name} error:`, error);
            }
        }

        let riskLevel = 'LOW';
        if (riskScore >= 50) {
            riskLevel = 'HIGH';
        } else if (riskScore >= 25) {
            riskLevel = 'MEDIUM';
        }

        return {
            riskLevel,
            riskScore,
            flaggedRules,
            reasons: flaggedRules.map(rule => this.getFraudRuleDescription(rule))
        };
    }

    getRuleRiskScore(ruleName) {
        const scores = {
            'duplicate_payment': 30,
            'unusual_amount': 20,
            'bank_details_changed': 25,
            'high_frequency_payments': 15
        };
        return scores[ruleName] || 10;
    }

    getFraudRuleDescription(ruleName) {
        const descriptions = {
            'duplicate_payment': 'Duplicate payment detected within 24 hours',
            'unusual_amount': 'Payment amount significantly different from historical pattern',
            'bank_details_changed': 'Bank account details changed from previous payments',
            'high_frequency_payments': 'Multiple payment attempts within short time period'
        };
        return descriptions[ruleName] || 'Unknown fraud rule triggered';
    }

    async verifyPayment(paymentId, bankReference) {
        try {
            // Get payment details
            const payment = await this.getPaymentById(paymentId);
            if (!payment) {
                throw new Error('Payment not found');
            }

            // Verify with payment provider
            let verification;
            switch (payment.payment_method) {
                case 'eft':
                    verification = await this.verifySASwitchPayment(payment.transaction_id, bankReference);
                    break;
                case 'card':
                    verification = await this.verifyMasterpassPayment(payment.transaction_id);
                    break;
                default:
                    throw new Error(`Verification not supported for payment method: ${payment.payment_method}`);
            }

            // Update payment status based on verification
            await this.updatePaymentStatus(paymentId, verification.status, verification.bankReference);
            
            return verification;
            
        } catch (error) {
            console.error('Payment verification error:', error);
            throw error;
        }
    }

    async reconcilePayments(date, provider = 'all') {
        try {
            const reconciliationResults = {
                date,
                provider,
                totalPayments: 0,
                matchedPayments: 0,
                unmatchedPayments: 0,
                discrepancies: []
            };

            // Get payments for the date
            const paymentsQuery = `
                SELECT * FROM payments 
                WHERE DATE(created_at) = $1 
                ${provider !== 'all' ? 'AND payment_method = $2' : ''}
                AND status IN ('SUBMITTED', 'COMPLETED')
            `;
            
            const params = [date];
            if (provider !== 'all') params.push(provider);
            
            const paymentsResult = await this.dbPool.query(paymentsQuery, params);
            const payments = paymentsResult.rows;

            reconciliationResults.totalPayments = payments.length;

            // Get bank statements/confirmations for the date
            const bankData = await this.getBankStatementData(date, provider);

            // Match payments with bank data
            for (const payment of payments) {
                const bankMatch = bankData.find(b => 
                    b.reference === payment.bank_reference || 
                    b.amount === payment.amount
                );

                if (bankMatch) {
                    reconciliationResults.matchedPayments++;
                    
                    // Check for amount discrepancies
                    if (bankMatch.amount !== payment.amount) {
                        reconciliationResults.discrepancies.push({
                            paymentId: payment.id,
                            type: 'AMOUNT_MISMATCH',
                            expectedAmount: payment.amount,
                            actualAmount: bankMatch.amount
                        });
                    }
                } else {
                    reconciliationResults.unmatchedPayments++;
                    reconciliationResults.discrepancies.push({
                        paymentId: payment.id,
                        type: 'NO_BANK_MATCH',
                        amount: payment.amount,
                        reference: payment.bank_reference
                    });
                }
            }

            // Save reconciliation results
            await this.saveReconciliationResults(reconciliationResults);

            return reconciliationResults;
            
        } catch (error) {
            console.error('Reconciliation error:', error);
            throw error;
        }
    }

    // Helper methods for API calls
    async callSASwitch(endpoint, payload) {
        const config = this.paymentConfig.providers.saswitch;
        const timestamp = new Date().toISOString();
        
        // Create signature for authentication
        const signature = this.createSASwitchSignature(payload, timestamp, config.secretKey);

        const response = await axios.post(`${config.apiUrl}${endpoint}`, payload, {
            headers: {
                'Content-Type': 'application/json',
                'X-Institution-Id': config.institutionId,
                'X-API-Key': config.apiKey,
                'X-Timestamp': timestamp,
                'X-Signature': signature
            }
        });

        return response.data;
    }

    async callMasterpass(endpoint, payload) {
        const config = this.paymentConfig.providers.masterpass;
        
        const response = await axios.post(`${config.apiUrl}${endpoint}`, payload, {
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${config.apiKey}`,
                'X-Merchant-Id': config.merchantId
            }
        });

        return response.data;
    }

    createSASwitchSignature(payload, timestamp, secretKey) {
        const dataToSign = JSON.stringify(payload) + timestamp;
        return crypto.createHmac('sha256', secretKey).update(dataToSign).digest('hex');
    }

    calculateSettlementDate() {
        const now = new Date();
        const settleDate = new Date(now);
        
        // EFT settlements typically happen next business day
        settleDate.setDate(settleDate.getDate() + 1);
        
        // Skip weekends
        if (settleDate.getDay() === 0) settleDate.setDate(settleDate.getDate() + 1); // Sunday
        if (settleDate.getDay() === 6) settleDate.setDate(settleDate.getDate() + 2); // Saturday
        
        return settleDate.toISOString().split('T')[0];
    }

    calculateCashExpiry() {
        const now = new Date();
        const expiry = new Date(now);
        expiry.setDate(expiry.getDate() + 30); // 30 days to collect cash
        return expiry.toISOString();
    }

    // Database operations
    async createPaymentRecord(paymentId, grantId, amount, paymentMethod, recipient) {
        const query = `
            INSERT INTO payments (
                id, grant_id, amount, currency, payment_method,
                recipient_name, recipient_id_number, recipient_phone,
                bank_account_number, bank_code, bank_branch_code,
                status, created_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW())
            RETURNING *
        `;

        const values = [
            paymentId,
            grantId,
            amount,
            'ZAR',
            paymentMethod,
            recipient.name,
            recipient.idNumber,
            recipient.phoneNumber,
            recipient.bankDetails?.accountNumber,
            recipient.bankDetails?.bankCode,
            recipient.bankDetails?.branchCode,
            'PENDING'
        ];

        const result = await this.dbPool.query(query, values);
        return result.rows[0];
    }

    async updatePaymentStatus(paymentId, status, transactionId = null, errorMessage = null) {
        const query = `
            UPDATE payments 
            SET status = $1, transaction_id = $2, error_message = $3, updated_at = NOW()
            WHERE id = $4
        `;

        await this.dbPool.query(query, [status, transactionId, errorMessage, paymentId]);
    }

    async logPaymentActivity(paymentId, activity, details) {
        const query = `
            INSERT INTO payment_activity_log (payment_id, activity, details, created_at)
            VALUES ($1, $2, $3, NOW())
        `;

        await this.dbPool.query(query, [paymentId, activity, JSON.stringify(details)]);
    }

    startScheduledJobs() {
        // Daily reconciliation job
        setInterval(async () => {
            try {
                const yesterday = new Date();
                yesterday.setDate(yesterday.getDate() - 1);
                const dateStr = yesterday.toISOString().split('T')[0];
                
                await this.reconcilePayments(dateStr);
                console.log(`Automatic reconciliation completed for ${dateStr}`);
            } catch (error) {
                console.error('Scheduled reconciliation error:', error);
            }
        }, 24 * 60 * 60 * 1000); // Daily

        // Payment status checking
        setInterval(async () => {
            try {
                await this.checkPendingPayments();
            } catch (error) {
                console.error('Payment status check error:', error);
            }
        }, 30 * 60 * 1000); // Every 30 minutes
    }

    async checkPendingPayments() {
        const query = `
            SELECT * FROM payments 
            WHERE status IN ('SUBMITTED', 'PENDING') 
            AND created_at < NOW() - INTERVAL '1 hour'
        `;

        const result = await this.dbPool.query(query);
        
        for (const payment of result.rows) {
            try {
                await this.verifyPayment(payment.id, payment.bank_reference);
            } catch (error) {
                console.error(`Error checking payment ${payment.id}:`, error);
            }
        }
    }

    start(port = 3002) {
        this.app.listen(port, () => {
            console.log(`Payment Service running on port ${port}`);
        });
    }
}

module.exports = PaymentService;

// If running directly
if (require.main === module) {
    const paymentService = new PaymentService();
    paymentService.start(process.env.PORT || 3002);
}