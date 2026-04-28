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

ProfHere is a comprehensive cross-platform campus management application built with Flutter and Firebase. It solves multiple common problems in academic institutions — students never know if faculty are available for consultation, lack of centralized communication, and difficulty managing academic activities. ProfHere provides real-time faculty status tracking, consultation queue management, community communication, event management, and optional IoT-based location tracking.

---

## Screenshots

> Add screenshots here after deployment

---

## Features

### For Students
- **Faculty Directory** — Browse all faculty with live availability status (Available, Busy, In Lecture, Meeting, Away, Holiday, Custom)
- **Consultation Queue** — Join a faculty's queue with a stated purpose; see your position and estimated wait time in real time
- **Faculty Subscriptions** — Subscribe to faculty and receive push notifications when their status changes
- **Events Board** — View upcoming and past campus events posted by Class Representatives (CRs)
- **Faculty QR Code** — Scan or share a QR code to open any faculty's profile directly
- **Faculty Schedule** — View a faculty's weekly lecture timetable
- **Todo List** — Personal task manager with priority levels and due dates
- **Community Chat** — Faculty-specific community channels for announcements and discussion
- **Profile Management** — Update name, department, year, student code, and profile photo
- **Location Access** — Request access to view faculty's real-time location (when NodeMCU is deployed)
- **Google Sign-In** — One-tap sign-in with Google account

### For Faculty
- **Status Dashboard** — One-tap status updates with 7 predefined options plus custom text status
- **Queue Management** — View the live consultation queue, call the next student, mark sessions complete
- **Lecture Schedule** — Add, edit, and delete timetable entries by day and time
- **Student Management** — View all students and assign/remove Class Representative (CR) status
- **Community Channel** — Post announcements and moderate discussions in faculty-specific channels
- **Android Home Widget** — Change status directly from the home screen without opening the app
- **Profile Photo** — Upload and update profile avatar
- **Location Settings** — Configure NodeMCU device and manage student location access requests
- **Location Access Control** — Approve/reject/revoke student requests to view real-time location

### For Admins
- **User Management** — View all users (students, faculty, admins), block/unblock, delete accounts
- **Faculty Management** — Add new faculty profiles, create faculty login accounts with auto-generated passwords
- **Credential Management** — View all faculty demo passwords for onboarding
- **Event Moderation** — View and manage all posted events, approve CR submissions
- **Consultation Logs** — Monitor all consultation activity across the campus
- **Location Access Oversight** — View and manage all location access requests across faculty

### Platform Features
- **Cross-platform** — Android APK + Progressive Web App (PWA)
- **Real-time sync** — All data streams live from Firestore; no manual refresh needed
- **Offline-aware** — Firestore local cache keeps the app usable without network
- **Push notifications** — FCM-powered alerts for status changes and mentions
- **Google Sign-In** — One-tap sign-in for students (web popup + mobile native)
- **Phone Authentication** — Alternative login method using phone number and OTP
- **Animated splash screen** — Cinematic letter-by-letter text assembly on launch
- **Permission flow** — First-launch notification permission request with graceful skip
- **Role-based routing** — Automatic navigation based on user role (student/faculty/admin)
- **Force password change** — Security feature for initial faculty accounts

---

## 🔌 NodeMCU Setup (Optional IoT Feature)

### Hardware Needed:
- NodeMCU ESP8266
- USB cable & power adapter
- WiFi network access

### Quick Setup:

1. **Get Firebase Credentials**
   - Project ID: Firebase Console → Settings → Project ID
   - Web API Key: Firebase Console → Settings → Web API Key
   - Faculty ID: Firebase Console → Authentication → Users → UID

2. **Update Code**
   - Open `nodemcu/faculty_location_tracker_software_only.ino`
   - Update WiFi credentials
   - Update Firebase credentials
   - Update faculty location details

3. **Upload to NodeMCU**
   - Open Arduino IDE
   - Select Board: NodeMCU 1.0 (ESP-12E)
   - Select Port
   - Click Upload

4. **Verify**
   - Open Serial Monitor (115200 baud)
   - Should see: "✅ Connected! Location updated!"

**Detailed guide**: See `nodemcu/FIREBASE_SETUP.md`

---

## 🗂️ Project Structure

```
Profhere/
├── lib/
│   ├── core/
│   │   ├── constants/           # App colors, themes, constants
│   │   ├── services/           # Notification, audio, widget services
│   │   └── theme/              # Material theme configuration
│   ├── data/
│   │   ├── datasources/
│   │   │   └── local/          # Hive local storage
│   │   ├── mock/               # Mock data seeder
│   │   └── repositories/       # Firestore repository implementations
│   ├── domain/
│   │   ├── entities/           # Data models (User, Faculty, Event, etc.)
│   │   └── repositories/       # Repository interfaces
│   ├── presentation/
│   │   ├── navigation/         # GoRouter configuration
│   │   ├── providers/          # Riverpod state management
│   │   ├── screens/
│   │   │   ├── admin/          # Admin dashboard and management
│   │   │   ├── auth/           # Login, register, phone auth
│   │   │   ├── community/      # Community chat features
│   │   │   ├── events/         # Event management
│   │   │   ├── faculty/        # Faculty dashboard and features
│   │   │   ├── onboarding/     # Permission and splash screens
│   │   │   ├── profile/        # Profile editing
│   │   │   ├── student/        # Student-specific features
│   │   │   └── todo/           # Todo list management
│   │   └── widgets/            # Reusable UI components
│   └── main.dart               # App entry point
├── nodemcu/
│   ├── faculty_location_tracker_software_only.ino  # NodeMCU code
│   ├── FIREBASE_SETUP.md                          # Setup guide
│   └── README.md                                  # Quick start
└── README.md                                      # This file
```

---

## 🔐 Security & Privacy

### Security Features:
- ✅ **Firebase Authentication** - Secure user authentication with Google Sign-In and Phone Auth
- ✅ **Role-based Access Control** - Different permissions for students, faculty, and admins
- ✅ **Firestore Security Rules** - Database-level access control
- ✅ **Permission-based Location Access** - Faculty must approve each student's location request
- ✅ **No exact GPS coordinates** - Only shows building/floor information
- ✅ **Time-delayed updates** - Location updates every 10-15 mins, not real-time tracking
- ✅ **Audit trail** - All access requests and actions are logged
- ✅ **Revoke anytime** - Faculty can remove student access at any time
- ✅ **Force password change** - Initial faculty accounts require password update

### Privacy Protection:
- Location data is limited to building and floor information
- No personal GPS coordinates are stored or transmitted
- Students must request and receive approval before accessing any location data
- Faculty have full control over who can see their location
- All communication is encrypted through Firebase

---

## 📊 Current Status

### ✅ Completed Features (95%)
- [x] **Authentication System** - Google Sign-In, Phone Auth, Registration
- [x] **Faculty Status Management** - Real-time status updates with 7+ options
- [x] **Consultation Queue System** - Complete queue management for faculty-student meetings
- [x] **Community Chat** - Faculty-specific channels with moderation
- [x] **Event Management** - CR can post events, faculty/admin can moderate
- [x] **Todo List** - Personal task management with priorities
- [x] **Profile Management** - Complete user profile editing
- [x] **Admin Dashboard** - User management, faculty creation, oversight tools
- [x] **Faculty Dashboard** - Status control, queue management, student oversight
- [x] **Student Dashboard** - Faculty directory, subscriptions, queue joining
- [x] **Android Home Widget** - Faculty status control from home screen
- [x] **Push Notifications** - Status change alerts and mentions
- [x] **Location Access System** - Request/approve/revoke location access
- [x] **NodeMCU Integration** - IoT device code for location tracking
- [x] **Cross-platform Support** - Android APK and Web PWA
- [x] **Offline Support** - Firestore local caching

### 🔄 Optional Enhancements (5%)
- [ ] **Advanced Analytics** - Usage statistics and insights
- [ ] **Bulk Operations** - Mass user management tools
- [ ] **Advanced Notifications** - Scheduled and conditional alerts
- [ ] **API Documentation** - External integration support

---

## 🧪 Testing

### Quick Test Flow:
```bash
# 1. Install app (Android)
flutter build apk
adb install build/app/outputs/flutter-apk/app-debug.apk

# 2. Test as Student
- Register/Login as student
- Browse faculty directory
- Subscribe to faculty for notifications
- Join consultation queue
- Post in community chat
- Manage todo items
- Request location access (if NodeMCU deployed)

# 3. Test as Faculty
- Login with faculty credentials
- Update status (Available/Busy/Custom)
- Manage consultation queue
- Post announcements in community
- Approve/reject location access requests
- Use Android home widget

# 4. Test as Admin
- Login with admin credentials
- Create new faculty accounts
- Manage users (block/unblock)
- Moderate events and community posts
- View consultation logs
- Oversee location access requests
```

### Web Testing:
Visit [profhere.web.app](https://profhere.web.app) and test all features in browser.

---

## 🐛 Known Issues & Limitations

### Current Limitations:
1. **NodeMCU Deployment** - IoT location tracking requires physical hardware setup
2. **Firebase Security Rules** - May need fine-tuning for production deployment
3. **Bulk Operations** - Admin panel lacks bulk user management features
4. **Advanced Analytics** - No usage statistics or insights dashboard yet

### Troubleshooting:
- **Login Issues**: Ensure Firebase Authentication is properly configured
- **Notification Problems**: Check FCM setup and device permissions
- **Widget Not Working**: Verify Android home widget permissions
- **Location Access**: Ensure NodeMCU is connected and Firebase credentials are correct

---

## 🚀 Getting Started

### Prerequisites:
- Flutter SDK (3.0+)
- Firebase project setup
- Android Studio / VS Code
- Git

### Installation:
1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/profhere.git
   cd profhere
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Enable Authentication, Firestore, Storage, and FCM
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place files in appropriate directories
   - Update `lib/firebase_options.dart`

4. **Run the app**
   ```bash
   flutter run
   ```

### Build for Production:
```bash
# Android APK
flutter build apk --release

# Web
flutter build web --release
```

---

## 📚 Key Technologies

### Frontend:
- **Flutter 3.x** - Cross-platform UI framework
- **Riverpod** - State management and dependency injection
- **GoRouter** - Declarative routing and navigation
- **Material Design 3** - Modern UI components and theming

### Backend:
- **Firebase Authentication** - User authentication and authorization
- **Cloud Firestore** - Real-time NoSQL database
- **Firebase Storage** - File and image storage
- **Firebase Cloud Messaging** - Push notifications

### Local Storage:
- **Hive** - Local settings and preferences storage
- **Firestore Offline** - Automatic data caching and sync

### Hardware Integration:
- **NodeMCU ESP8266** - IoT device for location tracking
- **Arduino IDE** - Hardware programming environment
- **Home Widget** - Android home screen widget integration

### Development Tools:
- **Flutter DevTools** - Debugging and performance analysis
- **Firebase Console** - Backend management and analytics
- **Android Studio / VS Code** - Development environments

---

## 🎯 Future Enhancements

### Planned Features:
- **Advanced Analytics** - Usage statistics and insights dashboard
- **Bulk Operations** - Mass user management and data operations
- **API Integration** - External system integration capabilities
- **Advanced Notifications** - Scheduled and conditional alerts
- **Multi-language Support** - Internationalization and localization
- **Dark Mode** - Alternative UI theme
- **Accessibility** - Enhanced accessibility features
- **Performance Optimization** - Further app performance improvements

### Hardware Enhancements:
- **LED Indicators** - Visual status indicators on NodeMCU devices
- **Sensor Integration** - Motion sensors for automatic presence detection
- **Multiple Device Support** - Faculty with multiple office locations

---

## 💰 Cost Estimation

### Development Costs:
- **Development Time**: ~200-300 hours (completed)
- **Firebase Usage**: Free tier supports up to 50K reads/writes per day
- **Hosting**: Firebase Hosting (free for basic usage)

### Hardware Costs (Optional IoT Feature):
- **NodeMCU ESP8266**: $3-5 per device
- **USB Cable & Adapter**: $2-3 per device
- **Total per Faculty**: ~$5-8

### Operational Costs:
- **Firebase**: Free tier (or $25-50/month if exceeded)
- **Maintenance**: Minimal (Firebase handles infrastructure)
- **Updates**: Standard app store deployment process

### For 50 Faculty Members:
- **Hardware**: $250-400 (one-time, optional)
- **Software**: Free to $50/month (depending on usage)
- **Total**: Very cost-effective solution

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## License

This project is released under the Copyright License.

---

<div align="center">

Built with Flutter · Powered by Firebase

**[profhere.web.app](https://profhere.web.app)**

</div>
