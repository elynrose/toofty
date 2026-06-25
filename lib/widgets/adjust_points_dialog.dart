import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/child_provider.dart';
import '../theme/app_colors.dart';

Future<void> showAdjustPointsDialog(
  BuildContext context, {
  required String childId,
  required String childName,
  required int currentPoints,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AdjustPointsDialog(
      childId: childId,
      childName: childName,
      currentPoints: currentPoints,
    ),
  );
}

class _AdjustPointsDialog extends StatefulWidget {
  const _AdjustPointsDialog({
    required this.childId,
    required this.childName,
    required this.currentPoints,
  });

  final String childId;
  final String childName;
  final int currentPoints;

  @override
  State<_AdjustPointsDialog> createState() => _AdjustPointsDialogState();
}

class _AdjustPointsDialogState extends State<_AdjustPointsDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentPoints}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number (0 or more)')),
      );
      return;
    }

    setState(() => _saving = true);
    await context.read<ChildProvider>().setPoints(widget.childId, value);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.childName}\'s points updated to $value'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _adjustBy(int delta) {
    final current = int.tryParse(_controller.text.trim()) ?? widget.currentPoints;
    final next = (current + delta).clamp(0, 999999);
    _controller.text = '$next';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Adjust points',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.childName,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Points',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _quickButton('-10', () => _adjustBy(-10)),
              const SizedBox(width: 8),
              _quickButton('-1', () => _adjustBy(-1)),
              const SizedBox(width: 8),
              _quickButton('+1', () => _adjustBy(1)),
              const SizedBox(width: 8),
              _quickButton('+10', () => _adjustBy(10)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _quickButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }
}
