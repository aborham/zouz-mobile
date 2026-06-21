import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient.dio);
});

class NotificationsListNotifier extends Notifier<AsyncValue<List<NotificationModel>>> {
  @override
  AsyncValue<List<NotificationModel>> build() {
    Future.microtask(() => _fetchNotifications());
    return const AsyncValue.loading();
  }

  Future<void> _fetchNotifications() async {
    state = const AsyncValue.loading();
    try {
      final authState = ref.read(authNotifierProvider);

      if (!authState.isInitialized || authState.status != AuthStatus.authenticated) {
        state = const AsyncValue.data([]);
        return;
      }

      final repository = ref.read(notificationRepositoryProvider);
      final notifications = await repository.fetchNotifications(limit: 50, offset: 0);
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _fetchNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    final repository = ref.read(notificationRepositoryProvider);
    try {
      await repository.markAsRead(notificationId);
      state = state.whenData((notifications) {
        return notifications.map((n) {
          if (n.id == notificationId) {
            return NotificationModel(
              id: n.id,
              title: n.title,
              body: n.body,
              isRead: true,
              createdAt: n.createdAt,
              data: n.data,
            );
          }
          return n;
        }).toList();
      });
    } catch (e) {
      // Ignore or handle error
    }
  }

  Future<void> markAllAsRead() async {
    final repository = ref.read(notificationRepositoryProvider);
    try {
      await repository.markAsRead(); // Passing null means mark all as read
      state = state.whenData((notifications) {
        return notifications.map((n) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            body: n.body,
            isRead: true,
            createdAt: n.createdAt,
            data: n.data,
          );
        }).toList();
      });
    } catch (e) {
      // Ignore or handle error
    }
  }
}

final notificationsListProvider = NotifierProvider<NotificationsListNotifier, AsyncValue<List<NotificationModel>>>(() {
  return NotificationsListNotifier();
});
