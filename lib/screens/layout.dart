import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppLayout extends StatelessWidget {
  final Widget child;

  const AppLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background (could be a subtle gradient or abstract shapes)
          Positioned(
            top: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Layout
          Row(
            children: [
              // Sidebar Navigation
              const _Sidebar(),
              // Main Content
              Expanded(
                child: ClipRect(
                  child: child.animate(key: ValueKey(GoRouterState.of(context).uri.toString()))
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.02, curve: Curves.easeOutCubic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();

    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Symbols.shield, size: 32, fill: 0, weight: 400),
                        const SizedBox(width: 12),
                        Text(
                          'V-SHIELD',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Protocol: VLESS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
              // Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  children: [
                    _NavItem(
                      icon: Symbols.grid_view,
                      label: 'Dashboard',
                      isSelected: currentRoute == '/',
                      onTap: () => context.go('/'),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                    _NavItem(
                      icon: Symbols.dns,
                      label: 'Servers',
                      isSelected: currentRoute == '/servers',
                      onTap: () => context.go('/servers'),
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                    _NavItem(
                      icon: Symbols.rss_feed,
                      label: 'Subscriptions',
                      isSelected: currentRoute == '/subscriptions',
                      onTap: () => context.go('/subscriptions'),
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                    _NavItem(
                      icon: Symbols.route,
                      label: 'Routing',
                      isSelected: currentRoute == '/routing',
                      onTap: () => context.go('/routing'),
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                    _NavItem(
                      icon: Symbols.settings_input_component,
                      label: 'Settings',
                      isSelected: currentRoute == '/settings',
                      onTap: () => context.go('/settings'),
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                  ],
                ),
              ),
              // Footer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _NavItem(
                      icon: Symbols.help_outline,
                      label: 'Support',
                      isSelected: false,
                      onTap: () {},
                      transparent: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool transparent;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
