import 'package:flutter/material.dart';

import '../widgets/todoos_background.dart';
import 'children_list_screen.dart';
import 'rewards_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    ChildrenListScreen(),
    RewardsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TodoosBackground(
        child: IndexedStack(
          index: _index,
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'Claims & Rewards',
          ),
        ],
      ),
    );
  }
}
