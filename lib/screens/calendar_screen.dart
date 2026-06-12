import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../models/child.dart';
import '../providers/child_provider.dart';

/// Screen showing weekly brushing calendar for children
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Child? _selectedChild;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childProvider = Provider.of<ChildProvider>(context, listen: false);
      if (childProvider.currentChild != null) {
        setState(() {
          _selectedChild = childProvider.currentChild;
        });
      } else if (childProvider.children.isNotEmpty) {
        setState(() {
          _selectedChild = childProvider.children.first;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Brushing Calendar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<ChildProvider>(
        builder: (context, childProvider, _) {
          if (childProvider.children.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
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
                ],
              ),
            );
          }

          // Use selected child or default to first
          final child = _selectedChild ?? childProvider.children.first;
          final weeklyHistory = childProvider.getWeeklyHistory(child.id);
          final now = DateTime.now();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Child selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Child>(
                      value: childProvider.children.firstWhere(
                        (c) => c.id == child.id,
                        orElse: () => childProvider.children.first,
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      items: childProvider.children.map((Child childItem) {
                        return DropdownMenuItem<Child>(
                          key: ValueKey(childItem.id),
                          value: childItem,
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    childItem.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(childItem.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (Child? newChild) {
                        if (newChild != null) {
                          setState(() {
                            _selectedChild = newChild;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Week header
                const Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                // Calendar grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final history = weeklyHistory[index];
                      final dayName = _getDayName(history.date.weekday);
                      final isFuture = history.date.isAfter(
                        DateTime(now.year, now.month, now.day),
                      );
                      final isToday = history.date.year == now.year &&
                          history.date.month == now.month &&
                          history.date.day == now.day;

                      return _DayCard(
                        dayName: dayName,
                        date: history.date,
                        completed: history.completed,
                        isFuture: isFuture,
                        isToday: isToday,
                        childId: child.id,
                        onLongPress: (date) {
                          _showClearConfirmationDialog(context, child.name, date, childProvider);
                        },
                      );
                    },
                  ),
                ),
                // Legend
                const SizedBox(height: 20),
                _buildLegend(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showClearConfirmationDialog(
    BuildContext context,
    String childName,
    DateTime date,
    ChildProvider childProvider,
  ) {
    final dateStr = '${_getDayName(date.weekday)}, ${date.month}/${date.day}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Clear Brushing Session?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Do you want to erase the brushing session(s) for $childName on $dateStr?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              await childProvider.clearSessionsForDate(
                childProvider.currentChild!.id,
                date,
              );
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Session cleared for $dateStr'),
                    backgroundColor: AppColors.accent,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Icons.check, Colors.green, 'Completed'),
          _buildLegendItem(Icons.close, Colors.red, 'Missed'),
          _buildLegendItem(Icons.remove, Colors.grey, 'Future'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}

/// Individual day card in the calendar grid
class _DayCard extends StatelessWidget {
  final String dayName;
  final DateTime date;
  final bool completed;
  final bool isFuture;
  final bool isToday;
  final String childId;
  final Function(DateTime) onLongPress;

  const _DayCard({
    required this.dayName,
    required this.date,
    required this.completed,
    required this.isFuture,
    required this.isToday,
    required this.childId,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;
    Color? iconColor;

    if (isFuture) {
      // Future days - gray
      backgroundColor = Colors.grey[300]!;
      textColor = Colors.grey[600]!;
      icon = null;
    } else if (completed) {
      // Completed - teal with white checkmark
      backgroundColor = AppColors.primary;
      textColor = Colors.white;
      icon = Icons.check;
      iconColor = Colors.white;
    } else {
      // Missed - teal with red X
      backgroundColor = AppColors.primary;
      textColor = Colors.white;
      icon = Icons.close;
      iconColor = Colors.red;
    }

    return GestureDetector(
      onLongPress: () {
        // Only allow clearing past or today's sessions, not future dates
        if (!isFuture && completed) {
          onLongPress(date);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(color: AppColors.textPrimary, width: 3)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(height: 8),
              Icon(
                icon,
                color: iconColor,
                size: 40,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
