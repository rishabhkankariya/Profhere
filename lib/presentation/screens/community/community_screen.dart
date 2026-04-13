import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/community_message.dart';
import '../../../domain/entities/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/prefs_provider.dart';
import '../../navigation/app_router.dart';
import '../../../data/datasources/local/hive_service.dart';

// ─── Persist rules acceptance ─────────────────────────────────────────────────
bool _hasAcceptedRules() =>
    HiveService.settings.get('community_rules_accepted') == true;

Future<void> _persistRulesAccepted() =>
    HiveService.settings.put('community_rules_accepted', true);

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});
  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _ctrl       = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _rulesAccepted = false;
  bool _showScrollFab = false;
  int  _charCount = 0;
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // @mention state
  List<String> _mentionSuggestions = [];
  int _mentionStart = -1;

  @override
  void initState() {
    super.initState();
    _rulesAccepted = _hasAcceptedRules();
    _scrollCtrl.addListener(_onScroll);
    _ctrl.addListener(_onTextChanged);
    // Suppress notifications while community is open
    NotificationService.isCommunityOpen = true;
    NotificationService.cancelAll();
  }

  void _onTextChanged() {
    setState(() => _charCount = _ctrl.text.length);
    _checkMention();
  }

  /// Detect @mention trigger and build suggestion list from all message senders
  void _checkMention() {
    final text   = _ctrl.text;
    final cursor = _ctrl.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return;

    // Find the last @ before cursor
    final before = text.substring(0, cursor);
    final atIdx  = before.lastIndexOf('@');

    if (atIdx == -1) {
      if (_mentionSuggestions.isNotEmpty) setState(() { _mentionSuggestions = []; _mentionStart = -1; });
      return;
    }

    // Only trigger if @ is at start or preceded by space
    if (atIdx > 0 && before[atIdx - 1] != ' ') {
      if (_mentionSuggestions.isNotEmpty) setState(() { _mentionSuggestions = []; _mentionStart = -1; });
      return;
    }

    final query = before.substring(atIdx + 1).toLowerCase();
    // Don't show if query has a space (mention already completed)
    if (query.contains(' ')) {
      if (_mentionSuggestions.isNotEmpty) setState(() { _mentionSuggestions = []; _mentionStart = -1; });
      return;
    }

    // Build unique sender names from messages
    final msgs = ref.read(communityMessagesProvider).value ?? [];
    final names = msgs
        .where((m) => m.status != MessageStatus.removed && !m.isAnonymous)
        .map((m) => m.senderName)
        .toSet()
        .where((n) => n.toLowerCase().contains(query))
        .take(5)
        .toList();

    setState(() {
      _mentionSuggestions = names;
      _mentionStart = atIdx;
    });
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
    // Re-enable notifications when leaving community
    NotificationService.isCommunityOpen = false;
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
    final prefs   = ref.read(userPrefsProvider);
    if (user == null) return;

    _ctrl.clear();
    ref.read(replyToProvider.notifier).state = null;

    final ok = await ref.read(communityNotifierProvider.notifier).send(
      senderId:     user.id,
      senderName:   user.name,
      senderRole:   user.role.name,
      text:         text,
      isAnonymous:  prefs.communityMode == CommunityMode.anonymous,
      senderAvatar: prefs.communityMode == CommunityMode.private ? prefs.avatarBase64 : null,
      replyTo:      replyTo,
    );

    if (!ok && mounted) {
      final err = ref.read(communityNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err?.toString().replaceAll('Exception: ', '') ??
            'Message flagged for violating community rules.'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ));
    } else {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user    = ref.watch(authNotifierProvider).user;
    final isAdmin = user?.role == UserRole.admin;
    final msgsAsync = ref.watch(communityMessagesProvider);
    final totalVisible = msgsAsync.value?.where((m) => m.status != MessageStatus.removed).length ?? 0;

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
                Text('$totalVisible messages',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w400)),
              ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_showSearch) {
              setState(() { _showSearch = false; _searchQuery = ''; _searchCtrl.clear(); });
              return;
            }
            final router = GoRouter.of(context);
            if (router.canPop()) { router.pop(); } else { context.go(AppRoutes.faculties); }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded, size: 20),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) { _searchQuery = ''; _searchCtrl.clear(); }
            }),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            onPressed: () => _showRules(context),
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
      body: !_rulesAccepted
          ? _RulesGate(onAccept: () async {
              await _persistRulesAccepted();
              setState(() => _rulesAccepted = true);
            })
          : Column(children: [
              // Pinned announcement banner
              _PinnedBanner(),
              Expanded(child: _MessageList(
                scrollCtrl: _scrollCtrl,
                currentUserId: user?.id ?? '',
                isAdmin: isAdmin,
                searchQuery: _searchQuery,
                onScrollReady: _scrollToBottom,
              )),
              // @mention suggestions
              if (_mentionSuggestions.isNotEmpty)
                _MentionSuggestions(
                  names: _mentionSuggestions,
                  onSelect: _insertMention,
                ),
              _ReplyBar(),
              _InputBar(ctrl: _ctrl, charCount: _charCount, onSend: _send),
            ]),
    );
  }

  void _showRules(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RulesSheet(),
    );
  }
}

// ─── Pinned Banner ────────────────────────────────────────────────────────────

class _PinnedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AppColors.primaryLight,
      child: const Row(children: [
        Icon(Icons.push_pin_rounded, size: 14, color: AppColors.primary),
        SizedBox(width: 8),
        Expanded(child: Text(
          'Welcome! Share ideas, ask questions, and collaborate respectfully.',
          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
        )),
      ]),
    );
  }
}

// ─── Rules Gate ───────────────────────────────────────────────────────────────

class _RulesGate extends StatelessWidget {
  final VoidCallback onAccept;
  const _RulesGate({required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 16),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.forum_rounded, color: Colors.white, size: 32),
        ).also((w) => Center(child: w)),
        const SizedBox(height: 20),
        const Text('Community Chat', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('A safe space for students and faculty to share ideas.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
        const SizedBox(height: 28),
        _RuleItem(icon: Icons.favorite_outline_rounded, color: AppColors.success,
            title: 'Be Kind & Respectful',
            body: 'Maintain a welcoming environment. Harassment or bullying is not permitted.'),
        _RuleItem(icon: Icons.block_rounded, color: AppColors.error,
            title: 'No Hate Speech',
            body: 'Zero tolerance for discriminatory remarks regarding race, religion, gender, or orientation.'),
        _RuleItem(icon: Icons.topic_outlined, color: AppColors.primary,
            title: 'Stay On-Topic',
            body: 'Keep conversations relevant. Move unrelated topics to private messages.'),
        _RuleItem(icon: Icons.campaign_outlined, color: AppColors.warning,
            title: 'No Spam or Advertising',
            body: 'Prohibit spam, excessive messaging, or unauthorized promotions.'),
        _RuleItem(icon: Icons.lock_outline_rounded, color: AppColors.info,
            title: 'Respect Privacy',
            body: 'Do not share personal information about yourself or others without consent.'),
        _RuleItem(icon: Icons.shield_outlined, color: AppColors.meeting,
            title: 'Safe Environment',
            body: 'Avoid sharing graphic violence, illegal content, or adult material.'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.errorBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text(
              'Abusive language, religious hate speech, or slurs will be automatically flagged and removed. Repeated violations result in removal.',
              style: TextStyle(fontSize: 12, color: AppColors.error, height: 1.5),
            )),
          ]),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onAccept,
          child: const Text('I Understand — Enter Chat'),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

extension _WidgetAlso on Widget {
  Widget also(Widget Function(Widget) fn) => Center(child: this);
}

class _RuleItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, body;
  const _RuleItem({required this.icon, required this.color, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4)),
        ])),
      ]),
    );
  }
}

// ─── Rules Sheet ──────────────────────────────────────────────────────────────

class _RulesSheet extends StatelessWidget {
  const _RulesSheet();
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Community Rules', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ...const [
            _RuleItem(icon: Icons.favorite_outline_rounded, color: AppColors.success,  title: 'Be Kind & Respectful',    body: 'Maintain a welcoming environment. Harassment, bullying, or disrespectful behavior is not permitted.'),
            _RuleItem(icon: Icons.block_rounded,            color: AppColors.error,    title: 'No Hate Speech',          body: 'Zero tolerance for discriminatory remarks regarding race, religion, gender, or sexual orientation.'),
            _RuleItem(icon: Icons.topic_outlined,           color: AppColors.primary,  title: 'Stay On-Topic',           body: 'Ensure conversations are relevant. Move unrelated topics to private messages.'),
            _RuleItem(icon: Icons.campaign_outlined,        color: AppColors.warning,  title: 'No Spam or Advertising',  body: 'Prohibit spam, excessive messaging, or unauthorized promotions.'),
            _RuleItem(icon: Icons.lock_outline_rounded,     color: AppColors.info,     title: 'Respect Privacy',         body: 'Do not share personal information about yourself or others without consent.'),
            _RuleItem(icon: Icons.shield_outlined,          color: AppColors.meeting,  title: 'Safe Environment',        body: 'Avoid sharing graphic violence, illegal content, or adult material.'),
            _RuleItem(icon: Icons.handshake_outlined,       color: AppColors.success,  title: 'Conflict Resolution',     body: 'Resolve disagreements privately rather than making scenes in public threads.'),
          ],        ]),
      ),
    );
  }
}

// ─── Message List ─────────────────────────────────────────────────────────────

class _MessageList extends ConsumerWidget {
  final ScrollController scrollCtrl;
  final String currentUserId;
  final bool isAdmin;
  final String searchQuery;
  final VoidCallback onScrollReady;
  const _MessageList({required this.scrollCtrl, required this.currentUserId,
      required this.isAdmin, required this.searchQuery, required this.onScrollReady});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msgsAsync = ref.watch(communityMessagesProvider);

    return msgsAsync.when(
      data: (msgs) {
        var visible = msgs.where((m) => m.status != MessageStatus.removed).toList();
        // Apply search filter
        if (searchQuery.isNotEmpty) {
          visible = visible.where((m) =>
              m.text.toLowerCase().contains(searchQuery) ||
              m.senderName.toLowerCase().contains(searchQuery)).toList();
        }
        onScrollReady();
        if (visible.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.forum_outlined,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(searchQuery.isNotEmpty ? 'No messages match "$searchQuery"' : 'No messages yet',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
            if (searchQuery.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Be the first to start the conversation!',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
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
              _MessageBubble(
                msg: msg,
                isMe: isMe,
                isAdmin: isAdmin,
                searchQuery: searchQuery,
                onReply: () => ref.read(replyToProvider.notifier).state = msg,
                onRemove: (isAdmin || isMe)
                    ? () => ref.read(communityNotifierProvider.notifier).remove(msg.id)
                    : null,
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

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends ConsumerWidget {
  final CommunityMessage msg;
  final bool isMe;
  final bool isAdmin;
  final String searchQuery;
  final VoidCallback onReply;
  final VoidCallback? onRemove;
  const _MessageBubble({required this.msg, required this.isMe, required this.isAdmin,
      required this.searchQuery, required this.onReply, this.onRemove});

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
              onLongPress: () => _showActions(context, ref, currentUserId),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Pinned indicator
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
                        Text(msg.senderName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(_roleLabel,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _roleColor)),
                        ),
                      ]),
                    ),
                  // Reply preview
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
                        Text(msg.replyToText!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  // Bubble
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isFlagged
                          ? AppColors.errorBg
                          : isMe
                              ? AppColors.primary
                              : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      border: isFlagged
                          ? Border.all(color: AppColors.error.withValues(alpha: 0.4))
                          : isMe
                              ? null
                              : Border.all(color: AppColors.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (isFlagged)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.flag_rounded, size: 12, color: AppColors.error),
                            SizedBox(width: 4),
                            Text('Flagged — violates community rules',
                                style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      // Highlight search matches
                      _HighlightText(
                        text: msg.text,
                        query: searchQuery,
                        baseStyle: TextStyle(
                          fontSize: 14,
                          color: isMe && !isFlagged ? Colors.white : AppColors.textPrimary,
                          height: 1.4,
                        ),
                        highlightColor: AppColors.warning,
                      ),
                    ]),
                  ),
                  // Reactions
                  if (msg.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: msg.reactions.entries.map((e) {
                          final isMyReaction = e.value == currentUserId;
                          return GestureDetector(
                            onTap: () {
                              if (isMyReaction) {
                                ref.read(communityNotifierProvider.notifier).removeReaction(msg.id, e.key);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isMyReaction ? AppColors.primaryLight : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isMyReaction ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Text(e.key, style: const TextStyle(fontSize: 16)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  // Timestamp and edited indicator
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 2, right: 2),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                      if (msg.isEdited) ...[
                        const SizedBox(width: 4),
                        const Text('• edited', style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
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

  void _showActions(BuildContext context, WidgetRef ref, String currentUserId) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Emoji reactions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              '👍', '❤️', '😂', '😮', '😢', '🙏'
            ].map((emoji) => GestureDetector(
              onTap: () {
                ref.read(communityNotifierProvider.notifier).addReaction(msg.id, emoji, currentUserId);
                Navigator.pop(context);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
              ),
            )).toList()),
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Message copied'),
                duration: Duration(seconds: 2),
              ));
            },
          ),
          if (isMe)
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.info),
              title: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, ref);
              },
            ),
          if (isAdmin)
            ListTile(
              leading: Icon(msg.isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: AppColors.warning),
              title: Text(msg.isPinned ? 'Unpin' : 'Pin', style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                ref.read(communityNotifierProvider.notifier).togglePin(msg.id);
              },
            ),
          if (onRemove != null)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(context); onRemove!(); },
            ),
        ]),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: msg.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Edit your message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              final ok = await ref.read(communityNotifierProvider.notifier).edit(msg.id, ctrl.text.trim());
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Edited message flagged — violates community rules'),
                  backgroundColor: AppColors.error,
                ));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─── Mention Suggestions ─────────────────────────────────────────────────────

class _MentionSuggestions extends StatelessWidget {
  final List<String> names;
  final ValueChanged<String> onSelect;
  const _MentionSuggestions({required this.names, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
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
                child: Text(
                  names[i].isNotEmpty ? names[i][0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
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

// ─── Sender Avatar ────────────────────────────────────────────────────────────

class _SenderAvatar extends StatelessWidget {
  final CommunityMessage msg;
  final Color roleColor;
  const _SenderAvatar({required this.msg, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    // Anonymous → people icon
    if (msg.isAnonymous) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.surfaceElevated,
        child: const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.textMuted),
      );
    }

    // Private with photo → show photo
    if (msg.senderAvatar != null && msg.senderAvatar!.isNotEmpty) {
      try {
        final bytes = base64Decode(msg.senderAvatar!);
        return CircleAvatar(radius: 16, backgroundImage: MemoryImage(bytes));
      } catch (_) {}
    }

    // Public / fallback → initials
    return CircleAvatar(
      radius: 16,
      backgroundColor: roleColor.withValues(alpha: 0.12),
      child: Text(
        msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: roleColor),
      ),
    );
  }
}

// ─── Reply Bar ────────────────────────────────────────────────────────────────

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

// ─── Input Bar ────────────────────────────────────────────────────────────────

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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
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
                  hintText: 'Share an idea or ask a question…',
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
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: isOverLimit ? null : onSend,
                    ),
            ),
          ]),
          // Character counter — only show when approaching limit
          if (charCount > 400)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 52),
              child: Text(
                '${500 - charCount} characters remaining',
                style: TextStyle(
                  fontSize: 11,
                  color: isOverLimit ? AppColors.error : AppColors.textMuted,
                  fontWeight: isOverLimit ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

// ─── Highlight Text ───────────────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final Color highlightColor;
  const _HighlightText({required this.text, required this.query, required this.baseStyle, required this.highlightColor});

  @override
  Widget build(BuildContext context) {
    // Build spans: highlight @mentions in primary color + search query in yellow
    final spans = <TextSpan>[];
    final mentionRegex = RegExp(r'@\w+');
    int start = 0;

    // First pass: split by @mentions
    for (final match in mentionRegex.allMatches(text)) {
      if (match.start > start) {
        spans.addAll(_searchSpans(text.substring(start, match.start), baseStyle));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: baseStyle.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = match.end;
    }
    if (start < text.length) {
      spans.addAll(_searchSpans(text.substring(start), baseStyle));
    }

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
