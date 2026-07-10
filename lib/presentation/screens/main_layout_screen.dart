/// الهيكل الرئيسي الموحّد: SideBar + ShellRoutes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../providers/office_settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/sidebar/nav_sidebar.dart';

/// غلاف التطبيق مع الشريط الجانبي الموحد.
class MainShellScreen extends ConsumerWidget {
  final Widget child;
  const MainShellScreen({super.key, required this.child});

  static const _shellRoutes = <String>{
    '/today',
    '/agenda',
    '/new-work',
    '/files',
    '/persons',
    '/work-orders',
    '/finance',
    '/documents',
    '/legal-library',
    '/search-reports',
    '/settings',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(officeSettingsProvider);
    final location = GoRouterState.of(context).uri.path;
    final selectedRoute = _shellRoutes.contains(location)
        ? location
        : (location.startsWith('/cases')
            ? '/files'
            : location.startsWith('/poa')
                ? '/persons'
                : '/today');

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
    // Keep sidebar selection in sync with current route.
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConstants.primaryNavy,
      elevation: 1,
      child: SizedBox(
        height: 56,
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
              const Spacer(),
              IconButton(
                tooltip: 'عمل جديد',
                onPressed: () => context.go('/new-work'),
                icon: const Icon(Icons.add_circle_outline, color: AppConstants.accentGold),
              ),
              IconButton(
                tooltip: 'أوامر العمل',
                onPressed: () => context.go('/work-orders'),
                icon: const Icon(Icons.assignment_ind_outlined, color: AppConstants.accentGold),
              ),
              IconButton(
                tooltip: 'البحث والتقارير',
                onPressed: () => context.go('/search-reports'),
                icon: const Icon(Icons.search, color: AppConstants.accentGold),
              ),
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

/// توافق خلفي: أي استدعاء قديم لـ MainLayoutScreen يذهب لليوم.
class MainLayoutScreen extends StatelessWidget {
  const MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // يُستخدم فقط كـ fallback؛ المسار الرئيسي ShellRoute.
    return const MainShellScreen(
      child: SizedBox.shrink(),
    );
  }
}
