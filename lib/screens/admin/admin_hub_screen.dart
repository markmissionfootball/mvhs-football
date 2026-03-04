import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/diablo_colors.dart';
import '../../providers/auth_provider.dart';

class AdminHubScreen extends ConsumerWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser =
        ref.watch(appUserProvider).whenOrNull(data: (u) => u);
    final isAdmin = appUser?.isAdminOrAbove ?? false;

    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'ADMIN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _AdminTile(
              icon: Icons.campaign,
              label: 'POST ANNOUNCEMENT',
              onTap: () => context.push('/admin/announcement'),
            ),
            if (isAdmin)
              _AdminTile(
                icon: Icons.person_add,
                label: 'INVITE USER',
                onTap: () => context.push('/admin/invite'),
              ),
            _AdminTile(
              icon: Icons.videocam,
              label: 'IMPORT FILM',
              onTap: () => context.push('/admin/import-film'),
            ),
            _AdminTile(
              icon: Icons.people,
              label: 'MANAGE ROSTER',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              },
            ),
            _AdminTile(
              icon: Icons.calendar_month,
              label: 'EDIT SCHEDULE',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              },
            ),
            _AdminTile(
              icon: Icons.assignment,
              label: 'DEPTH CHART',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              },
            ),
            _AdminTile(
              icon: Icons.analytics,
              label: 'ANALYTICS',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              },
            ),
            _AdminTile(
              icon: Icons.settings,
              label: 'SETTINGS',
              onTap: () => context.push('/profile/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DiabloColors.darkCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: DiabloColors.gold, size: 40),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
