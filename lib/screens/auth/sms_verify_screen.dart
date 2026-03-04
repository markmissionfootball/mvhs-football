import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/diablo_colors.dart';

class SmsVerifyScreen extends StatefulWidget {
  const SmsVerifyScreen({super.key});

  @override
  State<SmsVerifyScreen> createState() => _SmsVerifyScreenState();
}

class _SmsVerifyScreenState extends State<SmsVerifyScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _loading = true);
    // TODO: Firebase Phone Auth — send verification code
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _codeSent = true;
      _loading = false;
    });
  }

  Future<void> _verifyCode() async {
    setState(() => _loading = true);
    // TODO: Verify SMS code with Firebase
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      context.go('/change-password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.dark,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'VERIFY PHONE',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Two-Factor Authentication',
                style: TextStyle(
                  color: DiabloColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'Enter the 6-digit code sent to your phone.'
                    : 'Enter your mobile number to receive a verification code.',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              if (!_codeSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '(949) 555-0123',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    prefixIcon:
                        const Icon(Icons.phone, color: DiabloColors.gold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendCode,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: DiabloColors.red),
                          )
                        : const Text('SEND CODE'),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '------',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verifyCode,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: DiabloColors.red),
                          )
                        : const Text('VERIFY'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _sendCode,
                    child: const Text(
                      'RESEND CODE',
                      style: TextStyle(
                        color: DiabloColors.gold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
