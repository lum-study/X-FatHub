# X-FatHub

X-FatHub is a Flutter-based fitness platform designed to support healthier lifestyles through social interaction, class access, activity tracking, and motivation features.

## Project Description

The project focuses on combining fitness engagement with community and progress visibility. It helps users stay active by making it easier to join activities, track performance, and maintain motivation through achievements and social support.

## Feature Description

### 1. Community Management

- Encourages social support and motivation.
- Improves mental well-being through interaction.

### 2. Booking Management

- Makes fitness classes easily accessible.
- Promotes consistent participation in physical activities.

### 3. Activity Health Management

- Tracks workouts, calories, and progress.
- Encourages regular exercise and healthy habits.

### 4. User Profile

- Records achievements to maintain user motivation.
- Encourages continuous participation in fitness activities.

## Folder Structure

The project folder structure is:

```text
lib/
├── core/                         # Global app configurations and utilities
│   ├── constants/                # Colors, text styles, and API keys
│   ├── database/                 # SQLite initialization and helpers
│   ├── network/                  # Supabase client setup
│   └── utils/                    # Form input validators
│
├── shared/                       # Reusable components and global services
│   ├── services/
│   │   ├── location_service.dart # Location tracking implementation
│   │   ├── shared_prefs.dart     # Local storage for small data
│   │   └── file_service.dart     # Image Picker and Data File handling
│   └── widgets/                  # Reusable UI like buttons and text fields
│
├── features/                     # Core Application Modules
│   ├── activity_health/          # Tracking steps, workouts, and hydration
│   │   ├── models/
│   │   ├── repository/           # Data access and integration layer
│   │   ├── providers/            # State Management
│   │   └── views/                # Screens including Open Street Map
│   │
│   ├── booking/                  # Fitness class booking
│   │   ├── models/
│   │   ├── repository/           # Data access and integration layer
│   │   ├── providers/            # State Management
│   │   └── views/                # Class selection and booking screens
│   │
│   ├── community/                # Social feed and interactions
│   │   ├── models/
│   │   ├── repository/           # Data access and integration layer
│   │   ├── providers/            # State Management
│   │   └── views/                # Feed and post screens
│   │
│   ├── profile/                  # User profile and achievements
│   │   ├── models/
│   │   ├── repository/           # Data access and integration layer
│   │   ├── providers/            # State Management
│   │   └── views/                # Forms for updating profile
│   │
│   └── weather/                  # Weather module for outdoor activities
│       ├── models/
│       ├── repository/           # Data access and integration layer
│       ├── providers/
│       └── views/                # Weather Forecast screen using Web API
│
├── routes/
│   ├── app_routes.dart           # Navigation handling
│   └── main_screen.dart          # Main screen container
│
└── main.dart                     # Application entry point
```

## Installation Guide

### Prerequisites

- Flutter SDK compatible with Dart SDK `^3.10.7`
- A device/emulator for Android, iOS, Web, Windows, Linux, or macOS

### 1. Clone the repository

```bash
git clone <your-repository-url>
cd X-FatHub
```

### 2. Configure environment variables

This project uses `flutter_dotenv` and expects a `.env` file.

```bash
copy example.env .env
```

If you are using Git Bash, use:

```bash
cp example.env .env
```

Then update `.env` with your actual configuration values, for example Supabase keys.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run the app

```bash
flutter run
```