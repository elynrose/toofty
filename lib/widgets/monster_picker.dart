import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import '../models/monster_catalog.dart';

class MonsterPicker extends StatelessWidget {
  final String selectedMonsterId;
  final ValueChanged<String> onSelected;

  const MonsterPicker({
    super.key,
    required this.selectedMonsterId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MonsterCatalog.monsters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final monster = MonsterCatalog.monsters[index];
          final isSelected = monster.id == selectedMonsterId;
          return GestureDetector(
            onTap: () => onSelected(monster.id),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      MonsterCatalog.imageAsset(monster.id),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.pets,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  monster.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey[700],
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
