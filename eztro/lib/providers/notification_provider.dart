import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

final unreadNotificationCountProvider = StateNotifierProvider<UnreadNotificationCountNotifier, int>((ref) {
  return UnreadNotificationCountNotifier();
});

class UnreadNotificationCountNotifier extends StateNotifier<int> {
  UnreadNotificationCountNotifier() : super(0);

  Future<void> refresh() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      final count = await NotificationService.getUnreadCount(user.id);
      state = count;
    }
  }

  void decrement() {
    if (state > 0) state--;
  }
}
