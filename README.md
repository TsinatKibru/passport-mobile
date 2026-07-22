# Passport Track — Mobile App

> **Staff-facing Flutter application** for managing passport custody within the passport tracking system. Allows authorized staff to scan, issue, return, and track passports and storage boxes in real time.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Screens & Navigation](#screens--navigation)
- [Setup & Running Locally](#setup--running-locally)
- [Build for Production](#build-for-production)
- [Configuration](#configuration)
- [Conventions](#conventions)
- [Project Structure](#project-structure)

---

## Overview

The Passport Track mobile app is the field-facing client of the **Passport Track** system — a three-component platform consisting of:

| Component | Technology | Purpose |
|---|---|---|
| **Mobile App** (this) | Flutter | Staff scanning & custody management |
| **Admin Dashboard** | Next.js | Administrative oversight & reporting |
| **Backend API** | NestJS + PostgreSQL | Core business logic & data layer |

Staff use the mobile app on Android devices equipped with cameras to scan QR codes on passports and storage boxes, manage custody chains, and move passports through the vault workflow.

---

## Features

| Feature | Description |
|---|---|
| 🔐 **JWT Authentication** | Email/password login with secure token storage via `flutter_secure_storage` |
| 🤳 **Biometric Lock** | Optional fingerprint/face ID gate on app open, configurable per device |
| 📊 **Live Dashboard** | Real-time stats: total passports, boxes, rooms, and activity trend charts |
| 📷 **QR Code Scanner** | Multi-mode scanner backed by `mobile_scanner` for passport and box QR codes |
| 📦 **Passport Issuance** | Search & paginate passports, confirm identity via QR scan, issue to holder |
| 🔄 **Passport Return** | Multi-passport stacking workflow with intelligent box slot assignment |
| 📍 **Box Management** | Browse rooms, shelves, and box occupancy; move boxes with location validation |
| ⚠️ **Location Mismatch Handling** | Override prompt when a scanned box location differs from system records |
| 👤 **Profile & Settings** | View user profile, toggle biometric security, change theme and language |
| 🌐 **Localization** | Multi-language support via Flutter's `flutter_localizations` |
| 🌙 **Dark / Light Mode** | System-adaptive theme with a toggle in user settings |

---

## Architecture

The app follows a **clean, layered architecture** with clear separation of concerns:

```
Widgets / Screens
      │  (calls)
      ▼
 Repositories          ← Single entry point per domain (no raw Dio in screens)
      │  (calls)
      ▼
  ApiClient            ← One shared Dio instance with auth + error interceptors
      │  (calls)
      ▼
 Backend REST API       ← NestJS @ https://passport-api-seven.vercel.app/api
```

**State management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod` + `riverpod_annotation`)

**Routing:** [go_router](https://pub.dev/packages/go_router) with redirect guards for auth state

**HTTP:** [Dio](https://pub.dev/packages/dio) — single instance, `Bearer` token auto-injected, 401 auto-logout

---

## Screens & Navigation

| Route | Screen | Description |
|---|---|---|
| `/` | `HomeScreen` | Tab shell wrapping dashboard, scan, boxes, tasks, and profile |
| `/login` | `LoginScreen` | Email/password login with biometric suggestion |
| `/scan?mode=assign` | `ScanPage` | General passport/box QR scanner (assign, move modes) |
| `/scan?mode=issue` | `PassportIssuePage` | Passport issuance workflow with search & QR confirm |
| `/scan?mode=return` | `PassportReturnPage` | Passport return & box stacking workflow |

All protected routes are wrapped in `BiometricGuard`, which enforces the biometric lock if enabled by the user.

---

## Setup & Running Locally

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.9.0`
- Android Studio / Xcode (for device/emulator)
- A running instance of the [Passport Track API](../passport-track-api/README.md)

### 1. Install dependencies

```bash
cd passport_track_mobile
flutter pub get
```

### 2. Configure the API base URL

The base URL is baked in at build time via a Dart `--dart-define`. For local development, set it to your machine's IP or `localhost`:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000/api
```

If `API_BASE_URL` is not provided, it defaults to the hosted production API:
```
https://passport-api-seven.vercel.app/api
```

### 3. Run on a connected device or emulator

```bash
flutter run
```

---

## Build for Production

### Android App Bundle (Google Play)

```bash
flutter build appbundle \
  --dart-define=API_BASE_URL=https://your-production-api.com/api
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Android APK (direct install)

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-production-api.com/api
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS

```bash
flutter build ipa \
  --dart-define=API_BASE_URL=https://your-production-api.com/api
```

---

## Configuration

| Setting | How to configure |
|---|---|
| **API Base URL** | `--dart-define=API_BASE_URL=<url>` at build/run time |
| **App Icon** | Replace `assets/images/app-icon-test1-removebg.png`, then run `flutter pub run flutter_launcher_icons` |
| **Theme** | `lib/core/theme/` — edit `AppColors` and `AppTheme` |
| **Biometrics** | Toggled by the user in the Profile page; persisted to `flutter_secure_storage` |
| **Language** | ARB files under `lib/l10n/`; add new locales in `l10n.yaml` |

---

## Conventions

See [`CONVENTIONS.md`](./CONVENTIONS.md) for the full rule set. Key rules:

1. **No Dio/http calls in widgets.** All API communication goes through the repository layer (`lib/data/repositories/`).
2. **No raw colors in UI code.** Every color and text style must come from `AppTheme` / `AppColors`.
3. **Location mutations via service.** Box move operations must go through `LocationService.moveBox()` on the backend — never bypass the transaction.
4. **API contract first.** Any new API fields must be documented in [`API_CONTRACT.md`](../API_CONTRACT.md) before backend implementation begins.

---

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── core/
│   ├── router.dart                  # go_router config with auth redirects
│   ├── auth_provider.dart           # JWT auth state (Riverpod Notifier)
│   ├── biometric_provider.dart      # Biometric lock state
│   ├── camera_lifecycle_manager.dart# Global camera lifecycle observer
│   ├── locale_provider.dart         # Language preference
│   ├── theme_provider.dart          # Dark/light mode preference
│   ├── theme/                       # AppTheme, AppColors, AppTextStyles
│   └── providers/                   # Dashboard, analytics Riverpod providers
├── data/
│   ├── api/
│   │   └── api_client.dart          # Single Dio instance + auth interceptor
│   ├── models/                      # Dart model classes (Passport, Box, Room, …)
│   └── repositories/                # Domain repositories (PassportRepository, BoxRepository, …)
└── presentation/
    ├── login_screen.dart            # Login UI
    └── home/
        ├── home_screen.dart         # Bottom nav tab shell
        ├── dashboard_page.dart      # Stats & activity charts
        └── pages/
            ├── scan_page.dart       # Multi-mode QR scanner
            ├── passport_issue_page.dart   # Issuance workflow
            ├── passport_return_page.dart  # Return & stacking workflow
            ├── boxes_page.dart      # Box browser
            ├── tasks_page.dart      # Assigned tasks
            └── profile_page.dart    # Settings, biometrics, theme, logout
```

---

## Related Components

- [`../passport-track-api`](../passport-track-api) — NestJS backend
- [`../passport-track-admin`](../passport-track-admin) — Next.js admin dashboard
- [`../API_CONTRACT.md`](../API_CONTRACT.md) — Canonical API shape reference
- [`../CONVENTIONS.md`](../CONVENTIONS.md) — Cross-component conventions
