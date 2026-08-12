import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/standard_header.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _formatTimestamp(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    }
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            StandardHeader(
              title: l10n.notificationsTitle,
              showBack: true,
              onBack: () => _handleBack(context),
            trailingActions: notifications.isNotEmpty
                ? [
                    IconButton(
                      tooltip: l10n.markAllAsRead,
                      icon: const Icon(Icons.mark_chat_read_outlined),
                      onPressed: () => provider.markAllAsRead(),
                    ),
                    IconButton(
                      tooltip: l10n.clearAll,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      onPressed: () => provider.clearNotifications(),
                    ),
                  ]
                : null,
          ),
          SliverFillRemaining(
            hasScrollBody: notifications.isNotEmpty,
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_none,
                                size: 48,
                                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.noNewNotifications,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.allCaughtUp,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final note = notifications[index];
                            return AnimatedListItem(
                              index: index,
                              child: GestureDetector(
                              onTap: () => provider.markAsRead(note.id),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: note.isRead
                                      ? AppTheme.subtleShadow
                                      : AppTheme.cardShadow,
                                  border: note.isRead
                                      ? Border.all(color: AppTheme.divider, width: 1)
                                      : null,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: note.isRead
                                            ? AppTheme.textSecondary.withValues(alpha: 0.08)
                                            : AppTheme.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        note.isRead ? Icons.notifications_none : Icons.notifications_active,
                                        color: note.isRead ? AppTheme.textSecondary : AppTheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  note.title,
                                                  style: TextStyle(
                                                    color: AppTheme.textPrimary,
                                                    fontWeight: note.isRead ? FontWeight.w500 : FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!note.isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: AppTheme.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            note.body,
                                            style: TextStyle(
                                              color: note.isRead ? AppTheme.textSecondary : AppTheme.textPrimary,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _formatTimestamp(context, note.timestamp),
                                            style: TextStyle(color: AppTheme.textHint, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    ),
    );
  }
}
