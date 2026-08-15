import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_notification.dart';
import '../../../data/services/notification_service.dart';

/// Full list of a user's notifications (tap the Home bell icon to get
/// here), with a mark-as-read action per item.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local-user';
      final notifications = await ref.read(notificationServiceProvider).listNotifications(userId: userId);
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    await ref.read(notificationServiceProvider).markAsRead(notification.id);
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                  ],
                  if (_notifications.isEmpty)
                    const Expanded(
                      child: Center(child: Text('No notifications yet.')),
                    )
                  else
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.separated(
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return Card(
                              color: notification.isRead ? Colors.grey[100] : Colors.white,
                              child: ListTile(
                                title: Text(notification.message),
                                subtitle: Text('${notification.type.name} • ${notification.createdAt.toLocal()}'.split('.').first),
                                trailing: notification.isRead
                                    ? null
                                    : TextButton(
                                        onPressed: () {
                                          _markRead(notification);
                                        },
                                        child: const Text('Mark read'),
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
