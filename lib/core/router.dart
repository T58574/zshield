import 'package:go_router/go_router.dart';
import '../screens/layout.dart';
import '../screens/dashboard_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/routing_screen.dart';

import 'package:flutter/material.dart';

CustomTransitionPage buildPageWithDefaultTransition<T>({
  required BuildContext context, 
  required GoRouterState state, 
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => 
      FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 250),
  );
}

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => buildPageWithDefaultTransition(
            context: context, state: state, child: const DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/routing',
          pageBuilder: (context, state) => buildPageWithDefaultTransition(
            context: context, state: state, child: const RoutingScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => buildPageWithDefaultTransition(
            context: context, state: state, child: const SettingsScreen(),
          ),
        ),
      ],
    ),
  ],
);
