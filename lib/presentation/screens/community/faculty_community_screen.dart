import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/community_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';

// Faculty Community Screen - same UI as student but with moderation powers

class FacultyCommunityScreen extends ConsumerStatefulWidget {
  /// When [isEmbedded] is true (used inside the faculty dashboard tab),
  /// the AppBar back button is hidden since navigation is handled by the tab bar.
  final bool isEmbedded;
  const FacultyCommunityScreen({super.key, this.isEmbedded = false});
  @override
  ConsumerState<FacultyCommunityScreen> createState() => _FacultyCommunityScreenState();
}

class _FacultyCommunityScreenState extends ConsumerState<FacultyCommunityScreen> {
  final _ctrl       = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showScrollFab = false;
  int  _charCount = 0;
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showFlaggedOnly = false;
  List<String> _mentionSuggestions = [];
  int _mentionStart = -1;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _ctrl.addListener(_onTextChanged);
    if (!widget.isEmbedded) {
      NotificationService.isCommunityOpen = true;
      NotificationService.cancelAll();
    }
  }

  void _onTextChanged() {
    setState(() => _charCount = _ctrl.text.length);
    _checkMention();
  }

  void _checkMention() {
    final text   = _ctrl.text;
    final cursor = _ctrl.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return;
    final before = text.substring(0, cursor);
    final atIdx  = before.lastIndexOf('@');
    if (atIdx == -1) {
      if (_mentionSuggestions.isNotEmpty) setState(() { _mentionSuggestions = []; _mentionStart = -1; });
      return;
    }
    if (atIdx > 0 && before[atIdx - 1] != ' ') {
      if (_mentionSuggestions.isNotEmpty) setState(() { _mentionSuggestions = []; _mentionStart = -1; });
      return;
    }
    final query = before.substring(atIdx + 1).toLowerCase();
    if (query.contains(' ')) {
      if (_mentionSuggestions.isNotEmpty) setState(() { _mentionSuggestions = []; _mentionStart = -1; });
      return;
    }
    final msgs = ref.read(communityMessagesProvider).value ?? [];
    final names = msgs
        .where((m) => m.status != MessageStatus.removed && !m.isAnonymous)
        .map((m) => m.senderName)
        .toSet()
        .where((n) => n.toLowerCase().contains(query))
        .take(5)
        .toList();
    setState(() { _mentionSuggestions = names; _mentionStart = atIdx; });
  }

  void _insertMention(String name) {
    final text   = _ctrl.text;
    final cursor = _ctrl.selection.baseOffset;
    final before = text.substring(0, _mentionStart);
    final after  = cursor < text.length ? text.substring(cursor) : '';
    final newText = '$before@$name $after';
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: before.length + name.length + 2),
    );
    setState(() { _mentionSuggestions = []; _mentionStart = -1; });
  }

  void _onScroll() {
    final show = _scrollCtrl.hasClients &&
        _scrollCtrl.position.maxScrollExtent - _scrollCtrl.offset > 200;
    if (show != _showScrollFab) setState(() => _showScrollFab = show);
  }

  @override
  void dispose() {
    if (!widget.isEmbedded) NotificationService.isCommunityOpen = false;
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || text.length > 500) return;
    final user    = ref.read(authNotifierProvider).user;
    final replyTo = ref.read(replyToProvider);
    if (user == null) return;
    _ctrl.clear();
    ref.read(replyToProvider.notifier).state = null;
    final ok = await ref.read(communityNotifierProvider.notifier).send(
      senderId:   user.id,
      senderName: user.name,
      senderRole: user.role.name,
      text:       text,
      replyTo:    replyTo,
    );
    if (!ok && mounted) {
      final err = ref.read(communityNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err?.toString().replaceAll('Exception: ', '') ?? 'Message flagged.'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ));
    } else {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user      = ref.watch(authNotifierProvider).user;
    final msgsAsync = ref.watch(communityMessagesProvider);
    final blocked   = ref.watch(blockedUserIdsProvider).value ?? [];
    final totalVisible = msgsAsync.value
        ?.where((m) => m.status != MessageStatus.removed && !blocked.contains(m.senderId))
        .length ?? 0;
    final flaggedCount = msgsAsync.value
        ?.where((m) => m.status == MessageStatus.flagged)
        .length ?? 0;

    // The body content — shared between embedded and standalone modes
    final content = Column(children: [
      _FacultyModerationBanner(),
      _PinnedBanner(),
      Expanded(child: _FacultyMessageList(
        scrollCtrl: _scrollCtrl,
        currentUserId: user?.id ?? '',
        searchQuery: _searchQuery,
        showFlaggedOnly: _showFlaggedOnly,
        onScrollReady: _scrollToBottom,
      )),
      if (_mentionSuggestions.isNotEmpty)
        _MentionSuggestions(names: _mentionSuggestions, onSelect: _insertMention),
      _ReplyBar(),
      _InputBar(ctrl: _ctrl, charCount: _charCount, onSend: _send),
    ]);

    // When embedded in the dashboard tab, skip the Scaffold/AppBar entirely
    // to avoid nested Scaffold issues (grey screen)
    if (widget.isEmbedded) {
      return SizedBox.expand(
        child: ColoredBox(
        color: AppColors.background,
        child: Column(children: [
          // Mini toolbar row
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(children: [
              const SizedBox(width: 4),
              if (_showSearch)
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search messages…',
                      border: InputBorder.none,
                      isDense: true,
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                )
              else
                Expanded(
                  child: Text('$totalVisible messages · Faculty View',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
              if (flaggedCount > 0)
                Stack(clipBehavior: Clip.none, children: [
                  IconButton(
                    icon: Icon(_showFlaggedOnly ? Icons.flag_rounded : Icons.flag_outlined,
                        size: 18, color: _showFlaggedOnly ? AppColors.error : AppColors.textMuted),
                    onPressed: () => setState(() => _showFlaggedOnly = !_showFlaggedOnly),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Positioned(right: 2, top: 2,
                    child: Container(
                      width: 13, height: 13,
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: Center(child: Text('$flaggedCount',
                          style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700))),
                    )),
                ]),
              IconButton(
                icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded,
                    size: 18, color: AppColors.textSecondary),
                onPressed: () => setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) { _searchQuery = ''; _searchCtrl.clear(); }
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.manage_accounts_outlined, size: 18, color: AppColors.textSecondary),
                onPressed: () => _showMembersSheet(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ]),
          ),
          Expanded(child: content),
        ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search messages…',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              )
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Community Chat'),
                Text('$totalVisible messages · Faculty View',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w400)),
              ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_showSearch) {
              setState(() { _showSearch = false; _searchQuery = ''; _searchCtrl.clear(); });
              return;
            }
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (flaggedCount > 0)
            Stack(clipBehavior: Clip.none, children: [
              IconButton(
                icon: Icon(_showFlaggedOnly ? Icons.flag_rounded : Icons.flag_outlined,
                    size: 20, color: _showFlaggedOnly ? AppColors.error : null),
                onPressed: () => setState(() => _showFlaggedOnly = !_showFlaggedOnly),
              ),
              Positioned(right: 6, top: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: Center(child: Text('$flaggedCount',
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700))),
                )),
            ]),
          IconButton(
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded, size: 20),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) { _searchQuery = ''; _searchCtrl.clear(); }
            }),
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined, size: 20),
            onPressed: () => _showMembersSheet(context),
          ),
        ],
      ),
      floatingActionButton: _showScrollFab
          ? FloatingActionButton.small(
              onPressed: _scrollToBottom,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
            )
          : null,
      body: content,
    );
  }

  void _showMembersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _MembersManagementSheet(),
    );
  }
}

// Faculty Moderation Banner
class _FacultyModerationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Row(children: [
        Icon(Icons.admin_panel_settings_outlined, size: 14, color: AppColors.primary),
        SizedBox(width: 8),
        Expanded(child: Text(
          'Faculty view — you can delete, pin, block or restrict any student.',
          style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
        )),
      ]),
    );
  }
}

// Pinned Banner
class _PinnedBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msgs = ref.watch(communityMessagesProvider).value ?? [];
    final pinned = msgs.where((m) => m.isPinned && m.status != MessageStatus.removed).toList();
    if (pinned.isEmpty) return const SizedBox.shrink();
    final latest = pinned.last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AppColors.primaryLight,
      child: Row(children: [
        const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(
          latest.text,
          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        )),
      ]),
    );
  }
}

// Faculty Message List
class _FacultyMessageList extends ConsumerWidget {
  final ScrollController scrollCtrl;
  final String currentUserId;
  final String searchQuery;
  final bool showFlaggedOnly;
  final VoidCallback onScrollReady;
  const _FacultyMessageList({
    required this.scrollCtrl,
    required this.currentUserId,
    required this.searchQuery,
    required this.showFlaggedOnly,
    required this.onScrollReady,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msgsAsync = ref.watch(communityMessagesProvider);
    final blocked   = ref.watch(blockedUserIdsProvider).value ?? [];

    return msgsAsync.when(
      data: (msgs) {
        var visible = msgs
            .where((m) => m.status != MessageStatus.removed && !blocked.contains(m.senderId))
            .toList();
        if (showFlaggedOnly) {
          visible = visible.where((m) => m.status == MessageStatus.flagged).toList();
        }
        if (searchQuery.isNotEmpty) {
          visible = visible.where((m) =>
              m.text.toLowerCase().contains(searchQuery) ||
              m.senderName.toLowerCase().contains(searchQuery)).toList();
        }
        onScrollReady();
        if (visible.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(showFlaggedOnly ? Icons.flag_outlined : Icons.forum_outlined,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(showFlaggedOnly ? 'No flagged messages' : 'No messages yet',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
          ]));
        }
        return ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: visible.length,
          itemBuilder: (_, i) {
            final msg = visible[i];
            final isMe = msg.senderId == currentUserId;
            final showDate = i == 0 || !_sameDay(visible[i - 1].createdAt, msg.createdAt);
            return Column(children: [
              if (showDate) _DateDivider(msg.createdAt),
              _FacultyMessageBubble(
                msg: msg,
                isMe: isMe,
                searchQuery: searchQuery,
                onReply: () => ref.read(replyToProvider.notifier).state = msg,
              ),
            ]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider(this.date);
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      label = 'Today';
    } else {
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      label = '${months[date.month - 1]} ${date.day}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ),
        const Expanded(child: Divider()),
      ]),
    );
  }
}

class _FacultyMessageBubble extends ConsumerWidget {
  final CommunityMessage msg;
  final bool isMe;
  final String searchQuery;
  final VoidCallback onReply;
  const _FacultyMessageBubble({required this.msg, required this.isMe,
      required this.searchQuery, required this.onReply});

  Color get _roleColor {
    switch (msg.senderRole) {
      case 'admin':   return AppColors.error;
      case 'faculty': return AppColors.primary;
      default:        return AppColors.info;
    }
  }

  String get _roleLabel {
    switch (msg.senderRole) {
      case 'admin':   return 'Admin';
      case 'faculty': return 'Faculty';
      default:        return 'Student';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFlagged = msg.status == MessageStatus.flagged;
    final currentUserId = ref.watch(authNotifierProvider).user?.id ?? '';
    final restricted = ref.watch(restrictedUserIdsProvider).value ?? [];
    final blocked    = ref.watch(blockedUserIdsProvider).value ?? [];
    final isStudentMsg = msg.senderRole == 'student';
    final isBlocked    = blocked.contains(msg.senderId);
    final isRestricted = restricted.contains(msg.senderId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _SenderAvatar(msg: msg, roleColor: _roleColor),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showFacultyActions(context, ref, currentUserId, isStudentMsg, isBlocked, isRestricted),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (msg.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 2, right: 2),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.push_pin, size: 12, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text('Pinned', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning)),
                      ]),
                    ),
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 2),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(msg.senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: _roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(_roleLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _roleColor)),
                        ),
                        if (isRestricted) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                            child: const Text('RESTRICTED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.warning)),
                          ),
                        ],
                      ]),
                    ),
                  if (msg.replyToText != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border(left: BorderSide(color: _roleColor, width: 3)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(msg.replyToSender ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _roleColor)),
                        Text(msg.replyToText!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isFlagged ? AppColors.errorBg : isMe ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      border: isFlagged ? Border.all(color: AppColors.error.withValues(alpha: 0.4))
                          : isMe ? null : Border.all(color: AppColors.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (isFlagged)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.flag_rounded, size: 12, color: AppColors.error),
                            SizedBox(width: 4),
                            Text('Flagged — violates community rules', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      _HighlightText(
                        text: msg.text, query: searchQuery,
                        baseStyle: TextStyle(fontSize: 14, color: isMe && !isFlagged ? Colors.white : AppColors.textPrimary, height: 1.4),
                        highlightColor: AppColors.warning,
                      ),
                    ]),
                  ),
                  if (msg.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(spacing: 4, runSpacing: 4,
                        children: msg.reactions.entries.map((e) {
                          final isMyReaction = e.value == currentUserId;
                          final r = _kFacultyReactions.firstWhere(
                            (r) => r.key == e.key,
                            orElse: () => _kFacultyReactions.first,
                          );
                          return GestureDetector(
                            onTap: () {
                              if (isMyReaction) {
                                ref.read(communityNotifierProvider.notifier).removeReaction(msg.id, e.key);
                              } else {
                                ref.read(communityNotifierProvider.notifier).addReaction(msg.id, e.key, currentUserId);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isMyReaction
                                    ? r.color.withValues(alpha: 0.12)
                                    : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isMyReaction ? r.color : AppColors.border,
                                  width: isMyReaction ? 1.5 : 1,
                                ),
                              ),
                              child: Icon(r.icon, size: 13, color: isMyReaction ? r.color : AppColors.textMuted),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 2, right: 2),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      if (msg.isEdited) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_rounded, size: 9, color: AppColors.textMuted),
                      ],
                    ]),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _showFacultyActions(BuildContext context, WidgetRef ref, String currentUserId,
      bool isStudentMsg, bool isBlocked, bool isRestricted) {
    final facultyId = ref.read(authNotifierProvider).user?.id ?? '';
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _kFacultyReactions.map((r) => GestureDetector(
                onTap: () {
                  ref.read(communityNotifierProvider.notifier).addReaction(msg.id, r.key, currentUserId);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: r.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: r.color.withValues(alpha: 0.2)),
                  ),
                  child: Icon(r.icon, size: 20, color: r.color),
                ),
              )).toList(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.reply_rounded, color: AppColors.primary),
            title: const Text('Reply', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); onReply(); },
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded, color: AppColors.textSecondary),
            title: const Text('Copy text', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Clipboard.setData(ClipboardData(text: msg.text));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied'), duration: Duration(seconds: 2)));
            },
          ),
          ListTile(
            leading: Icon(msg.isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: AppColors.warning),
            title: Text(msg.isPinned ? 'Unpin' : 'Pin', style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); ref.read(communityNotifierProvider.notifier).togglePin(msg.id); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
            title: const Text('Delete message', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); _confirmDelete(context, ref); },
          ),
          if (isStudentMsg && msg.senderId != currentUserId) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(alignment: Alignment.centerLeft, child: Text('Student Moderation',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5))),
            ),
            ListTile(
              leading: Icon(isRestricted ? Icons.lock_open_outlined : Icons.lock_outline_rounded, color: AppColors.warning),
              title: Text(isRestricted ? 'Remove restriction' : 'Restrict student', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(isRestricted ? 'Allow this student to send messages again' : 'Student can read but cannot send messages', style: const TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                if (isRestricted) {
                  ref.read(communityNotifierProvider.notifier).unrestrictUser(msg.senderId);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restriction removed'), backgroundColor: AppColors.success));
                } else {
                  ref.read(communityNotifierProvider.notifier).restrictUser(msg.senderId, facultyId);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student restricted'), backgroundColor: AppColors.warning));
                }
              },
            ),
            ListTile(
              leading: Icon(isBlocked ? Icons.person_add_outlined : Icons.block_rounded, color: AppColors.error),
              title: Text(isBlocked ? 'Unblock student' : 'Block student',
                  style: TextStyle(color: isBlocked ? AppColors.textPrimary : AppColors.error, fontWeight: FontWeight.w600)),
              subtitle: Text(isBlocked ? 'Allow this student back into the chat' : 'Hide all messages and prevent participation', style: const TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                if (isBlocked) {
                  ref.read(communityNotifierProvider.notifier).unblockUser(msg.senderId);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student unblocked'), backgroundColor: AppColors.success));
                } else {
                  _confirmBlock(context, ref, facultyId);
                }
              },
            ),
          ],
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Permanently delete this message? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(context); ref.read(communityNotifierProvider.notifier).deleteMessage(msg.id); },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmBlock(BuildContext context, WidgetRef ref, String facultyId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Block Student'),
        content: Text('Block ${msg.senderName}? Their messages will be hidden and they cannot participate.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(communityNotifierProvider.notifier).blockUser(msg.senderId, facultyId);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${msg.senderName} has been blocked'), backgroundColor: AppColors.error));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}

// Mention Suggestions
class _MentionSuggestions extends StatelessWidget {
  final List<String> names;
  final ValueChanged<String> onSelect;
  const _MentionSuggestions({required this.names, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: names.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => InkWell(
          onTap: () => onSelect(names[i]),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primaryLight,
                child: Text(names[i].isNotEmpty ? names[i][0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              RichText(text: TextSpan(children: [
                const TextSpan(text: '@', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                TextSpan(text: names[i], style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              ])),
            ]),
          ),
        ),
      ),
    );
  }
}

// Sender Avatar
class _SenderAvatar extends StatelessWidget {
  final CommunityMessage msg;
  final Color roleColor;
  const _SenderAvatar({required this.msg, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    if (msg.isAnonymous) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.surfaceElevated,
        child: const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.textMuted),
      );
    }
    if (msg.senderAvatar != null && msg.senderAvatar!.isNotEmpty) {
      try {
        final bytes = base64Decode(msg.senderAvatar!);
        return CircleAvatar(radius: 16, backgroundImage: MemoryImage(bytes));
      } catch (_) {}
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: roleColor.withValues(alpha: 0.12),
      child: Text(msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: roleColor)),
    );
  }
}

// Reply Bar
class _ReplyBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final replyTo = ref.watch(replyToProvider);
    if (replyTo == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primaryLight,
      child: Row(children: [
        Container(width: 3, height: 36, color: AppColors.primary, margin: const EdgeInsets.only(right: 10)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Replying to ${replyTo.senderName}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          Text(replyTo.text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
          onPressed: () => ref.read(replyToProvider.notifier).state = null,
        ),
      ]),
    );
  }
}

// Input Bar
class _InputBar extends ConsumerWidget {
  final TextEditingController ctrl;
  final int charCount;
  final VoidCallback onSend;
  const _InputBar({required this.ctrl, required this.charCount, required this.onSend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(communityNotifierProvider).isLoading;
    final isOverLimit = charCount > 500;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      child: SafeArea(
        top: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write a message…',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: isOverLimit ? AppColors.error : AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: isOverLimit ? AppColors.error : AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: isOverLimit ? AppColors.error : AppColors.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isOverLimit ? AppColors.error : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: (isOverLimit ? AppColors.error : AppColors.primary).withValues(alpha: 0.3),
                  blurRadius: 8, offset: const Offset(0, 3),
                )],
              ),
              child: isLoading
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: isOverLimit ? null : onSend,
                    ),
            ),
          ]),
          if (charCount > 400)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 52),
              child: Text('${500 - charCount} characters remaining',
                  style: TextStyle(fontSize: 11, color: isOverLimit ? AppColors.error : AppColors.textMuted,
                      fontWeight: isOverLimit ? FontWeight.w600 : FontWeight.w400)),
            ),
        ]),
      ),
    );
  }
}

// Highlight Text
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final Color highlightColor;
  const _HighlightText({required this.text, required this.query, required this.baseStyle, required this.highlightColor});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final mentionRegex = RegExp(r'@\w+');
    int start = 0;
    for (final match in mentionRegex.allMatches(text)) {
      if (match.start > start) spans.addAll(_searchSpans(text.substring(start, match.start), baseStyle));
      spans.add(TextSpan(text: match.group(0), style: baseStyle.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)));
      start = match.end;
    }
    if (start < text.length) spans.addAll(_searchSpans(text.substring(start), baseStyle));
    if (spans.isEmpty) return Text(text, style: baseStyle);
    return RichText(text: TextSpan(children: spans));
  }

  List<TextSpan> _searchSpans(String segment, TextStyle style) {
    if (query.isEmpty) return [TextSpan(text: segment, style: style)];
    final spans = <TextSpan>[];
    final lower = segment.toLowerCase();
    int start = 0;
    while (true) {
      final idx = lower.indexOf(query, start);
      if (idx == -1) { spans.add(TextSpan(text: segment.substring(start), style: style)); break; }
      if (idx > start) spans.add(TextSpan(text: segment.substring(start, idx), style: style));
      spans.add(TextSpan(text: segment.substring(idx, idx + query.length),
          style: style.copyWith(backgroundColor: highlightColor.withValues(alpha: 0.35), fontWeight: FontWeight.w700)));
      start = idx + query.length;
    }
    return spans;
  }
}

// Members Management Sheet - shows blocked/restricted users
class _MembersManagementSheet extends ConsumerWidget {
  const _MembersManagementSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked    = ref.watch(blockedUserIdsProvider).value ?? [];
    final restricted = ref.watch(restrictedUserIdsProvider).value ?? [];
    final msgs       = ref.watch(communityMessagesProvider).value ?? [];

    // Build unique user map from messages
    final userMap = <String, String>{};
    for (final m in msgs) {
      if (!m.isAnonymous) userMap[m.senderId] = m.senderName;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Member Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('${blocked.length} blocked · ${restricted.length} restricted',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: (blocked.isEmpty && restricted.isEmpty)
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('No blocked or restricted students', style: TextStyle(color: AppColors.textMuted)),
                ]))
              : ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (blocked.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('Blocked Students', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
                      ),
                      ...blocked.map((uid) => _MemberTile(
                        userId: uid,
                        name: userMap[uid] ?? 'Unknown Student',
                        status: 'Blocked',
                        statusColor: AppColors.error,
                        actionLabel: 'Unblock',
                        onAction: () => ref.read(communityNotifierProvider.notifier).unblockUser(uid),
                      )),
                      const SizedBox(height: 16),
                    ],
                    if (restricted.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('Restricted Students', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning)),
                      ),
                      ...restricted.map((uid) => _MemberTile(
                        userId: uid,
                        name: userMap[uid] ?? 'Unknown Student',
                        status: 'Restricted',
                        statusColor: AppColors.warning,
                        actionLabel: 'Remove restriction',
                        onAction: () => ref.read(communityNotifierProvider.notifier).unrestrictUser(uid),
                      )),
                    ],
                  ],
                ),
        ),
      ]),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String userId, name, status, actionLabel;
  final Color statusColor;
  final VoidCallback onAction;
  const _MemberTile({required this.userId, required this.name, required this.status,
      required this.statusColor, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: statusColor)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ])),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: statusColor),
          child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

// ─── Faculty reaction model (mirrors community_screen.dart) ──────────────────

class _FacultyReaction {
  final String key;
  final IconData icon;
  final Color color;
  const _FacultyReaction(this.key, this.icon, this.color);
}

const _kFacultyReactions = [
  _FacultyReaction('like',      Icons.thumb_up_rounded,          AppColors.primary),
  _FacultyReaction('love',      Icons.favorite_rounded,           AppColors.error),
  _FacultyReaction('insightful',Icons.lightbulb_rounded,          AppColors.warning),
  _FacultyReaction('support',   Icons.volunteer_activism_rounded, Color(0xFF7C3AED)),
  _FacultyReaction('curious',   Icons.help_rounded,               AppColors.info),
  _FacultyReaction('celebrate', Icons.celebration_rounded,        AppColors.success),
];
