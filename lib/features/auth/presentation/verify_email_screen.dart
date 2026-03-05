import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_service.dart';

/// Shown when Firebase Auth status is [AuthStatus.emailVerificationRequired].
///
/// Flow:
///  1. User registers → Firebase sends verification email
///  2. This screen appears with email address and instructions
///  3. "I've verified" button polls Firebase to check email status
///  4. On confirmed → AuthWrapper auto-navigates to HomeShell
///  5. Resend button with 60-second cooldown prevents spam
///  6. Sign out button lets user correct a wrong email
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _resendCooldownSeconds = 60;

  bool _checking = false;
  bool _resendDisabled = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _checkVerification() async {
    setState(() => _checking = true);
    final auth = context.read<AuthService>();
    final verified = await auth.checkEmailVerified();
    if (!mounted) return;
    setState(() => _checking = false);

    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email not yet verified. Please check your inbox and click the link.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
    // If verified, AuthWrapper auto-navigates to HomeShell.
  }

  Future<void> _resend() async {
    final auth = context.read<AuthService>();
    final ok = await auth.resendEmailVerification();
    if (!mounted) return;

    if (ok) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email resent. Check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.lastError?.message ?? 'Failed to resend email.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _startCountdown() {
    setState(() {
      _resendDisabled = true;
      _countdown = _resendCooldownSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        setState(() => _resendDisabled = false);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final email = auth.firebaseUser?.email ?? 'your email';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // ── Icon ──────────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_unread_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Title ─────────────────────────────────────────────────────
              Text(
                'Verify your email',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'We sent a verification link to',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Click the link in the email to activate your account, then tap the button below.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const Spacer(),

              // ── Check button ──────────────────────────────────────────────
              FilledButton.icon(
                onPressed: _checking ? null : _checkVerification,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _checking
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: const SizedBox.shrink(),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _checking ? 'Checking…' : "I've verified my email",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Resend button ─────────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: _resendDisabled ? null : _resend,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  _resendDisabled
                      ? 'Resend in ${_countdown}s'
                      : 'Resend verification email',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(height: 16),

              // ── Sign out ──────────────────────────────────────────────────
              Center(
                child: TextButton.icon(
                  onPressed: () => context.read<AuthService>().signOut(),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out / use a different account'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
