import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/diablo_colors.dart';
import '../../models/invite.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class InviteUserScreen extends ConsumerStatefulWidget {
  const InviteUserScreen({super.key});

  @override
  ConsumerState<InviteUserScreen> createState() => _InviteUserScreenState();
}

class _InviteUserScreenState extends ConsumerState<InviteUserScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  UserRole _selectedRole = UserRole.player;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }
    if (name.isEmpty) {
      _showError('Please enter a display name');
      return;
    }

    setState(() => _loading = true);

    // Generate 6-digit OTP
    final code = (100000 + Random().nextInt(900000)).toString();
    final currentUid = ref.read(currentUidProvider);

    final invite = Invite(
      id: '', // Will be set by Firestore
      email: email.toLowerCase(),
      inviteCode: code,
      role: _selectedRole,
      displayName: name,
      createdBy: currentUid,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    final docId = await FirestoreService().createInvite(invite);

    if (!mounted) return;
    setState(() => _loading = false);

    if (docId != null) {
      _showCodeDialog(email, code);
    } else {
      _showError('Failed to create invite. Please try again.');
    }
  }

  void _showCodeDialog(String email, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DiabloColors.darkCard,
        title: const Text(
          'INVITE CREATED',
          style: TextStyle(
            color: DiabloColors.gold,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send this code to $email:',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This code expires in 7 days.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Clear form for next invite
              _emailController.clear();
              _nameController.clear();
              setState(() => _selectedRole = UserRole.player);
            },
            child: const Text(
              'DONE',
              style: TextStyle(
                color: DiabloColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: DiabloColors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'INVITE USER',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send an Invitation',
                style: TextStyle(
                  color: DiabloColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The user will receive a 6-digit code to register.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'EMAIL',
                  labelStyle: const TextStyle(
                    color: DiabloColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                  hintText: 'player@example.com',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  prefixIcon: const Icon(Icons.email_outlined, color: DiabloColors.gold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Display name field
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'DISPLAY NAME',
                  labelStyle: const TextStyle(
                    color: DiabloColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                  hintText: 'John Smith',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  prefixIcon: const Icon(Icons.person_outline, color: DiabloColors.gold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Role selection
              const Text(
                'ROLE',
                style: TextStyle(
                  color: DiabloColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _roleChip(UserRole.player, 'Player'),
                  _roleChip(UserRole.coach, 'Coach'),
                  _roleChip(UserRole.parent, 'Parent'),
                ],
              ),
              const SizedBox(height: 32),

              // Send button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendInvite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DiabloColors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'CREATE INVITE',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(UserRole role, String label) {
    final selected = _selectedRole == role;
    return ChoiceChip(
      label: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          fontSize: 12,
        ),
      ),
      selected: selected,
      selectedColor: DiabloColors.red,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      onSelected: (_) => setState(() => _selectedRole = role),
    );
  }
}
