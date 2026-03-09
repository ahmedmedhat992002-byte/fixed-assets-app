import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_service.dart';

/// Drop-in logout button for any screen.
///
/// Usage in Settings, drawer, or profile page:
/// ```dart
/// const LogoutButton()
/// const LogoutButton(style: LogoutButtonStyle.listTile)
/// ```
enum LogoutButtonStyle { elevated, listTile, textOnly }

class LogoutButton extends StatefulWidget {
  const LogoutButton({
    super.key,
    this.style = LogoutButtonStyle.elevated,
    this.label = 'Sign out',
  });

  final LogoutButtonStyle style;
  final String label;

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool _loading = false;

  Future<void> _onTap() async {
    final confirmed = await _confirm(context);
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    try {
      await context.read<AuthService>().signOut();
      // AuthWrapper auto-navigates to LoginScreen — no pushReplacement needed.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-out failed: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _confirm(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: SizedBox.shrink(),
          ),
        ),
      );
    }

    switch (widget.style) {
      case LogoutButtonStyle.elevated:
        return ElevatedButton.icon(
          onPressed: _onTap,
          icon: const Icon(Icons.logout_rounded, color: Colors.red),
          label: Text(widget.label, style: const TextStyle(color: Colors.red)),
          style: ElevatedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

      case LogoutButtonStyle.listTile:
        return ListTile(
          leading: const Icon(Icons.logout_rounded, color: Colors.red),
          title: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: _onTap,
        );

      case LogoutButtonStyle.textOnly:
        return TextButton.icon(
          onPressed: _onTap,
          icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
          label: Text(widget.label, style: const TextStyle(color: Colors.red)),
        );
    }
  }
}
