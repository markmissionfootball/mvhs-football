import 'package:flutter/material.dart';
import '../theme/diablo_colors.dart';

class ChatRoomTile extends StatelessWidget {
  final String roomName;
  final String? lastMessageTime;
  final bool isGroup;
  final bool hasUnread;
  final VoidCallback onTap;

  const ChatRoomTile({
    super.key,
    required this.roomName,
    this.lastMessageTime,
    this.isGroup = false,
    this.hasUnread = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: DiabloColors.darkCard,
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isGroup ? DiabloColors.gold : DiabloColors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isGroup
                    ? const Icon(Icons.groups, color: DiabloColors.dark, size: 24)
                    : Text(
                        roomName.isNotEmpty ? roomName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roomName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lastMessageTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        lastMessageTime!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Unread indicator
            if (hasUnread)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: DiabloColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
