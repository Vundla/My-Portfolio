# WCAG 2.1 AA Accessibility Compliance Framework
## Social Grants Pilot System

### Executive Summary

This document outlines the accessibility compliance framework for the Social Grants pilot system, ensuring adherence to Web Content Accessibility Guidelines (WCAG) 2.1 Level AA standards as required by South African disability rights legislation and international best practices.

## 1. Accessibility Standards & Legal Requirements

### 1.1 Applicable Standards
- **WCAG 2.1 Level AA**: Primary accessibility standard
- **South African Constitution**: Section 9 (Equality) and Section 10 (Human Dignity)
- **Employment Equity Act**: Reasonable accommodation requirements
- **Promotion of Equality and Prevention of Unfair Discrimination Act (PEPUDA)**
- **UN Convention on Rights of Persons with Disabilities (CRPD)**

### 1.2 Target User Groups
- Citizens with visual impairments (blind, low vision)
- Citizens with hearing impairments (deaf, hard of hearing)
- Citizens with motor disabilities
- Citizens with cognitive disabilities
- Elderly users with age-related impairments
- Users with temporary disabilities

## 2. WCAG 2.1 AA Compliance Checklist

### 2.1 Principle 1: Perceivable

#### 2.1.1 Text Alternatives (Level A)
- [ ] **1.1.1** All images have appropriate alt text
- [ ] **1.1.1** Decorative images marked as decorative (alt="")
- [ ] **1.1.1** Complex images have detailed descriptions
- [ ] **1.1.1** Form controls have accessible labels
- [ ] **1.1.1** Icon buttons have text alternatives

**Implementation:**
```html
<!-- Good examples -->
<img src="grant-status.png" alt="Grant application approved">
<img src="decoration.png" alt="" role="presentation">
<button><span class="icon-search" aria-hidden="true"></span>Search Applications</button>

<!-- Form labels -->
<label for="id-number">South African ID Number</label>
<input type="text" id="id-number" required>
```

#### 2.1.2 Captions and Audio Descriptions (Level A & AA)
- [ ] **1.2.1** Pre-recorded video has captions (Level A)
- [ ] **1.2.2** Pre-recorded audio has captions (Level A)
- [ ] **1.2.4** Live captions for live audio content (Level AA)
- [ ] **1.2.5** Audio descriptions for pre-recorded video (Level AA)

**Implementation:**
```html
<video controls>
    <source src="grant-application-tutorial.mp4" type="video/mp4">
    <track kind="captions" src="captions-en.vtt" srclang="en" label="English">
    <track kind="captions" src="captions-af.vtt" srclang="af" label="Afrikaans">
    <track kind="captions" src="captions-zu.vtt" srclang="zu" label="isiZulu">
    <track kind="descriptions" src="descriptions-en.vtt" srclang="en" label="English Descriptions">
</video>
```

#### 2.1.3 Adaptable Content (Level A)
- [ ] **1.3.1** Information and relationships are programmatically determinable
- [ ] **1.3.2** Content sequence is meaningful when presented linearly
- [ ] **1.3.3** Instructions don't rely solely on sensory characteristics

**Implementation:**
```html
<!-- Proper heading structure -->
<h1>Social Grant Applications</h1>
<h2>Application Types</h2>
<h3>Old Age Grant</h3>
<h3>Disability Grant</h3>
<h2>Application Status</h2>

<!-- Semantic form structure -->
<fieldset>
    <legend>Personal Information</legend>
    <label for="first-name">First Name</label>
    <input type="text" id="first-name" required>
    <label for="surname">Surname</label>
    <input type="text" id="surname" required>
</fieldset>
```

#### 2.1.4 Distinguishable Content (Level A & AA)
- [ ] **1.4.1** Color is not used as the only means of conveying information
- [ ] **1.4.2** Audio controls are available for auto-playing audio
- [ ] **1.4.3** Text has minimum contrast ratio of 4.5:1 (Level AA)
- [ ] **1.4.4** Text can be resized up to 200% without loss of functionality (Level AA)
- [ ] **1.4.5** Text in images is avoided except for logos (Level AA)

**Implementation:**
```css
/* High contrast color scheme */
:root {
    --primary-color: #1f4e79; /* 4.5:1 contrast on white */
    --success-color: #2d5c2d; /* 4.5:1 contrast on white */
    --error-color: #c41e3a; /* 4.5:1 contrast on white */
    --warning-color: #8b4513; /* 4.5:1 contrast on white */
}

/* Status indicators using color + icon + text */
.status-approved {
    color: var(--success-color);
}
.status-approved::before {
    content: "✓ ";
}

.status-rejected {
    color: var(--error-color);
}
.status-rejected::before {
    content: "✗ ";
}

/* Responsive text sizing */
body {
    font-size: 16px;
    line-height: 1.5;
}

@media (max-width: 768px) {
    body {
        font-size: 18px;
        line-height: 1.6;
    }
}
```

### 2.2 Principle 2: Operable

#### 2.2.1 Keyboard Accessible (Level A)
- [ ] **2.1.1** All functionality available via keyboard
- [ ] **2.1.2** No keyboard trap exists
- [ ] **2.1.4** Character key shortcuts can be disabled/remapped (Level A)

**Implementation:**
```javascript
// Keyboard navigation support
class AccessibleDropdown {
    constructor(element) {
        this.dropdown = element;
        this.trigger = element.querySelector('.dropdown-trigger');
        this.menu = element.querySelector('.dropdown-menu');
        this.items = element.querySelectorAll('.dropdown-item');
        
        this.bindEvents();
    }
    
    bindEvents() {
        this.trigger.addEventListener('keydown', (e) => {
            switch(e.key) {
                case 'Enter':
                case ' ':
                case 'ArrowDown':
                    e.preventDefault();
                    this.openMenu();
                    this.focusFirstItem();
                    break;
            }
        });
        
        this.menu.addEventListener('keydown', (e) => {
            switch(e.key) {
                case 'Escape':
                    this.closeMenu();
                    this.trigger.focus();
                    break;
                case 'ArrowDown':
                    e.preventDefault();
                    this.focusNextItem();
                    break;
                case 'ArrowUp':
                    e.preventDefault();
                    this.focusPreviousItem();
                    break;
                case 'Home':
                    e.preventDefault();
                    this.focusFirstItem();
                    break;
                case 'End':
                    e.preventDefault();
                    this.focusLastItem();
                    break;
            }
        });
    }
}
```

#### 2.2.2 Timing (Level A & AA)
- [ ] **2.2.1** Users can turn off, adjust, or extend time limits
- [ ] **2.2.2** Users can pause, stop, or hide moving content

**Implementation:**
```javascript
// Session timeout with user control
class AccessibleSessionManager {
    constructor(timeoutMinutes = 30) {
        this.timeoutDuration = timeoutMinutes * 60 * 1000;
        this.warningTime = 5 * 60 * 1000; // 5 minutes warning
        this.timeoutId = null;
        this.warningId = null;
        
        this.startSession();
    }
    
    startSession() {
        this.resetTimeout();
        
        // Listen for user activity
        ['mousedown', 'mousemove', 'keydown', 'scroll', 'touchstart'].forEach(event => {
            document.addEventListener(event, () => this.resetTimeout(), true);
        });
    }
    
    resetTimeout() {
        clearTimeout(this.timeoutId);
        clearTimeout(this.warningId);
        
        // Set warning timer
        this.warningId = setTimeout(() => {
            this.showTimeoutWarning();
        }, this.timeoutDuration - this.warningTime);
        
        // Set timeout timer
        this.timeoutId = setTimeout(() => {
            this.handleTimeout();
        }, this.timeoutDuration);
    }
    
    showTimeoutWarning() {
        const modal = this.createWarningModal();
        document.body.appendChild(modal);
        modal.querySelector('.extend-session').focus();
    }
    
    createWarningModal() {
        const modal = document.createElement('div');
        modal.className = 'timeout-warning-modal';
        modal.setAttribute('role', 'alertdialog');
        modal.setAttribute('aria-labelledby', 'timeout-title');
        modal.setAttribute('aria-describedby', 'timeout-message');
        
        modal.innerHTML = `
            <div class="modal-content">
                <h2 id="timeout-title">Session About to Expire</h2>
                <p id="timeout-message">
                    Your session will expire in 5 minutes due to inactivity. 
                    Would you like to extend your session?
                </p>
                <div class="modal-actions">
                    <button class="extend-session" type="button">
                        Extend Session
                    </button>
                    <button class="logout-now" type="button">
                        Logout Now
                    </button>
                </div>
            </div>
        `;
        
        // Bind events
        modal.querySelector('.extend-session').addEventListener('click', () => {
            this.extendSession();
            modal.remove();
        });
        
        modal.querySelector('.logout-now').addEventListener('click', () => {
            this.logout();
        });
        
        return modal;
    }
}
```

#### 2.2.3 Seizures and Physical Reactions (Level A & AA)
- [ ] **2.3.1** Content doesn't contain flashing more than 3 times per second

#### 2.2.4 Navigable (Level A & AA)
- [ ] **2.4.1** Bypass blocks mechanism provided (skip links)
- [ ] **2.4.2** Page has descriptive title
- [ ] **2.4.3** Focus order is logical and meaningful
- [ ] **2.4.4** Link purpose is clear from context (Level AA)
- [ ] **2.4.5** Multiple ways to locate pages (Level AA)
- [ ] **2.4.6** Headings and labels are descriptive (Level AA)
- [ ] **2.4.7** Focus indicator is visible (Level AA)

**Implementation:**
```html
<!-- Skip navigation links -->
<a href="#main-content" class="skip-link">Skip to main content</a>
<a href="#navigation" class="skip-link">Skip to navigation</a>

<!-- Descriptive page titles -->
<title>Apply for Old Age Grant - Step 2 of 4 - Social Grants</title>

<!-- Clear navigation structure -->
<nav aria-label="Main navigation">
    <ul>
        <li><a href="/dashboard">My Dashboard</a></li>
        <li><a href="/applications">My Applications</a></li>
        <li><a href="/payments">Payment History</a></li>
        <li><a href="/profile">My Profile</a></li>
    </ul>
</nav>

<!-- Breadcrumb navigation -->
<nav aria-label="Breadcrumb">
    <ol class="breadcrumb">
        <li><a href="/">Home</a></li>
        <li><a href="/applications">Applications</a></li>
        <li aria-current="page">New Application</li>
    </ol>
</nav>
```

```css
/* Focus indicators */
:focus {
    outline: 3px solid #1f4e79;
    outline-offset: 2px;
}

/* Skip links */
.skip-link {
    position: absolute;
    top: -40px;
    left: 6px;
    background: #1f4e79;
    color: white;
    padding: 8px;
    text-decoration: none;
    z-index: 9999;
}

.skip-link:focus {
    top: 6px;
}
```

### 2.3 Principle 3: Understandable

#### 2.3.1 Readable (Level A & AA)
- [ ] **3.1.1** Page language is identified
- [ ] **3.1.2** Language of parts is identified when different from page language (Level AA)

**Implementation:**
```html
<html lang="en">
<head>
    <title>Social Grants Application</title>
</head>
<body>
    <h1>Social Grant Application</h1>
    <p>Complete your application below.</p>
    
    <!-- Mixed language content -->
    <p>For help in Afrikaans: <span lang="af">Kontak ons by 0800 60 10 11</span></p>
    <p>For help in isiZulu: <span lang="zu">Shayela 0800 60 10 11</span></p>
</body>
</html>
```

#### 2.3.2 Predictable (Level A & AA)
- [ ] **3.2.1** Focus doesn't cause unexpected context changes
- [ ] **3.2.2** Input doesn't cause unexpected context changes
- [ ] **3.2.3** Navigation is consistent across pages (Level AA)
- [ ] **3.2.4** Components are consistently identified (Level AA)

**Implementation:**
```javascript
// Predictable form behavior
class AccessibleForm {
    constructor(form) {
        this.form = form;
        this.setupFormValidation();
    }
    
    setupFormValidation() {
        // Real-time validation without context changes
        this.form.addEventListener('input', (e) => {
            if (e.target.matches('[data-validate]')) {
                this.validateField(e.target, false); // Don't focus on error
            }
        });
        
        // Validation on blur
        this.form.addEventListener('blur', (e) => {
            if (e.target.matches('[data-validate]')) {
                this.validateField(e.target, false);
            }
        }, true);
        
        // Comprehensive validation on submit
        this.form.addEventListener('submit', (e) => {
            if (!this.validateAllFields()) {
                e.preventDefault();
                this.focusFirstError();
            }
        });
    }
    
    validateField(field, focusOnError = false) {
        const errorContainer = document.getElementById(field.getAttribute('aria-describedby'));
        const isValid = field.checkValidity();
        
        if (!isValid) {
            field.setAttribute('aria-invalid', 'true');
            errorContainer.textContent = field.validationMessage;
            errorContainer.style.display = 'block';
            
            if (focusOnError) {
                field.focus();
            }
        } else {
            field.removeAttribute('aria-invalid');
            errorContainer.textContent = '';
            errorContainer.style.display = 'none';
        }
        
        return isValid;
    }
}
```

#### 2.3.3 Input Assistance (Level A & AA)
- [ ] **3.3.1** Error identification is clear and specific
- [ ] **3.3.2** Labels and instructions are provided
- [ ] **3.3.3** Error suggestions are provided (Level AA)
- [ ] **3.3.4** Error prevention for legal/financial/data submissions (Level AA)

**Implementation:**
```html
<!-- Form with comprehensive error handling -->
<form novalidate>
    <fieldset>
        <legend>Personal Information</legend>
        
        <!-- ID Number field with validation -->
        <div class="form-group">
            <label for="id-number">
                South African ID Number
                <span class="required" aria-label="required">*</span>
            </label>
            <input 
                type="text" 
                id="id-number" 
                required 
                pattern="[0-9]{13}"
                aria-describedby="id-number-help id-number-error"
                data-validate="true">
            <div id="id-number-help" class="field-help">
                Enter your 13-digit South African ID number (e.g., 8001015009087)
            </div>
            <div id="id-number-error" class="error-message" style="display: none;" role="alert"></div>
        </div>
        
        <!-- Phone number with formatting -->
        <div class="form-group">
            <label for="phone">
                Phone Number
                <span class="required" aria-label="required">*</span>
            </label>
            <input 
                type="tel" 
                id="phone" 
                required 
                pattern="^(\+27|0)[0-9]{9}$"
                aria-describedby="phone-help phone-error"
                data-validate="true">
            <div id="phone-help" class="field-help">
                Enter your phone number (e.g., 0123456789 or +27123456789)
            </div>
            <div id="phone-error" class="error-message" style="display: none;" role="alert"></div>
        </div>
    </fieldset>
    
    <!-- Confirmation step for critical actions -->
    <div class="confirmation-section">
        <h3>Confirm Your Application</h3>
        <p>Please review your information before submitting:</p>
        <dl class="summary-list">
            <dt>ID Number:</dt>
            <dd id="confirm-id"></dd>
            <dt>Phone Number:</dt>
            <dd id="confirm-phone"></dd>
        </dl>
        
        <div class="checkbox-group">
            <input type="checkbox" id="confirm-accuracy" required>
            <label for="confirm-accuracy">
                I confirm that the information provided is accurate and complete
            </label>
        </div>
    </div>
    
    <button type="submit">Submit Application</button>
</form>
```

### 2.4 Principle 4: Robust

#### 2.4.1 Compatible (Level A & AA)
- [ ] **4.1.1** Markup is valid and well-formed
- [ ] **4.1.2** Name, role, and value are programmatically determinable
- [ ] **4.1.3** Status messages are programmatically determinable (Level AA)

**Implementation:**
```html
<!-- Custom components with proper ARIA -->
<div class="grant-status-card" role="region" aria-labelledby="status-heading">
    <h3 id="status-heading">Application Status</h3>
    <div class="status-indicator" role="status" aria-live="polite">
        <span class="status-icon" aria-hidden="true">✓</span>
        <span class="status-text">Approved</span>
    </div>
    <div class="status-details">
        <p>Your application has been approved. Payment will begin on the next payment date.</p>
    </div>
</div>

<!-- Progress indicator -->
<div class="progress-bar" role="progressbar" aria-valuenow="75" aria-valuemin="0" aria-valuemax="100" aria-label="Application completion progress">
    <div class="progress-fill" style="width: 75%"></div>
    <span class="progress-text">Step 3 of 4 (75% complete)</span>
</div>
```

```javascript
// Status message management
class AccessibleStatusManager {
    constructor() {
        this.statusRegion = this.createStatusRegion();
        document.body.appendChild(this.statusRegion);
    }
    
    createStatusRegion() {
        const region = document.createElement('div');
        region.id = 'status-messages';
        region.setAttribute('aria-live', 'polite');
        region.setAttribute('aria-atomic', 'false');
        region.className = 'sr-only';
        return region;
    }
    
    announceStatus(message, type = 'info') {
        const statusElement = document.createElement('div');
        statusElement.className = `status-message status-${type}`;
        statusElement.textContent = message;
        
        this.statusRegion.appendChild(statusElement);
        
        // Remove after announcement
        setTimeout(() => {
            if (statusElement.parentNode) {
                statusElement.parentNode.removeChild(statusElement);
            }
        }, 5000);
    }
    
    announceError(message) {
        this.announceStatus(message, 'error');
    }
    
    announceSuccess(message) {
        this.announceStatus(message, 'success');
    }
}
```

## 3. Testing & Validation Framework

### 3.1 Automated Testing Tools
- **axe-core**: Automated accessibility testing
- **Pa11y**: Command-line accessibility tester
- **Lighthouse**: Performance and accessibility auditing
- **WAVE**: Web accessibility evaluation

### 3.2 Manual Testing Procedures

#### 3.2.1 Keyboard Navigation Testing
```bash
# Testing checklist
# 1. Tab through all interactive elements
# 2. Verify focus order is logical
# 3. Ensure no keyboard traps exist
# 4. Test all keyboard shortcuts
# 5. Verify skip links work
```

#### 3.2.2 Screen Reader Testing
- **NVDA** (Windows) - Free screen reader
- **JAWS** (Windows) - Professional screen reader
- **VoiceOver** (macOS/iOS) - Built-in screen reader
- **TalkBack** (Android) - Built-in screen reader

### 3.3 Automated Testing Implementation

```javascript
// Accessibility testing with axe-core
const axe = require('axe-core');
const puppeteer = require('puppeteer');

class AccessibilityTester {
    async testPage(url) {
        const browser = await puppeteer.launch();
        const page = await browser.newPage();
        
        await page.goto(url);
        await page.injectFile(require.resolve('axe-core/axe.min.js'));
        
        const results = await page.evaluate(() => {
            return axe.run();
        });
        
        await browser.close();
        
        return {
            violations: results.violations,
            passes: results.passes,
            incomplete: results.incomplete,
            inapplicable: results.inapplicable
        };
    }
    
    generateReport(results) {
        console.log(`Accessibility Test Results:`);
        console.log(`Violations: ${results.violations.length}`);
        console.log(`Passes: ${results.passes.length}`);
        
        if (results.violations.length > 0) {
            console.log('\nViolations:');
            results.violations.forEach(violation => {
                console.log(`- ${violation.id}: ${violation.description}`);
                console.log(`  Impact: ${violation.impact}`);
                console.log(`  Nodes: ${violation.nodes.length}`);
            });
        }
        
        return results.violations.length === 0;
    }
}
```

## 4. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- [ ] Implement semantic HTML structure
- [ ] Add ARIA labels and roles
- [ ] Ensure keyboard navigation
- [ ] Implement focus management

### Phase 2: Content & Forms (Weeks 3-4)
- [ ] Form accessibility improvements
- [ ] Error handling and validation
- [ ] Content structure optimization
- [ ] Alternative text implementation

### Phase 3: Advanced Features (Weeks 5-6)
- [ ] Complex component accessibility
- [ ] Dynamic content handling
- [ ] Live regions implementation
- [ ] Multimedia accessibility

### Phase 4: Testing & Validation (Weeks 7-8)
- [ ] Automated testing setup
- [ ] Manual testing procedures
- [ ] User testing with disabled users
- [ ] Documentation and training

## 5. Accessibility Statement

The Social Grants pilot system is committed to ensuring digital accessibility for people with disabilities. We continually improve the user experience for everyone and apply relevant accessibility standards.

### Conformance Status
This website is partially conformant with WCAG 2.1 level AA. "Partially conformant" means that some parts of the content do not fully conform to the accessibility standard.

### Feedback Process
We welcome your feedback on the accessibility of the Social Grants system. Please contact us:
- **Email**: accessibility@sassa.gov.za
- **Phone**: 0800 60 10 11
- **Post**: SASSA Accessibility Team, Private Bag X01, Pretoria, 0001

### Assessment Method
This accessibility statement was created using automated and manual testing methods to evaluate compliance with WCAG 2.1 Level AA.

Last updated: January 2025