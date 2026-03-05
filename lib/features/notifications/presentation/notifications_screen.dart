import 'package:assets_management/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../data/notification_model.dart';
import '../data/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.onOpenDrawer,
    this.isDrawerVisible = false,
  });

  final VoidCallback? onOpenDrawer;
  final bool isDrawerVisible;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _expanded = {};
  bool _searchActive = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  List<NotificationModel> _filtered(
    List<NotificationModel> allNotifs,
    String tabKey,
  ) {
    if (allNotifs.isEmpty) return [];
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      List<NotificationModel> base;
      if (tabKey == 'today') {
        base = allNotifs
            .where(
              (n) =>
                  n.date.year == today.year &&
                  n.date.month == today.month &&
                  n.date.day == today.day,
            )
            .toList();
      } else if (tabKey == 'week') {
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        base = allNotifs
            .where(
              (n) =>
                  n.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                  n.date.isBefore(weekEnd.add(const Duration(days: 1))),
            )
            .toList();
      } else {
        base = allNotifs;
      }

      if (_searchQuery.trim().isEmpty) return base;
      final q = _searchQuery.trim().toLowerCase();
      return base
          .where(
            (n) =>
                n.title.toLowerCase().contains(q) ||
                n.subtitle.toLowerCase().contains(q) ||
                n.body.toLowerCase().contains(q),
          )
          .toList();
    } catch (e) {
      debugPrint('Error filtering notifications: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _navigateTo(NotificationModel notif) {
    if (notif.routeName == null) return;
    Navigator.of(
      context,
    ).pushNamed(notif.routeName!, arguments: notif.routeArgs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifService = context.watch<NotificationService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu, color: AppColors.primary),
                onPressed: widget.onOpenDrawer,
              )
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        title: _searchActive
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.buttonSearch,
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : Text(AppLocalizations.of(context)!.notifTitle),
        actions: [
          IconButton(
            icon: Icon(_searchActive ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searchActive = !_searchActive;
              if (!_searchActive) {
                _searchQuery = '';
                _searchCtrl.clear();
              }
            }),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) async {
              if (v == 'mark_all') {
                final messenger = ScaffoldMessenger.of(context);
                await notifService.markAllAsRead();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                    ),
                  );
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'mark_all',
                child: Text(AppLocalizations.of(context)!.notifMarkAllRead),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primaryLight, width: 2),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primaryLight,
              ),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: [
                Tab(text: AppLocalizations.of(context)!.notifToday),
                Tab(text: AppLocalizations.of(context)!.notifThisWeek),
                Tab(text: AppLocalizations.of(context)!.notifAll),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notifService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          final allItems = snapshot.data ?? [];

          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: ['today', 'week', 'all'].map((tabKey) {
                    final items = _filtered(allItems, tabKey);
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.notifications_none_rounded,
                              size: 56,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No results for "$_searchQuery"'
                                  : 'No notifications',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final notif = items[i];
                        final isExpanded = _expanded.contains(notif.id);
                        return _NotifTile(
                          notif: notif,
                          expanded: isExpanded,
                          onToggle: () => setState(() {
                            if (isExpanded) {
                              _expanded.remove(notif.id);
                            } else {
                              _expanded.add(notif.id);
                            }
                          }),
                          onNavigate: notif.routeName != null
                              ? () => _navigateTo(notif)
                              : null,
                          onDismiss: () =>
                              notifService.deleteNotification(notif.id),
                          onMarkAsRead: () => notifService.markAsRead(notif.id),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.notif,
    required this.expanded,
    required this.onToggle,
    this.onNavigate,
    required this.onDismiss,
    required this.onMarkAsRead,
  });

  final NotificationModel notif;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback? onNavigate;
  final VoidCallback onDismiss;
  final VoidCallback onMarkAsRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = now.difference(notif.date);

    String timeLabel;
    if (notif.date.year == today.year &&
        notif.date.month == today.month &&
        notif.date.day == today.day) {
      timeLabel = 'Today ${DateFormat.jm().format(notif.date)}';
    } else if (diff.inDays < 2 &&
        notif.date.isAfter(today.subtract(const Duration(days: 1)))) {
      timeLabel = 'Yesterday ${DateFormat.jm().format(notif.date)}';
    } else {
      timeLabel = DateFormat('dd-MM-yyyy').format(notif.date);
    }

    final iconColor = notif.getIconColor();

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: InkWell(
        onTap: () {
          onToggle();
          if (!notif.isRead) onMarkAsRead();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Opacity(
            opacity: notif.isRead ? 0.6 : 1.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon in circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(notif.getIcon(), color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notif.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      // Expanded body
                      if (expanded) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            notif.body,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        if (notif.progress != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Completed',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: iconColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        // Go to button
                        if (onNavigate != null) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: onNavigate,
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                              ),
                              label: const Text('Go to'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                textStyle: theme.textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 6),
                      // Details / Minimize toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (!notif.isRead) const SizedBox(width: 8),
                          Text(
                            expanded ? 'Minimize' : 'Details',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
