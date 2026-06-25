import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

enum ParentPinDialogMode { enter, set, change }

/// PIN entry dialog for parent-only actions.
Future<String?> showParentPinDialog(
  BuildContext context, {
  required ParentPinDialogMode mode,
  String? errorText,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: mode == ParentPinDialogMode.enter,
    builder: (context) => _ParentPinDialog(
      mode: mode,
      initialError: errorText,
    ),
  );
}

class _ParentPinDialog extends StatefulWidget {
  const _ParentPinDialog({
    required this.mode,
    this.initialError,
  });

  final ParentPinDialogMode mode;
  final String? initialError;

  @override
  State<_ParentPinDialog> createState() => _ParentPinDialogState();
}

class _ParentPinDialogState extends State<_ParentPinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _currentController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.mode) {
      case ParentPinDialogMode.enter:
        return 'Enter parent PIN';
      case ParentPinDialogMode.set:
        return 'Set parent PIN';
      case ParentPinDialogMode.change:
        return 'Change parent PIN';
    }
  }

  void _submit() {
    switch (widget.mode) {
      case ParentPinDialogMode.enter:
        final pin = _pinController.text.trim();
        if (pin.length < 4) {
          setState(() => _error = 'PIN must be at least 4 digits');
          return;
        }
        Navigator.pop(context, pin);
      case ParentPinDialogMode.set:
        final pin = _pinController.text.trim();
        final confirm = _confirmController.text.trim();
        if (pin.length < 4) {
          setState(() => _error = 'PIN must be at least 4 digits');
          return;
        }
        if (pin != confirm) {
          setState(() => _error = 'PINs do not match');
          return;
        }
        Navigator.pop(context, pin);
      case ParentPinDialogMode.change:
        final current = _currentController.text.trim();
        final pin = _pinController.text.trim();
        final confirm = _confirmController.text.trim();
        if (current.length < 4 || pin.length < 4) {
          setState(() => _error = 'PIN must be at least 4 digits');
          return;
        }
        if (pin != confirm) {
          setState(() => _error = 'New PINs do not match');
          return;
        }
        Navigator.pop(context, 'change:$current:$pin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.mode == ParentPinDialogMode.change) ...[
              _pinField(
                controller: _currentController,
                label: 'Current PIN',
              ),
              const SizedBox(height: 12),
            ],
            _pinField(
              controller: _pinController,
              label: widget.mode == ParentPinDialogMode.change
                  ? 'New PIN'
                  : 'PIN',
            ),
            if (widget.mode != ParentPinDialogMode.enter) ...[
              const SizedBox(height: 12),
              _pinField(
                controller: _confirmController,
                label: 'Confirm PIN',
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _pinField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 8,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onSubmitted: (_) => _submit(),
    );
  }
}
