<div align="center">

<img src="assets/logo.png" alt="ProfHere Logo" width="100" height="100" style="border-radius: 20px"/>

# ProfHere

### Smart Campus Faculty Availability & Consultation Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-green)](https://profhere.web.app)
[![Version](https://img.shields.io/badge/Version-1.0.0-blue)](https://github.com)
[![License](https://img.shields.io/badge/License-MIT-lightgrey)](LICENSE)

**Live Web App → [profhere.web.app](https://profhere.web.app)**

</div>

---

## What is ProfHere?

ProfHere is a cross-platform campus management application built with Flutter and Firebase. It solves a common problem in academic institutions — students never know if a faculty member is available for consultation. ProfHere gives faculty real-time status control and gives students instant visibility, queue management, and event updates — all in one place.

---

## Screenshots

> Add screenshots here after deployment

---

## Features

### For Students
- **Faculty Directory** — Browse all faculty with live availability status (Available, Busy, In Lecture, Meeting, Away, Holiday, Custom)
- **Consultation Queue** — Join a faculty's queue with a stated purpose; see your position and estimated wait time in real time
- **Subscriptions** — Subscribe to faculty and receive push notifications when their status changes
- **Events Board** — View upcoming and past campus events posted by Class Representatives
- **Faculty QR Code** — Scan or share a QR code to open any faculty's profile directly
- **Faculty Schedule** — View a faculty's weekly lecture timetable
- **Todo List** — Personal task manager with priority levels and due dates
- **Community Chat** — Faculty-specific community channels for announcements and discussion
- **Profile Management** — Update name, department, year, student code, and profile photo

### For Faculty
- **Status Dashboard** — One-tap status updates with 7 options including a custom text status
- **Queue Management** — View the live consultation queue, call the next student, mark sessions complete
- **Lecture Schedule** — Add, edit, and delete timetable entries by day and time
- **Student Management** — View all students and assign/remove Class Representative (CR) status
- **Community Channel** — Post announcements and moderate discussions
- **Android Home Widget** — Change status directly from the home screen without opening the app
- **Profile Photo** — Upload and update profile avatar

### For Admins
- **User Management** — View all users (students, faculty, admins), block/unblock, delete accounts
- **Faculty Management** — Add new faculty profiles, create faculty login accounts with auto-generated passwords
- **Credential Management** — View all faculty demo passwords for onboarding
- **Event Moderation** — View and manage all posted events
- **Consultation Logs** — Monitor all consultation activity across the campus

### Platform Features
- **Cross-platform** — Android APK + Progressive Web App (PWA)
- **Real-time sync** — All data streams live from Firestore; no manual refresh needed
- **Offline-aware** — Firestore local cache keeps the app usable without network
- **Push notifications** — FCM-powered alerts for status changes and mentions
- **Google Sign-In** — One-tap sign-in for students (web popup + mobile native)
- **Animated splash screen** — Cinematic letter-by-letter text assembly on launch
- **Permission flow** — First-launch notification permission request with graceful skip

---

## Architecture

ProfHere follows a clean layered architecture:

```
lib/
├── core/
│   ├── constants/        # App colors, theme tokens
│   ├── services/         # Notification, Widget, Permission services
│   ├── theme/            # Material theme configuration
│   └── utils/            # Toast helpers, formatters
│
├── data/
│   ├── datasources/      # Hive local storage (settings only)
│   ├── mock/             # Firestore seed data for first launch
│   ├── models/           # Hive-adapted data models
│   └── repositories/     # Firestore repository implementations
│
├── domain/
│   ├── entities/         # Pure Dart domain models (User, Faculty, Event…)
│   └── repositories/     # Abstract repository interfaces
│
└── presentation/
    ├── navigation/       # GoRouter configuration and route guards
    ├── providers/        # Riverpod state providers
    ├── screens/          # All UI screens by feature
    └── widgets/          # Shared reusable widgets
```

### State Management
Riverpod 2.x is used throughout:
- `StreamProvider` — live Firestore streams (faculty list, events, consultations)
- `StateNotifierProvider` — mutable state with async operations (auth, queue actions)
- `Provider` — dependency injection (repositories, services)

### Navigation
GoRouter with redirect guards:
- Unauthenticated users are redirected to `/login`
- Faculty with `mustChangePassword` flag are redirected to the force-change screen
- Role-based home routes: Admin → `/admin`, Faculty → `/faculty-dashboard`, Student → `/faculties`

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.x |
| State Management | Riverpod 2.x |
| Navigation | GoRouter 17.x |
| Backend / Database | Firebase Firestore |
| Authentication | Firebase Auth (Email + Google) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| File Storage | Firebase Storage |
| Local Storage | Hive (settings only) |
| QR Codes | qr_flutter |
| Home Widget | home_widget (Android) |
| Notifications | flutter_local_notifications |
| Permissions | permission_handler |

---

## Project Structure — Key Files

```
lib/
├── main.dart                          # App entry, splash/permission flow
├── firebase_options.dart              # Firebase project config
│
├── core/
│   ├── constants/app_colors.dart      # Design system colors
│   ├── services/notification_service.dart
│   ├── services/permission_service.dart
│   ├── services/widget_service.dart   # Android home widget sync
│   └── theme/app_theme.dart
│
├── data/repositories/
│   ├── firestore_auth_repository.dart # Auth: login, register, Google, phone
│   ├── firestore_event_repository.dart
│   ├── firestore_faculty_repository.dart
│   └── firestore_consultation_repository.dart
│
├── domain/entities/
│   ├── user.dart                      # User model with isCR flag
│   ├── faculty.dart                   # Faculty with FacultyStatus enum
│   ├── consultation.dart              # Queue entry model
│   ├── event.dart                     # Campus event model
│   └── academic.dart                  # Timetable, Subject, Marks models
│
└── presentation/
    ├── screens/
    │   ├── auth/                      # Login, Register, Phone auth
    │   ├── faculty/                   # Faculty list, detail, dashboard
    │   ├── admin/                     # Admin dashboard
    │   ├── events/                    # Events board + post sheet
    │   ├── community/                 # Chat screens
    │   ├── profile/                   # Edit profile
    │   ├── todo/                      # Todo list
    │   ├── onboarding/                # Permission screen
    │   └── splash_screen.dart         # Animated splash
    └── providers/
        ├── auth_provider.dart
        ├── faculty_provider.dart
        ├── event_provider.dart
        ├── consultation_provider.dart
        └── admin_provider.dart
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Firebase project with Firestore, Auth, Storage, and Messaging enabled
- Android Studio or VS Code with Flutter extension
- Node.js (for Firebase CLI)

### 1. Clone the repository

```bash
git clone https://github.com/your-username/profhere.git
cd profhere
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Firebase setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Firestore**, **Authentication** (Email/Password + Google), **Storage**, and **Cloud Messaging**
3. Download `google-services.json` → place in `android/app/`
4. Download `GoogleService-Info.plist` → place in `ios/Runner/`
5. Run FlutterFire CLI to generate `lib/firebase_options.dart`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. Deploy Firestore rules

```bash
firebase deploy --only firestore:rules
```

### 5. Run the app

```bash
# Android
flutter run

# Web
flutter run -d chrome

# Release APK (split by architecture)
flutter build apk --release --split-per-abi

# Release Web
flutter build web --release
firebase deploy --only hosting
```

---

## Firestore Data Model

```
users/{uid}
  name, email, roleIndex (0=student, 1=admin, 2=faculty)
  studentCode, department, yearOfStudy
  isCR (bool) — Class Representative flag
  mustChangePassword (bool)

faculty/{id}
  name, email, department, building, cabinId
  statusIndex, customStatusText, activeContext
  specialization, zone, avatarUrl

consultations/{id}
  facultyId, studentId, studentName, purpose
  status (pending | inProgress | completed | cancelled)
  position, waitTimeMinutes, requestedAt

events/{id}
  authorId, authorName, authorRole
  title, description, category (0-5)
  eventDate, createdAt, isApproved
  imageUrl (base64, max 700KB)

timetable/{id}
  facultyId, subjectName, room
  dayOfWeek (1-7), startTime, endTime

community/{id}
  channel (facultyId), senderId, senderName
  text, timestamp, reactions

todos/{id}
  userId, title, description
  priority, dueDate, isCompleted
```

---

## User Roles

| Role | Access |
|---|---|
| **Student** | Browse faculty, join queues, view events, community chat, todo list |
| **Student (CR)** | All student access + post campus events |
| **Faculty** | Status management, queue management, timetable, assign CR, community |
| **Admin** | Full access — manage users, faculty, events, view all consultations |

### Default Demo Accounts

| Role | Email | Password |
|---|---|---|
| Admin | admin@profhere.com | admin123 |
| Faculty | (created by admin) | (shown in admin dashboard) |
| Student | Register via app | (self-registered) |

---

## Android Home Widget

Faculty members can change their availability status directly from the Android home screen without opening the app.

**Setup:**
1. Long-press the home screen
2. Select Widgets → ProfHere
3. Add the widget
4. Tap any status button to update instantly

The widget syncs bidirectionally — changes made in the app reflect on the widget and vice versa.

---

## Build & Deploy

### Android APK

```bash
# Debug
flutter build apk --debug

# Release (split by CPU architecture — smaller file sizes)
flutter build apk --release --split-per-abi

# Output files
build/app/outputs/flutter-apk/
├── app-armeabi-v7a-release.apk   # ARM 32-bit (older devices)
├── app-arm64-v8a-release.apk     # ARM 64-bit (modern devices) ← recommended
└── app-x86_64-release.apk        # x86 64-bit (tablets, emulators)
```

### Web

```bash
flutter build web --release
firebase deploy --only hosting
```

### App Icons

```bash
dart run flutter_launcher_icons
```

---

## CI/CD

GitHub Actions workflows are included for Firebase Hosting:

- `.github/workflows/firebase-hosting-merge.yml` — deploys to production on merge to `main`
- `.github/workflows/firebase-hosting-pull-request.yml` — deploys preview channel on pull requests

---

## Environment Notes

- **Minimum Android SDK:** 21 (Android 5.0)
- **Target Android SDK:** Flutter default (latest stable)
- **Java/Kotlin:** Java 17, Kotlin JVM target 17
- **Web renderer:** CanvasKit (default)
- **App size:** ~20-25 MB APK, ~38 MB web bundle

---

## Known Limitations

- Image uploads are stored as base64 in Firestore (max 700KB). For production use, migrate to Firebase Storage URLs.
- Phone authentication is configured but requires additional Firebase setup for production.
- The Android home widget requires Android 5.0+ and does not support iOS.

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## License

This project is released under the MIT License. See [LICENSE](LICENSE) for details.

---

<div align="center">

Built with Flutter · Powered by Firebase

**[profhere.web.app](https://profhere.web.app)**

</div>


this update to check this branch is working or not 