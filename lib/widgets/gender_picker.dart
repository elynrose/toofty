import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import '../models/child_gender.dart';

class GenderPicker extends StatelessWidget {
  final ChildGender selected;
  final ValueChanged<ChildGender> onSelected;

  const GenderPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ChildGender>(
      segments: ChildGender.values
          .map(
            (g) => ButtonSegment(
              value: g,
              label: Text(g.label),
            ),
          )
          .toList(),
      selected: {selected},
      onSelectionChanged: (values) => onSelected(values.first),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.textPrimary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.grey[100];
        }),
      ),
    );
  }
}
