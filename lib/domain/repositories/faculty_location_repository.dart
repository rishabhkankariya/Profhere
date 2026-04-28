import '../entities/faculty_location.dart';

/// Repository for managing faculty's real-time location data
/// Location is updated by NodeMCU every 10-15 minutes
abstract class FacultyLocationRepository {
  /// Get real-time location stream for a specific faculty
  Stream<FacultyLocation?> getFacultyLocation(String facultyId);

  /// Update faculty location (called by NodeMCU or faculty app)
  Future<void> updateFacultyLocation({
    required String facultyId,
    required String building,
    required String floor,
    String? zone,
    String? cabinId,
    required String nodeMcuIp,
    required bool isPresent,
  });

  /// Mark faculty as not present (when they leave)
  Future<void> markFacultyAbsent(String facultyId);

  /// Get last known location (one-time fetch)
  Future<FacultyLocation?> getLastKnownLocation(String facultyId);
}
