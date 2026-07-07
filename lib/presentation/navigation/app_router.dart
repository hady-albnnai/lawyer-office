import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/main_layout_screen.dart';

/// تكوين نظام الملاحة والتوجيه الموحد في التطبيق باستخدام GoRouter
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (BuildContext context, GoRouterState state) {
        return const MainLayoutScreen();
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('خطأ في الملاحة: ${state.error}'),
    ),
  ),
);
