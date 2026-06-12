import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../models/brushing_settings.dart';
import '../models/brushing_activity.dart';
import '../providers/child_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late BrushingSettings _tempSettings;
  final Map<String, TextEditingController> _positionControllers = {};
  final Map<String, TextEditingController> _instructionControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      if (childProvider.currentChild != null) {
        setState(() {
          _tempSettings = childProvider.currentChild!.brushingSettings;
          // Initialize controllers for all activities
          for (var activity in _tempSettings.activities) {
            _positionControllers[activity.id] = TextEditingController(text: activity.positionName);
            _instructionControllers[activity.id] = TextEditingController(text: activity.instruction);
          }
        });
      }
    });
  }

  void _updateActivityDuration(int index, int newDuration) {
    setState(() {
      final activity = _tempSettings.activities[index];
      _tempSettings = _tempSettings.updateActivity(
        index,
        activity.copyWith(duration: newDuration),
      );
    });
    _autoSaveSettings();
  }

  void _updateActivityName(int index, String newName) {
    setState(() {
      final activity = _tempSettings.activities[index];
      _tempSettings = _tempSettings.updateActivity(
        index,
        activity.copyWith(positionName: newName),
      );
    });
    _autoSaveSettings();
  }

  void _updateActivityInstruction(int index, String newInstruction) {
    setState(() {
      final activity = _tempSettings.activities[index];
      _tempSettings = _tempSettings.updateActivity(
        index,
        activity.copyWith(instruction: newInstruction),
      );
    });
    _autoSaveSettings();
  }

  void _addNewActivity() {
    showDialog(
      context: context,
      builder: (context) => _AddActivityDialog(
        onAdd: (activity) {
          setState(() {
            _tempSettings = _tempSettings.addActivity(activity);
            // Initialize controllers for new activity
            _positionControllers[activity.id] = TextEditingController(text: activity.positionName);
            _instructionControllers[activity.id] = TextEditingController(text: activity.instruction);
          });
          _autoSaveSettings();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // Debounced auto-save to avoid too many writes
  Timer? _autoSaveTimer;
  void _autoSaveSettings() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () async {
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      if (childProvider.currentChild != null) {
        await childProvider.updateChildSettings(
          childProvider.currentChild!.id,
          _tempSettings,
        );
      }
    });
  }
  
  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    // Dispose all text controllers
    for (var controller in _positionControllers.values) {
      controller.dispose();
    }
    for (var controller in _instructionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    
    if (childProvider.currentChild == null) {
      return;
    }
    
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving settings...'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    
    // Save to phone storage
    try {
      await childProvider.updateChildSettings(
        childProvider.currentChild!.id,
        _tempSettings,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved for ${childProvider.currentChild!.name}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
    return '$secs seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Consumer<ChildProvider>(
          builder: (context, childProvider, _) {
            return Column(
              children: [
                const Text(
                  'Brushing Settings',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (childProvider.currentChild != null)
                  Text(
                    childProvider.currentChild!.name,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            );
          },
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Brushing Steps',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap and hold to reorder',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _addNewActivity,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Step'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Reorderable list of activities
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tempSettings.activities.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  _tempSettings = _tempSettings.reorderActivities(oldIndex, newIndex);
                });
                _autoSaveSettings();
              },
              itemBuilder: (context, index) {
                return _buildActivityCard(index, _tempSettings.activities[index]);
              },
            ),
          ),
          // Save button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(int index, BrushingActivityModel activity) {
    final positionController = _positionControllers[activity.id] ??
        TextEditingController(text: activity.positionName);
    final instructionController = _instructionControllers[activity.id] ??
        TextEditingController(text: activity.instruction);

    if (!_positionControllers.containsKey(activity.id)) {
      _positionControllers[activity.id] = positionController;
      _instructionControllers[activity.id] = instructionController;
    }

    return Card(
      key: ValueKey(activity.id),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.drag_handle,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  'Step ${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Position name field
            TextField(
              controller: positionController,
              decoration: InputDecoration(
                labelText: 'Position Name',
                hintText: 'e.g., Front, Left Side',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              onChanged: (value) => _updateActivityName(index, value),
            ),
            const SizedBox(height: 12),
            // Instruction field
            TextField(
              controller: instructionController,
              decoration: InputDecoration(
                labelText: 'Instruction',
                hintText: 'e.g., Brush the Front',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: const TextStyle(fontSize: 16),
              onChanged: (value) => _updateActivityInstruction(index, value),
            ),
            const SizedBox(height: 16),
            // Duration slider
            const Text(
              'Duration',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatTime(activity.duration),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Slider(
                    value: activity.duration.toDouble(),
                    min: 10,
                    max: 300,
                    divisions: 29,
                    activeColor: AppColors.primary,
                    onChanged: (value) => _updateActivityDuration(index, value.toInt()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for adding a new activity
class _AddActivityDialog extends StatefulWidget {
  final Function(BrushingActivityModel) onAdd;

  const _AddActivityDialog({required this.onAdd});

  @override
  State<_AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<_AddActivityDialog> {
  final _positionController = TextEditingController();
  final _instructionController = TextEditingController();
  int _duration = 60;

  @override
  void dispose() {
    _positionController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  void _addActivity() {
    if (_positionController.text.trim().isEmpty ||
        _instructionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newActivity = BrushingActivityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      positionName: _positionController.text.trim(),
      instruction: _instructionController.text.trim(),
      videoFileName: 'front',
      duration: _duration,
    );

    widget.onAdd(newActivity);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add New Step',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(
                labelText: 'Position Name',
                hintText: 'e.g., Front, Left Side',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructionController,
              decoration: const InputDecoration(
                labelText: 'Instruction',
                hintText: 'e.g., Brush the Front',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Duration: '),
                Expanded(
                  child: Slider(
                    value: _duration.toDouble(),
                    min: 10,
                    max: 300,
                    divisions: 29,
                    onChanged: (value) {
                      setState(() {
                        _duration = value.toInt();
                      });
                    },
                  ),
                ),
                Text('${_duration}s'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addActivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
