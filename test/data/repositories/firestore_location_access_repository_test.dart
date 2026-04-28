import 'package:flutter_test/flutter_test.dart';
import 'package:profhere/domain/entities/location_access.dart';

void main() {
  group('FirestoreLocationAccessRepository', () {
    group('LocationAccess Entity', () {
      test('creates LocationAccess with all fields', () {
        final access = LocationAccess(
          id: 'test-id',
          facultyId: 'faculty-1',
          studentId: 'student-1',
          studentName: 'John Doe',
          studentEmail: 'john@example.com',
          status: LocationAccessStatus.pending,
          requestedAt: DateTime.now(),
        );

        expect(access.id, 'test-id');
        expect(access.facultyId, 'faculty-1');
        expect(access.studentId, 'student-1');
        expect(access.studentName, 'John Doe');
        expect(access.studentEmail, 'john@example.com');
        expect(access.status, LocationAccessStatus.pending);
        expect(access.isPending, true);
        expect(access.isApproved, false);
      });

      test('copyWith creates new instance with updated fields', () {
        final original = LocationAccess(
          id: 'test-id',
          facultyId: 'faculty-1',
          studentId: 'student-1',
          studentName: 'John Doe',
          studentEmail: 'john@example.com',
          status: LocationAccessStatus.pending,
          requestedAt: DateTime.now(),
        );

        final updated = original.copyWith(
          status: LocationAccessStatus.approved,
          nodeMcuIpAddress: '192.168.1.100',
        );

        expect(updated.status, LocationAccessStatus.approved);
        expect(updated.nodeMcuIpAddress, '192.168.1.100');
        expect(updated.id, original.id); // Unchanged
        expect(updated.studentName, original.studentName); // Unchanged
      });

      test('LocationAccessStatus enum has correct labels', () {
        expect(LocationAccessStatus.pending.label, 'Pending');
        expect(LocationAccessStatus.approved.label, 'Approved');
        expect(LocationAccessStatus.rejected.label, 'Rejected');
        expect(LocationAccessStatus.revoked.label, 'Revoked');
      });

      test('LocationAccess status checks work correctly', () {
        final pending = LocationAccess(
          id: 'id',
          facultyId: 'fac',
          studentId: 'stu',
          studentName: 'Name',
          studentEmail: 'email@test.com',
          status: LocationAccessStatus.pending,
          requestedAt: DateTime.now(),
        );

        expect(pending.isPending, true);
        expect(pending.isApproved, false);
        expect(pending.isRejected, false);
        expect(pending.isRevoked, false);

        final approved = pending.copyWith(
          status: LocationAccessStatus.approved,
          approvedAt: DateTime.now(),
        );

        expect(approved.isPending, false);
        expect(approved.isApproved, true);
        expect(approved.isRejected, false);
        expect(approved.isRevoked, false);
      });

      test('LocationAccess equality works with Equatable', () {
        final now = DateTime.now();
        final access1 = LocationAccess(
          id: 'test-id',
          facultyId: 'faculty-1',
          studentId: 'student-1',
          studentName: 'John Doe',
          studentEmail: 'john@example.com',
          status: LocationAccessStatus.pending,
          requestedAt: now,
        );

        final access2 = LocationAccess(
          id: 'test-id',
          facultyId: 'faculty-1',
          studentId: 'student-1',
          studentName: 'John Doe',
          studentEmail: 'john@example.com',
          status: LocationAccessStatus.pending,
          requestedAt: now,
        );

        expect(access1, access2);
      });

      test('LocationAccess with different IDs are not equal', () {
        final now = DateTime.now();
        final access1 = LocationAccess(
          id: 'test-id-1',
          facultyId: 'faculty-1',
          studentId: 'student-1',
          studentName: 'John Doe',
          studentEmail: 'john@example.com',
          status: LocationAccessStatus.pending,
          requestedAt: now,
        );

        final access2 = LocationAccess(
          id: 'test-id-2',
          facultyId: 'faculty-1',
          studentId: 'student-1',
          studentName: 'John Doe',
          studentEmail: 'john@example.com',
          status: LocationAccessStatus.pending,
          requestedAt: now,
        );

        expect(access1, isNot(access2));
      });
    });

    group('LocationAccess with reason and timestamps', () {
      test('stores rejection reason', () {
        final now = DateTime.now();
        final access = LocationAccess(
          id: 'test-id',
          facultyId: 'faculty-1',
          studentId: 'student-1',
          studentName: 'John Doe',
          studentEmail: 'john@example.com',
          status: LocationAccessStatus.rejected,
          requestedAt: now,
          rejectedAt: now,
          reason: 'Privacy concerns',
        );

        expect(access.isRejected, true);
        expect(access.reason, 'Privacy concerns');
        expect(access.rejectedAt, now);
      });

      test('stores revocation reason', () {
        final now = DateTime.now();
        final access = LocationAccess(
          id: 'test-id',
          facultyId: 'faculty-1',
          studentId: 'student-1',
          studentName: 'John Doe',
          studentEmail: 'john@example.com',
          status: LocationAccessStatus.revoked,
          requestedAt: now,
          revokedAt: now,
          reason: 'No longer needed',
        );

        expect(access.isRevoked, true);
        expect(access.reason, 'No longer needed');
        expect(access.revokedAt, now);
      });

      test('stores NodeMCU IP when approved', () {
        final now = DateTime.now();
        final access = LocationAccess(
          id: 'test-id',
          facultyId: 'faculty-1',
          studentId: 'student-1',
          studentName: 'John Doe',
          studentEmail: 'john@example.com',
          status: LocationAccessStatus.approved,
          nodeMcuIpAddress: '192.168.1.100',
          requestedAt: now,
          approvedAt: now,
        );

        expect(access.isApproved, true);
        expect(access.nodeMcuIpAddress, '192.168.1.100');
        expect(access.approvedAt, now);
      });
    });
  });
}
