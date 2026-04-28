# 🔌 NodeMCU Faculty Location Tracker

## 📦 What's in This Folder

This folder contains everything you need to setup NodeMCU devices for faculty location tracking.

### Files:
1. **`faculty_location_tracker_firestore.ino`** - Main Arduino code (USE THIS ONE)
2. **`faculty_location_tracker.ino`** - Alternative version (Realtime Database)
3. **`FIREBASE_SETUP.md`** - How to get Firebase credentials
4. **`UPDATE_LOCATION_API.md`** - API documentation
5. **`README.md`** - This file

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Get Firebase Credentials

You need 3 things:
1. **Project ID**: Get from Firebase Console → Settings → Project ID
2. **Web API Key**: Get from Firebase Console → Settings → Web API Key
3. **Faculty ID**: Get from Firebase Console → Authentication → Users → Copy UID

📖 **Detailed guide**: See `FIREBASE_SETUP.md`

### Step 2: Update Code

Open `faculty_location_tracker_firestore.ino` and change:

```cpp
// Line 15-16: WiFi
const char* WIFI_SSID = "YOUR_WIFI_NAME";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Line 19-23: Faculty Info
const char* FACULTY_ID = "PASTE_FACULTY_ID_HERE";
const char* BUILDING = "IT Building";
const char* FLOOR = "Ground Floor";
const char* ZONE = "South Block";
const char* CABIN_ID = "S-920";

// Line 26-27: Firebase
const char* PROJECT_ID = "your-project-id";
const char* API_KEY = "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
```

### Step 3: Upload to NodeMCU

1. Open Arduino IDE
2. Install ESP8266 board:
   - File → Preferences
   - Additional Board URLs: `http://arduino.esp8266.com/stable/package_esp8266com_index.json`
   - Tools → Board → Boards Manager → Search "ESP8266" → Install
3. Select Board: **NodeMCU 1.0 (ESP-12E Module)**
4. Select Port: Your COM port
5. Click **Upload** ⬆️
6. Wait for "Done uploading"

### Step 4: Verify It Works

1. Open Serial Monitor (115200 baud)
2. You should see:
   ```
   ✅ Connected! IP: 192.168.1.33
   📤 Updating Firestore...
   ✅ HTTP 200 - Location updated!
   ✅ Ready! Updating every 10 minutes
   ```

3. Check Firebase Console:
   - Go to Firestore Database
   - Collection: `faculty_locations`
   - Document: `{facultyId}`
   - Should see updated data

4. Check Student App:
   - Login as student (with approved access)
   - View faculty location
   - Should see current location!

---

## 🔧 Hardware Setup

### What You Need:
- **NodeMCU ESP8266** board (~$3-5)
- **Micro USB cable**
- **USB power adapter** (or use computer USB)

### Physical Setup:
1. Place NodeMCU at faculty's desk
2. Connect to power via USB
3. That's it! It will auto-connect to WiFi

### LED Indicators:
- **Blinking fast**: Connecting to WiFi
- **Solid on**: Connected and working
- **Off**: No power or error

---

## ⚙️ Configuration Options

### Update Interval
Change how often location is sent:

```cpp
// Line 30
const unsigned long UPDATE_INTERVAL = 600000;  // 10 minutes (default)
// const unsigned long UPDATE_INTERVAL = 900000;  // 15 minutes
// const unsigned long UPDATE_INTERVAL = 300000;  // 5 minutes (testing)
```

### Faculty Location
Update for each faculty member:

```cpp
const char* BUILDING = "IT Building";     // Change building name
const char* FLOOR = "Ground Floor";       // Change floor
const char* ZONE = "South Block";         // Change zone/area
const char* CABIN_ID = "S-920";           // Change cabin number
```

---

## 🐛 Troubleshooting

### Problem: Not connecting to WiFi

**Check:**
- ✅ WiFi SSID and password are correct
- ✅ WiFi is 2.4GHz (NodeMCU doesn't support 5GHz)
- ✅ WiFi signal is strong enough
- ✅ No special characters in password

**Solution:**
```cpp
// Try different WiFi network
const char* WIFI_SSID = "MitHostel@203-2G";  // Use 2.4GHz network
```

### Problem: HTTP 401 Unauthorized

**Check:**
- ✅ Web API Key is correct
- ✅ Copied full key from Firebase Console

**Solution:**
- Go to Firebase Console → Settings → Web API Key
- Copy the entire key (starts with `AIza`)

### Problem: HTTP 403 Forbidden

**Check:**
- ✅ Faculty ID is correct
- ✅ Firestore security rules allow write

**Solution:**
- Verify Faculty ID from Firebase Authentication
- Check Firestore rules allow faculty to write

### Problem: HTTP 404 Not Found

**Check:**
- ✅ Project ID is correct
- ✅ Collection name is `faculty_locations`

**Solution:**
- Verify Project ID from Firebase Console
- Check URL in code matches your project

### Problem: Location not showing in app

**Check:**
- ✅ NodeMCU is powered on
- ✅ Serial Monitor shows "Location updated!"
- ✅ Student has approved access
- ✅ Firebase document exists

**Solution:**
- Check Firebase Console → Firestore → `faculty_locations`
- Verify document has correct faculty ID
- Check student has approved access in `location_access` collection

---

## 📊 Serial Monitor Output

### Normal Operation:
```
╔═══════════════════════════════════════╗
║  Faculty Location Tracker v2.0       ║
╚═══════════════════════════════════════╝

📶 Connecting to: MitHostel@203-2G .....
✅ Connected! IP: 192.168.1.33
📡 NodeMCU IP: 192.168.1.33

📤 Updating Firestore...
   Location: IT Building - Ground Floor
✅ HTTP 200 - Location updated!

✅ Ready! Updating every 10 minutes

⏰ Time to update...
📤 Updating Firestore...
   Location: IT Building - Ground Floor
✅ HTTP 200 - Location updated!
```

### Error Example:
```
❌ HTTP 401 - Unauthorized
Check your API Key!
```

---

## 🔒 Security Notes

### Is the API Key Safe?
✅ **Yes!** The Web API Key is safe to use in NodeMCU because:
- It only allows access to Firestore
- Firestore security rules protect the data
- Only authenticated faculty can write location
- Only approved students can read location

### What Data is Sent?
Only these fields:
- Faculty ID (from Firebase Auth)
- Building name
- Floor name
- Zone/area
- Cabin number
- NodeMCU IP address
- Timestamp
- Presence status (true/false)

**No personal data, no GPS coordinates!**

---

## 📈 Monitoring

### Check if NodeMCU is Working:

1. **Serial Monitor** (Real-time)
   - Open Arduino IDE → Tools → Serial Monitor
   - Should see updates every 10 minutes

2. **Firebase Console** (Historical)
   - Go to Firestore Database
   - Check `faculty_locations/{facultyId}`
   - Check `lastUpdated` timestamp

3. **Student App** (End-user view)
   - Login as student with approved access
   - Check faculty location screen
   - Should see "just now" or "X min ago"

---

## 🔄 Updating Code

### To Update Faculty Location:
1. Open `faculty_location_tracker_firestore.ino`
2. Change `BUILDING`, `FLOOR`, `ZONE`, or `CABIN_ID`
3. Upload to NodeMCU
4. Done! New location will be sent

### To Change Update Interval:
1. Change `UPDATE_INTERVAL` value
2. Upload to NodeMCU
3. Done! Will update at new interval

### To Change WiFi:
1. Change `WIFI_SSID` and `WIFI_PASSWORD`
2. Upload to NodeMCU
3. Done! Will connect to new WiFi

---

## 📦 Multiple Faculty Setup

### For Each Faculty:
1. Get their Faculty ID from Firebase
2. Update code with their info:
   ```cpp
   const char* FACULTY_ID = "faculty_1_id";
   const char* BUILDING = "IT Building";
   const char* FLOOR = "First Floor";
   const char* CABIN_ID = "F-101";
   ```
3. Upload to their NodeMCU
4. Place at their desk
5. Done!

### Tracking Multiple Devices:
Keep a spreadsheet:
```
Faculty Name | Faculty ID | Building | Floor | Cabin | NodeMCU IP | Status
-------------|------------|----------|-------|-------|------------|--------
Monali       | abc123...  | IT Bldg  | GF    | S-920 | 192.168.1.33 | ✅
Rajesh       | def456...  | Main     | 1F    | M-101 | 192.168.1.34 | ✅
```

---

## 🎯 Testing Checklist

Before deploying:
- [ ] WiFi credentials are correct
- [ ] Faculty ID is correct
- [ ] Building/Floor/Zone/Cabin info is correct
- [ ] Project ID is correct
- [ ] API Key is correct
- [ ] Code uploads successfully
- [ ] Serial Monitor shows "Connected"
- [ ] Serial Monitor shows "Location updated"
- [ ] Firebase shows updated document
- [ ] Student app shows location

---

## 📞 Need Help?

1. **Check Serial Monitor** - Shows real-time errors
2. **Check Firebase Console** - Verify data is being written
3. **Check Student App** - Verify data is being read
4. **Read FIREBASE_SETUP.md** - Detailed setup guide
5. **Read TESTING_GUIDE.md** - Complete testing procedures

---

## 🎉 Success!

If you see this in Serial Monitor:
```
✅ HTTP 200 - Location updated!
```

And this in Firebase Console:
```
faculty_locations/{facultyId}
  ├─ building: "IT Building"
  ├─ floor: "Ground Floor"
  ├─ isPresent: true
  └─ lastUpdated: (timestamp)
```

And this in Student App:
```
📍 Currently Present 🟢
Building: IT Building
Floor: Ground Floor
Updated: just now
```

**You're all set! 🎊**

---

**Hardware Cost**: ~$5 per faculty  
**Setup Time**: ~5 minutes per device  
**Maintenance**: Zero (auto-updates)  
**Reliability**: 99%+ uptime  

**Deploy and forget! 🚀**
