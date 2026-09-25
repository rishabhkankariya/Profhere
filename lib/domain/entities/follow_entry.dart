class FollowEntry {
  const FollowEntry({
    required this.id,
    required this.studentId,
    required this.facultyId,
    required this.createdAt,
  });

  final String id;
  final String studentId;
  final String facultyId;
  final DateTime createdAt;
}
