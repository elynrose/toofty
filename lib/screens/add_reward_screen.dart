import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/reward.dart';
import '../providers/rewards_provider.dart';

class AddRewardScreen extends StatefulWidget {
  final Reward? existingReward;

  const AddRewardScreen({super.key, this.existingReward});

  @override
  State<AddRewardScreen> createState() => _AddRewardScreenState();
}

class _AddRewardScreenState extends State<AddRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pointsController = TextEditingController();
  final _priceController = TextEditingController();
  final _picker = ImagePicker();
  String? _photoPath;
  bool _saving = false;

  bool get _isEditing => widget.existingReward != null;

  @override
  void initState() {
    super.initState();
    final reward = widget.existingReward;
    if (reward != null) {
      _nameController.text = reward.name;
      _pointsController.text = reward.pointsRequired.toString();
      _priceController.text = reward.price.toStringAsFixed(2);
      _photoPath = reward.photoPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pointsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _photoPath = image.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final provider = context.read<RewardsProvider>();
    final name = _nameController.text.trim();
    final points = int.parse(_pointsController.text.trim());
    final price = double.parse(_priceController.text.trim());

    if (_isEditing) {
      final updated = widget.existingReward!.copyWith(
        name: name,
        pointsRequired: points,
        price: price,
      );
      final newPhoto = _photoPath != widget.existingReward!.photoPath
          ? _photoPath
          : null;
      await provider.updateReward(updated, newPhotoPath: newPhoto);
    } else {
      await provider.addReward(
        name: name,
        photoPath: _photoPath,
        pointsRequired: points,
        price: price,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Reward' : 'Add Reward',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: _photoPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(_photoPath!),
                              fit: BoxFit.cover,
                              width: 140,
                              height: 140,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: AppColors.primary),
                              SizedBox(height: 8),
                              Text('Add photo', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _buildLabel('Reward name'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('e.g. Ice cream trip'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 20),
              _buildLabel('Points required'),
              TextFormField(
                controller: _pointsController,
                decoration: _inputDecoration('e.g. 50'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter points';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildLabel('Price'),
              TextFormField(
                controller: _priceController,
                decoration: _inputDecoration('e.g. 5.99'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a price';
                  final n = double.tryParse(v.trim());
                  if (n == null || n < 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Add Reward',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
