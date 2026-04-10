import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../constants/theme.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../services/api_service.dart';
import 'widgets/skeleton_loader.dart';
import 'widgets/error_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  Color _typeColor(String? type) {
    switch (type?.toUpperCase()) {
      case 'BOOKING_CONFIRMED':
        return Colors.blue;
      case 'BOOKING_CANCELLED':
        return Colors.red;
      case 'MAINTENANCE_DUE':
        return Colors.amber;
      case 'PAYMENT_SUCCESS':
        return Colors.green;
      case 'SYSTEM':
        return Colors.grey;
      default:
        return AppTheme.brandBlue;
    }
  }

  IconData _typeIcon(String? type) {
    switch (type?.toUpperCase()) {
      case 'BOOKING_CONFIRMED':
        return Icons.check_circle_outline;
      case 'BOOKING_CANCELLED':
        return Icons.cancel_outlined;
      case 'MAINTENANCE_DUE':
        return Icons.build_outlined;
      case 'PAYMENT_SUCCESS':
        return Icons.payment;
      case 'SYSTEM':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceGray,
      appBar: AppBar(
        title: Text("Notifications", style: Theme.of(context).textTheme.displaySmall),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textMain),
        centerTitle: true,
      ),
      body: notifs.when(
        loading: () => SkeletonList(itemCount: 5, itemHeight: 80),
        error: (e, _) => ErrorState(
          message: "Failed to load notifications.",
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (ctx, i) => _buildNotificationTile(context, ref, list[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, WidgetRef ref, NotificationModel notif) {
    final color = _typeColor(notif.type);
    final icon = _typeIcon(notif.type);
    final timeAgo = _formatTimeAgo(notif.createdAt);

    return GestureDetector(
      onTap: () async {
        if (!notif.isRead) {
          try {
            await ApiService.markNotificationRead(notif.id);
            ref.invalidate(notificationsProvider);
          } catch (e) {
            // Silently fail
          }
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? AppTheme.surfaceWhite : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.softShadow,
          border: notif.isRead
              ? null
              : Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notif.title != null)
                    Text(
                      notif.title!,
                      style: TextStyle(
                        fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textMain,
                      ),
                    ),
                  if (notif.title != null) SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        timeAgo,
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      if (!notif.isRead) ...[
                        SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_outlined, size: 64, color: AppTheme.textMuted),
          ),
          SizedBox(height: 24),
          Text("You're all caught up 🎉", style: Theme.of(context).textTheme.displaySmall),
          SizedBox(height: 8),
          Text("No new notifications at the moment.", style: TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return DateFormat('MMM d').format(dt);
  }
}
