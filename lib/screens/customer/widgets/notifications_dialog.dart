import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/notification_service.dart';

class NotificationsDialog extends StatefulWidget {
  final UserModel currentUser;
  final List<NotificationModel> initialNotifications;
  final Function(List<NotificationModel>, int) onNotificationsUpdated;

  const NotificationsDialog({
    super.key,
    required this.currentUser,
    required this.initialNotifications,
    required this.onNotificationsUpdated,
  });

  @override
  State<NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<NotificationsDialog> {
  late List<NotificationModel> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = widget.initialNotifications;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Notifications', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400,
        height: 350,
        child: _notifications.isEmpty
            ? const Center(child: Text('No notifications', style: TextStyle(color: Colors.white54)))
            : ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (ctx, i) {
                  final n = _notifications[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: n.isRead ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: TextStyle(color: Colors.white, fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(n.message, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 6),
                        if (!n.isRead)
                          InkWell(
                            onTap: () async {
                              await NotificationService.instance.markRead(n.id);
                              final fresh = await NotificationService.instance.getForUser(widget.currentUser.id);
                              final count = await NotificationService.instance.unreadCountForUser(widget.currentUser.id);
                              setState(() {
                                _notifications = fresh;
                              });
                              widget.onNotificationsUpdated(fresh, count);
                            },
                            child: const Text('Mark as Read', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        if (_notifications.any((n) => !n.isRead))
          TextButton(
            onPressed: () async {
              await NotificationService.instance.markAllRead(userId: widget.currentUser.id);
              final fresh = await NotificationService.instance.getForUser(widget.currentUser.id);
              final count = await NotificationService.instance.unreadCountForUser(widget.currentUser.id);
              setState(() {
                _notifications = fresh;
              });
              widget.onNotificationsUpdated(fresh, count);
            },
            child: const Text('Mark All as Read', style: TextStyle(color: Color(0xFF00D4FF))),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.white54)),
        )
      ],
    );
  }
}
