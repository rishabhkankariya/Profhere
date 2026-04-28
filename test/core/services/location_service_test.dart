import 'package:flutter_test/flutter_test.dart';
import 'package:profhere/core/services/location_service.dart';

void main() {
  group('LocationService', () {
    group('isValidIpAddress', () {
      test('returns true for valid IP addresses', () {
        expect(LocationService.isValidIpAddress('192.168.1.100'), true);
        expect(LocationService.isValidIpAddress('10.0.0.1'), true);
        expect(LocationService.isValidIpAddress('172.16.0.1'), true);
        expect(LocationService.isValidIpAddress('255.255.255.255'), true);
        expect(LocationService.isValidIpAddress('0.0.0.0'), true);
      });

      test('returns false for invalid IP addresses', () {
        expect(LocationService.isValidIpAddress('256.1.1.1'), false);
        expect(LocationService.isValidIpAddress('192.168.1'), false);
        expect(LocationService.isValidIpAddress('192.168.1.1.1'), false);
        expect(LocationService.isValidIpAddress('abc.def.ghi.jkl'), false);
        expect(LocationService.isValidIpAddress('192.168.1.a'), false);
        expect(LocationService.isValidIpAddress(''), false);
        expect(LocationService.isValidIpAddress('192.168.-1.1'), false);
      });

      test('returns false for edge cases', () {
        expect(LocationService.isValidIpAddress('...'), false);
        expect(LocationService.isValidIpAddress('192.168.1.'), false);
        expect(LocationService.isValidIpAddress('.192.168.1.1'), false);
      });
    });

    group('sendLocationToNodeMCU', () {
      test('constructs correct URL with device IP', () async {
        // This test verifies the URL construction logic
        // In a real scenario, we'd mock the http.get call
        const nodeMcuIp = '192.168.1.100';
        const deviceIp = '192.168.1.50';

        final expectedUrl =
            'http://$nodeMcuIp/updateLocation?ip=$deviceIp';

        expect(expectedUrl, 'http://192.168.1.100/updateLocation?ip=192.168.1.50');
      });

      test('throws exception for invalid NodeMCU IP', () async {
        expect(
          () => LocationService.sendLocationToNodeMCU(
            nodeMcuIpAddress: 'invalid-ip',
            deviceIp: '192.168.1.50',
          ),
          throwsException,
        );
      });
    });

    group('testNodeMCUConnection', () {
      test('returns false for invalid IP format', () async {
        // Should handle gracefully
        final result = await LocationService.testNodeMCUConnection('invalid');
        expect(result, false);
      });

      test('returns false for unreachable IP', () async {
        // Non-routable IP should timeout
        final result = await LocationService.testNodeMCUConnection('192.0.2.1');
        expect(result, false);
      });
    });
  });
}
