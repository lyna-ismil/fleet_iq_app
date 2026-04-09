import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

/// Fetches all notifications for the current user.
/// Automatically re-fetches when auth state changes (userId).
final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final userId = ref.watch(authProvider).userId;
  if (userId == null) return [];

  final data = await ApiService.getUserNotifications(userId);
  final notifications = (data['notifications'] as List? ?? [])
      .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
      .toList();
  return notifications;
});

/// Derived provider: count of unread notifications for badge display.
final unreadBadgeCountProvider = Provider.autoDispose<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.when(
    data: (list) => list.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
