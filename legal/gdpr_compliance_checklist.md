# GDPR Compliance Checklist - BizAgent

**Date:** February 8, 2026  
**Version:** 1.0  
**App:** BizAgent - AI Accountant

---

## ✅ Compliance Status Overview

- [x] Privacy Policy created and published
- [x] Terms of Service created and published
- [x] Legal basis for data processing identified
- [x] Data protection measures implemented
- [ ] DPO (Data Protection Officer) appointed
- [ ] Data Processing Agreement with third parties
- [ ] GDPR training for team members
- [ ] Incident response plan documented

---

## 1. Legal Documentation

### 1.1 Privacy Policy
- [x] Privacy Policy created in Slovak
- [x] Privacy Policy published on website
- [x] Privacy Policy accessible in app
- [x] Privacy Policy includes all GDPR required elements:
  - [x] Data controller information
  - [x] Types of data collected
  - [x] Purpose of data processing
  - [x] Legal basis for processing
  - [x] Data retention periods
  - [x] User rights (access, rectification, erasure, etc.)
  - [x] Third-party data sharing details
  - [x] International data transfers
  - [x] Contact information

### 1.2 Terms of Service
- [x] Terms of Service created
- [x] Terms published on website
- [x] Terms accessible during registration
- [x] Clear acceptance mechanism

### 1.3 Cookie Policy
- [ ] Cookie policy created (for web version)
- [ ] Cookie banner implemented
- [ ] Cookie preferences management

---

## 2. Lawful Basis for Processing

### 2.1 Consent (Article 6(1)(a) GDPR)
- [x] Consent mechanism for optional features:
  - [x] Camera access for scanning
  - [x] Push notifications
  - [x] Analytics tracking
  - [x] Google Drive backups
- [x] Consent is freely given
- [x] Consent is specific and informed
- [x] Easy withdrawal of consent
- [x] Record of consent maintained

### 2.2 Contract Performance (Article 6(1)(b) GDPR)
- [x] Processing necessary for service delivery:
  - [x] Account creation
  - [x] Invoice generation
  - [x] Expense tracking
  - [x] Basic app functionality

### 2.3 Legitimate Interest (Article 6(1)(f) GDPR)
- [x] Legitimate interest assessment documented:
  - [x] Service improvement
  - [x] Security measures
  - [x] Crash reporting
  - [x] Bug fixing

### 2.4 Legal Obligation (Article 6(1)(c) GDPR)
- [x] Compliance with Slovak laws:
  - [x] Invoice retention (10 years)
  - [x] Accounting records retention
  - [x] Tax documentation

---

## 3. User Rights Implementation

### 3.1 Right to Access (Article 15)
- [ ] Mechanism for users to request data copy
- [ ] Response within 30 days
- [ ] Data export in machine-readable format

### 3.2 Right to Rectification (Article 16)
- [x] Users can update profile information in app
- [x] Users can edit invoices and expenses
- [ ] Clear process for requesting corrections

### 3.3 Right to Erasure (Article 17)
- [x] Account deletion feature in app
- [x] Data deletion within 30 days
- [x] Retention of data required by law explained
- [x] Confirmation of deletion sent to user

### 3.4 Right to Data Portability (Article 20)
- [ ] Export functionality (CSV, JSON, PDF)
- [ ] Structured, machine-readable format
- [ ] Easy transfer to another service

### 3.5 Right to Object (Article 21)
- [x] Opt-out of analytics
- [x] Opt-out of marketing (not applicable - no marketing)
- [x] Opt-out of profiling (AI tips can be disabled)

### 3.6 Right to Restriction (Article 18)
- [ ] Ability to temporarily restrict processing
- [ ] Notification of restriction lifting

---

## 4. Data Protection Measures

### 4.1 Technical Measures
- [x] Encryption in transit (TLS 1.3)
- [x] Encryption at rest (Firebase)
- [x] Authentication (Firebase Auth)
- [x] Authorization (Firestore Security Rules)
- [x] App Check (API protection)
- [ ] Regular security audits
- [ ] Penetration testing
- [ ] Vulnerability scanning

### 4.2 Organizational Measures
- [ ] Access control policies
- [ ] Employee confidentiality agreements
- [ ] GDPR training for team
- [ ] Incident response procedures
- [ ] Data breach notification process
- [ ] Regular compliance reviews

### 4.3 Data Minimization
- [x] Only necessary data collected
- [x] Optional features clearly marked
- [x] No excessive data retention
- [x] Anonymization where possible

### 4.4 Pseudonymization & Anonymization
- [x] Analytics data anonymized
- [x] User IDs pseudonymized in logs
- [ ] AI training data anonymized

---

## 5. Third-Party Processors

### 5.1 Firebase (Google LLC)
- [x] Data Processing Agreement reviewed
- [x] Privacy Shield certified
- [x] EU-US data transfer safeguards
- [x] Documented in Privacy Policy
- [ ] Regular compliance verification

### 5.2 Google Drive
- [x] User consent required
- [x] User controls data
- [x] Documented in Privacy Policy

### 5.3 Finstat API
- [x] Minimal data shared (only IČO)
- [x] Data location: Slovakia (EU)
- [x] Documented in Privacy Policy

### 5.4 OpenAI
- [x] Data anonymized before sending
- [x] No personal identifiers sent
- [x] Documented in Privacy Policy
- [ ] Data Processing Agreement signed

---

## 6. International Data Transfers

### 6.1 EU to USA Transfers
- [x] Standard Contractual Clauses (SCCs)
- [x] Privacy Shield (where applicable)
- [x] Risk assessment completed
- [x] Documented in Privacy Policy
- [x] User informed of transfers

### 6.2 Data Localization
- [x] Primary data storage: EU (Firebase europe-west3)
- [x] Backups: User's Google Drive (user-controlled)
- [ ] Option to keep all data in EU

---

## 7. Data Retention & Deletion

### 7.1 Retention Periods Defined
- [x] Active accounts: Until deletion
- [x] Invoices: 10 years (legal requirement)
- [x] Expenses: 10 years (legal requirement)
- [x] Analytics: 14 months
- [x] Crash logs: 90 days
- [x] Deleted accounts: 30 days grace period

### 7.2 Automated Deletion
- [ ] Automated deletion scripts implemented
- [ ] Regular audit of retention compliance
- [ ] Deletion logs maintained

---

## 8. Data Breach Procedures

### 8.1 Detection
- [ ] Monitoring systems in place
- [ ] Alert mechanisms configured
- [ ] Regular security reviews

### 8.2 Response
- [ ] Incident response team identified
- [ ] Breach assessment process documented
- [ ] Notification procedures (72 hours to authority)
- [ ] User notification procedures
- [ ] Documentation templates ready

### 8.3 Reporting
- [ ] Data Protection Authority contact: Úrad na ochranu osobných údajov SR
- [ ] Breach notification template prepared
- [ ] User notification template prepared

---

## 9. Children's Data

### 9.1 Age Restrictions
- [x] App requires 18+ years
- [x] Age verification during registration
- [x] Parental consent option for <18
- [x] Documented in Terms of Service

### 9.2 Special Protections
- [x] No targeted advertising (not applicable)
- [x] Enhanced privacy for minors
- [x] Easy account deletion for parents

---

## 10. Marketing & Profiling

### 10.1 Direct Marketing
- [x] No direct marketing currently
- [x] Opt-in required if implemented
- [x] Easy opt-out mechanism

### 10.2 Profiling & Automated Decisions
- [x] AI tips are informational only
- [x] No automated decisions affecting users
- [x] Users can disable AI features
- [x] Documented in Privacy Policy

---

## 11. Data Protection Officer (DPO)

### 11.1 DPO Appointment
- [ ] DPO appointed (if required)
- [ ] DPO contact information published
- [ ] DPO has necessary resources and independence

**Current Status:** Company size may not require DPO, but recommended

**Planned DPO Contact:**
- Email: dpo@bizagent.app
- Availability: Pending appointment

---

## 12. Records of Processing Activities

### 12.1 Processing Register (Article 30)
- [ ] Processing activities documented
- [ ] Categories of data listed
- [ ] Purposes of processing listed
- [ ] Recipients of data listed
- [ ] Retention periods specified
- [ ] Security measures described

### 12.2 Regular Updates
- [ ] Quarterly review scheduled
- [ ] Updates after new features
- [ ] Version control maintained

---

## 13. Data Protection Impact Assessment (DPIA)

### 13.1 DPIA Necessity
- [ ] DPIA completed for high-risk processing:
  - [ ] Large-scale profiling (AI tips)
  - [ ] Automated decision making
  - [ ] Special categories of data

**Assessment:** Low-to-medium risk, but DPIA recommended for AI features

---

## 14. User Interface & Transparency

### 14.1 Privacy by Design
- [x] Privacy settings easily accessible
- [x] Clear explanations for permissions
- [x] Granular privacy controls
- [x] Default settings are privacy-friendly

### 14.2 Transparency
- [x] Privacy Policy linked in app
- [x] Clear language used
- [x] Icons and visual aids for clarity
- [x] Multiple language support

---

## 15. Compliance Monitoring

### 15.1 Regular Audits
- [ ] Quarterly compliance review scheduled
- [ ] Annual external audit planned
- [ ] Compliance dashboard created

### 15.2 Training
- [ ] Team GDPR training completed
- [ ] Annual refresher training planned
- [ ] New employee onboarding includes GDPR

### 15.3 Documentation
- [x] Privacy Policy versioned
- [x] Terms of Service versioned
- [ ] Change log maintained
- [ ] All consents logged

---

## 16. Specific Risks & Mitigations

### 16.1 Financial Data Risk
**Risk:** Sensitive financial information  
**Mitigation:**
- [x] Strong encryption
- [x] Access controls
- [x] Regular backups
- [x] User-controlled sharing

### 16.2 AI Processing Risk
**Risk:** AI may process personal data  
**Mitigation:**
- [x] Data anonymized before AI processing
- [x] No identifiers sent to AI
- [x] User can disable AI features
- [x] Transparency about AI usage

### 16.3 Third-Party Risk
**Risk:** Data sharing with external services  
**Mitigation:**
- [x] Minimal data sharing
- [x] Documented in Privacy Policy
- [x] User consent where required
- [ ] Regular vendor audits

---

## 17. Next Steps & Action Items

### Immediate (0-30 days):
- [ ] Appoint DPO or responsible person
- [ ] Implement data export functionality
- [ ] Complete Data Processing Agreements with all vendors
- [ ] Set up automated deletion scripts
- [ ] Create incident response plan

### Short-term (1-3 months):
- [ ] Conduct DPIA for AI features
- [ ] Implement comprehensive audit logging
- [ ] GDPR training for all team members
- [ ] External compliance audit
- [ ] Cookie policy for web version

### Medium-term (3-6 months):
- [ ] Achieve ISO 27001 certification (optional)
- [ ] Regular penetration testing schedule
- [ ] Compliance dashboard implementation
- [ ] Automated compliance monitoring

### Ongoing:
- [ ] Quarterly compliance reviews
- [ ] Annual privacy policy updates
- [ ] User feedback on privacy features
- [ ] Monitor regulatory changes

---

## 18. Regulatory Authority Contact

**Úrad na ochranu osobných údajov Slovenskej republiky**  
Hraničná 12  
820 07 Bratislava 27  
Slovenská republika

**Web:** https://dataprotection.gov.sk  
**Email:** statny.dozor@pdp.gov.sk  
**Tel.:** +421 2 3231 3214

---

## 📝 Notes & Observations

### Strengths:
- Strong technical security measures (Firebase)
- Clear privacy documentation
- User-friendly privacy controls
- GDPR-aware architecture

### Areas for Improvement:
- Complete DPO appointment
- Implement full data portability
- Enhance audit logging
- Regular compliance training
- External audits

---

## ✅ Approval & Sign-off

**Prepared by:** ___________________  
**Date:** February 8, 2026

**Reviewed by (Legal):** ___________________  
**Date:** ___________________

**Approved by (Management):** ___________________  
**Date:** ___________________

---

**Next Review Date:** May 8, 2026 (3 months)  
**Document Version:** 1.0  
**Classification:** Internal - Confidential