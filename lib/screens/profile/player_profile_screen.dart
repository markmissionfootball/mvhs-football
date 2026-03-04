import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/diablo_colors.dart';
import '../../widgets/diamond_divider.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(currentPlayerProvider);

    final player = playerAsync.whenOrNull(data: (p) => p);

    final displayName =
        player?.fullName.toUpperCase() ?? 'PLAYER NAME';
    final jerseyNum = player?.jerseyNumber != null
        ? '#${player!.jerseyNumber}'
        : '#00';
    final position = player?.position.isNotEmpty == true
        ? player!.position.toUpperCase()
        : 'POSITION';
    final team = player?.team.isNotEmpty == true
        ? player!.team.toUpperCase()
        : 'VARSITY';
    final subtitle = '$jerseyNum \u2022 $position \u2022 $team';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'MY PROFILE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: DiabloColors.dark,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: DiabloColors.gold, width: 2),
                      color: DiabloColors.red,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: DiabloColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const DiamondDivider(color: Colors.white24),
                ],
              ),
            ),

            // Menu items
            _buildMenuItem(context, Icons.fitness_center,
                'Strength & Conditioning',
                onTap: () => context.push('/profile/strength')),
            _buildMenuItem(context, Icons.show_chart, 'My Stats',
                onTap: () => context.push('/profile/stats')),
            _buildMenuItem(context, Icons.videocam, 'Film Room',
                onTap: () => context.push('/profile/film')),
            _buildMenuItem(context, Icons.school, 'Recruiting Hub',
                onTap: () => context.push('/profile/recruiting')),
            _buildMenuItem(context, Icons.emoji_events, 'Awards',
                onTap: () => context.push('/profile/awards')),
            _buildMenuItem(
              context,
              Icons.chat_bubble_outline,
              'Messages',
              onTap: () => context.go('/profile/chat'),
            ),
            _buildMenuItem(context, Icons.notifications, 'Notifications',
                onTap: () => context.push('/profile/settings')),
            _buildMenuItem(context, Icons.settings, 'Settings',
                onTap: () => context.push('/profile/settings')),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: DiabloColors.red),
      title: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }
}
