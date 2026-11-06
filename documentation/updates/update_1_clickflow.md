# 🛡️ GuardUp – Mobile App Testing Guide & Sprint Update #01

**Application Name:** GuardUp  
**Document Title:** Client Testing Guide & Feature Walkthrough  
**Date:** November 6, 2026  
**Build Version:** 1.0.0 (Build 1)  
**Status:** Ready for Client Testing & Review  

---

## 1. About GuardUp

**GuardUp** is an on-demand personal security and bodyguard booking mobile application. It seamlessly connects clients (individuals, families, and corporate executives) with verified, licensed professional bodyguards and certified private security companies.

The application is tailored around three user roles:
- **Clients (Customers):** Browse and search verified bodyguards, check ratings and credentials, book security details for specific dates and times, purchase membership plans, and track assignments.
- **Bodyguards:** Complete professional verification, upload licenses, set weekly working availability, review incoming job requests, and track earnings.
- **Security Companies:** Manage a fleet of bodyguards, review company-wide bookings, manage company documentation, and track business revenue.

---

## 2. App Download & Installation

You can download and install the latest test build on any Android smartphone using the link below:

* **Download Link:** [📥 Click Here to Download GuardUp APK (v1.0.0)](https://drive.google.com/drive/folders/guardup-staging-builds) *(Placeholder link: replace with your shared Google Drive or Firebase App Distribution link)*
* **Supported Devices:** Android 8.0 and above

### Quick Installation Steps:
1. Tap the download link on your Android device to download the `.apk` file.
2. Open the downloaded file.
3. If prompted with *"For your security, your phone is not allowed to install unknown apps from this source"*, tap **Settings** and toggle **"Allow from this source"** to **ON**.
4. Tap **Install**, then tap **Open** to launch GuardUp.

---

## 3. Demo Test Accounts

The app is pre-configured with test accounts so you can explore all three user experiences without needing real credentials.

| Role | Email | Password | Logged-in Identity | Experience Overview |
| :--- | :--- | :--- | :--- | :--- |
| **Client (Customer)** | `customer@gmail.com` | `Password@123` | **Alex Morgan** | Search guards, book protection, view plans & wallet |
| **Bodyguard** | `guard@gmail.com` | `Password@123` | **Vikram Singh** | Manage schedule, view earnings, accept bookings |
| **Security Company** | `company@gmail.com` | `Password@123` | **Apex Security Ltd.** | Manage guard roster, agency overview, view finances |

> **Note on Verification Codes:** If you test the sign-up or verification screens, enter any 6-digit number (e.g. `123456`) to proceed.

---

## 4. What Has Been Done So Far

Here is a summary of all the screens, modules, and features currently built and ready for testing:

### ✨ Visual Design & Branding
* **Luxury Dark Theme:** Sleek black and dark charcoal background accented with warm gold buttons and highlights.
* **Responsive Layout:** Formatted for modern smartphone screens with smooth scrolling, bottom navigation bars, and clear status cards.

### 👤 Authentication & Onboarding
* **Role Selection:** Interactive welcome screen to pick your role (Customer, Bodyguard, or Security Company).
* **Sign In & Sign Up:** Clean login and registration forms with email and password validation.
* **Email Verification:** Interactive 6-digit verification code screen.
* **Forgot Password:** Easy password recovery screen.
* **Admin Approval Notice:** Dedicated status screen for bodyguards waiting for license verification.

### 🛡️ Client (Customer) Experience
* **Home Dashboard:**
  * Top bar showing current city, client name, and notifications bell.
  * Membership discount banner (e.g., Gold Sentinel 20% discount).
  * Quick service category pills (Armed Protection, Tactical Driver, Executive Security).
  * Top-rated bodyguards carousel with instant "Book Now" actions.
  * Featured security companies list.
* **Search & Filters:** Search bar with instant keyword matching and filter options.
* **Bodyguards & Companies Directory:** Full directory list with ratings, hourly rates, and verified badges.
* **Bodyguard Profile View:**
  * Full profile with photo, badges, and verified license credentials.
  * Tabbed details: Overview & bio, verified documents/licenses, client reviews, and weekly availability schedule.
* **Interactive Booking Screen:**
  * Select start date, start time, end date, and end time.
  * Automatic duration and rate calculation.
  * Operative selection checkbox.
  * Transparent payment breakdown showing base rate, membership discount, and total payable amount.
* **Booking Confirmation:** Success screen with booking ID and quick buttons to message the guard or track mission progress.

### 🎖️ Bodyguard Experience
* **Profile Setup:** Photo uploader with circular frame and quick-add badge, bio, hourly rate, and experience details.
* **Document Verification (KYC):** Upload cards for National ID, Security License, Firearms Permit, and Address Proof with status tags and thumbnail previews.
* **Bodyguard Dashboard:**
  * Online/offline availability switch.
  * Summary cards for today's earnings, active hours, and completed assignments.
  * Incoming assignment requests with Accept and Decline actions.
* **Schedule & Availability:** Day-by-day availability toggles to set working hours.
* **Guard Detail View:** In-depth view of personal documents, booking history, and feedback.

### 🏢 Security Company Experience
* **Company Profile Setup:** Company name, registration number, headquarters address, and company documents.
* **Company Dashboard:** Overview of total guards active, completed bookings, and monthly revenue.
* **Fleet Roster:** Full list of all bodyguards registered under the agency with search and quick-management options.
* **Company Details:** Public agency profile visible to clients looking to book entire security teams.

### 💳 Payments, Wallet & Memberships
* **Digital Wallet:** Available balance card, recent transaction history with status badges (*Completed*, *Pending*, *Failed*).
* **Bank Details:** Add and edit bank accounts for direct payouts (Bank name, account number, routing code).
* **Membership Plans:** Tier comparison screen (*Silver Shield*, *Gold Sentinel*, *Platinum Elite*) with plan benefits and discounts.
* **Payment Success Screen:** Receipt summary card with confirmation details.

### 💬 Messaging, Notifications & Support
* **In-App Chat:** Conversations list and rich chat screen with real-time message bubbles and delivery status ticks.
* **Notifications Center:** Activity alerts for booking confirmations, payouts, and system messages.
* **Settings & Legal:** Edit Profile, Change Password, Terms & Conditions, Privacy Policy, and Contact Support screen.

---

## 5. Step-by-Step Testing Walkthrough

Follow these simple walkthroughs on your phone to test the primary user flows:

### 🚶 Flow 1: Client Discovery & Booking a Bodyguard
1. Open the app and log in using `customer@gmail.com` and password `Password@123`.
2. You will arrive at the **Customer Home Dashboard**.
3. Browse the top-rated bodyguards on the home screen or tap the **Search** icon at the top.
4. Tap on any bodyguard (for example, **Vikram Singh**).
5. Explore the tabs on the profile: **Overview**, **Documents**, **Reviews**, and **Availability**.
6. Tap **"Book Operative"** at the bottom.
7. On the **Booking Screen**, select your desired dates and times.
8. Check the bodyguard selection box and review the **Payment Summary** (base rate minus your membership discount).
9. Tap **"Next"** to review booking details, then confirm to reach the **Booking Confirmed** screen.
10. Tap **"Message Bodyguard"** to jump directly into the in-app chat.

---

### 🚶 Flow 2: Testing the Bodyguard Experience
1. Log out from the **Profile** tab, or restart the app.
2. Sign in with `guard@gmail.com` and password `Password@123`.
3. You will land on the **Bodyguard Dashboard**.
4. Check the today's earnings card and the incoming assignment request cards.
5. Tap on the **Profile** tab in the bottom bar to view your operative information, document verification status, and availability schedule.
6. Check the **Bookings** tab to review your upcoming assignments.

---

### 🚶 Flow 3: Testing the Security Company Experience
1. Sign in with `company@gmail.com` and password `Password@123`.
2. You will land on the **Company Dashboard**.
3. Notice the agency metrics: active bodyguards on duty, total bookings, and revenue.
4. Tap on the **Bodyguards** tab or tap **"View All"** to see your company's bodyguard fleet.
5. Tap on any guard to view their specific assignment history and documents.
6. Go to the **Profile** tab $\rightarrow$ tap **"My Wallet"** to review agency earnings, request a withdrawal, or update your bank account details.

---

### 🚶 Flow 4: Testing Memberships & Wallet
1. Sign in as a Customer (`customer@gmail.com`).
2. Go to the **Profile** tab (bottom right).
3. Tap **"Membership Plans"**:
   * Compare the tiers (**Silver**, **Gold Sentinel**, **Platinum Elite**).
   * Note the discounts and perks listed under each tier.
4. Go back to Profile and tap **"My Wallet"**:
   * View the balance card and list of recent transactions.
   * Tap **"Add Bank Account"** or **"Withdraw"** to open the bank details form.
   * Enter mock bank details and tap **Save**.

---

### 🚶 Flow 5: Testing In-App Chat & Notifications
1. From the bottom navigation bar, tap the **Chat** icon.
2. Tap on any conversation thread to open the messaging screen.
3. Type a message and tap send to test the message bubble layout.
4. Tap the **Bell** icon on the top right of the Home screen to view the Notifications center.

---

## 6. How to Provide Feedback

We welcome your feedback and observations during testing. When reporting any item, please let us know:
1. **The screen or step** where you noticed something (e.g. *Customer Booking Screen*).
2. **What you expected** vs. **what you saw**.
3. A **screenshot or short screen recording** (if applicable).
4. **Device model** (e.g. *Samsung Galaxy S22*, *Google Pixel 7*).

Thank you for testing **GuardUp**! We look forward to your thoughts and feedback.
