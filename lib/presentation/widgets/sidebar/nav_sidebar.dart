/// SideBar الرئيسي لتطبيق مكتب المحامي
/// 
/// هذا الملف ينفذ SideBar حسب مواصفات
/// PRODUCT_REDESIGN_MASTER_PLAN.md - القسم 3.2
/// 
/// آخر تحديث: 2026-07-09

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/custom_icons.dart';
import 'sidebar_item.dart';
import 'badge_widget.dart';

/// حالة SideBar (موسع/مطوي)
class SidebarState {
  final bool isExpanded;
  final String? selectedRoute;
  
  const SidebarState({
    this.isExpanded = true,
    this.selectedRoute,
  });
  
  SidebarState copyWith({
    bool? isExpanded,
    String? selectedRoute,
  }) {
    return SidebarState(
      isExpanded: isExpanded ?? this.isExpanded,
      selectedRoute: selectedRoute ?? this.selectedRoute,
    );
  }
}

/// Provider لحالة SideBar
final sidebarStateProvider = StateProvider<SidebarState>((ref) {
  return const SidebarState(isExpanded: true);
});

/// SideBar الرئيسي
class NavSidebar extends ConsumerWidget {
  /// قائمة عناصر SideBar
  final List<SidebarItemModel> items;
  
  /// العنوان الذي يظهر في أعلى SideBar (اختياري)
  final Widget? header;
  
  /// التذييل الذي يظهر في أسفل SideBar (اختياري)
  final Widget? footer;
  
  /// عرض SideBar عند التوسعة
  final double expandedWidth;
  
  /// عرض SideBar عند الطي
  final double collapsedWidth;
  
  /// لون خلفية SideBar
  final Color backgroundColor;
  
  /// لون الظل
  final Color shadowColor;
  
  /// دالة عند تغيير حالة التوسعة
  final void Function(bool isExpanded)? onExpandedChanged;
  
  const NavSidebar({
    super.key,
    required this.items,
    this.header,
    this.footer,
    this.expandedWidth = 280,
    this.collapsedWidth = 70,
    this.backgroundColor = AppColors.sidebarBackground,
    this.shadowColor = AppColors.shadowMedium,
    this.onExpandedChanged,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sidebarStateProvider);
    final isExpanded = state.isExpanded;
    final selectedRoute = state.selectedRoute ?? GoRouterState.of(context).uri.toString();
    
    return Container(
      width: isExpanded ? expandedWidth : collapsedWidth,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (العنوان)
          if (header != null) ...[
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.center,
              child: header,
            ),
            const Divider(
              color: AppColors.cardBorder,
              height: 1,
              thickness: 0.5,
            ),
          ],
          
          // قائمة العناصر
          Expanded(
            child: SingleChildScrollView(
              child: SidebarItemList(
                items: items,
                isExpanded: isExpanded,
                selectedRoute: selectedRoute,
                onItemSelected: (item) {
                  // تحديث المسار المختار
                  ref.read(sidebarStateProvider.notifier).state = 
                      state.copyWith(selectedRoute: item.route);
                  
                  // التنقل إلى المسار
                  context.go(item.route);
                },
              ),
            ),
          ),
          
          // Footer (التذييل)
          if (footer != null) ...[
            const Divider(
              color: AppColors.cardBorder,
              height: 1,
              thickness: 0.5,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: footer,
            ),
          ],
          
          // زر طي/توسعة SideBar
          Container(
            height: 48,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder, width: 0.5),
            ),
            child: IconButton(
              icon: Icon(
                isExpanded ? Icons.chevron_left : Icons.chevron_right,
                color: AppColors.textPrimary,
                size: 24,
              ),
              tooltip: isExpanded ? 'طي SideBar' : 'توسيع SideBar',
              onPressed: () {
                final newState = !isExpanded;
                ref.read(sidebarStateProvider.notifier).state = 
                    state.copyWith(isExpanded: newState);
                onExpandedChanged?.call(newState);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// SideBar مع عنوان وتذييل افتراضي
class AppSidebar extends NavSidebar {
  /// اسم المكتب
  final String officeName;
  
  /// اسم المحامي
  final String lawyerName;
  
  /// الشعار (اختياري)
  final Widget? logo;
  
  /// نسخة التطبيق
  final String version;
  
  const AppSidebar({
    super.key,
    required List<SidebarItemModel> items,
    this.officeName = 'مكتب المحامي',
    this.lawyerName = 'هادي فيصل البني',
    this.logo,
    this.version = '1.0.0',
    super.expandedWidth = 280,
    super.collapsedWidth = 70,
  }) : super(items: items);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavSidebar(
      items: items,
      header: _buildHeader(context, ref),
      footer: _buildFooter(context, ref),
      expandedWidth: expandedWidth,
      collapsedWidth: collapsedWidth,
      onExpandedChanged: onExpandedChanged,
    );
  }
  
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(sidebarStateProvider).isExpanded;
    
    if (!isExpanded) {
      return logo ?? Icon(
        Icons.verified_user,
        color: AppColors.primaryNavy,
        size: 32,
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (logo != null) ...[
          logo!,
          const SizedBox(height: 4),
        ],
        Text(
          officeName,
          style: AppTextStyles.headline6.copyWith(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          lawyerName,
          style: AppTextStyles.bodySmallSecondary.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(sidebarStateProvider).isExpanded;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline,
          color: AppColors.textSecondary,
          size: 16,
        ),
        if (isExpanded) ...[
          const SizedBox(width: 8),
          Text(
            'الإصدار $version',
            style: AppTextStyles.bodySmallSecondary,
          ),
        ],
      ],
    );
  }
}

/// قائمة عناصر SideBar الافتراضية (11 تبويب)

/// مساحات العمل الستة (The 6 Workspaces)
List<SidebarItemModel> getDefaultSidebarItems() {
  return [
    const SidebarItemModel(
      id: 'workspace',
      label: 'مكتب العمل',
      icon: Icons.dashboard_outlined,
      route: '/today',
      children: [
        SidebarItemModel(id: 'ws_today', label: 'لوحة اليوم', icon: CustomIcons.todayDashboard, route: '/today'),
        SidebarItemModel(id: 'ws_agenda', label: 'الأجندة والتقويم', icon: CustomIcons.agenda, route: '/agenda'),
        SidebarItemModel(id: 'ws_tasks', label: 'المهام اليومية', icon: Icons.task_alt, route: '/tasks'),
        SidebarItemModel(id: 'ws_wo', label: 'أوامر العمل', icon: CustomIcons.workOrders, route: '/work-orders'),
      ],
    ),
    const SidebarItemModel(
      id: 'legal_matters',
      label: 'الشؤون القانونية',
      icon: Icons.gavel_outlined,
      route: '/cases',
      children: [
        SidebarItemModel(id: 'lm_cases', label: 'الدعاوى', icon: Icons.gavel, route: '/cases'),
        SidebarItemModel(id: 'lm_companies', label: 'الشركات', icon: Icons.business, route: '/companies'),
        SidebarItemModel(id: 'lm_contracts', label: 'العقود', icon: Icons.description, route: '/contracts'),
        SidebarItemModel(id: 'lm_procedures', label: 'الإجراءات الإدارية', icon: Icons.assignment, route: '/procedures'),
      ],
    ),
    const SidebarItemModel(
      id: 'directory',
      label: 'السجلات والجهات',
      icon: Icons.folder_shared_outlined,
      route: '/persons',
      children: [
        SidebarItemModel(id: 'dir_persons', label: 'الأشخاص والجهات', icon: CustomIcons.persons, route: '/persons'),
        SidebarItemModel(id: 'dir_poa', label: 'الوكالات', icon: Icons.verified_user_outlined, route: '/poa'),
        SidebarItemModel(id: 'dir_archive', label: 'الأرشيف الفيزيائي', icon: Icons.archive, route: '/archive'),
      ],
    ),
    const SidebarItemModel(
      id: 'resources',
      label: 'الموارد والمستندات',
      icon: Icons.library_books_outlined,
      route: '/documents',
      children: [
        SidebarItemModel(id: 'res_docs', label: 'المستندات الرقمية', icon: CustomIcons.documents, route: '/documents'),
        SidebarItemModel(id: 'res_library', label: 'المكتبة القانونية', icon: CustomIcons.legalLibrary, route: '/legal-library'),
        SidebarItemModel(id: 'res_printing', label: 'الطباعة والنماذج', icon: Icons.print, route: '/printing'),
      ],
    ),
    const SidebarItemModel(
      id: 'finance_admin',
      label: 'الإدارة والتقارير',
      icon: Icons.account_balance_wallet_outlined,
      route: '/finance',
      children: [
        SidebarItemModel(id: 'fa_finance', label: 'المالية والصندوق', icon: CustomIcons.finance, route: '/finance'),
        SidebarItemModel(id: 'fa_search', label: 'البحث والتقارير', icon: CustomIcons.searchReports, route: '/search-reports'),
      ],
    ),
    const SidebarItemModel(
      id: 'system_settings',
      label: 'إعدادات النظام',
      icon: CustomIcons.settings,
      route: '/settings',
    ),
  ];
}
