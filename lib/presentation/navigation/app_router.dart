import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/cases/case_detail_screen.dart';
import '../screens/cases/cases_screen.dart';
import '../screens/cases/create_case_wizard.dart';
import '../screens/finance/finance_screen.dart';
import '../screens/main_layout_screen.dart';
import '../screens/new_work/new_work_screen.dart';
import '../screens/persons/person_detail_screen.dart';
import '../screens/persons/persons_screen.dart';
import '../screens/poa/poa_detail_screen.dart';
import '../screens/poa/poa_list_screen.dart';
import '../screens/search_reports/search_reports_screen.dart';

/// تكوين نظام الملاحة والتوجيه الموحد في التطبيق باستخدام GoRouter.
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
    GoRoute(
      path: '/new-work',
      name: 'new-work',
      builder: (BuildContext context, GoRouterState state) {
        return const NewWorkScreen();
      },
    ),
    GoRoute(
      path: '/search-reports',
      name: 'search-reports',
      builder: (BuildContext context, GoRouterState state) {
        return const SearchReportsScreen();
      },
    ),
    GoRoute(
      path: '/finance',
      name: 'finance',
      builder: (BuildContext context, GoRouterState state) {
        return const FinanceScreen();
      },
    ),
    GoRoute(
      path: '/persons',
      name: 'persons',
      builder: (BuildContext context, GoRouterState state) {
        return const PersonsScreen();
      },
    ),
    GoRoute(
      path: '/persons/:personId',
      name: 'person-detail',
      builder: (BuildContext context, GoRouterState state) {
        return PersonDetailScreen(personId: state.pathParameters['personId'] ?? '');
      },
    ),
    GoRoute(
      path: '/poa',
      name: 'poa',
      builder: (BuildContext context, GoRouterState state) {
        return const PoaListScreen();
      },
    ),
    GoRoute(
      path: '/poa/:agencyId',
      name: 'poa-detail',
      builder: (BuildContext context, GoRouterState state) {
        return PoaDetailScreen(agencyId: state.pathParameters['agencyId'] ?? '');
      },
    ),
    GoRoute(
      path: '/cases',
      name: 'cases',
      builder: (BuildContext context, GoRouterState state) {
        return const CasesScreen();
      },
    ),
    GoRoute(
      path: '/cases/create',
      name: 'case-create',
      builder: (BuildContext context, GoRouterState state) {
        return const CreateCaseWizard();
      },
    ),
    GoRoute(
      path: '/cases/:caseId',
      name: 'case-detail',
      builder: (BuildContext context, GoRouterState state) {
        final caseId = int.tryParse(state.pathParameters['caseId'] ?? '0') ?? 0;
        return CaseDetailScreen(caseId: caseId);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('خطأ في الملاحة: ${state.error}'),
    ),
  ),
);
