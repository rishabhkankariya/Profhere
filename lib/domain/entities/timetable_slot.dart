class TimetableSlot {
  const TimetableSlot({
    required this.id,
    required this.facultyId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
  });

  final String id;
  final String facultyId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String subject;
}
