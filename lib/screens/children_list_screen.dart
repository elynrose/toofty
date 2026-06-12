import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'package:provider/provider.dart';

import '../models/child.dart';
import '../models/child_gender.dart';
import '../models/monster_catalog.dart';
import '../providers/child_provider.dart';
import 'add_child_screen.dart';

/// Home screen showing all children with their scores
class ChildrenListScreen extends StatelessWidget {
  const ChildrenListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'todoos',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ChildProvider>(
        builder: (context, childProvider, _) {
          if (!childProvider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (childProvider.children.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.child_care,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No children added yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add-child');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Child'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a child to start brushing:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: childProvider.children.length,
                    itemBuilder: (context, index) {
                      final child = childProvider.children[index];
                      return _ChildCard(
                        child: child,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddChildScreen(existingChild: child),
                            ),
                          );
                        },
                        onTap: () async {
                          // Set as current child
                          await childProvider.setCurrentChild(child);
                          // Navigate to brushing screen
                          if (context.mounted) {
                            Navigator.pushNamed(context, '/brushing');
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add-child');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Child'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Card widget displaying child information
class _ChildCard extends StatelessWidget {
  final Child child;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ChildCard({
    required this.child,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);
    final todayCount = childProvider.getTodaySessionCount(child.id);
    final canBrush = childProvider.canBrushToday(child.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: canBrush ? onTap : () {
          // Show message that limit is reached
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${child.name} has already brushed twice today! Come back tomorrow! 🦷✨'),
              backgroundColor: AppColors.accent,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      MonsterCatalog.imageAsset(child.monsterId),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: (canBrush ? AppColors.primary : Colors.grey)
                            .withValues(alpha: 0.2),
                        child: Center(
                          child: Text(
                            child.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: canBrush ? AppColors.primary : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (child.gender != ChildGender.none)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.white,
                        child: Icon(
                          child.gender == ChildGender.male
                              ? Icons.male
                              : Icons.female,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              // Name, date of birth, and today's brushing count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Born ${child.formattedDateOfBirth}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      child.monsterName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.cleaning_services,
                          size: 16,
                          color: todayCount == 2 ? Colors.green : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Today: $todayCount/2',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: todayCount == 2 ? Colors.green : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
                tooltip: 'Edit child',
                onPressed: onEdit,
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${child.points}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'points',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
