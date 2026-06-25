import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/parent_pin_provider.dart';
import '../widgets/parent_pin_dialog.dart';

/// Returns true if the parent PIN is satisfied (already unlocked or verified).
///
/// When [requireConfigured] is false (e.g. opening Settings), access is allowed
/// until a PIN has been set. When true (e.g. adjusting points), a PIN must exist.
Future<bool> requireParentPin(
  BuildContext context, {
  bool requireConfigured = true,
}) async {
  final pinProvider = context.read<ParentPinProvider>();

  if (!pinProvider.isLoaded) return false;
  if (!pinProvider.hasPin) {
    if (!requireConfigured) return true;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set a parent PIN in Settings first.'),
        ),
      );
    }
    return false;
  }
  if (pinProvider.isUnlocked) return true;

  if (!context.mounted) return false;

  final entered = await showParentPinDialog(
    context,
    mode: ParentPinDialogMode.enter,
  );
  if (entered == null || !context.mounted) return false;

  final ok = await pinProvider.verifyPin(entered);
  if (ok) return true;

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incorrect PIN')),
    );
  }
  return false;
}
