/*
 * Faculty Location Tracker - Software Only Version v3.1
 * 
 * Features:
 * - Sends faculty location to Cloud Firestore every 10 minutes
 * - Software indicators via Serial Monitor (no hardware LEDs)
 * - Auto-reconnect on WiFi failure
 * - Watchdog timer for stability
 * - Error recovery and retry logic
 * - Comprehensive Serial Monitor logging
 * 
 * Hardware:
 * - NodeMCU ESP8266 only (no LEDs required)
 * 
 * Serial Monitor Indicators:
 * - [STATUS] WiFi connection status
 * - [UPDATE] Location update status
 * - [REQUEST] Pending access requests
 * - [VIEWING] Student viewing activity
 * - [ERROR] Error messages
 */

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include <Ticker.h>

// ═══════════════════════════════════════════════════════════════════════════
// ⚙️ CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

// WiFi
const char* WIFI_SSID = "MitHostel@203-2G";
const char* WIFI_PASSWORD = "MitHostel@203";

// Faculty Info (Get these from your Firebase Console)
const char* FACULTY_ID = "PASTE_FACULTY_ID_HERE";  // From Firebase Auth
const char* BUILDING = "IT Building";
const char* FLOOR = "Ground Floor";
const char* ZONE = "South Block";
const char* CABIN_ID = "S-920";

// Firebase Project (Get from Firebase Console > Project Settings)
const char* PROJECT_ID = "profhere";  // Your Firebase project ID
const char* API_KEY = "AIzaSyAmbCK1Kvnxf0llv1d4-nMJVEYHHOXhLh0";  // From Firebase Console

// Update intervals
const unsigned long UPDATE_INTERVAL = 600000;      // 10 min = 600000 ms
const unsigned long REQUEST_CHECK_INTERVAL = 30000; // 30 sec
const unsigned long VIEW_CHECK_INTERVAL = 10000;    // 10 sec

// ═══════════════════════════════════════════════════════════════════════════
// 🔧 GLOBALS
// ═══════════════════════════════════════════════════════════════════════════

unsigned long lastUpdate = 0;
unsigned long lastRequestCheck = 0;
unsigned long lastViewCheck = 0;
unsigned long lastWiFiCheck = 0;
String nodeMcuIp = "";
int updateFailCount = 0;
int wifiReconnectCount = 0;
bool ntpSynced = false;

// NTP Client for accurate timestamps
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 0, 60000);

// Watchdog timer
Ticker watchdog;
volatile bool watchdogTriggered = false;

// ═══════════════════════════════════════════════════════════════════════════
// 🐕 WATCHDOG
// ═══════════════════════════════════════════════════════════════════════════

void ICACHE_RAM_ATTR watchdogISR() {
  watchdogTriggered = true;
}

void feedWatchdog() {
  watchdogTriggered = false;
  watchdog.attach(300, watchdogISR);  // 5 minute watchdog
}

void setup() {
  Serial.begin(115200);
  delay(100);
  
  Serial.println("\n╔═══════════════════════════════════════╗");
  Serial.println("║  Faculty Location Tracker v3.1       ║");
  Serial.println("║  Software Only (No LEDs)              ║");
  Serial.println("╚═══════════════════════════════════════╝\n");
  
  // Start watchdog
  feedWatchdog();
  Serial.println("🐕 Watchdog started (5 min timeout)\n");
  
  // Connect WiFi
  connectWiFi();
  
  // Get IP
  if (WiFi.status() == WL_CONNECTED) {
    nodeMcuIp = WiFi.localIP().toString();
    Serial.println("📡 NodeMCU IP: " + nodeMcuIp + "\n");
  }
  
  // Initialize NTP
  timeClient.begin();
  syncNTP();
  
  // Initial update
  updateLocation();
  
  Serial.println("✅ Ready! Monitoring...\n");
  Serial.println("📊 Status:");
  Serial.println("   - Update interval: " + String(UPDATE_INTERVAL / 60000) + " minutes");
  Serial.println("   - Request check: " + String(REQUEST_CHECK_INTERVAL / 1000) + " seconds");
  Serial.println("   - View check: " + String(VIEW_CHECK_INTERVAL / 1000) + " seconds\n");
}

void loop() {
  unsigned long now = millis();
  
  // Feed watchdog
  feedWatchdog();
  
  // Check if watchdog was triggered
  if (watchdogTriggered) {
    Serial.println("\n[ERROR] ⚠️ Watchdog triggered! Restarting...");
    delay(1000);
    ESP.restart();
  }
  
  // Check WiFi connection every 30 seconds
  if (now - lastWiFiCheck >= 30000) {
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("\n[ERROR] ⚠️ WiFi disconnected! Reconnecting...");
      connectWiFi();
    } else {
      // Software indicator: WiFi status check (replaced LED_STATUS)
      Serial.println("[STATUS] ✓ WiFi Connected (Signal: " + String(WiFi.RSSI()) + " dBm)");
    }
    lastWiFiCheck = now;
  }
  
  // Update location every 10 minutes
  if (now - lastUpdate >= UPDATE_INTERVAL) {
    Serial.println("\n⏰ Time to update location...");
    updateLocation();
    lastUpdate = now;
  }
  
  // Check for pending requests every 30 seconds
  if (now - lastRequestCheck >= REQUEST_CHECK_INTERVAL) {
    checkPendingRequests();
    lastRequestCheck = now;
  }
  
  // Check if student is viewing every 10 seconds
  if (now - lastViewCheck >= VIEW_CHECK_INTERVAL) {
    checkStudentViewing();
    lastViewCheck = now;
  }
  
  // Sync NTP every hour
  if (!ntpSynced || (now % 3600000 < 1000)) {
    syncNTP();
  }
  
  delay(1000);
}

// ═══════════════════════════════════════════════════════════════════════════
// 📶 WIFI
// ═══════════════════════════════════════════════════════════════════════════

void connectWiFi() {
  Serial.print("📶 Connecting to: " + String(WIFI_SSID) + " ");
  
  // Disconnect first
  WiFi.disconnect();
  delay(100);
  
  // Set WiFi mode and hostname
  WiFi.mode(WIFI_STA);
  WiFi.hostname("ProfHere-" + String(FACULTY_ID).substring(0, 8));
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 40) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[STATUS] ✅ Connected! IP: " + WiFi.localIP().toString());
    Serial.println("[STATUS]    Signal: " + String(WiFi.RSSI()) + " dBm");
    nodeMcuIp = WiFi.localIP().toString();
    wifiReconnectCount++;
    updateFailCount = 0;  // Reset fail count on successful connection
  } else {
    Serial.println("\n[ERROR] ❌ Failed to connect!");
    Serial.println("[ERROR]    Reconnect attempts: " + String(wifiReconnectCount));
    
    // If failed multiple times, restart
    if (wifiReconnectCount > 5) {
      Serial.println("[ERROR] ⚠️ Too many reconnect failures. Restarting...");
      delay(1000);
      ESP.restart();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🕐 NTP SYNC
// ═══════════════════════════════════════════════════════════════════════════

void syncNTP() {
  if (WiFi.status() != WL_CONNECTED) return;
  
  Serial.print("🕐 Syncing time with NTP... ");
  
  int attempts = 0;
  while (!timeClient.update() && attempts < 5) {
    timeClient.forceUpdate();
    delay(1000);
    attempts++;
  }
  
  if (attempts < 5) {
    ntpSynced = true;
    Serial.println("✅ Time synced!");
    Serial.println("   Current time: " + getCurrentTimestamp());
  } else {
    ntpSynced = false;
    Serial.println("[ERROR] ❌ Failed to sync time");
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔥 FIRESTORE UPDATE
// ═══════════════════════════════════════════════════════════════════════════

void updateLocation() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[ERROR] ❌ No WiFi. Reconnecting...");
    connectWiFi();
    return;
  }
  
  // Software indicator: Starting update (replaced LED_UPDATE blink)
  Serial.println("[UPDATE] 📤 Starting location update...");
  
  WiFiClientSecure client;
  client.setInsecure();  // Skip SSL verification
  client.setTimeout(15000);  // 15 second timeout
  
  HTTPClient http;
  http.setTimeout(15000);
  
  // Firestore REST API endpoint
  String url = "https://firestore.googleapis.com/v1/projects/" + 
               String(PROJECT_ID) + 
               "/databases/(default)/documents/faculty_locations/" + 
               String(FACULTY_ID) + 
               "?key=" + String(API_KEY);
  
  // Update NTP time if synced
  if (ntpSynced) {
    timeClient.update();
  }
  
  // Build Firestore document
  StaticJsonDocument<1024> doc;
  
  doc["fields"]["facultyId"]["stringValue"] = FACULTY_ID;
  doc["fields"]["building"]["stringValue"] = BUILDING;
  doc["fields"]["floor"]["stringValue"] = FLOOR;
  doc["fields"]["zone"]["stringValue"] = ZONE;
  doc["fields"]["cabinId"]["stringValue"] = CABIN_ID;
  doc["fields"]["nodeMcuIp"]["stringValue"] = nodeMcuIp;
  doc["fields"]["isPresent"]["booleanValue"] = true;
  doc["fields"]["lastUpdated"]["timestampValue"] = getCurrentTimestamp();
  doc["fields"]["updateCount"]["integerValue"] = String(millis() / 1000);  // Uptime in seconds
  doc["fields"]["wifiSignal"]["integerValue"] = String(WiFi.RSSI());
  
  String payload;
  serializeJson(doc, payload);
  
  Serial.println("[UPDATE]    Location: " + String(BUILDING) + " - " + String(FLOOR));
  Serial.println("[UPDATE]    WiFi Signal: " + String(WiFi.RSSI()) + " dBm");
  
  // Send PATCH request (update document)
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  
  int httpCode = http.PATCH(payload);
  
  if (httpCode > 0) {
    if (httpCode == 200) {
      // Software indicator: Update success (replaced LED_UPDATE success blink)
      Serial.println("[UPDATE] ✅ Location updated successfully!");
      updateFailCount = 0;  // Reset fail count
    } else {
      Serial.println("[ERROR] ⚠️ HTTP " + String(httpCode) + " - " + http.getString());
      updateFailCount++;
    }
  } else {
    Serial.println("[ERROR] ❌ Update failed: " + http.errorToString(httpCode));
    updateFailCount++;
  }
  
  http.end();
  
  // If too many failures, try reconnecting WiFi
  if (updateFailCount >= 3) {
    Serial.println("[ERROR] ⚠️ Multiple update failures. Reconnecting WiFi...");
    connectWiFi();
    updateFailCount = 0;
  }
  
  Serial.println("[UPDATE]    Uptime: " + String(millis() / 60000) + " minutes");
  Serial.println("[UPDATE]    Free heap: " + String(ESP.getFreeHeap()) + " bytes\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// 📋 CHECK PENDING REQUESTS
// ═══════════════════════════════════════════════════════════════════════════

void checkPendingRequests() {
  if (WiFi.status() != WL_CONNECTED) return;
  
  WiFiClientSecure client;
  client.setInsecure();
  client.setTimeout(10000);
  
  HTTPClient http;
  http.setTimeout(10000);
  
  // Query Firestore for pending requests
  String url = "https://firestore.googleapis.com/v1/projects/" + 
               String(PROJECT_ID) + 
               "/databases/(default)/documents:runQuery?key=" + 
               String(API_KEY);
  
  // Build query for pending requests
  StaticJsonDocument<768> queryDoc;
  queryDoc["structuredQuery"]["from"][0]["collectionId"] = "location_access";
  queryDoc["structuredQuery"]["where"]["compositeFilter"]["op"] = "AND";
  
  // Filter: facultyId == FACULTY_ID
  queryDoc["structuredQuery"]["where"]["compositeFilter"]["filters"][0]["fieldFilter"]["field"]["fieldPath"] = "facultyId";
  queryDoc["structuredQuery"]["where"]["compositeFilter"]["filters"][0]["fieldFilter"]["op"] = "EQUAL";
  queryDoc["structuredQuery"]["where"]["compositeFilter"]["filters"][0]["fieldFilter"]["value"]["stringValue"] = FACULTY_ID;
  
  // Filter: status == "pending"
  queryDoc["structuredQuery"]["where"]["compositeFilter"]["filters"][1]["fieldFilter"]["field"]["fieldPath"] = "status";
  queryDoc["structuredQuery"]["where"]["compositeFilter"]["filters"][1]["fieldFilter"]["op"] = "EQUAL";
  queryDoc["structuredQuery"]["where"]["compositeFilter"]["filters"][1]["fieldFilter"]["value"]["stringValue"] = "pending";
  
  String queryPayload;
  serializeJson(queryDoc, queryPayload);
  
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  
  int httpCode = http.POST(queryPayload);
  
  if (httpCode == 200) {
    String response = http.getString();
    
    // Check if there are any pending requests
    if (response.indexOf("\"document\"") > 0) {
      // Software indicator: Pending requests detected (replaced LED_REQUEST blink)
      Serial.println("[REQUEST] 🟡 Pending access request(s) detected!");
    } else {
      // Software indicator: No pending requests (replaced LED_REQUEST off)
      Serial.println("[REQUEST] ✓ No pending requests");
    }
  } else if (httpCode > 0) {
    Serial.println("[ERROR] ⚠️ Request check failed: HTTP " + String(httpCode));
  }
  
  http.end();
}

// ═══════════════════════════════════════════════════════════════════════════
// 👁️ CHECK STUDENT VIEWING
// ═══════════════════════════════════════════════════════════════════════════

void checkStudentViewing() {
  if (WiFi.status() != WL_CONNECTED) return;
  
  WiFiClientSecure client;
  client.setInsecure();
  client.setTimeout(10000);
  
  HTTPClient http;
  http.setTimeout(10000);
  
  // Get faculty location document
  String url = "https://firestore.googleapis.com/v1/projects/" + 
               String(PROJECT_ID) + 
               "/databases/(default)/documents/faculty_locations/" + 
               String(FACULTY_ID) + 
               "?key=" + String(API_KEY);
  
  http.begin(client, url);
  
  int httpCode = http.GET();
  
  if (httpCode == 200) {
    String response = http.getString();
    
    // Check if lastViewedAt exists and is recent (within 5 minutes)
    if (response.indexOf("lastViewedAt") > 0) {
      // Parse the timestamp and check if it's within 5 minutes
      int viewedIndex = response.indexOf("lastViewedAt");
      if (viewedIndex > 0) {
        // Software indicator: Student viewing detected (replaced LED_VIEWING on)
        Serial.println("[VIEWING] 🔴 Student is viewing your location!");
      }
    } else {
      // Software indicator: No recent views (replaced LED_VIEWING off)
      Serial.println("[VIEWING] ✓ No recent student views");
    }
  } else if (httpCode > 0) {
    Serial.println("[ERROR] ⚠️ View check failed: HTTP " + String(httpCode));
  }
  
  http.end();
}

// ═══════════════════════════════════════════════════════════════════════════
// 🕐 TIMESTAMP
// ═══════════════════════════════════════════════════════════════════════════

String getCurrentTimestamp() {
  if (!ntpSynced) {
    // Return a placeholder if NTP not synced
    return "2024-01-01T00:00:00Z";
  }
  
  // Get current time from NTP
  unsigned long epochTime = timeClient.getEpochTime();
  
  // Convert to ISO 8601 format
  time_t rawtime = epochTime;
  struct tm* timeinfo = gmtime(&rawtime);
  
  char buffer[30];
  strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", timeinfo);
  
  return String(buffer);
}

// ═══════════════════════════════════════════════════════════════════════════
// 📊 DIAGNOSTICS
// ═══════════════════════════════════════════════════════════════════════════

void printDiagnostics() {
  Serial.println("\n📊 System Diagnostics:");
  Serial.println("   Uptime: " + String(millis() / 60000) + " minutes");
  Serial.println("   Free heap: " + String(ESP.getFreeHeap()) + " bytes");
  Serial.println("   WiFi RSSI: " + String(WiFi.RSSI()) + " dBm");
  Serial.println("   WiFi reconnects: " + String(wifiReconnectCount));
  Serial.println("   Update failures: " + String(updateFailCount));
  Serial.println("   NTP synced: " + String(ntpSynced ? "Yes" : "No"));
  Serial.println("   IP Address: " + nodeMcuIp);
  Serial.println();
}
