import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/entities/community_message.dart';
import '../datasources/local/hive_service.dart';

/// Banned words list — messages containing these are auto-flagged.
const _bannedPatterns = [
  // abuse
  'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'damn', 'crap',
  // hate / religion
  'kafir', 'infidel', 'jihad', 'terrorist', 'nazi', 'nigger', 'faggot',
  // slurs
  'retard', 'idiot', 'stupid', 'loser',
];

class CommunityRepository {
  static const _uuid = Uuid();
  final _controller = StreamController<List<CommunityMessage>>.broadcast();

  void _notify() => _controller.add(_getAll());

  List<CommunityMessage> _getAll() {
    return HiveService.community.values
        .whereType<Map>()
        .map(_fromMap)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  CommunityMessage _fromMap(Map m) => CommunityMessage(
        id: m['id'] as String,
        senderId: m['senderId'] as String,
        senderName: m['senderName'] as String,
        senderRole: m['senderRole'] as String,
        text: m['text'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        status: MessageStatus.values[m['status'] as int? ?? 0],
        isAnonymous: m['isAnonymous'] as bool? ?? false,
        senderAvatar: m['senderAvatar'] as String?,
        replyToId: m['replyToId'] as String?,
        replyToText: m['replyToText'] as String?,
        replyToSender: m['replyToSender'] as String?,
        isPinned: m['isPinned'] as bool? ?? false,
        editedAt: m['editedAt'] != null ? DateTime.parse(m['editedAt'] as String) : null,
        reactions: m['reactions'] != null ? Map<String, String>.from(m['reactions'] as Map) : {},
      );

  Map<String, dynamic> _toMap(CommunityMessage msg) => {
        'id': msg.id,
        'senderId': msg.senderId,
        'senderName': msg.senderName,
        'senderRole': msg.senderRole,
        'text': msg.text,
        'createdAt': msg.createdAt.toIso8601String(),
        'status': msg.status.index,
        'isAnonymous': msg.isAnonymous,
        'senderAvatar': msg.senderAvatar,
        'replyToId': msg.replyToId,
        'replyToText': msg.replyToText,
        'replyToSender': msg.replyToSender,
        'isPinned': msg.isPinned,
        'editedAt': msg.editedAt?.toIso8601String(),
        'reactions': msg.reactions,
      };

  /// Returns true if the text violates community rules.
  bool containsBannedContent(String text) {
    final lower = text.toLowerCase();
    return _bannedPatterns.any((p) => lower.contains(p));
  }

  Stream<List<CommunityMessage>> watch() async* {
    yield _getAll();
    yield* _controller.stream;
  }

  Future<CommunityMessage> sendMessage({
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
    bool isAnonymous = false,
    String? senderAvatar,
    CommunityMessage? replyTo,
  }) async {
    final isBanned = containsBannedContent(text);
    final msg = CommunityMessage(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: isAnonymous ? 'Anonymous' : senderName,
      senderRole: senderRole,
      text: text,
      createdAt: DateTime.now(),
      status: isBanned ? MessageStatus.flagged : MessageStatus.visible,
      isAnonymous: isAnonymous,
      senderAvatar: isAnonymous ? null : senderAvatar,
      replyToId: replyTo?.id,
      replyToText: replyTo?.text,
      replyToSender: replyTo?.senderName,
    );
    await HiveService.community.put(msg.id, _toMap(msg));
    _notify();
    if (isBanned) throw Exception('Your message was flagged for violating community rules.');
    return msg;
  }

  Future<void> removeMessage(String id) async {
    final raw = HiveService.community.get(id);
    if (raw == null) return;
    final updated = Map<String, dynamic>.from(raw as Map);
    updated['status'] = MessageStatus.removed.index;
    await HiveService.community.put(id, updated);
    _notify();
  }

  Future<void> editMessage(String id, String newText) async {
    final raw = HiveService.community.get(id);
    if (raw == null) return;
    final isBanned = containsBannedContent(newText);
    final updated = Map<String, dynamic>.from(raw as Map);
    updated['text'] = newText;
    updated['editedAt'] = DateTime.now().toIso8601String();
    if (isBanned) {
      updated['status'] = MessageStatus.flagged.index;
    }
    await HiveService.community.put(id, updated);
    _notify();
    if (isBanned) throw Exception('Your edited message was flagged for violating community rules.');
  }

  Future<void> togglePin(String id) async {
    final raw = HiveService.community.get(id);
    if (raw == null) return;
    final updated = Map<String, dynamic>.from(raw as Map);
    updated['isPinned'] = !(updated['isPinned'] as bool? ?? false);
    await HiveService.community.put(id, updated);
    _notify();
  }

  Future<void> addReaction(String messageId, String emoji, String userId) async {
    final raw = HiveService.community.get(messageId);
    if (raw == null) return;
    final updated = Map<String, dynamic>.from(raw as Map);
    final reactions = Map<String, String>.from(updated['reactions'] as Map? ?? {});
    reactions[emoji] = userId;
    updated['reactions'] = reactions;
    await HiveService.community.put(messageId, updated);
    _notify();
  }

  Future<void> removeReaction(String messageId, String emoji) async {
    final raw = HiveService.community.get(messageId);
    if (raw == null) return;
    final updated = Map<String, dynamic>.from(raw as Map);
    final reactions = Map<String, String>.from(updated['reactions'] as Map? ?? {});
    reactions.remove(emoji);
    updated['reactions'] = reactions;
    await HiveService.community.put(messageId, updated);
    _notify();
  }

  void dispose() => _controller.close();
}
