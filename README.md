# X-FatHub

X-FatHub is a Flutter fitness app that combines activity tracking, class booking, community features, and user profile management in one mobile-first experience.

## Modules

### 1. Community Management

Builds the social side of the app and supports engagement through:

- Feed screens for browsing posts and media
- Post creation, comments, and community interaction
- Profile views tied to community activity
- Media playback and map/location selection helpers

### 2. Booking Management

Handles the fitness class and gym booking flow:

- Gym, package, and booking browsing screens
- Booking detail and checkout flow
- Payment success and cancellation states
- Local booking data storage and repository access

### 3. Activity Health Management

Tracks fitness and wellness activity across the app:

- Step tracking and workout/activity summaries
- Hydration logging and history views
- Background and native activity services
- Location, pedometer, and notification integrations

### 4. User Profile

Manages user account and personal settings:

- Login, profile dashboard, and profile editing
- Settings and email verification screens
- Profile data models and repository layer
- Shared authentication and account state support

## Project Structure

```text
android/                     Android app shell
ios/                         iOS app shell
web/                         Web entry files and assets
lib/                         Main Flutter application code
├── core/                    Shared config, database, services, and providers
├── features/
│   ├── activity_health/     Step, hydration, workout, and tracking flows
│   ├── booking/             Gym, package, booking, checkout, and payment screens
│   ├── community/           Feed, posts, comments, map picker, and media widgets
│   └── profile/             Login, dashboard, edit, settings, and verification screens
├── routes/                  App navigation and main container screens
└── main.dart                App entry point
test/                        Flutter tests
supabase/                    Edge functions and backend helpers
supabase_migrations/        SQL schema, seed, and reset scripts
```

## Tech Stack

- Flutter / Dart
- Provider state management
- Supabase backend
- SQLite for local storage
- Background services, notifications, location, and sensor integrations

## Setup

1. Install Flutter SDK.
2. Copy `example.env` to `.env` and add your Supabase values.
3. Run `flutter pub get`.
4. Start the app with `flutter run`.

## Notes

- The app supports multiple targets, including Android, iOS, Web, and desktop platforms.
- Assets are configured in `pubspec.yaml` under `.env` and `lib/assets/img/`.
