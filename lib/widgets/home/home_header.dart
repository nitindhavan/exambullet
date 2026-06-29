import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent/models/User.dart';
import 'package:percent/screens/notifications_screen.dart';
import 'package:percent/utils/theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    Key? key,
    required this.user,
    required this.goalCount,
    required this.onTapSearch,
  }) : super(key: key);

  final UserModel user;
  final int goalCount;
  final VoidCallback onTapSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Avatar + Greeting
              Expanded(
                child: Row(
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hey, ${user.name.trim().split(' ').first} 👋',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Let\'s prepare today',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right: Notifications
              _NotificationBell(userId: user.uid),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final name = user.name.trim();
    String initials = '';
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.isNotEmpty) {
        initials = parts.first.substring(0, 1);
        if (parts.length > 1 && parts.last.isNotEmpty) {
          initials += parts.last.substring(0, 1);
        }
      }
    }
    initials = initials.toUpperCase();

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: GoogleFonts.outfit(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              )
            : const Icon(
                Icons.person_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
      ),
    );
  }

}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({Key? key, required this.userId}) : super(key: key);
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('users/$userId/lastNotificationReadTime').onValue,
      builder: (context, readSnapshot) {
        final lastRead = readSnapshot.data?.snapshot.value as int? ?? 0;

        return StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('notifications').onValue,
          builder: (context, notifSnapshot) {
            int unreadCount = 0;
            if (notifSnapshot.hasData && notifSnapshot.data!.snapshot.value != null) {
              final rawMap = notifSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              rawMap.forEach((key, val) {
                final timestamp = val['timestamp'] as int? ?? 0;
                if (timestamp > lastRead) {
                  unreadCount++;
                }
              });
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreen(userId: userId),
                  ),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.borderLight, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppTheme.textPrimary,
                      size: 20,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        child: Center(
                          child: Text(
                            '$unreadCount',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
