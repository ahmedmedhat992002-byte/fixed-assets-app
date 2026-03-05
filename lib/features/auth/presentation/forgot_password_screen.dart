import 'package:flutter/material.dart';
import 'widgets/auth_layout.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key, this.onSendOtp, this.onBack});

  final VoidCallback? onSendOtp;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthLayout(
      title: 'Forgot password?',
      subtitle: 'Enter your registered email and we\'ll send you a reset code.',
      children: [
        const TextField(
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: onSendOtp, child: const Text('Send OTP')),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Remember your password?', style: theme.textTheme.bodyMedium),
            TextButton(
              onPressed: onBack ?? () => Navigator.of(context).pop(),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ],
    );
  }
}
