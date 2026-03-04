import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../theme/diablo_colors.dart';
import '../../services/biometric_service.dart';
import '../../services/e2e_crypto_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _gameReminders = true;
  bool _workoutReminders = true;
  bool _announcements = true;
  bool _chatMessages = true;

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DiabloColors.darkCard,
        title: const Text(
          'SIGN OUT',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'SIGN OUT',
              style: TextStyle(
                color: DiabloColors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirebaseAuth.instance.signOut();
      await BiometricService().clearEnrollment();
      E2eCryptoService().clearCache();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: DiabloColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // Account section
          _sectionHeader('ACCOUNT'),
          ListTile(
            leading: const Icon(Icons.lock, color: DiabloColors.gold),
            title: const Text(
              'Change Password',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () => context.push('/change-password'),
          ),
          const Divider(color: Colors.white12, indent: 16, endIndent: 16),

          // Notifications section
          _sectionHeader('NOTIFICATIONS'),
          SwitchListTile(
            title: const Text(
              'Game Reminders',
              style: TextStyle(color: Colors.white),
            ),
            value: _gameReminders,
            activeColor: DiabloColors.gold,
            onChanged: (val) => setState(() => _gameReminders = val),
          ),
          SwitchListTile(
            title: const Text(
              'Workout Reminders',
              style: TextStyle(color: Colors.white),
            ),
            value: _workoutReminders,
            activeColor: DiabloColors.gold,
            onChanged: (val) => setState(() => _workoutReminders = val),
          ),
          SwitchListTile(
            title: const Text(
              'Announcements',
              style: TextStyle(color: Colors.white),
            ),
            value: _announcements,
            activeColor: DiabloColors.gold,
            onChanged: (val) => setState(() => _announcements = val),
          ),
          SwitchListTile(
            title: const Text(
              'Chat Messages',
              style: TextStyle(color: Colors.white),
            ),
            value: _chatMessages,
            activeColor: DiabloColors.gold,
            onChanged: (val) => setState(() => _chatMessages = val),
          ),
          const Divider(color: Colors.white12, indent: 16, endIndent: 16),

          // About section
          _sectionHeader('ABOUT'),
          const ListTile(
            leading: Icon(Icons.info_outline, color: DiabloColors.gold),
            title: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 32),

          // Sign out
          Center(
            child: TextButton(
              onPressed: _signOut,
              child: const Text(
                'SIGN OUT',
                style: TextStyle(
                  color: DiabloColors.red,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: DiabloColors.gold,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}
