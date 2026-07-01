import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:percent/models/notification.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key, required this.userId}) : super(key: key);
  final String userId;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _previousLastReadTime = 0;
  bool _isReadTimeLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreviousReadTimeAndMarkRead();
  }

  Future<void> _loadPreviousReadTimeAndMarkRead() async {
    try {
      final ref = FirebaseDatabase.instance.ref();
      final snap = await ref.child('users/${widget.userId}/lastNotificationReadTime').get();
      if (mounted) {
        setState(() {
          _previousLastReadTime = snap.value as int? ?? 0;
          _isReadTimeLoaded = true;
        });
      }
      // Update database so that the home screen notification badge resets
      await ref.child('users/${widget.userId}/lastNotificationReadTime').set(DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error loading last read time: $e');
      if (mounted) {
        setState(() {
          _isReadTimeLoaded = true;
        });
      }
    }
  }

  String _formatTimeAgo(int timestampMs) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      }
      return '${difference.inDays} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(title: 'Notifications'),
      body: !_isReadTimeLoaded
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5))
          : StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('notifications').onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5));
                }

                final List<NotificationModel> notifications = [];
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final rawMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  rawMap.forEach((key, val) {
                    notifications.add(NotificationModel.fromMap(val as Map, key as String));
                  });
                  // Sort by newest first
                  notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                }

                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    final isUnread = item.timestamp > _previousLastReadTime;
                    return _buildNotificationCard(item, isUnread);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 44,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "You're all caught up!",
              style: AppTheme.headingMd.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              "When you receive new updates, announcements, or test reminders, they will appear here.",
              textAlign: TextAlign.center,
              style: AppTheme.body,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, bool isUnread) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isUnread ? AppTheme.primaryLight.withValues(alpha: 0.25) : Colors.white,
        borderRadius: AppTheme.brMd,
        border: Border.all(
          color: isUnread ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.borderLight,
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: AppTheme.brMd,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppTheme.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                // Title and Body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTheme.headingSm.copyWith(fontSize: 16),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'NEW',
                                style: AppTheme.label.copyWith(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: AppTheme.bodySm.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTimeAgo(notification.timestamp),
                            style: AppTheme.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Subtle indicator of read status
                          Icon(
                            isUnread ? Icons.mark_chat_unread_rounded : Icons.mark_chat_read_rounded,
                            size: 14,
                            color: isUnread ? AppTheme.primary : AppTheme.textLight,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
