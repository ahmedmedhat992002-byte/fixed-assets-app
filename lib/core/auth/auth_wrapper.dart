import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_service.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/home/presentation/home_shell.dart';

/// State-driven navigation gatekeeper.
///
/// When [AuthService.status] transitions to [unauthenticated] or [error]
/// (i.e. after logout), this widget:
///   1. Pops all sub-routes so the navigator stack is clean
///   2. Wraps auth screens in [PopScope(canPop: false)] so the back button
///      cannot return to authenticated screens
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        switch (auth.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const _LoadingPage();

          case AuthStatus.authenticated:
            return const HomeShell();

          case AuthStatus.emailVerificationRequired:
            return const _AuthGuard(child: VerifyEmailScreen());

          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            // Clear any stacked routes (e.g. asset detail, settings) that were
            // pushed while the user was authenticated. This runs after build so
            // the Navigator is fully resolved.
            _clearRouteStack(context);
            return const _AuthGuard(child: LoginScreen());
        }
      },
    );
  }

  /// Pops all routes above the first (root) route after the current frame.
  static void _clearRouteStack(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = Navigator.maybeOf(context);
      if (navigator != null && navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      }
    });
  }
}

/// Wraps an auth screen and prevents the OS back gesture/button from
/// navigating back to any previously authenticated route.
class _AuthGuard extends StatelessWidget {
  const _AuthGuard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Block back navigation completely on auth screens
      onPopInvokedWithResult: (didPop, _) {
        // No-op: back press on login/verify screens does nothing.
      },
      child: child,
    );
  }
}

class _LoadingPage extends StatefulWidget {
  const _LoadingPage();

  @override
  State<_LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<_LoadingPage> {
  @override
  void initState() {
    super.initState();
    // Safety timeout: if Firebase Auth has not responded in 6 seconds,
    // force the user to the login screen so they are never stuck on splash.
    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;
      final auth = context.read<AuthService>();
      if (auth.status == AuthStatus.initial ||
          auth.status == AuthStatus.loading) {
        auth.forceUnauthenticated();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logo_new.jpeg',
          width: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
