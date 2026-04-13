import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/community_message.dart';

const _bannedPatterns = [
  'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'damn', 'crap',
  'kafir', 'infidel', 'jihad', 'terrorist', 'nazi', 'nigger', 'faggot',
  'retard', 'idiot', 'stupid', 'loser',
];

class FirestoreCommunityRepository {
  static const _uuid = Uuid();
  final _col = FirebaseFirestore.instance.collection('community');

  CommunityMessage _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CommunityMessage(
      id: doc.id,
      senderId: d['senderId'] as String,
      senderName: d['senderName'] as String,
      senderRole: d['senderRole'] as String,
      text: d['text'] as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values[d['status'] as int? ?? 0],
      isAnonymous: d['isAnonymous'] as bool? ?? false,
      senderAvatar: d['senderAvatar'] as String?,
      replyToId: d['replyToId'] as String?,
      replyToText: d['replyToText'] as String?,
      replyToSender: d['replyToSender'] as String?,
      isPinned: d['isPinned'] as bool? ?? false,
      editedAt: (d['editedAt'] as Timestamp?)?.toDate(),
      reactions: d['reactions'] != null
          ? Map<String, String>.from(d['reactions'] as Map)
          : {},
    );
  }

  bool containsBannedContent(String text) {
    final lower = text.toLowerCase();
    return _bannedPatterns.any((p) => lower.contains(p));
  }

  Stream<List<CommunityMessage>> watch() {
    return _col
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
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
    final id = _uuid.v4();
    await _col.doc(id).set({
      'senderId': senderId,
      'senderName': isAnonymous ? 'Anonymous' : senderName,
      'senderRole': senderRole,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'status': isBanned ? MessageStatus.flagged.index : MessageStatus.visible.index,
      'isAnonymous': isAnonymous,
      'senderAvatar': isAnonymous ? null : senderAvatar,
      'replyToId': replyTo?.id,
      'replyToText': replyTo?.text,
      'replyToSender': replyTo?.senderName,
      'isPinned': false,
      'editedAt': null,
      'reactions': {},
    });
    if (isBanned) throw Exception('Your message was flagged for violating community rules.');
    final doc = await _col.doc(id).get();
    return _fromDoc(doc);
  }

  Future<void> removeMessage(String id) async {
    await _col.doc(id).update({'status': MessageStatus.removed.index});
  }

  Future<void> editMessage(String id, String newText) async {
    final isBanned = containsBannedContent(newText);
    await _col.doc(id).update({
      'text': newText,
      'editedAt': FieldValue.serverTimestamp(),
      if (isBanned) 'status': MessageStatus.flagged.index,
    });
    if (isBanned) throw Exception('Your edited message was flagged for violating community rules.');
  }

  Future<void> togglePin(String id) async {
    final doc = await _col.doc(id).get();
    final current = (doc.data() as Map<String, dynamic>)['isPinned'] as bool? ?? false;
    await _col.doc(id).update({'isPinned': !current});
  }

  Future<void> addReaction(String messageId, String emoji, String userId) async {
    await _col.doc(messageId).update({'reactions.$emoji': userId});
  }

  Future<void> removeReaction(String messageId, String emoji) async {
    await _col.doc(messageId).update({
      'reactions.$emoji': FieldValue.delete(),
    });
  }
}
