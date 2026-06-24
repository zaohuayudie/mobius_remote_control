import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobius_desk_flutter/core/theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: const _BottomNav(),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/device')) currentIndex = 1;
    if (location.startsWith('/setting')) currentIndex = 2;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/connect');
            break;
          case 1:
            context.go('/device');
            break;
          case 2:
            context.go('/setting');
            break;
        }
      },
      destinations: [
        NavigationDestination(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.connect_without_contact_outlined, color: Colors.grey.shade500, size: 22),
          ),
          selectedIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.connect_without_contact, color: AppTheme.primaryColor, size: 22),
          ),
          label: '连接',
        ),
        NavigationDestination(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.devices_outlined, color: Colors.grey.shade500, size: 22),
          ),
          selectedIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.devices, color: AppTheme.primaryColor, size: 22),
          ),
          label: '设备',
        ),
        NavigationDestination(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.settings_outlined, color: Colors.grey.shade500, size: 22),
          ),
          selectedIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.settings, color: AppTheme.primaryColor, size: 22),
          ),
          label: '设置',
        ),
      ],
    );
  }
}
