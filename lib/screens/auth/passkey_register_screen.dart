import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/diablo_colors.dart';
import '../../widgets/diamond_divider.dart';

class PasskeyRegisterScreen extends StatelessWidget {
  const PasskeyRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.dark,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'QUICK LOGIN',
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: DiabloColors.gold, width: 2),
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 56,
                  color: DiabloColors.gold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SET UP QUICK LOGIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              const DiamondDivider(color: DiabloColors.gold),
              const SizedBox(height: 16),
              const Text(
                'Use Face ID or fingerprint to sign in instantly next time. No password needed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Register WebAuthn passkey via Cloud Function
                    context.go('/onboarding');
                  },
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('ENABLE PASSKEY'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/onboarding'),
                child: const Text(
                  'SKIP FOR NOW',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
