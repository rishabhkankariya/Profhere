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

## 🔌 NodeMCU Setup

### Hardware Needed:
- NodeMCU ESP8266
- 4x LEDs (optional): Green, Blue, Yellow, Red
- 4x 220Ω Resistors
- USB cable & power adapter

### Quick Setup:

1. **Get Firebase Credentials**
   - Project ID: Firebase Console → Settings → Project ID
   - Web API Key: Firebase Console → Settings → Web API Key
   - Faculty ID: Firebase Console → Authentication → Users → UID

2. **Update Code**
   - Open `nodemcu/faculty_location_tracker_firestore.ino`
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
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── faculty_location.dart          # Location data model
│   │   │   └── location_access.dart           # Access request model
│   │   └── repositories/
│   ├── data/
│   │   └── repositories/
│   │       └── firestore_faculty_location_repository.dart
│   ├── presentation/
│   │   ├── providers/
│   │   │   ├── faculty_location_provider.dart
│   │   │   └── location_access_provider.dart
│   │   └── screens/
│   │       ├── student/
│   │       │   └── student_location_access_screen.dart
│   │       └── faculty/
│   │           └── faculty_location_update_screen.dart
│   └── core/
│       └── services/
├── nodemcu/
│   ├── faculty_location_tracker_firestore.ino  # Main NodeMCU code
│   ├── FIREBASE_SETUP.md                       # Setup guide
│   └── README.md                               # Quick start
├── TESTING_GUIDE.md                            # Complete testing guide
├── FACULTY_LOCATION_TRACKING.md                # System documentation
├── COMPLETE_SYSTEM_OVERVIEW.md                 # Full overview
├── PROJECT_STATUS_AND_ROADMAP.md               # Current status & roadmap
└── README.md                                   # This file
```

---

## 🔐 Security & Privacy

### Security Features:
- ✅ **Permission-based** - Faculty must approve each student
- ✅ **Firebase Security Rules** - Database-level access control
- ✅ **No exact GPS** - Only shows floor/building
- ✅ **Time-delayed** - Updates every 10-15 mins, not real-time
- ✅ **Audit trail** - All requests logged
- ✅ **Revoke anytime** - Faculty can remove access

### Firebase Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Faculty Locations - Only approved students can read
    match /faculty_locations/{facultyId} {
      allow write: if request.auth != null && request.auth.uid == facultyId;
      allow read: if request.auth != null && hasApprovedAccess();
    }
    
    // Location Access Requests
    match /location_access/{accessId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null && isOwner();
      allow update: if request.auth != null && isFaculty();
    }
  }
}
```

---

## 📊 Current Status

### ✅ Completed (65%)
- [x] Student request/view location
- [x] Faculty approve/reject/revoke
- [x] Real-time location display
- [x] Revoke & request again flow
- [x] NodeMCU code (ready to deploy)
- [x] Complete documentation

### ❌ Remaining (35%)
- [ ] Faculty location update in menu
- [ ] Firebase security rules applied
- [ ] NodeMCU deployed to faculty desks
- [ ] LED indicators integrated
- [ ] Push notifications
- [ ] Admin panel

**See `PROJECT_STATUS_AND_ROADMAP.md` for detailed roadmap**

---

## 🧪 Testing

### Quick Test:
```bash
# 1. Install app
adb install build/app/outputs/flutter-apk/app-debug.apk

# 2. Test as Student
- Login as student
- Request access from faculty
- Wait for approval
- View location

# 3. Test as Faculty
- Login as faculty
- Approve student request
- Update location (manual)
- Revoke access

# 4. Test Revoke Flow
- Student should see "Access Revoked"
- Student can tap "Request Again"
```

**Complete testing guide**: See `TESTING_GUIDE.md`

---

## 🐛 Known Issues

### Issue 1: Location Not Showing
**Problem**: Students see "No Location Data"  
**Cause**: Faculty hasn't updated location yet  
**Fix**: Faculty needs to update location manually or via NodeMCU

### Issue 2: Firebase Rules Too Permissive
**Problem**: Security rules allow all access  
**Cause**: Using test rules  
**Fix**: Apply production rules (see Security section)

### Issue 3: LED Not Integrated
**Problem**: LEDs available but not used  
**Cause**: Not implemented yet  
**Fix**: See `PROJECT_STATUS_AND_ROADMAP.md` Task 3

---

## 💡 LED Indicators (Optional)

### LED System:
- 🟢 **Green LED** - Power/WiFi status
- 🔵 **Blue LED** - Location update in progress
- 🟡 **Yellow LED** - Pending access request
- 🔴 **Red LED** - Student viewing location

### Wiring:
```
NodeMCU Pin → 220Ω Resistor → LED (+) → LED (-) → GND

D1 → Green LED  (Status)
D2 → Blue LED   (Update)
D3 → Yellow LED (Request)
D4 → Red LED    (Viewing)
```

**See `PROJECT_STATUS_AND_ROADMAP.md` for LED integration guide**

---

## 📚 Documentation

- **`README.md`** - This file (quick start)
- **`TESTING_GUIDE.md`** - Complete testing procedures
- **`FACULTY_LOCATION_TRACKING.md`** - System documentation
- **`COMPLETE_SYSTEM_OVERVIEW.md`** - Full system overview
- **`PROJECT_STATUS_AND_ROADMAP.md`** - Current status & roadmap
- **`nodemcu/FIREBASE_SETUP.md`** - Firebase configuration
- **`nodemcu/README.md`** - NodeMCU quick start

---

## 🎯 Next Steps

### Immediate (Critical):
1. ✅ Add "Update My Location" to faculty menu
2. ✅ Apply Firebase security rules
3. ✅ Setup one NodeMCU device
4. ✅ Test end-to-end flow

### Short-term (High Priority):
1. ✅ Wire LEDs to NodeMCU
2. ✅ Add LED control code
3. ✅ Test LED indicators
4. ✅ Deploy to all faculty

### Long-term (Nice to Have):
1. ✅ Push notifications
2. ✅ Admin panel
3. ✅ Analytics dashboard
4. ✅ Queue management

---

## 💰 Cost Estimation

### Per Faculty:
- NodeMCU ESP8266: $3-5
- LEDs & Resistors: $1-2
- USB Cable & Adapter: $2-3
- **Total**: ~$6-10 per faculty

### For 50 Faculty:
- Hardware: $300-500 (one-time)
- Firebase: Free tier (or $25-50/month if exceeded)
- **Total**: ~$300-500 one-time cost

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## License

This project is released under the MIT License. See [LICENSE](LICENSE) for details.

---

<div align="center">

Built with Flutter · Powered by Firebase

**[profhere.web.app](https://profhere.web.app)**

</div>
