# 🏗️ GuardUp App Architecture Refactoring Plan

**File:** `documentation/app_architecture_refactoring_plan.md`  
**Target Codebase:** `guardup/` (Flutter Mobile App)  
**Reference Architecture:** `guardup_admin/` (Clean, Type-Safe, DB-Mirrored)  

---

## 1. Executive Summary & Objectives

The goal of this refactoring is to bring the mobile app (`guardup/`) up to the clean, type-safe, and well-structured architectural standard established in the admin panel (`guardup_admin/`).

### Primary Objectives:
1. **Eliminate Untyped Maps & "Faltu Getters"**: Remove `Map<String, dynamic>? userData` and the ~30 string-indexed map getters from `AuthState`. Replace them with a single strongly-typed `UserModel? user`.
2. **Eliminate Fake & Phantom Fields**: Strip out columns from `BodyGuardModel` and `CompanyModel` that do not exist in the database (e.g. `currency`, `clearanceLevel`, `isVerified`, `totalCompletedMissions`, `licensesAndBadges`, `activeGuards`, `reviewCount`, `bookingsCount`).
3. **Align 1:1 with Database Schema**: Model `UserModel`, `BodyGuardModel`, and `CompanyModel` directly from the PostgreSQL schema, using strongly-typed relational embeddings (`user.bodyguard`, `user.company`, `user.documents`, `user.availabilities`, `user.services`).
4. **Fix Individual Guard Profile Loading**: Fix the root cause where individual guards cannot view or update their Experience, Languages, Certifications, Bio, and Hourly Rate on their profile screen (which works on the company side because the company side passes a typed `BodyGuardModel`).
5. **Standardize Repositories**: Extend and properly leverage `BaseSupabaseRepository<T>` for CRUD, type deserialization, and error handling.

---

## 2. Database Schema (Source of Truth)

All models must strictly reflect the PostgreSQL schema without inventing arbitrary fields:

```sql
-- 1. Identity & Account (One per login)
CREATE TABLE public.users (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  phone_number TEXT NULL,
  phone_code TEXT NULL DEFAULT '+91',
  role public.user_role NOT NULL DEFAULT 'CUSTOMER',
  status public.user_status NOT NULL DEFAULT 'INCOMPLETE',
  profile_image_url TEXT NULL,
  metadata JSONB NULL DEFAULT '{}',
  is_push_notification_enabled BOOLEAN NOT NULL DEFAULT true,
  rejection_reason TEXT NULL,
  gender public.gender_type NULL DEFAULT 'MALE',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Company Profile (1:1 with users for role = COMPANY)
CREATE TABLE public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  company_name TEXT,
  business_email TEXT,
  company_type TEXT,
  company_phone_code TEXT DEFAULT '+91',
  company_phone_number TEXT,
  experience_years INTEGER DEFAULT 0,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  license_number TEXT,
  status public.user_status NOT NULL DEFAULT 'PENDING',
  rejection_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Bodyguard Profile (Self-registered: user_id set; Company-managed: company_id set, user_id NULL)
CREATE TABLE public.bodyguards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  profile_image_url TEXT,
  hourly_rate NUMERIC(10, 2) DEFAULT 0.00,
  rating NUMERIC(2, 1) DEFAULT 0.0,
  experience_years INTEGER DEFAULT 0,
  bio TEXT,
  languages TEXT,
  certifications TEXT,
  service_area TEXT,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_active BOOLEAN NOT NULL DEFAULT true,
  status public.user_status NOT NULL DEFAULT 'PENDING',
  rejection_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT bodyguards_owner_check CHECK (user_id IS NOT NULL OR company_id IS NOT NULL)
);

-- 4. Child Relations (Ownership check: exactly one of user_id OR bodyguard_id is set)
-- public.user_services (service_id, user_id, bodyguard_id)
-- public.user_documents (document_type_id, file_url, file_name, status, rejection_reason, user_id, bodyguard_id)
-- public.user_availabilities (day_of_week, start_time, end_time, is_available, user_id, bodyguard_id)
-- public.user_bank_accounts (user_id, account_holder_name, account_number, ifsc_code, bank_name, is_primary)
```

---

## 3. Root-Cause Analysis: Admin vs. App Architecture

### The Admin Architecture (`guardup_admin`)
- `UserModel` contains all account fields and nested relation models:
  ```dart
  final CompanyModel? company;
  final BodyguardModel? bodyguard;
  final List<UserDocumentModel>? documents;
  final List<UserAvailabilityModel>? availabilities;
  final List<ServiceModel>? serviceListData;
  final List<UserBankAccountModel>? bankAccounts;
  ```
- No untyped maps in state; properties are accessed directly: `state.user.company?.companyName`, `state.user.bodyguard?.experienceYears`.
- `BaseSupabaseRepository<T>` handles CRUD operations cleanly and safely.

### The App's Flaws & Why Individual Bodyguard Profile Failed
1. **Anemic `UserModel`**: App's `UserModel` only has 6 fields (`id`, `name`, `profileImageUrl`, `role`, `createdAt`, `updatedAt`).
2. **Untyped Map `userData` in `AuthState`**: Because `UserModel` was incomplete, the app dumped raw JSON into `userData` and created ~30 manual string getters (`userData?['phone_code']`, `userData?['experience_years']`).
3. **The Profile Screen Bug**:
   - For **Company-Managed Bodyguards**: `widget.bodyguard` is passed as a populated `BodyGuardModel` (`guard`). It reads `guard.experienceYears`, `guard.languages`, and `guard.certifications` directly from the model. **This is why it works on the company side.**
   - For **Individual Bodyguards**: `widget.bodyguard` is `null`. The profile screen falls back to `AuthState`: `state.experienceYears`, `state.languages`, `state.certifications`, `state.bio`, `state.hourlyRate`.
   - In `AuthState`, these getters read `userData?['experience_years']`, `userData?['languages']`, etc. But since the profile split, these columns live in the **`bodyguards` table** (`public.bodyguards`), which Supabase returns nested under `userData['bodyguard']`. Because `AuthState` never looked inside `userData['bodyguard']`, it **always returned `0` for experience and empty for languages/certifications/bio/rate**!

---

## 4. Target Architecture

```
                               Target Clean Architecture

  Supabase Database
         │
         ▼
  BaseSupabaseRepository<UserModel>
         │
         ▼ (Deserializes joined query into typed aggregate)
     UserModel
       ├── id, email, name, phoneNumber, phoneCode, role, status, gender, ...
       ├── CompanyModel? company (1:1 with public.companies)
       ├── BodyGuardModel? bodyguard (1:1 with public.bodyguards)
       ├── List<UserDocumentModel>? documents (1:1 with public.user_documents)
       ├── List<UserAvailabilityModel>? availabilities (1:1 with public.user_availabilities)
       └── List<ServiceItemModel>? services (1:1 with public.user_services)
         │
         ▼
     AuthState (Only holds `final UserModel? user;`)
         │
         ▼ (Direct type-safe property access across UI)
     state.user?.name
     state.user?.bodyguard?.experienceYears
     state.user?.bodyguard?.languages
     state.user?.bodyguard?.certifications
     state.user?.bodyguard?.hourlyRate
     state.user?.company?.companyName
```

---

## 5. Step-by-Step Implementation Roadmap

### Step 1: Domain & Data Models Alignment
1. **Refactor `UserModel` (`guardup/lib/features/auth/data/model/user.model.dart`)**:
   - Add all database columns: `email`, `phoneCode`, `phoneNumber`, `gender`, `status`, `rejectionReason`, `isPushNotificationEnabled`, `metadata`.
   - Add typed relation fields:
     ```dart
     final CompanyModel? company;
     final BodyGuardModel? bodyguard;
     final List<UserDocumentModel>? documents;
     final List<UserAvailabilityModel>? availabilities;
     final List<ServiceItemModel>? services;
     final List<UserBankAccountModel>? bankAccounts;
     ```
   - Update `fromJson` and `toJson` to handle nested deserialization (matching `guardup_admin`'s approach).

2. **Refactor `BodyGuardModel` (`guardup/lib/features/body_guard/data/models/body_guard.model.dart`)**:
   - **Remove phantom columns**: `currency`, `clearanceLevel`, `isVerified`, `totalCompletedMissions`, `licensesAndBadges`.
   - **Retain 1:1 DB columns**: `id`, `userId`, `companyId`, `name`, `profileImageUrl`, `hourlyRate`, `rating`, `experienceYears`, `bio`, `languages`, `certifications`, `serviceArea`, `address`, `latitude`, `longitude`, `isActive`, `status`, `rejectionReason`, `createdAt`, `updatedAt`.
   - Reuse standard child models: `UserDocumentModel` and `UserAvailabilityModel`.

3. **Refactor `CompanyModel` (`guardup/lib/features/company/data/models/company.model.dart`)**:
   - **Remove phantom columns**: `activeGuards`, `reviewCount`, `bookingsCount`, `isVerified`, `isOnline`.
   - **Retain 1:1 DB columns**: `id`, `userId`, `companyName`, `businessEmail`, `companyType`, `companyPhoneCode`, `companyPhoneNumber`, `experienceYears`, `address`, `latitude`, `longitude`, `licenseNumber`, `status`, `rejectionReason`, `createdAt`, `updatedAt`.

4. **Code Generation**:
   - Run `dart run build_runner build --delete-conflicting-outputs` in `guardup/`.

---

### Step 2: Repository Standardization (`BaseSupabaseRepository`)
1. **Refactor `SupabaseUserRepository`**:
   - Inherits `BaseSupabaseRepository<UserModel>`.
   - Update `_fetchProfileRow` / `getUserProfile` to select joined relations:
     ```dart
     .select('''
       *,
       bodyguard:bodyguards!bodyguards_user_id_fkey(*),
       company:companies!companies_user_id_fkey(*),
       documents:user_documents!user_documents_user_id_fkey(*),
       availabilities:user_availabilities!user_availabilities_user_id_fkey(*)
     ''')
     ```
   - Deserialize directly into `UserModel.fromJson(response)`.
   - Eliminate raw untyped `Map<String, dynamic>` returns.

2. **Refactor `BodyguardRepository`**:
   - Inherits `BaseSupabaseRepository<BodyGuardModel>`.
   - Use typed deserializer `BodyGuardModel.fromJson`.

---

### Step 3: AuthState & AuthBloc Cleanup
1. **Remove Untyped Map & String Getters from `AuthState`**:
   - Delete `final Map<String, dynamic>? userData;`.
   - Delete all ~30 string-indexed map getters (`userData?['...']`).
2. **Expose Typed Properties on `AuthState`**:
   - `final UserModel? user;`
   - Clean typed forwarders:
     ```dart
     UserModel? get user;
     String get displayName => user?.company?.companyName ?? user?.name ?? '';
     String get email => user?.email ?? '';
     String get phoneNumber => user?.phoneNumber ?? '';
     String get phoneCode => user?.phoneCode ?? '+91';
     UserRole get role => user?.role ?? UserRole.customer;
     UserStatus get status => user?.status ?? UserStatus.incomplete;
     
     // Typed Guard helpers:
     BodyGuardModel? get guardProfile => user?.bodyguard;
     int get experienceYears => guardProfile?.experienceYears ?? 0;
     String get languages => guardProfile?.languages ?? '';
     String get certifications => guardProfile?.certifications ?? '';
     String get bio => guardProfile?.bio ?? '';
     num get hourlyRate => guardProfile?.hourlyRate ?? 0;
     double get rating => guardProfile?.rating ?? 4.95;
     String get guardAddress => guardProfile?.address ?? '';
     double? get guardLatitude => guardProfile?.latitude;
     double? get guardLongitude => guardProfile?.longitude;
     String? get guardBodyguardId => guardProfile?.id;
     ```
3. **Simplify `AuthBloc`**:
   - Emits `AuthState` directly containing the strongly-typed `UserModel`.

---

### Step 4: UI Screen & Tab Integration
1. **Fix `BodyGuardProfileScreen` (`body_guard_profile_screen.dart`)**:
   - For an individual guard, use `state.guardProfile` (typed `BodyGuardModel`) as `guard`.
   - Both individual guard and company guard will share the exact same typed property access:
     ```dart
     final guard = isCompanyGuard ? widget.bodyguard! : state.guardProfile;
     final experienceYears = guard?.experienceYears ?? 0;
     final languages = guard?.languages ?? '';
     final certifications = guard?.certifications ?? '';
     final bio = guard?.bio;
     final hourlyRate = guard?.hourlyRate ?? 60.0;
     final location = guard?.address ?? 'Location not set';
     ```
   - Pass `guard?.id` to `EditKeyDetailsSheet`, `EditBioSheet`, and `EditServicesSheet`.
2. **Update Edit Sheets & Action Callbacks**:
   - Save directly to `bodyguards` table using `guard.id`.
   - Refresh state via `AuthCheckStatusRequested`.
3. **Clean Up UI Call-Sites**:
   - Update guard cards, company profile views, and registration sheets to read from typed model getters instead of map indexers.

---

### Step 5: Verification & Quality Gates
1. Run `flutter analyze` across `guardup/` to ensure **0 errors, 0 warnings**.
2. Run `flutter analyze` across `guardup_admin/` to ensure **0 errors, 0 warnings**.
3. Adhere to Git staging rule:
   - Non-app files (`documentation/`, `supabase/`, `guardup_admin/`) remain staged.
   - App files (`guardup/`) remain unstaged.
