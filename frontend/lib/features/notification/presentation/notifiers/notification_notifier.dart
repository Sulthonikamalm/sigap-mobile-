import 'package:flutter/foundation.dart';
import '../../data/models/notification_record.dart';
import '../../data/mock/mock_notification_data.dart';

/// Single source of truth untuk seluruh state notifikasi.
///
/// Menggantikan semua setState() yang tersebar di _NotificationPageState.
/// Pattern: ChangeNotifier + Provider (konsisten dengan ChatNotifier,
/// SatgasNotifier, dan EmergencyLiveProvider).
///
/// Keuntungan kunci: komponen di luar halaman notifikasi
/// (misal badge counter di BottomNav) bisa listen ke unreadCount
/// tanpa harus memiliki akses ke State widget.
class NotificationNotifier extends ChangeNotifier {
  List<NotificationRecord> _notifications = [];
  List<NotificationRecord> get notifications =>
      List.unmodifiable(_notifications);

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// Jumlah notifikasi belum dibaca — bisa diakses dari mana saja.
  int get unreadCount => _notifications.where((n) => n.isUnread).length;

  /// Muat data notifikasi dari sumber data.
  /// Di production: ganti Future.delayed dengan HTTP call.
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulasi network delay
      await Future<void>.delayed(const Duration(milliseconds: 600));
      _notifications = MockNotificationData.getNotifications();
    } catch (e) {
      // Jika API gagal, biarkan list kosong dan tampilkan empty state.
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tandai semua notifikasi sebagai sudah dibaca.
  Future<void> markAllAsRead() async {
    // Snapshot untuk rollback
    final previousState = List<NotificationRecord>.from(_notifications);

    try {
      // Simulasi API call — di production: await api.markAllAsRead()
      await Future<void>.delayed(const Duration(milliseconds: 300));

      _notifications = _notifications.map((n) {
        return n.isUnread ? n.copyWith(isUnread: false) : n;
      }).toList();
      notifyListeners();
    } catch (e) {
      // Rollback ke state sebelumnya
      _notifications = previousState;
      notifyListeners();
      rethrow; // Biarkan UI menampilkan SnackBar error
    }
  }

  /// Tandai satu notifikasi sebagai sudah dibaca.
  Future<void> markAsRead(String id) async {
    try {
      // Simulasi API call — di production: await api.markAsRead(id)
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && _notifications[index].isUnread) {
        _notifications[index] =
            _notifications[index].copyWith(isUnread: false);
        notifyListeners();
      }
    } catch (_) {
      // Silent — mark-as-read gagal tidak perlu mengganggu UX
    }
  }

  /// Hapus satu notifikasi. Optimistic delete dengan rollback jika gagal.
  Future<void> removeNotification(String id) async {
    final removedIndex = _notifications.indexWhere((n) => n.id == id);
    if (removedIndex == -1) return;

    final removedItem = _notifications[removedIndex];

    // Optimistic delete
    _notifications.removeAt(removedIndex);
    notifyListeners();

    try {
      // Simulasi API call — di production: await api.deleteNotification(id)
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      // Rollback: kembalikan item jika API gagal
      _notifications.insert(removedIndex, removedItem);
      notifyListeners();
      rethrow; // Biarkan UI menampilkan SnackBar error
    }
  }
}
