import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft sky-blue gradient matching the todoos splash artwork.
class TodoosBackground extends StatelessWidget {
  const TodoosBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: child,
    );
  }
}
