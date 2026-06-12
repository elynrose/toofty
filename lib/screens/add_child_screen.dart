import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/child.dart';
import '../models/child_gender.dart';
import '../models/monster_catalog.dart';
import '../providers/child_provider.dart';
import '../widgets/gender_picker.dart';
import '../widgets/monster_picker.dart';

/// Screen to add or edit a child profile.
class AddChildScreen extends StatefulWidget {
  final Child? existingChild;

  const AddChildScreen({super.key, this.existingChild});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late DateTime _selectedDateOfBirth;
  late ChildGender _selectedGender;
  late String _selectedMonsterId;

  bool get _isEditing => widget.existingChild != null;

  @override
  void initState() {
    super.initState();
    final child = widget.existingChild;
    if (child != null) {
      _nameController.text = child.name;
      _selectedDateOfBirth = child.dateOfBirth;
      _selectedGender = child.gender;
      _selectedMonsterId = child.monsterId;
    } else {
      _selectedDateOfBirth = DateTime.now().subtract(const Duration(days: 365 * 5));
      _selectedGender = ChildGender.none;
      _selectedMonsterId = MonsterCatalog.defaultId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChild() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final childProvider = context.read<ChildProvider>();

    if (_isEditing) {
      await childProvider.updateChildProfile(
        childId: widget.existingChild!.id,
        name: name,
        dateOfBirth: _selectedDateOfBirth,
        gender: _selectedGender,
        monsterId: _selectedMonsterId,
      );
    } else {
      await childProvider.addChild(
        name,
        _selectedDateOfBirth,
        gender: _selectedGender,
        monsterId: _selectedMonsterId,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDateOfBirth = picked);
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
          _isEditing ? 'Edit Child' : 'Add Child',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    MonsterCatalog.imageAsset(_selectedMonsterId),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.child_care,
                      size: 80,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _sectionTitle('Child\'s Name'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Enter name'),
                style: const TextStyle(fontSize: 18),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _sectionTitle('Date of birth'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  DateFormat.yMMMd().format(_selectedDateOfBirth),
                  style: const TextStyle(fontSize: 18),
                ),
                subtitle: const Text('Tap to choose date of birth'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateOfBirth,
              ),
              const SizedBox(height: 24),
              _sectionTitle('Gender'),
              GenderPicker(
                selected: _selectedGender,
                onSelected: (g) {
                  setState(() {
                    _selectedGender = g;
                    final suggested = MonsterCatalog.monsterForGender(g.name);
                    if (MonsterCatalog.isAvailable(suggested)) {
                      _selectedMonsterId = suggested;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),
              _sectionTitle('Choose a monster'),
              MonsterPicker(
                selectedMonsterId: _selectedMonsterId,
                onSelected: (id) => setState(() => _selectedMonsterId = id),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChild,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'Save Changes' : 'Add Child',
                    style: const TextStyle(
                      fontSize: 20,
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
