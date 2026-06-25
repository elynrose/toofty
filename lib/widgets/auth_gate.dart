import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_config_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/brushing_provider.dart';
import '../providers/child_provider.dart';
import '../providers/parent_pin_provider.dart';
import '../providers/rewards_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/main_shell.dart';
import '../theme/app_colors.dart';
import '../widgets/todoos_background.dart';

/// Routes signed-in users to the app and everyone else to [AuthScreen].
/// Loads tenant-scoped data per authenticated user id.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _boundUserId;
  bool _binding = false;

  Future<void> _bindTenant(String userId) async {
    if (_binding || _boundUserId == userId) return;

    setState(() => _binding = true);
    try {
      await Future.wait([
        context.read<AppConfigProvider>().loadRemoteConfig(),
        context.read<ChildProvider>().bindTenant(userId),
        context.read<ParentPinProvider>().bindTenant(userId),
        context.read<RewardsProvider>().bindTenant(userId),
        context.read<BrushingProvider>().bindTenant(userId),
      ]);
      if (mounted) {
        setState(() => _boundUserId = userId);
      }
    } finally {
      if (mounted) {
        setState(() => _binding = false);
      }
    }
  }

  Future<void> _clearTenant() async {
    if (_boundUserId == null && !_binding) return;

    setState(() => _binding = true);
    try {
      await Future.wait([
        context.read<ChildProvider>().bindTenant(null),
        context.read<ParentPinProvider>().bindTenant(null),
        context.read<RewardsProvider>().bindTenant(null),
        context.read<BrushingProvider>().bindTenant(null),
      ]);
      if (mounted) {
        setState(() => _boundUserId = null);
      }
    } finally {
      if (mounted) {
        setState(() => _binding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          if (_boundUserId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _clearTenant();
            });
          }
          return const AuthScreen(key: ValueKey('auth_screen'));
        }

        if (!auth.profileLoaded) {
          return const Scaffold(
            body: TodoosBackground(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        final userId = auth.user!.uid;
        if (_boundUserId != userId && !_binding) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _bindTenant(userId);
          });
        }

        if (_boundUserId != userId || _binding) {
          return const Scaffold(
            body: TodoosBackground(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        return MainShell(key: ValueKey('main_shell_$userId'));
      },
    );
  }
}
