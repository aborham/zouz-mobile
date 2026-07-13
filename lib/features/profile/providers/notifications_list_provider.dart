import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient.dio);
});

class NotificationListState {
  final List<NotificationModel> notifications;
  final bool hasMore;
  final bool isLoadingMore;

  NotificationListState({
    required this.notifications,
    required this.hasMore,
    required this.isLoadingMore,
  });

  NotificationListState copyWith({
    List<NotificationModel>? notifications,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class NotificationsListNotifier extends Notifier<AsyncValue<NotificationListState>> {
  int _offset = 0;
  final int _limit = 20;

  @override
  AsyncValue<NotificationListState> build() {
    Future.microtask(() => _fetchNotifications());
    return const AsyncValue.loading();
  }

  Future<void> _fetchNotifications() async {
    _offset = 0;
    state = const AsyncValue.loading();
    try {
      final authState = ref.read(authNotifierProvider);

      if (!authState.isInitialized || authState.status != AuthStatus.authenticated) {
        state = AsyncValue.data(NotificationListState(notifications: [], hasMore: false, isLoadingMore: false));
        return;
      }

      final repository = ref.read(notificationRepositoryProvider);
      final notifications = await repository.fetchNotifications(limit: _limit, offset: _offset);
      
      _offset += notifications.length;
      final hasMore = notifications.length == _limit;

      state = AsyncValue.data(NotificationListState(
        notifications: notifications,
        hasMore: hasMore,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final repository = ref.read(notificationRepositoryProvider);
      final newNotifications = await repository.fetchNotifications(limit: _limit, offset: _offset);
      
      _offset += newNotifications.length;
      final hasMore = newNotifications.length == _limit;

      state = AsyncValue.data(currentState.copyWith(
        notifications: [...currentState.notifications, ...newNotifications],
        hasMore: hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      // In case of error, just stop loading and don't change existing list
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
      // Optionally could show a snackbar or log error
    }
  }

  Future<void> refresh() async {
    await _fetchNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    final repository = ref.read(notificationRepositoryProvider);
    try {
      await repository.markAsRead(notificationId);
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(
          notifications: currentState.notifications.map((n) {
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
          }).toList(),
        ));
      }
    } catch (e) {
      // Ignore or handle error
    }
  }

  Future<void> markAllAsRead() async {
    final repository = ref.read(notificationRepositoryProvider);
    try {
      await repository.markAsRead(); // Passing null means mark all as read
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(
          notifications: currentState.notifications.map((n) {
            return NotificationModel(
              id: n.id,
              title: n.title,
              body: n.body,
              isRead: true,
              createdAt: n.createdAt,
              data: n.data,
            );
          }).toList(),
        ));
      }
    } catch (e) {
      // Ignore or handle error
    }
  }
}

final notificationsListProvider = NotifierProvider<NotificationsListNotifier, AsyncValue<NotificationListState>>(() {
  return NotificationsListNotifier();
});
