# GuardUp Update DOC

**Date:** November 26, 2026

---

## 1. App Download & Installation

| Platform | Link | Email | Password |
|----------|------|-------|----------|
| **Admin** | [Admin Panel](https://guardup-991fd.web.app/) | admin@gmail.com | 123456 |
| **Android app** | [GuardUp APK](https://drive.google.com/file/d/1ISIm2U2ce6K8KKp0ZuXqkzE56RvJPXcd/view?usp=share_link) | Customer: amanm.webwiders+customer@gmail.com | 123456 for all |
| | | BodyGuard: amanm.webwiders+guard@gmail.com | |
| | | Company: amanm.webwiders+company@gmail.com | |
| **iOS app** | [GuardUp IPA](https://ioair.link/p4vthr) | Same as above | Same as above |

> [!NOTE]
> Please uninstall the old app and install the new APK/IPA before testing.

---

## App-Side Work

### 1. Guard Management (Company Side)

Companies can now manage their own bodyguard operatives directly within the app. This covers the full lifecycle from onboarding a new guard through approval, to viewing their profile, documents, availability, and bookings.

#### 1.1 Add Guard

- A Company can tap **Add** on the My Bodyguards screen to register a new guard under their company.
- The form collects the guard's full name, hourly rate, bio, and services offered — the same profile fields used in standalone guard sign-up.
- After saving, the new guard appears in the company's list with a **Pending** status.

#### 1.2 Guard Status Tabs (Pending / Approved / Rejected)

- The Company Bodyguards screen shows all guards in tabs: **All**, **Approved**, **Pending**, and **Rejected**.
- Each tab filters the paginated list to the relevant status so the company can quickly see which guards still need action.
- Guards can be searched by name within the list.

#### 1.3 Guard Approval & Rejection Flow

- When the admin reviews a guard added by a company, they can approve or reject documents and the profile (same admin document-review flow as before).
- Rejected guards appear in the **Rejected** tab; the company can tap a guard to see the rejection reason and re-upload documents or edit the profile.
- Once all documents are approved, the guard moves to **Approved** and the company is notified.

#### 1.4 Guard Detail Screen (Company View)

After a guard is approved, the company can tap any guard card to open their full detail screen. The detail screen has three tabs:

- **Overview** — Shows the guard's join date, operative biography, operational metrics (hourly rate, experience, rating), tactical clearance, and assigned services.
- **Document** — Lists every document the guard has uploaded with its status (Approved / Pending / Rejected). Rejected documents show the reason. Each document can be opened and previewed in-app.
- **Booking** — Shows the guard's booking history under the company.

The company can tap **Edit** on a guard card to update their profile, or **Delete** to remove them (with a confirmation popup).

#### 1.5 Guard Availability (Company View)

- Inside the guard's profile (accessible to both the guard themselves and their company), the **My Availability** tab lets the guard set their available days and working hours for each day of the week.
- Each day of the week can be toggled on (available) or off (day off). When toggled on, a "From" and "To" time picker appears for that day.
- Changes are saved with the **Save Availability** button. The saved schedule is reflected when customers browse or book.

#### 1.6 Guard Profile Self-Edit (Guard Side)

Guards can also edit their own profile from their home screen:

- **About tab** — Edit bio, key details (experience, hourly rate, location, languages, certifications, qualifications), and assigned services using bottom-sheet editors.
- **My Availability tab** — Toggle days and set hours for the week.
- **My Documents tab** — View document statuses and upload additional documents.
- **Reviews tab** — View client reviews and ratings (UI ready; data to be integrated in a later update).

---

### 2. Customer Side — Guard & Company Listing, Detail, and Filtering

#### 2.1 Guard & Company Listing Screen

- Customers now see a unified **Bodyguards & Security** listing screen accessible from the home screen.
- The screen has two pill tabs at the top: **Solo** and **Company**.
  - **Solo tab** — Shows individual bodyguards (not under any company). Each card shows the guard's photo, name, specialisation, rating, hourly rate, and location.
  - **Company tab** — Shows verified security companies. Each card shows the company logo, name, services, rating, and operative count.
- Both lists are paginated and update live as the customer scrolls down.
- A live search bar at the top filters both lists by name. Typing is debounced so results update smoothly as the customer types.
- Tapping a guard card opens the **Guard Detail Screen**. Tapping a company card opens the **Company Detail Screen**.

#### 2.2 Guard Detail Screen (Customer View)

The guard detail screen adapts for the customer role and has three tabs:

- **About** — Shows the guard's bio and an interactive booking duration selector. The customer picks a start date, start time, end date, and end time. The **Grand Total** in the sticky bottom bar updates live as the duration changes (hourly rate × hours).
- **Experience** — Shows years of experience, specialisation title, and the list of services the guard offers.
- **Reviews** — Shows the guard's average rating, total review count, and individual reviews (UI ready; reviews data will be populated in a later update).

A sticky **Book Now** button is always visible at the bottom. Tapping it shows a "Coming soon" message until the full booking flow is live.

#### 2.3 Company Detail Screen (Customer View)

Tapping a company card opens its profile with:

- A header card showing the company logo, name, operative count, live presence indicator, rating, and a **Book Now** button.
- **About tab** — Shows the company's joined date, description, and verified documents.
- **Bodyguards tab** — Shows all approved guards deployed under that company. The customer can tap a guard in this list to open their Guard Detail Screen.
- **Reviews tab** — Shows the company's rating and client reviews (UI ready; data to be integrated later).

The **Book Now** button on the company screen shows "Coming soon" until the booking flow is complete.

#### 2.4 Guard & Company Search / Filter

Customers can open an advanced filter screen from the listing screen. The filter screen supports:

- **Location / Address** — Type an address to find guards near a location.
- **Gender** — Filter by Any, Male, or Female.
- **Hourly Rate** — A range slider from \$0 to \$300 to set a minimum and maximum rate.
- **Rating** — Filter by All Ratings, 4.5 & Above, 4.0 & Above, or 3.5 & Above.
- **Service Type** — Opens a service picker sheet where the customer can search and select one or more services. Selected services are highlighted.
- **Availability** — Filter by the guard's current availability status.
- **Company** — Opens a company picker sheet where the customer can pick a specific company to browse only that company's guards.

A blue dot badge appears on the filter icon when any filter is active so the customer always knows filters are applied.

Tapping **Apply** closes the filter and refreshes the list with the selected criteria.

#### 2.5 All Services Screen

- Tapping **See All** on the customer home screen opens the full **All Services** screen.
- Services are shown in a responsive grid. Each tile shows the service icon and name.
- A search bar at the top lets the customer search services by name or description.
- Tapping a service tile takes the customer to the bodyguard listing pre-filtered to that service.

#### 2.6 Booking Flow — Guard Route

When the customer taps **Book Now** on the guard detail screen, the app passes the selected start date, start time, end date, end time, and hourly rate to the **Booking Details screen**:

- Shows the guard's photo, name, and key details.
- Displays a payment summary: operative subtotal (rate × hours), platform discount, and final total.
- A **Confirm Booking** button progresses to the payment confirmation screen (full payment integration coming in a later update).

#### 2.7 Booking Flow — Company Route

When booking through a company, the **Company Booking screen** lets the customer:

- Pick a start and end date and time.
- Search for and select a specific guard from the company's approved roster using an in-screen search bar.
- The selected guard's card is highlighted with a checkbox.
- A payment summary at the bottom updates based on the selected guard's rate and chosen duration.

---

### 3. Company Home Screen Updates

- The company home screen now shows a live **operative overview card** (total guards, active bookings) using real data.
- A **My Bodyguards** mini-roster is displayed on the home screen, showing the first few guards with their status badges. Tapping **See All** opens the full Guard Management screen.
- The **Latest Bookings** section is live with real data fetched and paginated on the home screen.
- The company header in the app bar shows the company's real name, logo, and profile data.

---

### 4. Guard Home Screen Updates

- The guard home screen shows real **Earnings**, **Bookings**, and **Rating** metric cards fetched live.
- A **Latest Bookings** section shows recent booking cards (guard perspective) with pagination.
- A **Transaction History** section lists the guard's payment transactions with pagination.

---

### 5. Miscellaneous

- **Role-adaptive Guard Detail Screen** — The same `GuardDetailScreen` is used for both Company and Customer roles. The app detects the logged-in role automatically and shows the right tabs and CTAs (Edit/Delete for Company; Book Now for Customer).
- **Skeleton loaders** — The guard listing screen shows animated skeleton placeholders while the first page of data is loading, so the app feels fast and polished.
- **Empty states** — If no guards or companies match the search or filters, a friendly empty state is shown with a relevant icon and message.
- **Debounced search** — All search fields across the guard list, company list, and company bodyguards screen use a 500ms debounce so the backend is not hit on every keystroke.
- **Paginated feeds** — All lists (guards, companies, company guards, bookings, transactions) use the shared `AppPagination` widget with pull-to-refresh and infinite scroll.
- **In-app document preview** — On the company view of a guard's Document tab, tapping **View Document** opens an in-app file preview sheet without leaving the app.

---

## Clarifications

### Booking Flow — Next Steps

The UI for booking a guard (solo route) and booking through a company is now complete. The flow ends at the payment confirmation screen. Before we wire in real payments, please clarify:

1. **Payment Gateway** — Which payment provider should we integrate? (e.g. Stripe, Razorpay, PayPal)
2. **Booking Confirmation** — After payment succeeds, what does the customer see? Should the guard / company get a push notification?
3. **Guard Acceptance** — Does a guard need to accept a booking before it is confirmed, or is it auto-confirmed after payment?
4. **Cancellation Policy** — Can a customer cancel a booking? Within what time window, and is any refund given?
5. **Reviews & Ratings** — After a completed booking, should the customer be prompted to leave a review for the guard and/or company?

---

*Feedback: Please share your feedback here.*

---

Thanks and Best Regards,
**Shweta Aggrawal**
