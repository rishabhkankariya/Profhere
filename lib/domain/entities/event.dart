import 'package:equatable/equatable.dart';

enum EventCategory { academic, cultural, sports, workshop, seminar, other }

class CollegeEvent extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole; // 'student_cr', 'faculty', 'admin'
  final String title;
  final String description; // the "about" bio — CR writes everything here
  final EventCategory category;
  final DateTime eventDate;
  final String? imageUrl;   // uploaded image (base64 or storage URL)
  final DateTime createdAt;
  final bool isApproved;    // faculty/admin approves CR posts

  const CollegeEvent({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.title,
    required this.description,
    required this.category,
    required this.eventDate,
    this.imageUrl,
    required this.createdAt,
    this.isApproved = false,
  });

  bool get isPast => eventDate.isBefore(DateTime.now());

  CollegeEvent copyWith({
    String? id, String? authorId, String? authorName, String? authorRole,
    String? title, String? description, EventCategory? category,
    DateTime? eventDate, String? imageUrl, DateTime? createdAt, bool? isApproved,
  }) => CollegeEvent(
    id: id ?? this.id,
    authorId: authorId ?? this.authorId,
    authorName: authorName ?? this.authorName,
    authorRole: authorRole ?? this.authorRole,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    eventDate: eventDate ?? this.eventDate,
    imageUrl: imageUrl ?? this.imageUrl,
    createdAt: createdAt ?? this.createdAt,
    isApproved: isApproved ?? this.isApproved,
  );

  @override
  List<Object?> get props => [id, authorId, title, eventDate, category, isApproved];
}
