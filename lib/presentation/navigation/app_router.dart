import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/agenda/agenda_screen.dart';
import '../screens/cases/case_detail_screen.dart';
import '../screens/cases/cases_screen.dart';
import '../screens/cases/create_case_wizard.dart';
import '../screens/dashboard/today_dashboard_screen.dart';
import '../screens/documents/documents_screen.dart';
import '../screens/finance/finance_screen.dart';
import '../screens/legal_library/legal_library_screen.dart';
import '../screens/main_layout_screen.dart';
import '../screens/new_work/new_work_screen.dart';
import '../screens/onboarding/first_run_setup_screen.dart';
import '../screens/persons/person_detail_screen.dart';
import '../screens/persons/persons_screen.dart';
import '../screens/poa/poa_detail_screen.dart';
import '../screens/poa/poa_list_screen.dart';
import '../screens/search_reports/search_reports_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/work_orders/work_orders_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final firstRun = ref.watch(firstRunCompletedProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final done = firstRun.maybeWhen(data: (v) => v, orElse: () => true);
      final onSetup = state.matchedLocation == '/setup';
      if (!done && !onSetup) return '/setup';
      if (done && onSetup) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/setup', name: 'setup', builder: (_, __) => const FirstRunSetupScreen()),
      GoRoute(path: '/', name: 'home', builder: (_, __) => const MainLayoutScreen()),
      GoRoute(path: '/today', name: 'today', builder: (_, __) => const TodayDashboardScreen()),
      GoRoute(path: '/agenda', name: 'agenda', builder: (_, __) => const AgendaScreen()),
      GoRoute(path: '/new-work', name: 'new-work', builder: (_, __) => const NewWorkScreen()),
      GoRoute(path: '/work-orders', name: 'work-orders', builder: (_, __) => const WorkOrdersScreen()),
      GoRoute(path: '/search-reports', name: 'search-reports', builder: (_, __) => const SearchReportsScreen()),
      GoRoute(path: '/finance', name: 'finance', builder: (_, __) => const FinanceScreen()),
      GoRoute(path: '/legal-library', name: 'legal-library', builder: (_, __) => const LegalLibraryScreen()),
      GoRoute(path: '/settings', name: 'settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/documents', name: 'documents', builder: (_, __) => const DocumentsScreen()),
      GoRoute(path: '/persons', name: 'persons', builder: (_, __) => const PersonsScreen()),
      GoRoute(
        path: '/persons/:personId',
        name: 'person-detail',
        builder: (_, state) => PersonDetailScreen(personId: state.pathParameters['personId'] ?? ''),
      ),
      GoRoute(path: '/poa', name: 'poa', builder: (_, __) => const PoaListScreen()),
      GoRoute(
        path: '/poa/:agencyId',
        name: 'poa-detail',
        builder: (_, state) => PoaDetailScreen(agencyId: state.pathParameters['agencyId'] ?? ''),
      ),
      GoRoute(path: '/cases', name: 'cases', builder: (_, __) => const CasesScreen()),
      GoRoute(path: '/cases/create', name: 'case-create', builder: (_, __) => const CreateCaseWizard()),
      GoRoute(
        path: '/cases/:caseId',
        name: 'case-detail',
        builder: (_, state) {
          final caseId = int.tryParse(state.pathParameters['caseId'] ?? '0') ?? 0;
          return CaseDetailScreen(caseId: caseId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('خطأ في الملاحة: ${state.error}')),
    ),
  );
});

/// توافق خلفي لبعض الاستدعاءات القديمة.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const MainLayoutScreen()),
  ],
);
