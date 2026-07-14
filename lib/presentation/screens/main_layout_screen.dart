/// الهيكل الرئيسي الموحّد: SideBar + ShellRoutes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../providers/office_settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/sidebar/nav_sidebar.dart';
import 'admin_procedures/create_procedure_screen.dart';
import 'cases/create_case_wizard.dart';
import 'companies/create_company_wizard.dart';
import 'contracts/create_contract_screen.dart';
import 'work_orders/work_order_dialogs.dart';

/// غلاف التطبيق مع الشريط الجانبي الموحد.
class MainShellScreen extends ConsumerWidget {
  final Widget child;
  const MainShellScreen({super.key, required this.child});

  static const _shellRoutes = <String>{
    '/today',
    '/agenda',
    '/files',
    '/persons',
    '/work-orders',
    '/finance',
    '/documents',
    '/legal-library',
    '/search-reports',
    '/settings',
    '/cases',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(officeSettingsProvider);
    final location = GoRouterState.of(context).uri.path;
    
    // نحدد المسار للـ Sidebar بناءً على بداية الرابط (مثلاً /cases/1 تقع ضمن الشؤون القانونية)
    String selectedRoute = '/today';
    if (location.startsWith('/cases')) selectedRoute = '/cases';
    else if (location.startsWith('/poa') || location.startsWith('/persons')) selectedRoute = '/persons';
    else if (location.startsWith('/work-orders')) selectedRoute = '/work-orders';
    else if (location.startsWith('/agenda')) selectedRoute = '/agenda';
    else if (location.startsWith('/finance')) selectedRoute = '/finance';
    else if (location.startsWith('/documents')) selectedRoute = '/documents';
    else if (location.startsWith('/legal-library')) selectedRoute = '/legal-library';
    else if (location.startsWith('/search-reports')) selectedRoute = '/search-reports';
    else if (location.startsWith('/settings')) selectedRoute = '/settings';
    else if (location.startsWith('/files')) selectedRoute = '/files';

    final officeName = settingsAsync.maybeWhen(
      data: (s) => s.officeTitle,
      orElse: () => AppConstants.defaultOfficeTitle,
    );
    final lawyerName = settingsAsync.maybeWhen(
      data: (s) => s.lawyerName,
      orElse: () => AppConstants.defaultLawyerName,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Row(
          children: [
            AppSidebar(
              items: getDefaultSidebarItems(),
              officeName: officeName,
              lawyerName: lawyerName,
              version: '6.2.0',
            ),
            // Force selected route highlight via provider sync
            _SidebarRouteSync(selectedRoute: selectedRoute),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.cardBorder),
            Expanded(
              child: Column(
                children: [
                  _TopBar(officeName: officeName, lawyerName: lawyerName),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarRouteSync extends ConsumerWidget {
  final String selectedRoute;
  const _SidebarRouteSync({required this.selectedRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(sidebarStateProvider);
      if (state.selectedRoute != selectedRoute) {
        ref.read(sidebarStateProvider.notifier).state =
            state.copyWith(selectedRoute: selectedRoute);
      }
    });
    return const SizedBox.shrink();
  }
}

class _TopBar extends StatelessWidget {
  final String officeName;
  final String lawyerName;
  const _TopBar({required this.officeName, required this.lawyerName});

  void _handleQuickAction(BuildContext context, String action) {
    switch (action) {
      case 'case':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateCaseWizard()));
        break;
      case 'company':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateCompanyWizard()));
        break;
      case 'contract':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateContractScreen()));
        break;
      case 'procedure':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateProcedureScreen()));
        break;
      case 'work_order':
        showDialog(context: context, builder: (_) => const CreateWorkOrderDialog());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConstants.primaryNavy,
      elevation: 1,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                officeName,
                style: AppTextStyles.headline6.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                lawyerName,
                style: AppTextStyles.bodySmall.copyWith(color: AppConstants.accentGold),
              ),
              
              const SizedBox(width: 48),
              
              // محرك البحث الشامل (Omnibar)
              Expanded(
                child: Container(
                  height: 40,
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.accentGold.withOpacity(0.3)),
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'بحث شامل (Ctrl+K)...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: AppConstants.accentGold),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (val) {
                      // سيتم ربط هذا لاحقاً بشاشة البحث المتقدم ومحرك FTS5
                      context.go('/search-reports');
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 24),
              
              // زر الإجراء السريع (Quick Add)
              PopupMenuButton<String>(
                tooltip: 'إجراء سريع',
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppConstants.accentGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: AppConstants.primaryNavy, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'إضافة سريع',
                        style: AppTextStyles.labelLarge.copyWith(color: AppConstants.primaryNavy, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                onSelected: (action) => _handleQuickAction(context, action),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'case',
                    child: ListTile(
                      leading: Icon(Icons.gavel, color: AppColors.primaryNavy),
                      title: Text('دعوى قضائية جديدة'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'work_order',
                    child: ListTile(
                      leading: Icon(Icons.assignment_ind, color: AppColors.success),
                      title: Text('أمر عمل لمعقب'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'company',
                    child: ListTile(
                      leading: Icon(Icons.business, color: AppColors.secondaryGold),
                      title: Text('تأسيس شركة'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'contract',
                    child: ListTile(
                      leading: Icon(Icons.description, color: AppColors.info),
                      title: Text('تنظيم عقد'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'procedure',
                    child: ListTile(
                      leading: Icon(Icons.assignment, color: AppColors.warning),
                      title: Text('إجراء إداري'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              IconButton(
                tooltip: 'الإعدادات',
                onPressed: () => context.go('/settings'),
                icon: const Icon(Icons.settings_outlined, color: AppConstants.accentGold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// توافق خلفي
class MainLayoutScreen extends StatelessWidget {
  const MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainShellScreen(child: SizedBox.shrink());
  }
}
