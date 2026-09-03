# X-FatHub 🏋️‍♂️📱

[![Flutter](https://img.shields.io/badge/Flutter-v3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-v3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend%20%26%20Auth-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![SQLite](https://img.shields.io/badge/SQLite-Offline%20Cache-003B57?logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![Stripe](https://img.shields.io/badge/Stripe-Checkout%20Integration-635BFF?logo=stripe&logoColor=white)](https://stripe.com)

**X-FatHub** is an all-in-one mobile fitness and wellness platform built with Flutter. It blends hardware-driven activity tracking, gym and fitness package bookings with Stripe payments, an interactive social fitness community, and personalized health profiling into a dark-themed mobile experience.

---

## 📑 Table of Contents

- [Core Modules & Features](#-core-modules--features)
  - [1. Activity & Health Tracking](#1-activity--health-tracking)
  - [2. Booking & Gym Management](#2-booking--gym-management)
  - [3. Community Management](#3-community-management)
  - [4. User Profile & Authentication](#4-user-profile--authentication)
  - [5. Home Dashboard](#5-home-dashboard)
- [Architecture & Core Services](#-architecture--core-services)
- [Deep Linking & URI Scheme](#-deep-linking--uri-scheme)
- [Project Directory Structure](#-project-directory-structure)
- [Tech Stack & Dependencies](#-tech-stack--dependencies)
- [Supabase Backend & Edge Functions](#-supabase-backend--edge-functions)
- [Getting Started & Setup](#-getting-started--setup)
  - [Prerequisites](#prerequisites)
  - [Installation Steps](#installation-steps)
  - [Environment Configuration](#environment-configuration)
- [Android Permissions & Setup](#-android-permissions--setup)
- [Testing](#-testing)

---

## 🚀 Core Modules & Features

### 1. Activity & Health Tracking
Located in [`lib/features/activity_health`](file:///d:/Siew%20Feng/Archive/X-FatHub/lib/features/activity_health):
- **Hardware Pedometer & Daily Step Tracker**:
  - Direct hardware step sensor integration using `pedometer`.
  - Continuous step counting via background service (`flutter_background_service`) and periodic sync via `workmanager`.
  - Midnight reset logic with baseline recalibration to accurately separate daily counts.
  - Interactive daily step history and graphical visualization powered by `fl_chart`.
  - Offline step logging via SQLite (`LocalActivityDatabase`) with cloud synchronization to Supabase.
- **Hydration Logging & Reminders**:
  - Quick-add water intake presets (+250ml, +500ml, custom amount) with real-time circular progress tracking toward daily hydration goals.
  - Hydration log history and daily intake summaries.
  - Automated hydration reminders sent through local notification channels.
- **GPS Outdoor Activity Tracking**:
  - Real-time GPS workout tracking for running, jogging, and cycling.
  - Interactive live maps utilizing OpenStreetMap via `flutter_map` and `latlong2`.
  - Live metrics calculation: elapsed duration, distance, pace, speed, and estimated calories burned.
  - Route drawing with coordinate persistence (`activity_locations`).
  - Workout summary screen with interactive route replay and past activity history.

### 2. Booking & Gym Management
Located in [`lib/features/booking`](file:///d:/Siew%20Feng/Archive/X-FatHub/lib/features/booking):
- **Fitness Packages & Classes**:
  - Browse gym passes, personal training, and group class packages with search and category filtering (Gym, Yoga, HIIT, Pilates, Boxing).
  - Package details detailing session count, validity period, benefits, and rules.
- **Slot Selection & Booking**:
  - Choose workout time slots, dates, and coaches.
  - Dynamic slot status tracking and session count validation.
- **Interactive Gym Map & Navigation**:
  - In-app OpenStreetMap view ([`GymLocationViewScreen`](file:///d:/Siew%20Feng/Archive/X-FatHub/lib/features/booking/views/gym_location_view_screen.dart)) resolving gym addresses via `geocoding`.
  - One-tap external launch to **Google Maps** and **Waze** for turn-by-turn driving directions.
- **Stripe Checkout Integration**:
  - Seamless payment handling through Supabase Edge Function (`create-checkout-session`).
  - Deep-link redirection back to the app on payment completion or cancellation.
- **Check-in QR Code Generation**:
  - Dynamic QR code generation (`qr_flutter`) containing verified booking ID and session data for quick gym desk check-in.
- **Multi-Version Offline Booking Cache**:
  - SQLite database cache (`LocalBookingDatabase` v3) supporting offline viewing of upcoming and past bookings, gym address metadata, and QR check-in passes.

### 3. Community Management
Located in [`lib/features/community`](file:///d:/Siew%20Feng/Archive/X-FatHub/lib/features/community):
- **Social Feed**:
  - Feed of user-shared fitness milestones, workouts, images, and videos.
  - Custom video playback support with inline controls (`video_player`).
  - Like interactions and threaded comments.
- **Rich Post Creation**:
  - Multi-image and video upload via `image_picker`.
  - Location tagging with interactive OpenStreetMap picker ([`MapPickerScreen`](file:///d:/Siew%20Feng/Archive/X-FatHub/lib/features/community/views/map_picker_screen.dart)).
  - Direct attachment of logged workouts and activities via [`ActivityPickerScreen`](file:///d:/Siew%20Feng/Archive/X-FatHub/lib/features/community/views/activity_picker_screen.dart).
- **Public Community Profiles**:
  - View member community profiles, total shared posts, and fitness badges.
- **Offline Community Cache**:
  - SQLite caching via `LocalCommunityDatabase` allowing users to view recent community feeds offline.

### 4. User Profile & Authentication
Located in [`lib/features/profile`](file:///d:/Siew%20Feng/Archive/X-FatHub/lib/features/profile):
- **Supabase Authentication**:
  - Email and password sign-in, account registration, and password recovery.
  - Deep link listener for email verification confirmation (`xfathub://auth/verified`).
- **Comprehensive Profile Dashboard**:
  - Personal health metrics: current weight, initial weight, target goal weight, height, and computed BMI.
  - Step goals and daily hydration targets.
  - Weight tracking history chart to visualize progress over time.
  - Milestone and achievement badges based on user workouts and consistency.
- **Profile Customization & Settings**:
  - Profile edit screen for bio, personal measurements, and avatar upload to Supabase Storage.
  - Application settings including notification toggles, permission status checks, cache clearing, password change with validation, and full account deletion (via `delete-user` Edge Function).

### 5. Home Dashboard
Located in [`lib/features/home`](file:///d:/Siew%20Feng/Archive/X-FatHub/lib/features/home):
- **Central Fitness Hub**:
  - Dynamic greeting with authenticated user profile data.
  - Daily quick stats cards: Steps vs. Goal, Hydration vs. Target, and Active Minutes.
  - Next upcoming gym session preview with direct tap-through to the check-in QR pass.
  - Today's activity overview and recent community highlights.
  - Pull-to-refresh to trigger global multi-viewmodel state sync.

---

## 🏛️ Architecture & Core Services

The app follows the **MVVM (Model-View-ViewModel)** architectural pattern with repository abstraction and offline-first synchronization:

```
┌────────────────────────────────────────────────────────┐
│                        UI View                         │
│       (Screens & Widgets - Black & Orange Theme)       │
└───────────────────────────▲────────────────────────────┘
                            │ listens / triggers
┌───────────────────────────┴────────────────────────────┐
│                       ViewModel                        │
│   (ChangeNotifier Providers: Step, Booking, Profile)   │
└───────────────────────────▲────────────────────────────┘
                            │ calls
┌───────────────────────────┴────────────────────────────┐
│                      Repository                        │
│          (Data abstraction & offline routing)          │
└─────────────┬────────────────────────────┬─────────────┘
              │                            │
              ▼                            ▼
┌───────────────────────────┐┌───────────────────────────┐
│       Local SQLite        ││     Supabase Service      │
│  - activity_cache.db      ││  - PostgreSQL + RLS       │
│  - booking_cache.db (v3)  ││  - Auth & Storage         │
│  - community_cache.db     ││  - Edge Functions         │
│  - profile_cache.db       ││  - Stripe Webhooks        │
└───────────────────────────┘└───────────────────────────┘
```

### Core Services (`lib/core/service`)

- **`PedometerService`**: Streams step sensor events, tracks hardware baseline, handles day transitions, and calculates daily step deltas.
- **`BackgroundService`**: Runs a continuous foreground task (`flutter_background_service`) ensuring uninterrupted step counting when the app is minimized.
- **`WorkManagerService`**: Periodic background task manager for syncing offline metrics with Supabase.
- **`LocationTrackingService` & `BackgroundLocationService`**: Battery-conscious GPS position streaming with distance filters and background foreground-service hooks.
- **`NotificationService`**: Multi-channel local notification manager:
  - `health_reminders` (High priority) — Hydration alerts and workout reminders.
  - `health_achievements` (Default priority) — Step goal milestone achievements.
  - `general` (Default priority) — General system and booking notices.
- **`PermissionService`**: Centralized runtime requester for Activity Recognition, Fine/Coarse/Background Location, Post Notifications (Android 13+), and Camera/Storage.
- **Network Awareness (`Connectivity`)**: Automatic recovery detection using `connectivity_plus` that refreshes remote feeds and flushes local changes when internet connection is restored.

---

## 🔗 Deep Linking & URI Scheme

X-FatHub registers the custom URI scheme `xfathub://` handled through an Android intent filter and native `MethodChannel` (`com.example.xfathub/deep_link`):

| URI Scheme | Handler | Destination |
| :--- | :--- | :--- |
| `xfathub://hydration` | Deep Link Channel | Navigates directly to [HydrationLogScreen](file:///d:/Siew%20Feng/Archive/X-FatHub/lib/features/activity_health/views/hydration_log_screen.dart) |
| `xfathub://payment/success` | Deep Link Channel | Navigates to [PaymentSuccessScreen](file:///d:/Siew%20Feng/Archive/X-FatHub/lib/features/booking/views/payment_success_screen.dart) |
| `xfathub://payment/cancel` | Deep Link Channel | Navigates to [PaymentCancelScreen](file:///d:/Siew%20Feng/Archive/X-FatHub/lib/features/booking/views/payment_cancel_screen.dart) |
| `xfathub://auth/verified` | Deep Link Channel | Navigates to [EmailVerifiedScreen](file:///d:/Siew%20Feng/Archive/X-FatHub/lib/features/profile/views/email_verified_screen.dart) |

---

## 📁 Project Directory Structure

```text
X-FatHub/
├── android/                         # Native Android configuration, manifest, services
├── ios/                             # Native iOS configuration
├── web/                             # Web configuration and assets
├── supabase/
│   ├── config.toml                  # Supabase local configuration
│   └── functions/                   # Deno-based Supabase Edge Functions
│       ├── create-checkout-session/ # Stripe Checkout session creator
│       ├── delete-user/             # Admin account deletion service
│       └── stripe-webhook/          # Stripe payment reconciliation webhook
├── supabase_migrations/
│   ├── init_schema.sql              # Complete database schema, tables, RLS, functions
│   ├── seed_dummy_data.sql          # Seed data (packages, gyms, slots, sample users)
│   └── reset_test_env.sql           # Database wipe and reset script
├── lib/
│   ├── assets/img/                  # App branding, SVG logos, launcher icons
│   ├── core/
│   │   ├── config/                  # Environment loader (env_config.dart)
│   │   ├── database/                # SQLite databases (booking, activity, community, profile)
│   │   ├── providers/               # MultiProvider registration (app_providers.dart)
│   │   └── service/                 # Pedometer, location, notifications, background services
│   ├── features/
│   │   ├── activity_health/         # Steps, Hydration, GPS Activity tracking
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   ├── viewmodels/
│   │   │   └── views/
│   │   ├── booking/                 # Packages, gym slots, maps, Stripe payment, QR check-in
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   ├── viewmodels/
│   │   │   └── views/
│   │   ├── community/               # Social feed, posts, comments, media player, map picker
│   │   │   ├── models/
│   │   │   ├── providers/
│   │   │   ├── repository/
│   │   │   ├── views/
│   │   │   └── widgets/
│   │   ├── home/                    # Central dashboard overview screen
│   │   │   └── views/
│   │   └── profile/                 # Auth, dashboard, settings, edit profile, metrics
│   │       ├── models/
│   │       ├── repositories/
│   │       ├── viewmodels/
│   │       └── views/
│   ├── routes/                      # Route definitions and bottom navigation bar shell
│   └── main.dart                    # App initialization, services setup, theme config
├── DEBUG_STEP_RESET.md              # Troubleshooting guide for pedometer midnight reset
├── NOTIFICATION_SERVICE_GUIDE.md    # Multi-channel notification architecture guide
├── example.env                      # Template environment variable configuration
└── pubspec.yaml                     # Dependencies and asset declarations
```

---

## 🛠️ Tech Stack & Dependencies

| Category | Technology / Package | Purpose |
| :--- | :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) (Dart SDK `^3.10.7`) | Cross-platform mobile development |
| **State Management** | [`provider`](https://pub.dev/packages/provider) | MVVM architecture with `ChangeNotifier` |
| **Backend & Auth** | [`supabase_flutter`](https://pub.dev/packages/supabase_flutter) | PostgreSQL database, Auth, Storage, and Realtime |
| **Local Storage** | [`sqflite`](https://pub.dev/packages/sqflite), [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Offline caching of bookings, metrics, and feed |
| **Payments** | Stripe & Supabase Edge Functions | Checkout sessions with mobile deep links |
| **Hardware & Sensors** | [`pedometer`](https://pub.dev/packages/pedometer), [`geolocator`](https://pub.dev/packages/geolocator) | Step sensor counting & real-time GPS location |
| **Background Execution**| [`flutter_background_service`](https://pub.dev/packages/flutter_background_service), [`workmanager`](https://pub.dev/packages/workmanager) | Ongoing step counting & periodic sync |
| **Maps & Geo** | [`flutter_map`](https://pub.dev/packages/flutter_map), [`latlong2`](https://pub.dev/packages/latlong2), [`geocoding`](https://pub.dev/packages/geocoding) | OpenStreetMap display, coordinate mapping, address lookup |
| **Notifications** | [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) | Multi-channel local reminders and milestones |
| **Charts** | [`fl_chart`](https://pub.dev/packages/fl_chart) | Step history and weight tracking graphs |
| **Media & Assets** | [`image_picker`](https://pub.dev/packages/image_picker), [`video_player`](https://pub.dev/packages/video_player), [`flutter_svg`](https://pub.dev/packages/flutter_svg) | Post media upload, video playback, SVG rendering |
| **QR Code** | [`qr_flutter`](https://pub.dev/packages/qr_flutter) | Check-in pass QR rendering for bookings |
| **Connectivity** | [`connectivity_plus`](https://pub.dev/packages/connectivity_plus) | Auto-refresh on network restoration |

---

## 🗄️ Supabase Backend & Edge Functions

The backend is backed by Supabase with Row Level Security (RLS) policies configured in [`supabase_migrations/init_schema.sql`](file:///d:/Siew%20Feng/Archive/X-FatHub/supabase_migrations/init_schema.sql):

- **Key Tables**:
  - `profiles`: User metrics, goals, weight targets, and avatar URLs.
  - `weight_history`: Historical weight logging for trend charting.
  - `packages` & `gyms` & `package_gyms`: Available fitness passes, venues, and gym relationships.
  - `slots` & `bookings`: Scheduled workout slots, coach assignments, payment status, and session counts.
  - `step_records`: Synced daily step records.
  - `hydration_logs`: Daily water intake records.
  - `activities` & `activity_locations`: GPS tracked workout sessions and polyline waypoints.
  - `posts`, `comments`, `likes`: Social community feed content and interactions.

- **Supabase Edge Functions** (Deno):
  - **`create-checkout-session`**: Generates a Stripe Checkout session for a chosen package and user ID, returning the checkout URL with redirect schemas.
  - **`stripe-webhook`**: Listens for `checkout.session.completed` events and automatically registers or confirms the user's booking in Supabase.
  - **`delete-user`**: Uses the Supabase Service Role key to cleanly remove user data and authentication records upon request.

---

## ⚡ Getting Started & Setup

### Prerequisites

- Flutter SDK (version compatible with Dart `^3.10.7`)
- Android Studio / Xcode with emulator or physical testing device
- A [Supabase](https://supabase.com) project
- A [Stripe](https://stripe.com) account (for payment features)

### Installation Steps

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd X-FatHub
   ```

2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**:
   Create a `.env` file in the project root by copying the template:
   ```bash
   # Windows PowerShell
   copy example.env .env

   # macOS / Linux / Git Bash
   cp example.env .env
   ```

4. **Populate your `.env` configuration**:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SECRET_KEY=your_supabase_service_role_key
   SUPABASE_PUBLISHABLE_KEY=your_supabase_publishable_key
   SUPABASE_ANON_KEY=your_supabase_anon_key

   STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
   STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
   STRIPE_CHECKOUT_SUCCESS_URL=xfathub://payment/success
   STRIPE_CHECKOUT_CANCEL_URL=xfathub://payment/cancel
   ```

5. **Set up Supabase Database**:
   - In your Supabase Dashboard SQL Editor, run [`supabase_migrations/init_schema.sql`](file:///d:/Siew%20Feng/Archive/X-FatHub/supabase_migrations/init_schema.sql) to create all tables, functions, and RLS policies.
   - *(Optional)* Run [`supabase_migrations/seed_dummy_data.sql`](file:///d:/Siew%20Feng/Archive/X-FatHub/supabase_migrations/seed_dummy_data.sql) to seed default packages, gyms, slots, and test data.

6. **Deploy Edge Functions** *(if testing Stripe payments & account deletion)*:
   ```bash
   supabase functions deploy create-checkout-session
   supabase functions deploy stripe-webhook
   supabase functions deploy delete-user
   ```

7. **Run the application**:
   ```bash
   flutter run
   ```

---

## 📱 Android Permissions & Setup

The Android app requires specific permissions defined in [`android/app/src/main/AndroidManifest.xml`](file:///d:/Siew%20Feng/Archive/X-FatHub/android/app/src/main/AndroidManifest.xml):

- **Step Tracking**: `android.permission.ACTIVITY_RECOGNITION`
- **Location Tracking**: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`
- **Foreground Services**: `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`
- **Background Execution**: `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED`
- **Notifications**: `POST_NOTIFICATIONS` (Android 13+)
- **External Links**: `<queries>` declaration for HTTP/HTTPS web links and navigation launchers.

---

## 🧪 Testing

Run standard Flutter unit and widget tests:

```bash
# Run unit & widget tests
flutter test

# Run static analysis
flutter analyze
```

---

## 📖 Additional Documentation

- [Step Counter Midnight Reset Debugging Guide](file:///d:/Siew%20Feng/Archive/X-FatHub/DEBUG_STEP_RESET.md)
- [Notification Service Implementation Guide](file:///d:/Siew%20Feng/Archive/X-FatHub/NOTIFICATION_SERVICE_GUIDE.md)
