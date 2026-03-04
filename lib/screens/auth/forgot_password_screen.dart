import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/diablo_colors.dart';
import '../../providers/auth_service_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _inputController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    setState(() => _loading = true);

    final authService = ref.read(authServiceProvider);
    await authService.sendPasswordReset(input);

    if (mounted) {
      setState(() {
        _loading = false;
        _sent = true; // Always show success to prevent enumeration
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.dark,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'RESET PASSWORD',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _sent ? _buildSentState() : _buildInputState(),
        ),
      ),
    );
  }

  Widget _buildInputState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Forgot Your Password?',
          style: TextStyle(
            color: DiabloColors.gold,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your username or email and we\'ll send you a reset link.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _inputController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Username or email',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            prefixIcon: const Icon(Icons.email_outlined, color: DiabloColors.gold),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleReset(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleReset,
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
                    'SEND RESET LINK',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => context.go('/login'),
            child: const Text(
              'BACK TO LOGIN',
              style: TextStyle(
                color: DiabloColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSentState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: DiabloColors.gold,
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Check Your Email',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'If an account exists with that username or email,\nyou\'ll receive a password reset link.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DiabloColors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'BACK TO LOGIN',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
