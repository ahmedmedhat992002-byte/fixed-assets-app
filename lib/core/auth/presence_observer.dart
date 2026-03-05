import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

class PresenceObserver extends StatefulWidget {
  const PresenceObserver({super.key, required this.child});

  final Widget child;

  @override
  State<PresenceObserver> createState() => _PresenceObserverState();
}

class _PresenceObserverState extends State<PresenceObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final authService = context.read<AuthService>();

    if (state == AppLifecycleState.resumed) {
      authService.updatePresence(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      authService.updatePresence(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
