import '../entities/location_access.dart';

abstract class LocationAccessRepository {
  /// Request location access from a faculty member
  Future<void> requestLocationAccess({
    required String facultyId,
    required String studentId,
    required String studentName,
    required String studentEmail,
  });

  /// Get all access requests for a faculty member
  Stream<List<LocationAccess>> getAccessRequestsForFaculty(String facultyId);

  /// Get all access requests from a student
  Stream<List<LocationAccess>> getAccessRequestsFromStudent(String studentId);

  /// Approve a location access request
  Future<void> approveLocationAccess({
    required String accessId,
    required String nodeMcuIpAddress,
  });

  /// Reject a location access request
  Future<void> rejectLocationAccess({
    required String accessId,
    required String reason,
  });

  /// Revoke an approved location access
  Future<void> revokeLocationAccess({
    required String accessId,
    required String reason,
  });

  /// Get a single access record by ID
  Future<LocationAccess?> getLocationAccessById(String accessId);

  /// Check if a student has approved access to a faculty's location
  Future<bool> hasApprovedAccess({
    required String facultyId,
    required String studentId,
  });

  /// Get approved access record (with NodeMCU IP)
  Future<LocationAccess?> getApprovedAccess({
    required String facultyId,
    required String studentId,
  });

  /// Get all approved accesses for a faculty (for admin dashboard)
  Stream<List<LocationAccess>> getApprovedAccessesForFaculty(String facultyId);

  /// Get all pending accesses across all faculty (for admin dashboard)
  Stream<List<LocationAccess>> getAllPendingAccesses();

  /// Get all accesses for a faculty (all statuses - for admin)
  Stream<List<LocationAccess>> getAllAccessesForFaculty(String facultyId);
}
