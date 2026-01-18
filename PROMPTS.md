# 🎯 10 Essential Prompts to Complete BizAgent

Copy-paste these prompts to Claude to build features:

## 1. Invoice Form Screen
```
Create a complete InvoiceForm widget for BizAgent Flutter app with:
- Client selector (with autocomplete)
- Dynamic items list (add/remove rows)
- Auto-calculation of subtotal, VAT, total
- Date pickers for issue/due date
- Form validation
- Save as draft or send
Use Riverpod for state management and Material 3 design
```

## 2. Camera Scanner with OCR
```
Build a CameraScanner widget for expense receipt scanning:
- Live camera preview
- Capture button with animation
- OCR processing with google_mlkit_text_recognition
- Extract: amount, date, vendor
- Show preview with detected fields
- Edit/confirm functionality
Material 3 UI with smooth animations
```

## 3. Dashboard with Charts
```
Create Dashboard screen with:
- Monthly revenue/expense cards
- Cashflow chart (last 6 months) using fl_chart
- Recent invoices list (last 5)
- Quick actions (new invoice, scan receipt)
- Overdue invoices alert
Use shimmer loading states, Riverpod providers
```

## 4. Expense List with Categories
```
Build ExpenseList screen featuring:
- Grouped by month
- Category chips (filterable)
- Swipe to delete
- Pull to refresh
- Empty state illustration
- FAB for quick add
Material 3 cards, smooth animations
```

## 5. PDF Preview & Share
```
Create PDFPreview screen:
- Render PDF using flutter_pdfview
- Zoom/pan controls
- Share button (share_plus)
- Download to device
- Print option
- Loading indicator
Modern UI with Material 3
```

## 6. AI Email Generator
```
Build AI Email Generator screen:
- Purpose selector (invoice reminder, quote, etc)
- Context input field
- Tone selector (formal, friendly, urgent)
- Generate button (calls Claude API)
- Copy to clipboard
- Save as template
Loading states, error handling
```

## 7. Settings & Profile
```
Create Settings screens:
- Profile (name, company, IČO, DIČ)
- Company address form
- Bank account details
- Subscription tier display
- Theme toggle (light/dark)
- Language selector (SK/EN)
Validation, save indicators
```

## 8. Authentication Flow
```
Build complete auth flow:
- Splash screen with animation
- Login (email/password)
- Register with company details
- Password reset
- Biometric login option
Firebase Auth integration, error handling
```

## 9. Cashflow Chart & Analytics
```
Create Cashflow Analytics screen:
- Income vs Expenses chart (bar/line)
- Category breakdown (pie chart)
- Month-over-month comparison
- Profit/loss indicator
- Export to PDF/Excel
Use fl_chart, beautiful gradients
```

## 10. Payment Reminders List
```
Build Payment Reminders screen:
- List of overdue invoices
- Days overdue badge
- Send reminder button
- Auto-reminder settings
- Reminder history
- Mark as paid quick action
Material 3, swipe actions
```

---

## 🚀 Bonus Prompts

### 11. Onboarding Flow
```
Create 3-screen onboarding with:
- SVG illustrations
- Feature highlights
- Skip button
- Get Started CTA
Use PageView, dots indicator, animations
```

### 12. Document Manager
```
Build Documents screen:
- File upload (image/pdf)
- Grid/list view toggle
- Search functionality
- Share/delete actions
- Storage usage indicator
Firebase Storage integration
```

---

## 💡 How to Use

1. Copy one prompt at a time
2. Paste to Claude
3. Review generated code
4. Add to your project
5. Test & iterate

Each prompt builds on the foundation - do them in order for best results!
