# 🔥 Firebase Setup for NodeMCU

## 📋 What You Need

To make NodeMCU work with your Firebase project, you need:

1. ✅ Firebase Project ID
2. ✅ Firebase Web API Key
3. ✅ Faculty ID (from Firebase Auth)
4. ✅ WiFi Credentials

---

## 🔍 Step 1: Get Firebase Project ID

### Method 1: Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (e.g., "ProfHere")
3. Click ⚙️ **Settings** → **Project Settings**
4. Under "General" tab, find **Project ID**
5. Copy it (e.g., `profhere-app`)

### Method 2: From Firebase URL
- Your Firebase URL: `https://profhere-app.firebaseio.com`
- Project ID is: `profhere-app`

---

## 🔑 Step 2: Get Web API Key

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click ⚙️ **Settings** → **Project Settings**
4. Under "General" tab, scroll to **Web API Key**
5. Copy the key (looks like: `AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`)

⚠️ **Security Note**: This key is safe to use in NodeMCU because:
- It only allows access to Firestore
- Firestore security rules protect the data
- Only approved students can read location
- Faculty must be authenticated to write

---

## 👤 Step 3: Get Faculty ID

### Method 1: From Firebase Console

1. Go to Firebase Console → **Authentication**
2. Click on **Users** tab
3. Find the faculty member (e.g., Monali Tigane)
4. Copy the **User UID** (looks like: `abc123def456ghi789`)

### Method 2: From Flutter App

Add this temporary code to your faculty profile screen:

```dart
// In faculty profile screen
final user = ref.watch(authNotifierProvider).user;
print('Faculty ID: ${user?.id}');  // Check console logs
```

Then:
1. Login as faculty
2. Open profile screen
3. Check logs: `adb logcat | grep "Faculty ID"`
4. Copy the ID

### Method 3: From Firestore

1. Go to Firebase Console → **Firestore Database**
2. Open `users` collection
3. Find the faculty document
4. The document ID is the Faculty ID

---

## 📶 Step 4: Get WiFi Credentials

You already have these:
- **SSID**: `MitHostel@203-2G`
- **Password**: `MitHostel@203`

⚠️ **Important**: NodeMCU only supports **2.4GHz WiFi**, not 5GHz!

---

## 🔧 Step 5: Configure NodeMCU Code

Open `faculty_location_tracker_firestore.ino` and update:

```cpp
// WiFi
const char* WIFI_SSID = "MitHostel@203-2G";
const char* WIFI_PASSWORD = "MitHostel@203";

// Faculty Info
const char* FACULTY_ID = "abc123def456ghi789";  // ← Paste Faculty ID here
const char* BUILDING = "IT Building";
const char* FLOOR = "Ground Floor";
const char* ZONE = "South Block";
const char* CABIN_ID = "S-920";

// Firebase
const char* PROJECT_ID = "profhere-app";  // ← Paste Project ID here
const char* API_KEY = "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";  // ← Paste API Key here
```

---

## 🔒 Step 6: Setup Firestore Security Rules

### Current Rules (Permissive - For Testing)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all reads/writes for testing
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### Production Rules (Secure)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Faculty Locations - Secure Access
    match /faculty_locations/{facultyId} {
      // Faculty can update their own location
      allow write: if request.auth != null && request.auth.uid == facultyId;
      
      // Students with approved access can read
      allow read: if request.auth != null && (
        // Check if student has approved access
        exists(/databases/$(database)/documents/location_access/$(request.auth.uid + '_' + facultyId)) &&
        get(/databases/$(database)/documents/location_access/$(request.auth.uid + '_' + facultyId)).data.status == 'approved'
      );
    }
    
    // Location Access Requests
    match /location_access/{accessId} {
      // Students can create requests
      allow create: if request.auth != null;
      
      // Faculty can read their own requests
      allow read: if request.auth != null && (
        resource.data.facultyId == request.auth.uid ||
        resource.data.studentId == request.auth.uid
      );
      
      // Faculty can update their own requests (approve/reject/revoke)
      allow update: if request.auth != null && resource.data.facultyId == request.auth.uid;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Faculty collection
    match /faculty/{facultyId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == facultyId;
    }
  }
}
```

To apply rules:
1. Go to Firebase Console → **Firestore Database**
2. Click **Rules** tab
3. Paste the rules above
4. Click **Publish**

---

## 🧪 Step 7: Test Configuration

### Test 1: Check Project ID
```bash
# Should return your project info
curl "https://firestore.googleapis.com/v1/projects/profhere-app/databases/(default)/documents"
```

### Test 2: Check API Key
```bash
# Should return 200 OK
curl "https://firestore.googleapis.com/v1/projects/profhere-app/databases/(default)/documents?key=YOUR_API_KEY"
```

### Test 3: Upload to NodeMCU
1. Open Arduino IDE
2. Select Board: "NodeMCU 1.0 (ESP-12E Module)"
3. Select Port: Your COM port
4. Click Upload
5. Open Serial Monitor (115200 baud)
6. Should see:
   ```
   ✅ Connected! IP: 192.168.1.33
   ✅ HTTP 200 - Location updated!
   ```

---

## 📊 Verification Checklist

Before deploying NodeMCU:

- [ ] Firebase Project ID is correct
- [ ] Web API Key is correct
- [ ] Faculty ID is correct (from Firebase Auth)
- [ ] WiFi credentials are correct
- [ ] Building, Floor, Zone, Cabin info is correct
- [ ] Firestore security rules are published
- [ ] NodeMCU connects to WiFi successfully
- [ ] NodeMCU sends data to Firestore successfully
- [ ] Student can see location in app

---

## 🐛 Common Issues

### Issue: "HTTP 401 Unauthorized"
**Cause**: Wrong API Key
**Solution**: Double-check Web API Key from Firebase Console

### Issue: "HTTP 403 Forbidden"
**Cause**: Security rules blocking access
**Solution**: 
- Use permissive rules for testing
- Verify faculty ID is correct
- Check if faculty is authenticated

### Issue: "HTTP 404 Not Found"
**Cause**: Wrong Project ID or collection name
**Solution**: 
- Verify Project ID
- Check collection name is `faculty_locations`

### Issue: NodeMCU not connecting to WiFi
**Cause**: Wrong credentials or 5GHz WiFi
**Solution**:
- Verify WiFi SSID and password
- Ensure WiFi is 2.4GHz
- Check WiFi signal strength

---

## 📝 Configuration Template

Save this for each faculty member:

```
Faculty: _______________
Faculty ID: _______________
Building: _______________
Floor: _______________
Zone: _______________
Cabin: _______________
NodeMCU IP: _______________
WiFi SSID: _______________
Last Updated: _______________
Status: ✅ Working / ❌ Not Working
```

---

## 🚀 Quick Start Commands

```bash
# 1. Check device
adb devices

# 2. Install app
adb install build\app\outputs\flutter-apk\app-debug.apk

# 3. Check logs
adb logcat | grep Flutter

# 4. Monitor NodeMCU
# Open Arduino IDE → Tools → Serial Monitor (115200 baud)
```

---

## 📞 Need Help?

1. **Firebase Console**: https://console.firebase.google.com
2. **Arduino IDE**: https://www.arduino.cc/en/software
3. **NodeMCU Docs**: https://nodemcu.readthedocs.io
4. **ESP8266 Community**: https://github.com/esp8266/Arduino

---

**You're all set! 🎉**

Now upload the code to NodeMCU and watch it automatically update faculty location every 10 minutes!
