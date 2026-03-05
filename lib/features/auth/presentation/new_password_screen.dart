import 'package:flutter/material.dart';
import 'widgets/auth_layout.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key, this.onConfirm});

  final VoidCallback? onConfirm;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Create new password',
      subtitle:
          'Your new password must be different from previously used passwords.',
      children: [
        TextField(
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'New password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: widget.onConfirm,
          child: const Text('Set new password'),
        ),
      ],
    );
  }
}
