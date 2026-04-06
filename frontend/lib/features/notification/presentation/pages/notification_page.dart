import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';
import '../../data/models/notification_record.dart';
import '../../data/mock/mock_notification_data.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late List<NotificationRecord> _notifications;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _notifications = MockNotificationData.getNotifications();
      _isLoading = false;
    });
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications.map((n) {
        return n.isUnread ? n.copyWith(isUnread: false) : n;
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ditandai sudah dibaca'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && _notifications[index].isUnread) {
        _notifications[index] = _notifications[index].copyWith(isUnread: false);
      }
    });
  }

  void _removeNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Notifikasi",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.textDark,
          ),
        ),
        iconTheme: const IconThemeData(color: AppConstants.textDark),
        actions: [
          if (!_isLoading && _notifications.any((n) => n.isUnread))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                "Tandai Dibaca",
                style: TextStyle(
                  fontSize: 13,
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppConstants.primaryColor),
      );
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _loadNotifications();
      },
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          final isFirst = index == 0;

          // Section header (Hari Ini / Kemarin / Lebih Lama)
          Widget? sectionHeader;
          if (isFirst || notif.section != _notifications[index - 1].section) {
            sectionHeader = Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                notif.section,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sectionHeader != null) sectionHeader,
              Dismissible(
                key: Key(notif.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.errorColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => _removeNotification(notif.id),
                child: GestureDetector(
                  onTap: () => _markAsRead(notif.id),
                  child: _NotificationTile(notification: notif),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: AppConstants.primaryColor.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Belum Ada Notifikasi",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Notifikasi terbaru akan muncul di sini.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationRecord notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isUnread
            ? AppConstants.primaryColor.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isUnread
              ? AppConstants.primaryColor.withValues(alpha: 0.15)
              : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notification.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification.icon,
                color: notification.iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: AppConstants.textDark,
                          ),
                        ),
                      ),
                      if (notification.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppConstants.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.time,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
