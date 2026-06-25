import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/monster_catalog.dart';
import '../../models/reward.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/app_colors.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      return const Center(
        child: Text('Admin access required'),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Rewards'),
              Tab(text: 'Monsters'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _UsersTab(adminService: AdminService()),
                _RewardsTab(adminService: AdminService()),
                _MonstersTab(adminService: AdminService()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.adminService});

  final AdminService adminService;

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().user?.uid;

    return StreamBuilder<List<AppUserRecord>>(
      stream: adminService.watchUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('No users registered yet'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final user = users[index];
            final isSelf = user.uid == currentUid;

            return Card(
              child: ListTile(
                title: Text(user.email.isEmpty ? user.uid : user.email),
                subtitle: Text(
                  [
                    if (user.admin) 'Admin',
                    if (user.disabled) 'Disabled',
                    if (user.lastSeenAt != null)
                      'Last seen: ${user.lastSeenAt!.toLocal()}'.split('.').first,
                  ].join(' · '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isSelf)
                      Switch(
                        value: user.admin,
                        onChanged: (value) async {
                          try {
                            await adminService.setUserAdmin(user.uid, value);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                      ),
                    Switch(
                      value: !user.disabled,
                      onChanged: isSelf
                          ? null
                          : (enabled) async {
                              try {
                                await adminService.setUserDisabled(
                                  user.uid,
                                  !enabled,
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$e')),
                                  );
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RewardsTab extends StatefulWidget {
  const _RewardsTab({required this.adminService});

  final AdminService adminService;

  @override
  State<_RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<_RewardsTab> {
  List<Reward> _rewards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rewards = await widget.adminService.fetchDefaultRewards();
    if (!mounted) return;
    setState(() {
      _rewards = rewards.isNotEmpty
          ? rewards
          : context.read<AppConfigProvider>().defaultRewards;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await widget.adminService.saveDefaultRewards(_rewards);
    if (mounted) {
      context.read<AppConfigProvider>().applyDefaultRewardsLocally(_rewards);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default rewards saved')),
      );
    }
  }

  Future<void> _editReward([int? index]) async {
    final existing = index != null ? _rewards[index] : null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final pointsController = TextEditingController(
      text: existing?.pointsRequired.toString() ?? '50',
    );
    final priceController = TextEditingController(
      text: existing?.price.toStringAsFixed(2) ?? '0',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add default reward' : 'Edit reward'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(labelText: 'Points'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _rewards.removeAt(index!));
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final reward = Reward(
        id: existing?.id ?? 'default_${DateTime.now().millisecondsSinceEpoch}',
        name: nameController.text.trim(),
        pointsRequired: int.tryParse(pointsController.text.trim()) ?? 50,
        price: double.tryParse(priceController.text.trim()) ?? 0,
      );
      setState(() {
        if (index != null) {
          _rewards[index] = reward;
        } else {
          _rewards.add(reward);
        }
      });
    }

    nameController.dispose();
    pointsController.dispose();
    priceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Default rewards for new accounts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _rewards.length,
            itemBuilder: (context, index) {
              final reward = _rewards[index];
              return Card(
                child: ListTile(
                  title: Text(reward.name),
                  subtitle: Text(
                    '${reward.pointsRequired} pts · \$${reward.price.toStringAsFixed(2)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editReward(index),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _editReward(),
              icon: const Icon(Icons.add),
              label: const Text('Add default reward'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save default rewards'),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonstersTab extends StatefulWidget {
  const _MonstersTab({required this.adminService});

  final AdminService adminService;

  @override
  State<_MonstersTab> createState() => _MonstersTabState();
}

class _MonstersTabState extends State<_MonstersTab> {
  List<MonsterInfo> _monsters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final monsters = await widget.adminService.fetchAllMonstersConfig();
    if (!mounted) return;
    setState(() {
      _monsters = monsters;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await widget.adminService.saveMonsters(_monsters);
    if (mounted) {
      context.read<AppConfigProvider>().applyMonstersLocally(
            _monsters.where((m) => m.enabled).toList(),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monsters saved')),
      );
    }
  }

  Future<void> _editMonster(MonsterInfo monster) async {
    final nameController = TextEditingController(text: monster.name);
    var enabled = monster.enabled;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit monster'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${monster.id}'),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enabled'),
                value: enabled,
                onChanged: (value) => setDialogState(() => enabled = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      setState(() {
        final index = _monsters.indexWhere((m) => m.id == monster.id);
        _monsters[index] = monster.copyWith(
          name: nameController.text.trim(),
          enabled: enabled,
        );
      });
    }
    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _monsters.length,
            itemBuilder: (context, index) {
              final monster = _monsters[index];
              return Card(
                child: ListTile(
                  leading: Image.asset(
                    MonsterCatalog.imageAsset(monster.id),
                    width: 48,
                    height: 48,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.pets, color: AppColors.primary),
                  ),
                  title: Text(monster.name),
                  subtitle: Text(monster.enabled ? monster.id : '${monster.id} · disabled'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editMonster(monster),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save monsters'),
            ),
          ),
        ),
      ],
    );
  }
}
