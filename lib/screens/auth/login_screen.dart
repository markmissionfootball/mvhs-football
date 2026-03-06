import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/diablo_colors.dart';
import '../../widgets/diamond_divider.dart';
import '../../services/biometric_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_service_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  final _biometric = BiometricService();
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final available = await _biometric.isAvailable();
    if (mounted) {
      setState(() => _biometricAvailable = available);
    }

    // Auto-prompt if biometric is enrolled
    if (available) {
      final enrolled = await _biometric.isEnrolled();
      if (enrolled && mounted) {
        _handleBiometricLogin();
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Demo bypass for development
    if (_usernameController.text.toLowerCase() == 'demo') {
      ref.read(isDemoModeProvider.notifier).state = true;
      if (mounted) context.go('/home');
      return;
    }

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    setState(() => _loading = true);

    final authService = ref.read(authServiceProvider);
    final result = await authService.signInWithUsername(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    switch (result) {
      case AuthSuccess(user: final user):
        // After successful login, offer biometric enrollment if available
        if (_biometricAvailable) {
          final enrolled = await _biometric.isEnrolled();
          if (!enrolled && mounted) {
            await _promptBiometricEnrollment(user.uid);
          }
        }

        if (!mounted) return;

        // Route based on user state
        if (user.mustChangePassword) {
          context.go('/change-password');
        } else if (!user.onboardingSurveyComplete) {
          context.go('/onboarding');
        } else {
          context.go('/home');
        }

      case AuthError(message: final message):
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: DiabloColors.red,
          ),
        );
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _loading = true);

    final authenticated = await _biometric.authenticate();
    if (!authenticated) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final creds = await _biometric.getStoredCredentials();
    if (creds == null) {
      // Credentials cleared — fall back to password login
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Use stored credentials to sign in
    final authService = ref.read(authServiceProvider);
    final result = await authService.signInWithUsername(
      creds.username,
      '', // Biometric bypass — password not needed for stored creds
    );

    if (!mounted) return;

    switch (result) {
      case AuthSuccess(user: final user):
        if (user.mustChangePassword) {
          context.go('/change-password');
        } else if (!user.onboardingSurveyComplete) {
          context.go('/onboarding');
        } else {
          context.go('/home');
        }
      case AuthError():
        setState(() => _loading = false);
        // Biometric auth failed — user can try password
    }
  }

  Future<void> _promptBiometricEnrollment(String uid) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DiabloColors.darkCard,
        title: const Text(
          'Enable Quick Login?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Use Face ID or fingerprint to sign in faster next time.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'NOT NOW',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'ENABLE',
              style: TextStyle(color: DiabloColors.gold),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await _biometric.enrollCredentials(
        uid: uid,
        username: _usernameController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.dark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/mv_logo.png',
                  height: 120,
                ),
                const SizedBox(height: 16),
                const Text(
                  'MVHS FOOTBALL',
                  style: TextStyle(
                    color: DiabloColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 8),
                const DiamondDivider(color: DiabloColors.gold),
                const SizedBox(height: 32),

                // Username field
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Username',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    prefixIcon: const Icon(Icons.person_outline,
                        color: DiabloColors.gold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: DiabloColors.gold, width: 2),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: DiabloColors.gold),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: DiabloColors.gold, width: 2),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 24),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleLogin,
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
                            'SIGN IN',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Biometric login option
                if (_biometricAvailable)
                  TextButton.icon(
                    onPressed: _loading ? null : _handleBiometricLogin,
                    icon: const Icon(Icons.fingerprint,
                        color: DiabloColors.gold, size: 28),
                    label: const Text(
                      'SIGN IN WITH BIOMETRICS',
                      style: TextStyle(
                        color: DiabloColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                // Fallback: show passkey button on web / non-biometric devices
                if (!_biometricAvailable)
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement passkey authentication
                    },
                    icon: const Icon(Icons.fingerprint, color: DiabloColors.gold),
                    label: const Text(
                      'SIGN IN WITH PASSKEY',
                      style: TextStyle(
                        color: DiabloColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Forgot password link
                TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: const Text(
                    'FORGOT PASSWORD?',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                // Register with invite code link
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text(
                    'HAVE AN INVITE CODE?',
                    style: TextStyle(
                      color: DiabloColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
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
