class Faculty {
  const Faculty({
    required this.id,
    required this.userId,
    required this.name,
    required this.status,
    required this.cabin,
    required this.department,
  });

  final String id;
  final String userId;
  final String name;
  final String status;
  final String cabin;
  final String department;

  Faculty copyWith({
    String? id,
    String? userId,
    String? name,
    String? status,
    String? cabin,
    String? department,
  }) {
    return Faculty(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      status: status ?? this.status,
      cabin: cabin ?? this.cabin,
      department: department ?? this.department,
    );
  }
}
