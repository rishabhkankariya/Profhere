import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';

// ─── Events Screen ────────────────────────────────────────────────────────────

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});
  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  EventCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final user        = ref.watch(authNotifierProvider).user;
    final eventsAsync = ref.watch(eventsProvider);

    // CR students and admin can post. Faculty can only view.
    final canPost = user != null &&
        (user.role == UserRole.admin ||
            (user.role == UserRole.student && user.isCR));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Events')),
      body: Column(children: [
        // Category filter chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _FilterChip(
                  label: 'All',
                  active: _filter == null,
                  onTap: () => setState(() => _filter = null)),
              ...EventCategory.values.map((c) => _FilterChip(
                    label: _catLabel(c),
                    active: _filter == c,
                    onTap: () =>
                        setState(() => _filter = _filter == c ? null : c),
                  )),
            ],
          ),
        ),

        Expanded(
          child: eventsAsync.when(
            data: (all) {
              final list = _filter == null
                  ? all
                  : all.where((e) => e.category == _filter).toList();

              if (list.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.event_outlined,
                          color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(height: 16),
                    const Text('No events yet',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    const Text('Events posted by CR appear here',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    if (canPost) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _showPostSheet(context, user),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Post Event'),
                      ),
                    ],
                  ]),
                );
              }

              final now      = DateTime.now();
              final upcoming = list.where((e) => e.eventDate.isAfter(now)).toList();
              final past     = list.where((e) => !e.eventDate.isAfter(now)).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  if (upcoming.isNotEmpty) ...[
                    _SectionHeader(title: 'Upcoming', count: upcoming.length),
                    ...upcoming.map((e) => _EventCard(
                          event: e,
                          currentUser: user,
                          onEdit: _canEdit(user, e) && user != null
                              ? () => _showEditSheet(context, user, e)
                              : null,
                          onDelete: _canDelete(user, e)
                              ? () => _confirmDelete(context, ref, e)
                              : null,
                        )),
                  ],
                  if (past.isNotEmpty) ...[
                    _SectionHeader(title: 'Past Events', count: past.length),
                    ...past.map((e) => _EventCard(
                          event: e,
                          currentUser: user,
                          isPast: true,
                          onEdit: _canEdit(user, e) && user != null
                              ? () => _showEditSheet(context, user, e)
                              : null,
                          onDelete: _canDelete(user, e)
                              ? () => _confirmDelete(context, ref, e)
                              : null,
                        )),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
      ]),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: () => _showPostSheet(context, user),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Post Event',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  // CR can edit/delete their own events. Admin can delete any.
  bool _canEdit(User? user, CollegeEvent e) =>
      user != null && user.id == e.authorId;

  bool _canDelete(User? user, CollegeEvent e) =>
      user != null &&
      (user.role == UserRole.admin || user.id == e.authorId);

  void _showPostSheet(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PostEventSheet(user: user),
    );
  }

  void _showEditSheet(BuildContext context, User user, CollegeEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PostEventSheet(user: user, existing: event),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CollegeEvent e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Remove "${e.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(eventNotifierProvider.notifier).delete(e.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _catLabel(EventCategory c) => switch (c) {
        EventCategory.academic => 'Academic',
        EventCategory.cultural => 'Cultural',
        EventCategory.sports   => 'Sports',
        EventCategory.workshop => 'Workshop',
        EventCategory.seminar  => 'Seminar',
        EventCategory.other    => 'Other',
      };
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final CollegeEvent event;
  final User? currentUser;
  final bool isPast;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _EventCard({
    required this.event,
    this.currentUser,
    this.isPast = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final catColors = [
      AppColors.primary, AppColors.meeting, AppColors.success,
      AppColors.warning, AppColors.info,    AppColors.textMuted,
    ];
    final color = catColors[event.category.index];
    final hasActions = onEdit != null || onDelete != null;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPast ? AppColors.border : color.withValues(alpha: 0.2),
            width: isPast ? 1 : 1.5,
          ),
          boxShadow: isPast
              ? null
              : [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image / placeholder header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            child: _EventImage(
              imageUrl: event.imageUrl,
              color: color,
              isPast: isPast,
              category: event.category,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Category + date + actions row
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPast ? AppColors.surfaceElevated : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_catLabel(event.category),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isPast ? AppColors.textMuted : color)),
                ),
                const Spacer(),
                Icon(Icons.calendar_today_rounded,
                    size: 11,
                    color: isPast ? AppColors.textMuted : AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(_fmtDate(event.eventDate),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPast ? AppColors.textMuted : AppColors.textSecondary)),
                // CR edit/delete actions — only for the author
                if (hasActions) ...[
                  const SizedBox(width: 10),
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                      ),
                    ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.error),
                      ),
                    ),
                  ],
                ],
              ]),
              const SizedBox(height: 10),

              // Title
              Text(event.title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isPast ? AppColors.textMuted : AppColors.textPrimary)),
              const SizedBox(height: 6),

              // Bio preview
              Text(event.description,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary, height: 1.45),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),

              // Author + read more
              Row(children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Text(
                    event.authorName.isNotEmpty ? event.authorName[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(event.authorName,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis),
                ),
                const Row(children: [
                  Text('Read more',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                ]),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EventDetailSheet(event: event),
    );
  }

  String _catLabel(EventCategory c) => switch (c) {
        EventCategory.academic => 'Academic',
        EventCategory.cultural => 'Cultural',
        EventCategory.sports   => 'Sports',
        EventCategory.workshop => 'Workshop',
        EventCategory.seminar  => 'Seminar',
        EventCategory.other    => 'Other',
      };

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ─── Event image / placeholder ────────────────────────────────────────────────

class _EventImage extends StatelessWidget {
  final String? imageUrl;
  final Color color;
  final bool isPast;
  final EventCategory category;
  const _EventImage({this.imageUrl, required this.color, required this.isPast, required this.category});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      try {
        return SizedBox(
          height: 160,
          width: double.infinity,
          child: Image.memory(
            base64Decode(imageUrl!),
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        );
      } catch (_) {}
    }

    return _placeholder();
  }

  Widget _placeholder() {
    final catIcons = [
      Icons.school_rounded, Icons.theater_comedy_rounded,
      Icons.sports_soccer_rounded, Icons.build_rounded,
      Icons.mic_rounded, Icons.event_rounded,
    ];
    // Fixed 160px height — same as image banner so card size is always consistent
    return Container(
      height: 160, width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPast
              ? [AppColors.surfaceElevated, AppColors.surfaceHigh]
              : [color.withValues(alpha: 0.15), color.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(catIcons[category.index], size: 48,
            color: isPast
                ? AppColors.textMuted.withValues(alpha: 0.4)
                : color.withValues(alpha: 0.4)),
      ),
    );
  }
}

// ─── Event detail sheet (read-only for faculty/students) ─────────────────────

class _EventDetailSheet extends StatelessWidget {
  final CollegeEvent event;
  const _EventDetailSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    final catColors = [
      AppColors.primary, AppColors.meeting, AppColors.success,
      AppColors.warning, AppColors.info,    AppColors.textMuted,
    ];
    final color = catColors[event.category.index];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Column(children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        ),
        Expanded(
          child: ListView(
            controller: ctrl,
            padding: EdgeInsets.zero,
            children: [
              _EventImage(imageUrl: event.imageUrl, color: color, isPast: event.isPast, category: event.category),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(_catLabel(event.category),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(_fmtDate(event.eventDate),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 14),
                  Text(event.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary, letterSpacing: -0.4)),
                  const SizedBox(height: 14),
                  Text(event.description,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                  const SizedBox(height: 20),
                  // Author card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Text(event.authorName.isNotEmpty ? event.authorName[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(event.authorName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text(
                          event.authorRole == 'student_cr' ? 'Class Representative'
                              : event.authorRole == 'faculty' ? 'Faculty' : 'Admin',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  String _catLabel(EventCategory c) => switch (c) {
        EventCategory.academic => 'Academic',
        EventCategory.cultural => 'Cultural',
        EventCategory.sports   => 'Sports',
        EventCategory.workshop => 'Workshop',
        EventCategory.seminar  => 'Seminar',
        EventCategory.other    => 'Other',
      };

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ─── Post / Edit Event Sheet ──────────────────────────────────────────────────
// CR posts directly — no approval needed.
// Editing pre-fills all fields from the existing event.

class _PostEventSheet extends ConsumerStatefulWidget {
  final User user;
  final CollegeEvent? existing; // null = new post, non-null = edit
  const _PostEventSheet({required this.user, this.existing});
  @override
  ConsumerState<_PostEventSheet> createState() => _PostEventSheetState();
}

class _PostEventSheetState extends ConsumerState<_PostEventSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bioCtrl;
  late EventCategory _category;
  late DateTime      _eventDate;
  String?            _imageBase64;
  bool               _loading = false;

  static const _bioHint =
      'Tell everyone about this event. Include:\n'
      '  What is it about?\n'
      '  When and where exactly?\n'
      '  Who should attend?\n'
      '  Any registration or contact details?';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl  = TextEditingController(text: e?.title ?? '');
    _bioCtrl    = TextEditingController(text: e?.description ?? '');
    _category   = e?.category ?? EventCategory.academic;
    _eventDate  = e?.eventDate ?? DateTime.now().add(const Duration(days: 7));
    _imageBase64 = e?.imageUrl;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Compress aggressively — Firestore docs have a 1MB limit.
    // maxWidth: 800, quality: 50 keeps base64 well under 500KB.
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 50);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final base64Str = base64Encode(bytes);

    // Warn if still too large (> 700KB base64 = ~500KB image)
    if (base64Str.length > 700 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Image too large — please choose a smaller image'),
          backgroundColor: AppColors.warning,
        ));
      }
      return;
    }
    setState(() => _imageBase64 = base64Str);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(_isEdit ? 'Edit Event' : 'Post an Event',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                _isEdit
                    ? 'Update your event details below'
                    : 'Your event will be visible to everyone immediately',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                // ── Image picker ──────────────────────────────────────────
                GestureDetector(
                  onTap: _pickImage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 160,
                    decoration: BoxDecoration(
                      color: _imageBase64 != null ? Colors.transparent : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _imageBase64 != null
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AppColors.border,
                        width: _imageBase64 != null ? 1.5 : 1,
                      ),
                    ),
                    child: _imageBase64 != null
                        ? Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.memory(base64Decode(_imageBase64!),
                                  height: 160, width: double.infinity, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8, right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageBase64 = null),
                                child: Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                            // Change image hint
                            Positioned(
                              bottom: 8, right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.edit_rounded, size: 11, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('Change', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ),
                          ])
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(height: 10),
                            const Text('Add event image',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                            const SizedBox(height: 3),
                            const Text('Optional — tap to upload',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ]),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Title ─────────────────────────────────────────────────
                TextField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Event title',
                    hintText: 'e.g. Annual Tech Fest 2025',
                    prefixIcon: Icon(Icons.event_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Category ──────────────────────────────────────────────
                _CategorySelector(
                  selected: _category,
                  onSelect: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: 14),

                // ── Date ──────────────────────────────────────────────────
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _eventDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _eventDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(_fmtDate(_eventDate),
                          style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_rounded, size: 14, color: AppColors.primary),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Bio / About ───────────────────────────────────────────
                TextField(
                  controller: _bioCtrl,
                  maxLines: 8,
                  minLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'About this event',
                    hintText: _bioHint,
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textDisabled, height: 1.6),
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 100),
                      child: Icon(Icons.description_outlined, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Submit ────────────────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(_isEdit ? 'Save Changes' : 'Publish Event',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _bioCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in the title and about section'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => _loading = true);

    try {
      if (_isEdit) {
        await ref.read(eventNotifierProvider.notifier).update(
          widget.existing!.copyWith(
            title: _titleCtrl.text.trim(),
            description: _bioCtrl.text.trim(),
            category: _category,
            eventDate: _eventDate,
            imageUrl: _imageBase64,
          ),
        );
      } else {
        await ref.read(eventNotifierProvider.notifier).add(
          CollegeEvent(
            id: '',
            authorId: widget.user.id,
            authorName: widget.user.name,
            authorRole: widget.user.role == UserRole.student ? 'student_cr' : widget.user.role.name,
            title: _titleCtrl.text.trim(),
            description: _bioCtrl.text.trim(),
            category: _category,
            eventDate: _eventDate,
            imageUrl: _imageBase64,
            createdAt: DateTime.now(),
          ),
          autoApprove: true,
        );
      }

      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Event updated' : 'Event published'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ─── Category selector ────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  final EventCategory selected;
  final ValueChanged<EventCategory> onSelect;
  const _CategorySelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const icons  = [Icons.school_rounded, Icons.theater_comedy_rounded, Icons.sports_soccer_rounded, Icons.build_rounded, Icons.mic_rounded, Icons.event_rounded];
    const labels = ['Academic', 'Cultural', 'Sports', 'Workshop', 'Seminar', 'Other'];
    const colors = [AppColors.primary, AppColors.meeting, AppColors.success, AppColors.warning, AppColors.info, AppColors.textMuted];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: EventCategory.values.map((c) {
          final active = selected == c;
          return GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: active ? colors[c.index].withValues(alpha: 0.1) : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? colors[c.index] : AppColors.border, width: active ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icons[c.index], size: 14, color: active ? colors[c.index] : AppColors.textMuted),
                const SizedBox(width: 6),
                Text(labels[c.index],
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? colors[c.index] : AppColors.textMuted)),
              ]),
            ),
          );
        }).toList(),
      ),
    ]);
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.4)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(6)),
          child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}
