# TODO NOW - BizAgent Google Play Store Launch

**Priority:** HIGH  
**Deadline:** Before Google Play Store submission  
**Last Updated:** February 8, 2026

---

## 🎯 PHASE 2 COMPLETION STATUS

### ✅ Completed Tasks

#### Store Listing Content
- [x] Slovak (sk-SK) store listing texts created
  - [x] Title (30 chars max)
  - [x] Short description (80 chars max)
  - [x] Full description (4000 chars max)
  - [x] Keywords
- [x] English (en-US) store listing texts created
  - [x] Title
  - [x] Short description
  - [x] Full description
  - [x] Keywords

#### Legal Documents
- [x] Privacy Policy (markdown) created
- [x] Privacy Policy (HTML) created for web
- [x] Terms of Service (markdown) created
- [x] Terms of Service (HTML) created for web
- [x] GDPR Compliance Checklist created
- [x] Data Safety Form documentation created

#### Design Guides
- [x] Icon Design Guide created
- [x] Feature Graphic Guide created
- [x] Screenshots Guide created
- [x] Google Play Assets README created

#### Directory Structure
- [x] All required directories created
- [x] .gitkeep files for screenshot folders

---

## 🚨 CRITICAL - DO BEFORE LAUNCH

### 1. Create Visual Assets (PRIORITY: URGENT)

#### App Icon (Required)
- [ ] Design 512x512 px app icon
  - Follow guidelines in: `google_play_assets/icons/ICON_DESIGN_GUIDE.md`
  - Use BizAgent brand colors
  - Save as 32-bit PNG with alpha channel
  - Max file size: 1 MB
- [ ] Test icon on different backgrounds
- [ ] Upload to `google_play_assets/icons/`

#### Feature Graphic (Required)
- [ ] Design 1024x500 px feature graphic
  - Follow guidelines in: `google_play_assets/feature_graphic/FEATURE_GRAPHIC_GUIDE.md`
  - Include app screenshot or key message
  - Use BizAgent branding
  - Save as PNG or JPEG
  - Max file size: 1 MB
- [ ] Test on mobile and desktop
- [ ] Upload to `google_play_assets/feature_graphic/`

#### Screenshots (Required - Minimum 2)
- [ ] Capture phone screenshots (1080x1920 px recommended)
  - Dashboard with stats
  - Receipt scanning feature
  - Invoice creation
  - Expense list
  - AI Accountant feature
  - Reports/Analytics
  - (Minimum 2, maximum 8)
- [ ] Follow guidelines in: `google_play_assets/screenshots/SCREENSHOTS_GUIDE.md`
- [ ] Add optional text overlays/captions
- [ ] Upload to `google_play_assets/screenshots/phone/`

#### Tablet Screenshots (Optional but recommended)
- [ ] Capture 7-inch tablet screenshots
- [ ] Upload to `google_play_assets/screenshots/tablet_7inch/`

---

### 2. Publish Legal Documents (PRIORITY: URGENT)

- [ ] Upload Privacy Policy HTML to web server
  - Target URL: `https://bizagent.app/legal/privacy-policy.html`
  - Verify accessibility
  - Test on mobile and desktop

- [ ] Upload Terms of Service HTML to web server
  - Target URL: `https://bizagent.app/legal/terms-of-service.html`
  - Verify accessibility
  - Test on mobile and desktop

- [ ] Add links to legal documents in app
  - Settings → Privacy Policy
  - Settings → Terms of Service
  - Registration screen → Terms acceptance

- [ ] Verify legal document links in-app work correctly

---

### 3. Google Play Console Setup (PRIORITY: HIGH)

#### App Information
- [ ] Create app in Google Play Console
- [ ] Set app name: "BizAgent - AI Účtovník"
- [ ] Set default language: Slovak (sk-SK)
- [ ] Add secondary language: English (en-US)
- [ ] Set app category: Business
- [ ] Set content rating: Everyone (no mature content)
- [ ] Provide contact details:
  - Email: support@bizagent.app
  - Website: https://bizagent.app

#### Store Listing
- [ ] Upload app icon (512x512 px)
- [ ] Upload feature graphic (1024x500 px)
- [ ] Upload phone screenshots (minimum 2)
- [ ] Copy title from: `google_play_assets/store_listings/sk_SK/title.txt`
- [ ] Copy short description from: `google_play_assets/store_listings/sk_SK/short_description.txt`
- [ ] Copy full description from: `google_play_assets/store_listings/sk_SK/full_description.txt`
- [ ] Repeat for English (en-US) listing

#### Data Safety Section
- [ ] Complete Data Safety questionnaire
  - Use answers from: `legal/data_safety_form.md`
  - Review each question carefully
  - Be accurate and complete

#### Privacy Policy
- [ ] Add Privacy Policy URL: `https://bizagent.app/legal/privacy-policy.html`
- [ ] Verify URL is publicly accessible

---

### 4. App Bundle Preparation (PRIORITY: HIGH)

- [ ] Build release APK/AAB
  - `flutter build appbundle --release`
- [ ] Sign app with release key
- [ ] Test signed release build
- [ ] Verify app size < 150 MB
- [ ] Test on multiple devices

---

### 5. Pre-Launch Testing (PRIORITY: MEDIUM)

- [ ] Internal testing track
  - Upload APK/AAB
  - Add internal testers
  - Test for 3-5 days
  - Gather feedback

- [ ] Closed alpha testing (optional)
  - Invite select users
  - Test for 1-2 weeks
  - Fix critical bugs

- [ ] Open beta testing (recommended)
  - Public beta in Slovakia
  - Test for 2-4 weeks
  - Monitor reviews and crash reports

---

### 6. GDPR & Legal Compliance (PRIORITY: HIGH)

- [ ] Review GDPR Compliance Checklist
  - File: `legal/gdpr_compliance_checklist.md`
  - Complete all action items marked as urgent

- [ ] Appoint Data Protection Officer (if required)
  - Email: dpo@bizagent.app
  - Document responsibilities

- [ ] Data Processing Agreements
  - Firebase/Google
  - OpenAI
  - Finstat
  - Any other third parties

- [ ] Implement user data export functionality
  - Settings → Export data (CSV, JSON, PDF)

- [ ] Verify account deletion works properly
  - Test full deletion flow
  - Verify 30-day grace period
  - Confirm data cleanup

---

### 7. App Store Optimization (ASO) (PRIORITY: MEDIUM)

- [ ] Keyword research
  - Slovak keywords for accounting apps
  - Competitor analysis
  - Update keywords if needed

- [ ] A/B test store listing elements
  - Try different feature graphic designs
  - Test screenshot orders
  - Experiment with description hooks

- [ ] Monitor search rankings
  - Track target keywords
  - Adjust based on performance

---

### 8. Marketing Preparation (PRIORITY: MEDIUM)

- [ ] Create landing page
  - bizagent.app
  - Include app screenshots
  - Download links
  - Feature highlights

- [ ] Social media setup
  - Instagram: @bizagent_app
  - Facebook: /bizagentapp
  - LinkedIn company page

- [ ] Press kit
  - App description
  - Screenshots
  - Logo files
  - Contact information

- [ ] Launch announcement
  - Email to beta testers
  - Social media posts
  - Press release (optional)

---

### 9. Support Infrastructure (PRIORITY: MEDIUM)

- [ ] Support email setup
  - support@bizagent.app
  - Auto-responder configured
  - Ticket system (optional)

- [ ] FAQ page
  - Common questions
  - Troubleshooting
  - How-to guides

- [ ] User documentation
  - Quick start guide
  - Feature tutorials
  - Video demos (optional)

- [ ] In-app help
  - Tooltips
  - Help screens
  - Contact support button

---

### 10. Analytics & Monitoring (PRIORITY: MEDIUM)

- [ ] Firebase Analytics configured
  - Track key events
  - User engagement
  - Feature usage

- [ ] Crashlytics setup
  - Crash reporting enabled
  - Symbol files uploaded
  - Alert notifications

- [ ] Performance monitoring
  - App startup time
  - Network requests
  - Screen rendering

- [ ] Dashboard for metrics
  - User acquisition
  - Retention rates
  - Feature adoption
  - Revenue (future)

---

## 📅 TIMELINE & MILESTONES

### Week 1: Asset Creation (Days 1-7)
- [ ] Day 1-2: Design app icon
- [ ] Day 3-4: Create feature graphic
- [ ] Day 5-7: Capture and edit screenshots

### Week 2: Legal & Compliance (Days 8-14)
- [ ] Day 8-9: Publish legal documents
- [ ] Day 10-11: GDPR compliance review
- [ ] Day 12-14: Data safety section completion

### Week 3: Testing & Polish (Days 15-21)
- [ ] Day 15-16: Internal testing
- [ ] Day 17-19: Bug fixes
- [ ] Day 20-21: Final QA

### Week 4: Submission & Launch (Days 22-28)
- [ ] Day 22-23: Complete Play Console setup
- [ ] Day 24: Submit for review
- [ ] Day 25-27: Review period (Google)
- [ ] Day 28: Public launch! 🚀

---

## 🚫 BLOCKERS & DEPENDENCIES

### Current Blockers:
1. **Visual Assets Missing**
   - Need designer or design tools
   - Estimated time: 2-3 days
   - Can use Figma (free) or hire designer

2. **Web Server for Legal Docs**
   - Need to deploy HTML files
   - Estimated time: 1 day
   - Can use Firebase Hosting, Vercel, or existing server

3. **Release Signing Key**
   - Need to generate and secure
   - Estimated time: 1 hour
   - Must be done before first production release

### Dependencies:
- Design assets → Store listing completion
- Legal docs published → Play Console submission
- APK signed → Testing and release
- Testing complete → Public launch

---

## 👥 TEAM ASSIGNMENTS

### Design Team:
- [ ] App icon design
- [ ] Feature graphic design
- [ ] Screenshot capture and editing
- [ ] Marketing materials

### Development Team:
- [ ] Legal document web deployment
- [ ] In-app legal links
- [ ] Data export functionality
- [ ] Account deletion testing
- [ ] APK building and signing

### Legal/Compliance:
- [ ] GDPR checklist review
- [ ] Data Processing Agreements
- [ ] Privacy policy final review
- [ ] Terms of service final review

### Marketing:
- [ ] ASO keyword research
- [ ] Landing page creation
- [ ] Social media setup
- [ ] Launch plan

---

## 📧 CONTACTS & RESOURCES

### Internal:
- **Support:** support@bizagent.app
- **DPO:** dpo@bizagent.app
- **Legal:** legal@bizagent.app

### External:
- **Google Play Console:** https://play.google.com/console
- **Firebase Console:** https://console.firebase.google.com
- **Design Resources:** Figma, Adobe Creative Cloud

### Documentation:
- All guides in: `google_play_assets/`
- Legal docs in: `legal/`
- This checklist: `TODO_NOW.md`

---

## ✅ COMPLETION CRITERIA

### Ready for Submission When:
1. ✅ All required assets uploaded
2. ✅ Store listing complete (both languages)
3. ✅ Data safety section filled out
4. ✅ Privacy policy live and accessible
5. ✅ APK/AAB built, signed, and tested
6. ✅ Internal testing passed
7. ✅ GDPR compliance verified
8. ✅ All blockers resolved

### Launch Checklist:
- [ ] Submitted to Google Play
- [ ] Review approved by Google
- [ ] Production track set to 100% rollout
- [ ] App live on Play Store
- [ ] Marketing campaign activated
- [ ] Support channels monitored
- [ ] Analytics tracking confirmed

---

## 🎉 POST-LAUNCH

### Day 1-7:
- [ ] Monitor crash reports
- [ ] Respond to user reviews
- [ ] Track download numbers
- [ ] Fix critical bugs immediately

### Week 2-4:
- [ ] Analyze user feedback
- [ ] Plan first update
- [ ] A/B test store listing
- [ ] Marketing campaign results

### Month 2+:
- [ ] Regular feature updates
- [ ] User engagement campaigns
- [ ] Performance optimizations
- [ ] Expand to other markets (Czech Republic, etc.)

---

**Remember:** Quality over speed. Better to launch right than to launch fast.

**Good luck with the launch! 🚀**

---

**Last Updated:** February 8, 2026  
**Next Review:** Daily until launch  
**Status:** Phase 2 Documentation Complete - Ready for Asset Creation

**Questions?** Contact support@bizagent.app