# ProfHere

ProfHere is a Flutter + Firebase smart campus platform for faculty availability, academic visibility, and consultation management.

## Current Capabilities

- Role-aware experience for `Admin`, `Faculty`, and `Student`
- Faculty availability list with smart search suggestions
- Faculty workspace with manual override timers and consultation queue handling
- Admin workspace for faculty management and recent activity monitoring
- Academic hub for subjects, marks, timetable, and Excel import
- Notification subscriptions for faculty availability changes
- Timetable-driven status automation with manual override support

## Architecture

- `lib/presentation`: screens, widgets, and Riverpod providers
- `lib/data`: Firebase-backed repositories and models
- `lib/domain`: entities and repository contracts
- `lib/core`: theme, constants, alerts, and scheduling/status utilities
- `functions`: Firebase Cloud Functions for faculty availability notifications

## Security Model

- Frontend route gating restricts admin and faculty-only screens
- Registration creates student accounts by default
- Faculty role is inferred from managed campus faculty data when a user profile is missing
- Firestore rules now separate `users`, `faculty`, `subjects`, `marks`, `timetable`, `consultation_queue`, and `activity_logs`

## Automated Status Logic

- Active timetable slot: faculty is set to `Not Available`
- No active slot: faculty returns to `Available`
- Manual override remains active until `manual_override_until`
- Optional `expected_return_at` supports away timers in the UI

## Testing

Run locally:

```bash
flutter test
dart analyze lib test
flutter build apk --release
```

Included coverage currently focuses on:

- status indicator mapping
- faculty search/provider filtering
- faculty status resolution logic
- entity/model behavior

## Release Verification

The Android release build completes successfully and produces:

- `build/app/outputs/flutter-apk/app-release.apk`
