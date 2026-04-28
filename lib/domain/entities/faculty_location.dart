import 'package:equatable/equatable.dart';

/// Represents faculty's real-time location sent by NodeMCU
/// Updated every 10-15 minutes by the NodeMCU device
class FacultyLocation extends Equatable {
  final String facultyId;
  final String building;
  final String floor;
  final String? zone;        // e.g., "North Wing", "Lab Area"
  final String? cabinId;     // e.g., "S-920"
  final String nodeMcuIp;    // NodeMCU device IP
  final DateTime lastUpdated; // Last time NodeMCU sent location
  final bool isPresent;      // Is faculty currently present at this location

  const FacultyLocation({
    required this.facultyId,
    required this.building,
    required this.floor,
    this.zone,
    this.cabinId,
    required this.nodeMcuIp,
    required this.lastUpdated,
    required this.isPresent,
  });

  /// Check if location data is stale (older than 20 minutes)
  bool get isStale {
    final diff = DateTime.now().difference(lastUpdated);
    return diff.inMinutes > 20;
  }

  /// Get human-readable time ago string
  String get timeAgo {
    final diff = DateTime.now().difference(lastUpdated);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  FacultyLocation copyWith({
    String? facultyId,
    String? building,
    String? floor,
    String? zone,
    String? cabinId,
    String? nodeMcuIp,
    DateTime? lastUpdated,
    bool? isPresent,
  }) {
    return FacultyLocation(
      facultyId: facultyId ?? this.facultyId,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      zone: zone ?? this.zone,
      cabinId: cabinId ?? this.cabinId,
      nodeMcuIp: nodeMcuIp ?? this.nodeMcuIp,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isPresent: isPresent ?? this.isPresent,
    );
  }

  @override
  List<Object?> get props => [
        facultyId,
        building,
        floor,
        zone,
        cabinId,
        nodeMcuIp,
        lastUpdated,
        isPresent,
      ];
}
