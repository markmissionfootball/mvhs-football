import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/diablo_colors.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/schedule')) return 1;
    if (location.startsWith('/coach')) return 2;
    if (location.startsWith('/team')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/schedule');
      case 2:
        context.go('/coach');
      case 3:
        context.go('/team');
      case 4:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => _onTap(context, i),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'HOME',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'SCHEDULE',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: index == 2
                    ? DiabloColors.gold
                    : DiabloColors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_football,
                color: index == 2
                    ? DiabloColors.red
                    : DiabloColors.white,
                size: 24,
              ),
            ),
            label: 'COACH',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'TEAM',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'ME',
          ),
        ],
      ),
    );
  }
}
