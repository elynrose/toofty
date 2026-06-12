import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/child.dart';
import '../models/reward.dart';
import '../models/reward_claim.dart';
import '../providers/child_provider.dart';
import '../providers/rewards_provider.dart';
import 'add_reward_screen.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Claims & Rewards',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Claim Rewards'),
            Tab(text: 'Manage Rewards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ClaimRewardsTab(
            selectedChildId: _selectedChildId,
            onChildSelected: (id) => setState(() => _selectedChildId = id),
          ),
          const _ManageRewardsTab(),
        ],
      ),
    );
  }
}

class _ClaimRewardsTab extends StatelessWidget {
  final String? selectedChildId;
  final ValueChanged<String> onChildSelected;

  const _ClaimRewardsTab({
    required this.selectedChildId,
    required this.onChildSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChildProvider, RewardsProvider>(
      builder: (context, childProvider, rewardsProvider, _) {
        if (!childProvider.isInitialized || !rewardsProvider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final children = childProvider.children;
        if (children.isEmpty) {
          return _emptyState(
            icon: Icons.child_care,
            message: 'Add a child on the Home tab first',
          );
        }

        final childId = selectedChildId ?? childProvider.currentChild?.id ?? children.first.id;
        final child = children.firstWhere((c) => c.id == childId);
        final rewards = rewardsProvider.rewards;
        final claims = rewardsProvider.claimsForChild(childId);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: childId,
                      decoration: InputDecoration(
                        labelText: 'Claiming as',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: children
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        if (id != null) onChildSelected(id);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PointsBadge(points: child.points),
                ],
              ),
            ),
            if (rewards.isEmpty)
              Expanded(
                child: _emptyState(
                  icon: Icons.card_giftcard,
                  message: 'No rewards yet.\nParents can add them in Manage Rewards.',
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewards[index];
                    final canAfford = child.points >= reward.pointsRequired;
                    return _RewardClaimCard(
                      reward: reward,
                      canAfford: canAfford,
                      onClaim: () => _claimReward(context, child, reward),
                    );
                  },
                ),
              ),
            if (claims.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 18, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Text(
                      '${child.name}\'s claims',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: claims.length,
                  itemBuilder: (context, index) {
                    final claim = claims[index];
                    return _ClaimHistoryChip(claim: claim);
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _claimReward(
    BuildContext context,
    Child child,
    Reward reward,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claim reward?'),
        content: Text(
          'Spend ${reward.pointsRequired} points for "${reward.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Claim'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final childProvider = context.read<ChildProvider>();
    final rewardsProvider = context.read<RewardsProvider>();

    final success = await childProvider.spendPoints(
      child.id,
      reward.pointsRequired,
    );

    if (!success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough points')),
        );
      }
      return;
    }

    await rewardsProvider.recordClaim(
      childId: child.id,
      childName: child.name,
      reward: reward,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${child.name} claimed "${reward.name}"!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}

class _ManageRewardsTab extends StatelessWidget {
  const _ManageRewardsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<RewardsProvider>(
      builder: (context, provider, _) {
        if (!provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final rewards = provider.rewards;

        return Stack(
          children: [
            if (rewards.isEmpty)
              _emptyState(
                icon: Icons.add_shopping_cart,
                message: 'No rewards yet.\nTap + to add one for your kids.',
              )
            else
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  final reward = rewards[index];
                  return _ManageRewardTile(reward: reward);
                },
              ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddRewardScreen(),
                    ),
                  );
                },
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add),
                label: const Text('Add Reward'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ManageRewardTile extends StatelessWidget {
  final Reward reward;

  const _ManageRewardTile({required this.reward});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _RewardPhoto(path: reward.photoPath, size: 56),
        title: Text(
          reward.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${reward.pointsRequired} pts · ${currency.format(reward.price)}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddRewardScreen(existingReward: reward),
                ),
              );
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete reward?'),
                  content: Text('Remove "${reward.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<RewardsProvider>().deleteReward(reward.id);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _RewardClaimCard extends StatelessWidget {
  final Reward reward;
  final bool canAfford;
  final VoidCallback onClaim;

  const _RewardClaimCard({
    required this.reward,
    required this.canAfford,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: _RewardPhoto(path: reward.photoPath, size: double.infinity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${reward.pointsRequired} pts',
                      style: TextStyle(
                        fontSize: 13,
                        color: canAfford ? AppColors.primary : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  currency.format(reward.price),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canAfford ? onClaim : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      canAfford ? 'Claim' : 'Need more pts',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardPhoto extends StatelessWidget {
  final String? path;
  final double size;

  const _RewardPhoto({required this.path, required this.size});

  @override
  Widget build(BuildContext context) {
    if (path != null && File(path!).existsSync()) {
      return Image.file(
        File(path!),
        width: size == double.infinity ? null : size,
        height: size == double.infinity ? null : size,
        fit: BoxFit.cover,
      );
    }
    return Container(
      width: size == double.infinity ? null : size,
      height: size == double.infinity ? null : size,
      color: AppColors.primary.withOpacity(0.15),
      child: const Icon(Icons.card_giftcard, color: AppColors.primary, size: 32),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;

  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: AppColors.accent, size: 18),
          const SizedBox(width: 4),
          Text(
            '$points',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimHistoryChip extends StatelessWidget {
  final RewardClaim claim;

  const _ClaimHistoryChip({required this.claim});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.MMMd().format(claim.claimedAt);
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            claim.rewardName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            '$date · ${claim.pointsSpent} pts',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

Widget _emptyState({required IconData icon, required String message}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  );
}
