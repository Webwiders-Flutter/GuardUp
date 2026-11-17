-- ============================================================
-- Seed default Legal Content
--
-- Roles:
--   CUSTOMER
--   GUARD     (Bodyguard)
--   COMPANY   (Security company / agency)
--
-- Content Types:
--   TERMS
--   ABOUT_US
--   PRIVACY_POLICY
--   DELETE_ACCOUNT
--   SUPPORT
--
-- Languages:
--   en
--
-- Total:
--   3 roles × 5 content types × 1 language = 15 records
--
-- Safe to run multiple times. Existing rows are left untouched
-- (ON CONFLICT DO NOTHING) so content already edited by an admin
-- is never overwritten by this default seed.
-- ============================================================

INSERT INTO public.legal_content (
  role,
  language,
  content_type,
  content_html,
  last_published_at
)
SELECT
  v.role::public.user_role,
  v.language::public.language_code,
  v.content_type::public.legal_content_type,
  v.content_html,
  NOW()
FROM (
  VALUES

  /* ==========================================================
     ==========================================================
                           ENGLISH
     ==========================================================
     ========================================================== */

  /* ----------------------------------------------------------
     CUSTOMER - TERMS (en)
     ---------------------------------------------------------- */
  ('CUSTOMER', 'en', 'TERMS', $html$
<h1>Terms &amp; Conditions</h1>
<p>Welcome to <strong>GuardUp</strong>. These Terms &amp; Conditions govern your use of the GuardUp application as a customer. By creating an account or booking a protection service, you agree to these terms.</p>

<h2>1. About the Platform</h2>
<p>GuardUp is a technology platform that connects customers with independent, verified bodyguards and licensed security companies. GuardUp does not itself provide security services; services are delivered by the bodyguard or company you book.</p>

<h2>2. Eligibility &amp; Account</h2>
<ul>
  <li>You must be at least 18 years old and legally able to enter into a contract.</li>
  <li>You must provide accurate, complete and up-to-date information.</li>
  <li>You are responsible for keeping your login credentials secure and for all activity on your account.</li>
</ul>

<h2>3. Bookings</h2>
<p>When you place a booking you must accurately describe the service required, including date, time, location, duration and any known risks. A booking is confirmed only once it has been accepted by the bodyguard or company.</p>

<h2>4. Payments, Cancellations &amp; Refunds</h2>
<p>Prices are shown before you confirm a booking. Applicable fees, taxes and cancellation charges are displayed in the app. Refunds, where applicable, are processed to the original payment method according to the cancellation policy shown at the time of booking.</p>

<h2>5. Lawful Use</h2>
<p>You agree not to use GuardUp or any booked personnel for any unlawful purpose. In particular, you must not:</p>
<ul>
  <li>Request any action that breaks the law or endangers others.</li>
  <li>Ask personnel to carry, use or display weapons in breach of local regulations.</li>
  <li>Harass, threaten, abuse or discriminate against any bodyguard, company or staff member.</li>
  <li>Provide false identity details or misrepresent the nature of a booking.</li>
</ul>
<p>Bodyguards and companies may refuse or end an assignment if they reasonably believe it is unlawful or unsafe.</p>

<h2>6. Emergencies</h2>
<p>GuardUp is not an emergency service. In any situation involving immediate danger, always contact your local police or emergency services first.</p>

<h2>7. Ratings &amp; Reviews</h2>
<p>Reviews must be honest and based on your genuine experience. We may remove reviews that are abusive, misleading or unrelated to the service.</p>

<h2>8. Limitation of Liability</h2>
<p>To the maximum extent permitted by law, GuardUp is not liable for the acts or omissions of independent bodyguards or companies, or for indirect or consequential losses arising from the use of the platform.</p>

<h2>9. Suspension &amp; Termination</h2>
<p>We may suspend or close your account if you breach these terms, misuse the platform, or if required by law.</p>

<h2>10. Changes to These Terms</h2>
<p>We may update these terms from time to time. Continued use of GuardUp after an update means you accept the revised terms.</p>

<h2>11. Contact</h2>
<p>For questions about these terms, contact us at <strong>support@guardup.com</strong>.</p>
$html$),

  /* ----------------------------------------------------------
     CUSTOMER - PRIVACY_POLICY (en)
     ---------------------------------------------------------- */
  ('CUSTOMER', 'en', 'PRIVACY_POLICY', $html$
<h1>Privacy Policy</h1>
<p>This Privacy Policy explains how <strong>GuardUp</strong> collects, uses and protects your personal information when you use the app as a customer.</p>

<h2>1. Information We Collect</h2>
<ul>
  <li><strong>Account details:</strong> name, email address, phone number and profile photo.</li>
  <li><strong>Booking details:</strong> service type, dates, times, pickup and destination locations, and notes you provide.</li>
  <li><strong>Location data:</strong> your location while a booking is active, to coordinate with your assigned personnel.</li>
  <li><strong>Payment data:</strong> transaction records. Card details are handled by our payment provider and are not stored by GuardUp.</li>
  <li><strong>Device &amp; usage data:</strong> device type, app version, and diagnostic logs.</li>
</ul>

<h2>2. How We Use Your Information</h2>
<ul>
  <li>To create and manage your account.</li>
  <li>To match you with bodyguards and companies and to manage your bookings.</li>
  <li>To process payments and refunds.</li>
  <li>To send booking updates, security alerts and service notifications.</li>
  <li>To prevent fraud, keep the platform safe and comply with legal obligations.</li>
</ul>

<h2>3. Sharing Your Information</h2>
<p>We share only what is necessary:</p>
<ul>
  <li>With the bodyguard or company assigned to your booking (name, contact number and booking details).</li>
  <li>With payment and infrastructure providers who process data on our behalf.</li>
  <li>With authorities when required by law or to protect someone's safety.</li>
</ul>
<p>We never sell your personal information.</p>

<h2>4. Data Retention</h2>
<p>We keep your information for as long as your account is active and as required for legal, tax and dispute-resolution purposes.</p>

<h2>5. Security</h2>
<p>We use encryption in transit, access controls and secure infrastructure to protect your data. No system is completely secure, so please keep your credentials private.</p>

<h2>6. Your Rights</h2>
<p>You can access and update your profile at any time, and you can request deletion of your account from the app. You may also contact us to request a copy of your data.</p>

<h2>7. Contact</h2>
<p>For privacy questions, contact us at <strong>support@guardup.com</strong>.</p>
$html$),

  /* ----------------------------------------------------------
     CUSTOMER - ABOUT_US (en)
     ---------------------------------------------------------- */
  ('CUSTOMER', 'en', 'ABOUT_US', $html$
<h1>About GuardUp</h1>
<p><strong>GuardUp</strong> makes professional personal protection simple, transparent and accessible. We connect individuals, families and businesses with verified bodyguards and licensed security companies.</p>

<h2>What We Offer</h2>
<ul>
  <li>Personal and close protection</li>
  <li>Event and venue security</li>
  <li>Travel and escort protection</li>
  <li>Residential and corporate security</li>
</ul>

<h2>How It Works</h2>
<ul>
  <li><strong>Browse:</strong> explore verified bodyguards and security companies with ratings and service details.</li>
  <li><strong>Book:</strong> choose the service, date, time and location that suit you.</li>
  <li><strong>Stay protected:</strong> track your booking and stay in touch with your assigned personnel.</li>
</ul>

<h2>Our Commitment</h2>
<p>Every bodyguard and company on GuardUp goes through document verification and admin approval before they can accept bookings. We are committed to safety, discretion and professionalism in every assignment.</p>
$html$),

  /* ----------------------------------------------------------
     CUSTOMER - DELETE_ACCOUNT (en)
     ---------------------------------------------------------- */
  ('CUSTOMER', 'en', 'DELETE_ACCOUNT', $html$
<h1>Delete Your Account</h1>
<p>You can permanently delete your GuardUp customer account at any time. Please read the information below before continuing.</p>

<h2>Before You Delete</h2>
<ul>
  <li>Complete or cancel any upcoming or active bookings.</li>
  <li>Make sure any pending payments or refunds have been settled.</li>
  <li>Download any booking receipts you may need.</li>
</ul>

<h2>How to Delete</h2>
<p>Go to <strong>Profile &rarr; Delete Account</strong> in the app and confirm. If you cannot access the app, email <strong>support@guardup.com</strong> from your registered email address.</p>

<h2>What Gets Deleted</h2>
<ul>
  <li>Your profile, contact details and profile photo.</li>
  <li>Saved addresses and preferences.</li>
  <li>Your login access to GuardUp.</li>
</ul>

<h2>What We May Retain</h2>
<p>Some records, such as completed transactions and invoices, may be kept for the period required by law for tax, accounting, fraud-prevention and dispute-resolution purposes.</p>

<h2>This Action Is Permanent</h2>
<p>Once your account is deleted it cannot be restored. You will need to register again to use GuardUp.</p>
$html$),

  /* ----------------------------------------------------------
     CUSTOMER - SUPPORT (en)
     ---------------------------------------------------------- */
  ('CUSTOMER', 'en', 'SUPPORT', $html$
<h1>Help &amp; Support</h1>
<p>Our support team is here to help with your bookings, payments and account.</p>

<h2>Contact Us</h2>
<ul>
  <li><strong>In-app:</strong> Profile &rarr; Contact Us</li>
  <li><strong>Email:</strong> support@guardup.com</li>
  <li><strong>Hours:</strong> 10:00 AM &ndash; 7:00 PM (Mon&ndash;Sat)</li>
</ul>

<h2>We Can Help With</h2>
<ul>
  <li>Creating, changing or cancelling a booking</li>
  <li>Payments, invoices and refunds</li>
  <li>Concerns about a bodyguard or company</li>
  <li>Account access and profile updates</li>
</ul>

<h2>Emergencies</h2>
<p>If you are in immediate danger, contact your <strong>local police or emergency services</strong> first. GuardUp support is not an emergency response service.</p>

<h2>Report a Safety Concern</h2>
<p>If something during a booking made you feel unsafe, please contact us as soon as possible with your booking details so we can investigate.</p>
$html$),

  /* ----------------------------------------------------------
     GUARD - TERMS (en)
     ---------------------------------------------------------- */
  ('GUARD', 'en', 'TERMS', $html$
<h1>Terms &amp; Conditions for Bodyguards</h1>
<p>These Terms &amp; Conditions govern your use of <strong>GuardUp</strong> as a bodyguard. By registering, you agree to these terms.</p>

<h2>1. Your Relationship with GuardUp</h2>
<p>GuardUp is a platform that connects you with customers. You provide services as an independent professional and are responsible for the services you deliver.</p>

<h2>2. Eligibility &amp; Verification</h2>
<ul>
  <li>You must be at least 18 years old and legally permitted to work as a security professional.</li>
  <li>You must hold every licence, permit and certification required by local law, and keep them valid.</li>
  <li>You must upload genuine documents. Your account is reviewed by our admin team before you can accept bookings.</li>
  <li>Submitting false or altered documents will result in permanent removal from the platform.</li>
</ul>

<h2>3. Profile Accuracy</h2>
<p>Your profile, experience, services and rates must be accurate and kept up to date.</p>

<h2>4. Bookings &amp; Professional Conduct</h2>
<ul>
  <li>Arrive on time, properly presented, and deliver the service agreed in the booking.</li>
  <li>Act lawfully at all times. Any use of force must be lawful, necessary and proportionate.</li>
  <li>Carry or use weapons only where you are legally licensed to do so.</li>
  <li>Refuse any instruction that is unlawful or puts anyone at unreasonable risk, and report it to GuardUp.</li>
  <li>Treat customers with respect and never discriminate, harass or abuse.</li>
</ul>

<h2>5. Confidentiality</h2>
<p>You must keep all customer information, locations, schedules and conversations strictly confidential, during and after an assignment.</p>

<h2>6. Fees &amp; Payments</h2>
<p>Applicable platform or membership fees are shown in the app. Earnings are paid according to the payout terms displayed in your account.</p>

<h2>7. Ratings</h2>
<p>Customers may rate and review your service. Consistently low ratings or verified complaints may lead to review or suspension of your account.</p>

<h2>8. Suspension &amp; Termination</h2>
<p>GuardUp may suspend or remove your account for breaches of these terms, expired documents, misconduct or legal requirements.</p>

<h2>9. Limitation of Liability</h2>
<p>To the maximum extent permitted by law, GuardUp is not liable for any loss arising from the services you provide. You are responsible for any insurance required for your work.</p>

<h2>10. Contact</h2>
<p>For questions about these terms, contact <strong>support@guardup.com</strong>.</p>
$html$),

  /* ----------------------------------------------------------
     GUARD - PRIVACY_POLICY (en)
     ---------------------------------------------------------- */
  ('GUARD', 'en', 'PRIVACY_POLICY', $html$
<h1>Privacy Policy for Bodyguards</h1>
<p>This Privacy Policy explains how <strong>GuardUp</strong> handles your personal information as a bodyguard on the platform.</p>

<h2>1. Information We Collect</h2>
<ul>
  <li><strong>Profile details:</strong> name, email, phone number, photo, experience, services and rates.</li>
  <li><strong>Verification documents:</strong> identity documents, licences, certificates and any other documents you upload.</li>
  <li><strong>Location data:</strong> your location while you are on an active booking.</li>
  <li><strong>Booking &amp; earnings data:</strong> assignments, ratings, reviews and payout records.</li>
  <li><strong>Device &amp; usage data:</strong> device type, app version and diagnostic logs.</li>
</ul>

<h2>2. How We Use Your Information</h2>
<ul>
  <li>To verify your identity and qualifications.</li>
  <li>To display your public profile to customers and send you booking requests.</li>
  <li>To coordinate active bookings and support customer safety.</li>
  <li>To process payouts and keep financial records.</li>
  <li>To prevent fraud and meet legal obligations.</li>
</ul>

<h2>3. What Customers Can See</h2>
<p>Customers can see your public profile: name, photo, services, rates, experience and ratings. Your verification documents are never shown to customers and are only reviewed by authorised GuardUp administrators.</p>

<h2>4. Sharing</h2>
<p>We share data only with customers you are booked with, service providers who process data on our behalf, and authorities where required by law. We never sell your personal information.</p>

<h2>5. Retention &amp; Security</h2>
<p>Documents and records are stored securely and kept for as long as your account is active and as required by law.</p>

<h2>6. Your Rights</h2>
<p>You can update your profile and documents in the app and request deletion of your account at any time.</p>

<h2>7. Contact</h2>
<p>For privacy questions, contact <strong>support@guardup.com</strong>.</p>
$html$),

  /* ----------------------------------------------------------
     GUARD - ABOUT_US (en)
     ---------------------------------------------------------- */
  ('GUARD', 'en', 'ABOUT_US', $html$
<h1>About GuardUp</h1>
<p><strong>GuardUp</strong> is a platform built for security professionals. We help verified bodyguards find customers who need trusted, professional protection.</p>

<h2>Why GuardUp</h2>
<ul>
  <li><strong>Get discovered:</strong> showcase your experience, services and rates to customers looking for protection.</li>
  <li><strong>Build your reputation:</strong> earn ratings and reviews for every assignment you complete.</li>
  <li><strong>Work your way:</strong> choose the services you offer and manage your bookings from one app.</li>
</ul>

<h2>Verified &amp; Trusted</h2>
<p>Every bodyguard is verified by our admin team before going live. This keeps standards high and gives customers confidence in the professionals they book.</p>

<h2>Our Commitment</h2>
<p>We are committed to fair treatment, transparent fees and support for the professionals who keep our customers safe.</p>
$html$),

  /* ----------------------------------------------------------
     GUARD - DELETE_ACCOUNT (en)
     ---------------------------------------------------------- */
  ('GUARD', 'en', 'DELETE_ACCOUNT', $html$
<h1>Delete Your Account</h1>
<p>You can permanently delete your GuardUp bodyguard account at any time. Please read the following before continuing.</p>

<h2>Before You Delete</h2>
<ul>
  <li>Complete or hand over any active or upcoming bookings.</li>
  <li>Make sure all pending payouts have been received.</li>
  <li>Download any earnings statements you may need.</li>
</ul>

<h2>How to Delete</h2>
<p>Go to <strong>Profile &rarr; Delete Account</strong> in the app and confirm. If you cannot access the app, email <strong>support@guardup.com</strong> from your registered email address.</p>

<h2>What Gets Deleted</h2>
<ul>
  <li>Your public profile, services and rates.</li>
  <li>Your uploaded verification documents.</li>
  <li>Your login access to GuardUp.</li>
</ul>

<h2>What We May Retain</h2>
<p>Records of completed bookings, payouts and any safety reports may be kept for the period required by law for tax, accounting, fraud-prevention and dispute-resolution purposes.</p>

<h2>This Action Is Permanent</h2>
<p>A deleted account cannot be restored. To work on GuardUp again you will need to register and complete verification again.</p>
$html$),

  /* ----------------------------------------------------------
     GUARD - SUPPORT (en)
     ---------------------------------------------------------- */
  ('GUARD', 'en', 'SUPPORT', $html$
<h1>Help &amp; Support</h1>
<p>Our support team is here to help you with verification, bookings and payouts.</p>

<h2>Contact Us</h2>
<ul>
  <li><strong>In-app:</strong> Profile &rarr; Contact Us</li>
  <li><strong>Email:</strong> support@guardup.com</li>
  <li><strong>Hours:</strong> 10:00 AM &ndash; 7:00 PM (Mon&ndash;Sat)</li>
</ul>

<h2>We Can Help With</h2>
<ul>
  <li>Document upload and account verification</li>
  <li>Booking requests and schedule issues</li>
  <li>Payouts, fees and earnings</li>
  <li>Disputes or concerns about a customer</li>
</ul>

<h2>Safety on Duty</h2>
<p>If you or your customer are in immediate danger, contact your <strong>local police or emergency services</strong> first, then inform GuardUp as soon as it is safe to do so.</p>
$html$),

  /* ----------------------------------------------------------
     COMPANY - TERMS (en)
     ---------------------------------------------------------- */
  ('COMPANY', 'en', 'TERMS', $html$
<h1>Terms &amp; Conditions for Security Companies</h1>
<p>These Terms &amp; Conditions govern your use of <strong>GuardUp</strong> as a security company or agency. By registering, you agree to these terms on behalf of your company.</p>

<h2>1. Authority</h2>
<p>The person registering confirms they are authorised to act on behalf of the company and to accept these terms.</p>

<h2>2. Licensing &amp; Verification</h2>
<ul>
  <li>Your company must be legally registered and hold every licence required to provide security services in its area of operation.</li>
  <li>You must upload genuine registration and licensing documents and keep them valid.</li>
  <li>Your account is reviewed by our admin team before you can accept bookings.</li>
</ul>

<h2>3. Responsibility for Personnel</h2>
<p>You are fully responsible for the personnel you deploy, including:</p>
<ul>
  <li>Background checks, training and valid licences for every guard.</li>
  <li>Their conduct, which must be lawful, professional and respectful.</li>
  <li>Employment, payroll, tax and insurance obligations.</li>
</ul>

<h2>4. Bookings &amp; Service Delivery</h2>
<p>You must deliver the service agreed in each booking, with the agreed number of qualified personnel, at the agreed time and place. You must refuse any request that is unlawful or unsafe and report it to GuardUp.</p>

<h2>5. Confidentiality</h2>
<p>All customer information, locations and schedules must be kept strictly confidential by your company and personnel.</p>

<h2>6. Fees &amp; Payments</h2>
<p>Applicable platform or membership fees are shown in the app. Payments are settled according to the payout terms displayed in your account.</p>

<h2>7. Suspension &amp; Termination</h2>
<p>GuardUp may suspend or remove your company for breaches of these terms, expired licences, verified complaints or legal requirements.</p>

<h2>8. Limitation of Liability</h2>
<p>To the maximum extent permitted by law, GuardUp is not liable for any loss arising from services delivered by your company or personnel.</p>

<h2>9. Contact</h2>
<p>For questions about these terms, contact <strong>support@guardup.com</strong>.</p>
$html$),

  /* ----------------------------------------------------------
     COMPANY - PRIVACY_POLICY (en)
     ---------------------------------------------------------- */
  ('COMPANY', 'en', 'PRIVACY_POLICY', $html$
<h1>Privacy Policy for Security Companies</h1>
<p>This Privacy Policy explains how <strong>GuardUp</strong> handles information about your company and its representatives.</p>

<h2>1. Information We Collect</h2>
<ul>
  <li><strong>Company details:</strong> company name, business email, phone number, address, services and rates.</li>
  <li><strong>Representative details:</strong> name and contact details of the account holder.</li>
  <li><strong>Verification documents:</strong> registration certificates, licences and other documents you upload.</li>
  <li><strong>Booking &amp; payment data:</strong> assignments, ratings, reviews and payout records.</li>
  <li><strong>Device &amp; usage data:</strong> device type, app version and diagnostic logs.</li>
</ul>

<h2>2. How We Use Your Information</h2>
<ul>
  <li>To verify your company and its licences.</li>
  <li>To display your company profile to customers and send you booking requests.</li>
  <li>To process payments and keep financial records.</li>
  <li>To prevent fraud and meet legal obligations.</li>
</ul>

<h2>3. Personnel Data</h2>
<p>If you share information about your personnel with GuardUp or with customers, you are responsible for having a lawful basis and any required consent to do so.</p>

<h2>4. Sharing</h2>
<p>Customers can see your public company profile. Verification documents are only reviewed by authorised GuardUp administrators. We share data with service providers acting on our behalf and with authorities where required by law. We never sell your information.</p>

<h2>5. Retention &amp; Security</h2>
<p>Information is stored securely and kept while your account is active and as required by law.</p>

<h2>6. Contact</h2>
<p>For privacy questions, contact <strong>support@guardup.com</strong>.</p>
$html$),

  /* ----------------------------------------------------------
     COMPANY - ABOUT_US (en)
     ---------------------------------------------------------- */
  ('COMPANY', 'en', 'ABOUT_US', $html$
<h1>About GuardUp</h1>
<p><strong>GuardUp</strong> helps licensed security companies reach customers who need reliable, professional protection services.</p>

<h2>Why GuardUp</h2>
<ul>
  <li><strong>Reach more customers:</strong> present your company, services and rates to people actively looking for security.</li>
  <li><strong>Manage bookings easily:</strong> receive and handle booking requests from one place.</li>
  <li><strong>Grow your reputation:</strong> collect ratings and reviews for every assignment you deliver.</li>
</ul>

<h2>Verified Partners</h2>
<p>Every company on GuardUp is verified by our admin team before going live, so customers can book with confidence.</p>

<h2>Our Commitment</h2>
<p>We are committed to transparent fees, fair treatment and long-term partnerships with the security companies on our platform.</p>
$html$),

  /* ----------------------------------------------------------
     COMPANY - DELETE_ACCOUNT (en)
     ---------------------------------------------------------- */
  ('COMPANY', 'en', 'DELETE_ACCOUNT', $html$
<h1>Delete Your Company Account</h1>
<p>You can permanently delete your GuardUp company account at any time. Please read the following before continuing.</p>

<h2>Before You Delete</h2>
<ul>
  <li>Complete or cancel all active and upcoming bookings.</li>
  <li>Make sure all pending payouts and invoices have been settled.</li>
  <li>Download any statements or records you may need.</li>
</ul>

<h2>How to Delete</h2>
<p>Go to <strong>Profile &rarr; Delete Account</strong> in the app and confirm. If you cannot access the app, email <strong>support@guardup.com</strong> from your registered business email address.</p>

<h2>What Gets Deleted</h2>
<ul>
  <li>Your company profile, services and rates.</li>
  <li>Your uploaded registration and licensing documents.</li>
  <li>Login access for your company account.</li>
</ul>

<h2>What We May Retain</h2>
<p>Records of completed bookings, payments and any safety reports may be kept for the period required by law for tax, accounting, fraud-prevention and dispute-resolution purposes.</p>

<h2>This Action Is Permanent</h2>
<p>A deleted company account cannot be restored. You will need to register and complete verification again to return to GuardUp.</p>
$html$),

  /* ----------------------------------------------------------
     COMPANY - SUPPORT (en)
     ---------------------------------------------------------- */
  ('COMPANY', 'en', 'SUPPORT', $html$
<h1>Help &amp; Support</h1>
<p>Our partner support team is here to help your company with verification, bookings and payments.</p>

<h2>Contact Us</h2>
<ul>
  <li><strong>In-app:</strong> Profile &rarr; Contact Us</li>
  <li><strong>Email:</strong> support@guardup.com</li>
  <li><strong>Hours:</strong> 10:00 AM &ndash; 7:00 PM (Mon&ndash;Sat)</li>
</ul>

<h2>We Can Help With</h2>
<ul>
  <li>Company verification and document uploads</li>
  <li>Booking requests and assignment issues</li>
  <li>Fees, invoices and payouts</li>
  <li>Disputes or concerns about a customer</li>
</ul>

<h2>Emergencies</h2>
<p>If your personnel or a customer are in immediate danger, contact <strong>local police or emergency services</strong> first, then inform GuardUp as soon as it is safe to do so.</p>
$html$)

) AS v(role, language, content_type, content_html)
ON CONFLICT (role, content_type, language) DO NOTHING;
