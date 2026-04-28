import 'package:flutter_test/flutter_test.dart';
import 'package:profhere/core/services/location_service.dart';
import 'package:profhere/domain/entities/location_access.dart';

void main() {
  group('Location Tracker Integration Tests', () {
    group('LocationService - IP Validation', () {
      test('validates correct IP addresses', () {
        expect(LocationService.isValidIpAddress('192.168.1.100'), true);
        expect(LocationService.isValidIpAddress('10.0.0.1'), true);
        expect(LocationService.isValidIpAddress('172.16.0.1'), true);
      });

      test('rejects invalid IP addresses', () {
        expect(LocationService.isValidIpAddress('256.1.1.1'), false);
        expect(LocationService.isValidIpAddress('192.168.1'), false);
        expect(LocationService.isValidIpAddress('abc.def.ghi.jkl'), false);
      });

      test('constructs correct NodeMCU URL', () {
        const nodeMcuIp = '192.168.1.100';
        const deviceIp = '192.168.1.50';
        final expectedUrl =
            'http://$nodeMcuIp/updateLocation?ip=$deviceIp';

        expect(
          expectedUrl,
          'http://192.168.1.100/updateLocation?ip=192.168.1.50',
        );
      });
    });

    group('LocationAccess Entity', () {
      test('creates pending request', () {
        final now = DateTime.now();
        final access = LocationAccess(
          id: 'req-001',
          facultyId: 'fac-001',
          studentId: 'stu-001',
          studentName: 'Alice Johnson',
          studentEmail: 'alice@university.edu',
          status: LocationAccessStatus.pending,
          requestedAt: now,
        );

        expect(access.isPending, true);
        expect(access.isApproved, false);
        expect(access.nodeMcuIpAddress, null);
      });

      test('transitions from pending to approved', () {
        final now = DateTime.now();
        final pending = LocationAccess(
          id: 'req-001',
          facultyId: 'fac-001',
          studentId: 'stu-001',
          studentName: 'Alice Johnson',
          studentEmail: 'alice@university.edu',
          status: LocationAccessStatus.pending,
          requestedAt: now,
        );

        final approved = pending.copyWith(
          status: LocationAccessStatus.approved,
          nodeMcuIpAddress: '192.168.1.100',
          approvedAt: now,
        );

        expect(approved.isApproved, true);
        expect(approved.nodeMcuIpAddress, '192.168.1.100');
        expect(approved.approvedAt, now);
      });

      test('transitions from pending to rejected', () {
        final now = DateTime.now();
        final pending = LocationAccess(
          id: 'req-001',
          facultyId: 'fac-001',
          studentId: 'stu-001',
          studentName: 'Alice Johnson',
          studentEmail: 'alice@university.edu',
          status: LocationAccessStatus.pending,
          requestedAt: now,
        );

        final rejected = pending.copyWith(
          status: LocationAccessStatus.rejected,
          rejectedAt: now,
          reason: 'Privacy concerns',
        );

        expect(rejected.isRejected, true);
        expect(rejected.reason, 'Privacy concerns');
      });

      test('transitions from approved to revoked', () {
        final now = DateTime.now();
        final approved = LocationAccess(
          id: 'req-001',
          facultyId: 'fac-001',
          studentId: 'stu-001',
          studentName: 'Alice Johnson',
          studentEmail: 'alice@university.edu',
          status: LocationAccessStatus.approved,
          nodeMcuIpAddress: '192.168.1.100',
          requestedAt: now,
          approvedAt: now,
        );

        final revoked = approved.copyWith(
          status: LocationAccessStatus.revoked,
          revokedAt: now,
          reason: 'No longer needed',
        );

        expect(revoked.isRevoked, true);
        expect(revoked.reason, 'No longer needed');
      });
    });

    group('LocationAccess Workflow Scenarios', () {
      test('complete approval workflow', () {
        final requestTime = DateTime(2024, 4, 26, 10, 0, 0);
        final approvalTime = DateTime(2024, 4, 26, 10, 5, 0);

        // Step 1: Student requests access
        final request = LocationAccess(
          id: 'req-001',
          facultyId: 'fac-001',
          studentId: 'stu-001',
          studentName: 'Alice Johnson',
          studentEmail: 'alice@university.edu',
          status: LocationAccessStatus.pending,
          requestedAt: requestTime,
        );

        expect(request.isPending, true);
        expect(request.status.label, 'Pending');

        // Step 2: Faculty approves with NodeMCU IP
        final approved = request.copyWith(
          status: LocationAccessStatus.approved,
          nodeMcuIpAddress: '192.168.1.100',
          approvedAt: approvalTime,
        );

        expect(approved.isApproved, true);
        expect(approved.nodeMcuIpAddress, '192.168.1.100');
        expect(approved.status.label, 'Approved');

        // Step 3: Student can now send location
        expect(
          LocationService.isValidIpAddress(approved.nodeMcuIpAddress!),
          true,
        );
      });

      test('rejection workflow', () {
        final requestTime = DateTime(2024, 4, 26, 10, 0, 0);
        final rejectionTime = DateTime(2024, 4, 26, 10, 2, 0);

        // Step 1: Student requests access
        final request = LocationAccess(
          id: 'req-002',
          facultyId: 'fac-001',
          studentId: 'stu-002',
          studentName: 'Bob Smith',
          studentEmail: 'bob@university.edu',
          status: LocationAccessStatus.pending,
          requestedAt: requestTime,
        );

        // Step 2: Faculty rejects with reason
        final rejected = request.copyWith(
          status: LocationAccessStatus.rejected,
          rejectedAt: rejectionTime,
          reason: 'I prefer not to share my location',
        );

        expect(rejected.isRejected, true);
        expect(rejected.reason, 'I prefer not to share my location');
        expect(rejected.status.label, 'Rejected');
      });

      test('revocation workflow', () {
        final requestTime = DateTime(2024, 4, 26, 10, 0, 0);
        final approvalTime = DateTime(2024, 4, 26, 10, 5, 0);
        final revocationTime = DateTime(2024, 4, 26, 15, 0, 0);

        // Step 1: Request and approve
        final approved = LocationAccess(
          id: 'req-003',
          facultyId: 'fac-001',
          studentId: 'stu-003',
          studentName: 'Carol White',
          studentEmail: 'carol@university.edu',
          status: LocationAccessStatus.approved,
          nodeMcuIpAddress: '192.168.1.100',
          requestedAt: requestTime,
          approvedAt: approvalTime,
        );

        // Step 2: Faculty revokes access
        final revoked = approved.copyWith(
          status: LocationAccessStatus.revoked,
          revokedAt: revocationTime,
          reason: 'Consultation completed',
        );

        expect(revoked.isRevoked, true);
        expect(revoked.reason, 'Consultation completed');
        expect(revoked.status.label, 'Revoked');
      });
    });

    group('LocationAccess Status Enum', () {
      test('all status values have labels', () {
        expect(LocationAccessStatus.pending.label, 'Pending');
        expect(LocationAccessStatus.approved.label, 'Approved');
        expect(LocationAccessStatus.rejected.label, 'Rejected');
        expect(LocationAccessStatus.revoked.label, 'Revoked');
      });

      test('status index mapping', () {
        expect(LocationAccessStatus.pending.index, 0);
        expect(LocationAccessStatus.approved.index, 1);
        expect(LocationAccessStatus.rejected.index, 2);
        expect(LocationAccessStatus.revoked.index, 3);
      });
    });

    group('LocationAccess Equality', () {
      test('same data creates equal objects', () {
        final now = DateTime.now();
        final access1 = LocationAccess(
          id: 'req-001',
          facultyId: 'fac-001',
          studentId: 'stu-001',
          studentName: 'Alice Johnson',
          studentEmail: 'alice@university.edu',
          status: LocationAccessStatus.pending,
          requestedAt: now,
        );

        final access2 = LocationAccess(
          id: 'req-001',
          facultyId: 'fac-001',
          studentId: 'stu-001',
          studentName: 'Alice Johnson',
          studentEmail: 'alice@university.edu',
          status: LocationAccessStatus.pending,
          requestedAt: now,
        );

        expect(access1, access2);
      });

      test('different IDs create unequal objects', () {
        final now = DateTime.now();
        final access1 = LocationAccess(
          id: 'req-001',
          facultyId: 'fac-001',
          studentId: 'stu-001',
          studentName: 'Alice Johnson',
          studentEmail: 'alice@university.edu',
          status: LocationAccessStatus.pending,
          requestedAt: now,
        );

        final access2 = LocationAccess(
          id: 'req-002',
          facultyId: 'fac-001',
          studentId: 'stu-001',
          studentName: 'Alice Johnson',
          studentEmail: 'alice@university.edu',
          status: LocationAccessStatus.pending,
          requestedAt: now,
        );

        expect(access1, isNot(access2));
      });
    });

    group('Multiple Requests Scenario', () {
      test('faculty receives multiple requests', () {
        final now = DateTime.now();
        final requests = [
          LocationAccess(
            id: 'req-001',
            facultyId: 'fac-001',
            studentId: 'stu-001',
            studentName: 'Alice Johnson',
            studentEmail: 'alice@university.edu',
            status: LocationAccessStatus.pending,
            requestedAt: now,
          ),
          LocationAccess(
            id: 'req-002',
            facultyId: 'fac-001',
            studentId: 'stu-002',
            studentName: 'Bob Smith',
            studentEmail: 'bob@university.edu',
            status: LocationAccessStatus.pending,
            requestedAt: now.add(const Duration(minutes: 5)),
          ),
          LocationAccess(
            id: 'req-003',
            facultyId: 'fac-001',
            studentId: 'stu-003',
            studentName: 'Carol White',
            studentEmail: 'carol@university.edu',
            status: LocationAccessStatus.pending,
            requestedAt: now.add(const Duration(minutes: 10)),
          ),
        ];

        expect(requests.length, 3);
        expect(requests.every((r) => r.isPending), true);
        expect(requests.every((r) => r.facultyId == 'fac-001'), true);
      });

      test('faculty approves some and rejects others', () {
        final now = DateTime.now();
        var requests = [
          LocationAccess(
            id: 'req-001',
            facultyId: 'fac-001',
            studentId: 'stu-001',
            studentName: 'Alice Johnson',
            studentEmail: 'alice@university.edu',
            status: LocationAccessStatus.pending,
            requestedAt: now,
          ),
          LocationAccess(
            id: 'req-002',
            facultyId: 'fac-001',
            studentId: 'stu-002',
            studentName: 'Bob Smith',
            studentEmail: 'bob@university.edu',
            status: LocationAccessStatus.pending,
            requestedAt: now.add(const Duration(minutes: 5)),
          ),
        ];

        // Approve first
        requests[0] = requests[0].copyWith(
          status: LocationAccessStatus.approved,
          nodeMcuIpAddress: '192.168.1.100',
          approvedAt: now.add(const Duration(minutes: 1)),
        );

        // Reject second
        requests[1] = requests[1].copyWith(
          status: LocationAccessStatus.rejected,
          rejectedAt: now.add(const Duration(minutes: 2)),
          reason: 'Not available',
        );

        expect(requests[0].isApproved, true);
        expect(requests[1].isRejected, true);
        expect(
          requests.where((r) => r.isApproved).length,
          1,
        );
        expect(
          requests.where((r) => r.isRejected).length,
          1,
        );
      });
    });
  });
}
