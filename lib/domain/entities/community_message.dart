import 'package:equatable/equatable.dart';

enum MessageStatus { visible, flagged, removed }

class CommunityMessage extends Equatable {
  final String id;
  final String senderId;
  final String senderName;     // 'Anonymous' when anonymous
  final String senderRole;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;
  final bool isAnonymous;
  final String? senderAvatar;  // base64 — only set when mode=private
  final String? replyToId;
  final String? replyToText;
  final String? replyToSender;
  final bool isPinned;
  final DateTime? editedAt;
  final Map<String, String> reactions; // emoji -> userId

  const CommunityMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    this.status = MessageStatus.visible,
    this.isAnonymous = false,
    this.senderAvatar,
    this.replyToId,
    this.replyToText,
    this.replyToSender,
    this.isPinned = false,
    this.editedAt,
    this.reactions = const {},
  });

  bool get isVisible => status == MessageStatus.visible;
  bool get isEdited => editedAt != null;

  CommunityMessage copyWith({
    MessageStatus? status,
    String? text,
    bool? isPinned,
    DateTime? editedAt,
    Map<String, String>? reactions,
  }) => CommunityMessage(
        id: id,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        text: text ?? this.text,
        createdAt: createdAt,
        status: status ?? this.status,
        isAnonymous: isAnonymous,
        senderAvatar: senderAvatar,
        replyToId: replyToId,
        replyToText: replyToText,
        replyToSender: replyToSender,
        isPinned: isPinned ?? this.isPinned,
        editedAt: editedAt ?? this.editedAt,
        reactions: reactions ?? this.reactions,
      );

  @override
  List<Object?> get props => [id, senderId, text, createdAt, status, isAnonymous, isPinned, editedAt, reactions];
}
