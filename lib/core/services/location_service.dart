import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

/// Service to handle WiFi IP detection and NodeMCU communication
class LocationService {
  static const _timeout = Duration(seconds: 5);

  /// Get the device's current WiFi IP address
  /// Returns null if not connected to WiFi
  static Future<String?> getWifiIP() async {
    if (kIsWeb) {
      debugPrint('LocationService: WiFi IP not available on web');
      return null;
    }

    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      debugPrint('LocationService: WiFi IP = $ip');
      return ip;
    } catch (e) {
      debugPrint('LocationService: Error getting WiFi IP: $e');
      return null;
    }
  }

  /// Send the device's WiFi IP to the NodeMCU
  /// The NodeMCU will use this IP to identify the faculty member's location
  static Future<String> sendLocationToNodeMCU({
    required String nodeMcuIpAddress,
    required String deviceIp,
  }) async {
    if (kIsWeb) {
      debugPrint('LocationService: NodeMCU communication not available on web');
      return 'Web platform - simulation mode';
    }

    try {
      final url = Uri.parse(
        'http://$nodeMcuIpAddress/updateLocation?ip=$deviceIp',
      );

      debugPrint('LocationService: Sending to NodeMCU at $url');

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        debugPrint('LocationService: Success - ${response.body}');
        return response.body;
      } else {
        debugPrint('LocationService: Failed - ${response.statusCode}');
        throw Exception('NodeMCU returned ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('LocationService: Connection error: $e');
      throw Exception('Cannot connect to NodeMCU. Check IP address and WiFi.');
    } catch (e) {
      debugPrint('LocationService: Error: $e');
      rethrow;
    }
  }

  /// Validate NodeMCU IP address format
  static bool isValidIpAddress(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    try {
      for (final part in parts) {
        final num = int.parse(part);
        if (num < 0 || num > 255) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Test connection to NodeMCU (for settings validation)
  static Future<bool> testNodeMCUConnection(String nodeMcuIpAddress) async {
    if (kIsWeb) return true; // Assume success on web

    try {
      final url = Uri.parse('http://$nodeMcuIpAddress/status');
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('LocationService: Test connection failed: $e');
      return false;
    }
  }
}
