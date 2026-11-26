# GuardUp

> On-demand personal security and bodyguard booking platform for iOS, Android, and Web.

---

## 📁 Repository Structure

```
GuardUp/
├── documentation/                   # Architecture, requirements & workflows
│   ├── initial/                     # Original specifications & assets
│   └── system_analysis_and_architecture.md
├── guardup/                         # Flutter Mobile App (Customer & Bodyguard)
├── guardup-admin/                   # Super Admin Web Panel (Coming soon)
├── .gitignore
└── README.md
```

---

## 🚀 Quick Start

### Mobile App (Flutter)
```bash
cd guardup
flutter pub get
flutter run
```

### Documentation
Refer to [system_analysis_and_architecture.md](documentation/system_analysis_and_architecture.md) for full project specifications, flows, and technical details.

For user status changes, push notifications, emails and the related database triggers, see [notifications_and_user_lifecycle.md](documentation/notifications_and_user_lifecycle.md).

For deleting users (what is removed, who can do it, security guards), see [user_deletion.md](documentation/user_deletion.md).

For reviewing applications (approve / reject documents and profiles, rejection reasons), see [user_review_and_rejection.md](documentation/user_review_and_rejection.md).

For user profile data (users, availability, bank accounts, documents) and what the admin User Details screen shows, see [user_profile_data.md](documentation/user_profile_data.md).

For contact / support requests (statuses, RLS, admin Help & Support screen), see [contact_us.md](documentation/contact_us.md).

For customer membership plans (pricing, booking discount rules, admin management), see [membership_plans.md](documentation/membership_plans.md).

For the customer company and bodyguard listings (filters, solo vs company-managed guards, the `account_status` / `listing_*` computed fields), see [user_profiles.md → Listings and filters](documentation/user_profiles.md#listings-and-filters-mobile-app).

For the protection services catalogue (table, RLS, service icons and the `admin` storage bucket), see [services.md](documentation/services.md).

