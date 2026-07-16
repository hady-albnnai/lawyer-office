import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/permission_catalog.dart';
import '../../../data/database/database.dart' as db;
import '../../providers/auth_providers.dart';
import '../../providers/app_providers.dart';
import '../../providers/ui_data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../cases/case_models.dart';
import '../work_orders/work_order_dialogs.dart';
import '../work_orders/work_order_models.dart';

class DailyWorkCenterScreen extends ConsumerStatefulWidget {
  const DailyWorkCenterScreen({super.key});

  @override
  ConsumerState<DailyWorkCenterScreen> createState() => _DailyWorkCenterScreenState();
}

class _DailyWorkCenterScreenState extends ConsumerState<DailyWorkCenterScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  DateTime _calendarDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.cardBackground,
          appBar: AppBar(
            title: const Text('مكتب العمل'),
            actions: [
              _AddWorkButton(),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'طباعة لائحة العمل',
                icon: const Icon(Icons.print),
                onPressed: () => _showPrintComingSoon(context),
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              indicatorColor: AppColors.secondaryGold,
              labelColor: AppColors.secondaryGold,
              unselectedLabelColor: AppColors.textOnLight.withOpacity(0.75),
              tabs: const [
                Tab(text: 'اليوم'),
                Tab(text: 'الغد'),
                Tab(text: 'الأسبوع'),
                Tab(text: 'التقويم'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _DayWorkView(day: DateTime.now(), mode: _WorkViewMode.today),
              _DayWorkView(day: DateTime.now().add(const Duration(days: 1)), mode: _WorkViewMode.tomorrow),
              _WeekWorkView(startDay: DateTime.now()),
              _CalendarWorkView(
                selectedDay: _calendarDay,
                onChanged: (d) => setState(() => _calendarDay = d),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrintComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('سيتم تفعيل طباعة لائحة اليوم/الغد حسب المكلف ضمن مرحلة الطباعة والكشوف.'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}

enum _WorkViewMode { today, tomorrow, week, calendar }

class _WorkItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String entityRoute;
  final String assignedTo;
  final DateTime date;
  final TimeOfDay? time;
  final Color color;
  final IconData icon;
  final String priority;
  final String status;
  final bool needsResult;
  final VoidCallback? onResult;

  const _WorkItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.entityRoute,
    required this.assignedTo,
    required this.date,
    this.time,
    required this.color,
    required this.icon,
    this.priority = 'عادية',
    this.status = 'مجدول',
    this.needsResult = false,
    this.onResult,
  });
}

class _DayWorkView extends ConsumerWidget {
  final DateTime day;
  final _WorkViewMode mode;
  const _DayWorkView({required this.day, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _collectItemsForDay(context, ref, day, includeAttention: mode == _WorkViewMode.today);
    return _WorkList(
      title: mode == _WorkViewMode.today ? 'أعمال اليوم — إدخال النتائج' : 'أعمال الغد — التحضير والتوزيع',
      subtitle: mode == _WorkViewMode.today
          ? 'كل ما تاريخه اليوم يظهر هنا حسب صلاحياتك لإدخال النتائج والمتابعة.'
          : 'جهّز ملفات الغد ووزّع العمل قبل موعده.',
      day: day,
      items: items,
      mode: mode,
    );
  }
}

class _WeekWorkView extends ConsumerWidget {
  final DateTime startDay;
  const _WeekWorkView({required this.startDay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = <_WorkItem>[];
    for (var i = 0; i < 7; i++) {
      final day = DateTime(startDay.year, startDay.month, startDay.day).add(Duration(days: i));
      all.addAll(_collectItemsForDay(context, ref, day));
    }
    return _WorkList(
      title: 'أعمال الأسبوع',
      subtitle: 'رؤية قريبة للأعمال القادمة خلال سبعة أيام.',
      day: startDay,
      items: all,
      mode: _WorkViewMode.week,
      groupByDay: true,
    );
  }
}

class _CalendarWorkView extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onChanged;
  const _CalendarWorkView({required this.selectedDay, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 360,
          child: Card(
            margin: const EdgeInsets.all(16),
            child: CalendarDatePicker(
              initialDate: selectedDay,
              firstDate: DateTime(DateTime.now().year - 5),
              lastDate: DateTime(DateTime.now().year + 5),
              onDateChanged: onChanged,
            ),
          ),
        ),
        Expanded(
          child: _DayWorkView(day: selectedDay, mode: _WorkViewMode.calendar),
        ),
      ],
    );
  }
}

class _WorkList extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime day;
  final List<_WorkItem> items;
  final _WorkViewMode mode;
  final bool groupByDay;

  const _WorkList({
    required this.title,
    required this.subtitle,
    required this.day,
    required this.items,
    required this.mode,
    this.groupByDay = false,
  });

  @override
  Widget build(BuildContext context) {
    final attention = items.where((i) => i.priority == 'حرجة' || i.status.contains('متأخر') || i.type == 'نقص').toList();
    final regular = items.where((i) => !attention.contains(i)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(title: title, subtitle: subtitle, items: items),
        Expanded(
          child: items.isEmpty
              ? _empty()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (attention.isNotEmpty) ...[
                      _sectionTitle('يحتاج انتباه', AppColors.error),
                      ...attention.map((i) => _WorkItemCard(item: i, mode: mode)),
                      const SizedBox(height: 12),
                    ],
                    if (groupByDay)
                      ..._groupedByDate(regular)
                    else
                      ..._groupedByType(regular),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 72, color: AppColors.textSecondary.withOpacity(0.45)),
          const SizedBox(height: 16),
          Text('لا توجد أعمال ضمن هذا اليوم', style: AppTextStyles.headline6),
          const SizedBox(height: 8),
          Text('ستظهر هنا الجلسات والمراجعات وأوامر العمل والنواقص والمهام حسب تاريخها وصلاحياتك.', style: AppTextStyles.bodySmallSecondary, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  List<Widget> _groupedByType(List<_WorkItem> source) {
    final order = ['جلسة', 'تحضير', 'إجراء', 'أمر عمل', 'نقص', 'مهمة'];
    final widgets = <Widget>[];
    for (final type in order) {
      final group = source.where((i) => i.type == type).toList();
      if (group.isEmpty) continue;
      widgets.add(_sectionTitle(_labelForType(type), group.first.color));
      widgets.addAll(group.map((i) => _WorkItemCard(item: i, mode: mode)));
      widgets.add(const SizedBox(height: 10));
    }
    final rest = source.where((i) => !order.contains(i.type)).toList();
    if (rest.isNotEmpty) {
      widgets.add(_sectionTitle('أعمال أخرى', AppColors.primaryNavy));
      widgets.addAll(rest.map((i) => _WorkItemCard(item: i, mode: mode)));
    }
    return widgets;
  }

  List<Widget> _groupedByDate(List<_WorkItem> source) {
    final days = <String, List<_WorkItem>>{};
    for (final item in source) {
      final key = _date(item.date);
      days.putIfAbsent(key, () => []).add(item);
    }
    final widgets = <Widget>[];
    for (final entry in days.entries) {
      widgets.add(_sectionTitle(entry.key, AppColors.primaryNavy));
      widgets.addAll(entry.value.map((i) => _WorkItemCard(item: i, mode: mode)));
      widgets.add(const SizedBox(height: 10));
    }
    return widgets;
  }

  Widget _sectionTitle(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text, style: AppTextStyles.headline6.copyWith(color: color, fontWeight: FontWeight.bold)),
      );

  String _labelForType(String type) {
    switch (type) {
      case 'جلسة':
        return 'الجلسات';
      case 'تحضير':
        return 'تحضيرات ومراجعات';
      case 'إجراء':
        return 'الإجراءات والمعاملات';
      case 'أمر عمل':
        return 'أوامر العمل';
      case 'نقص':
        return 'النواقص';
      case 'مهمة':
        return 'مهام مخصصة';
      default:
        return type;
    }
  }

  String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_WorkItem> items;
  const _Header({required this.title, required this.subtitle, required this.items});

  @override
  Widget build(BuildContext context) {
    final sessions = items.where((i) => i.type == 'جلسة').length;
    final workOrders = items.where((i) => i.type == 'أمر عمل').length;
    final deficiencies = items.where((i) => i.type == 'نقص').length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.5))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headline5.copyWith(color: AppColors.primaryNavy)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmallSecondary),
              ],
            ),
          ),
          _metric('الأعمال', items.length, Icons.task_alt, AppColors.primaryNavy),
          const SizedBox(width: 8),
          _metric('جلسات', sessions, Icons.gavel, AppColors.info),
          const SizedBox(width: 8),
          _metric('أوامر', workOrders, Icons.assignment_ind, AppColors.success),
          const SizedBox(width: 8),
          _metric('نواقص', deficiencies, Icons.warning_amber, AppColors.error),
        ],
      ),
    );
  }

  Widget _metric(String label, int count, IconData icon, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(0.25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: color), const SizedBox(width: 5), Text('$label: $count')]),
      );
}

class _WorkItemCard extends StatelessWidget {
  final _WorkItem item;
  final _WorkViewMode mode;
  const _WorkItemCard({required this.item, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: item.color.withOpacity(0.12), child: Icon(item.icon, color: item.color)),
                const SizedBox(width: 10),
                Expanded(child: Text(item.title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold))),
                _tag(item.type, item.color),
                const SizedBox(width: 6),
                _tag(item.status, AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.subtitle, style: AppTextStyles.bodySmallSecondary),
            const SizedBox(height: 6),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _mini(Icons.event, _date(item.date)),
                if (item.time != null) _mini(Icons.access_time, item.time!.format(context)),
                _mini(Icons.person, item.assignedTo.isEmpty ? 'غير مكلف' : item.assignedTo),
                _mini(Icons.flag, item.priority),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (item.entityRoute.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('فتح الملف'),
                    onPressed: () => context.go(item.entityRoute),
                  ),
                if (item.needsResult && mode == _WorkViewMode.today && item.onResult != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.fact_check, size: 16),
                    label: const Text('إدخال نتيجة'),
                    onPressed: item.onResult,
                  ),
                if (mode == _WorkViewMode.tomorrow)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.assignment_ind, size: 16),
                    label: const Text('تعيين / تحضير'),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('سيتم تفعيل توزيع العمل والطباعة ضمن مرحلة المهام المخصصة.'), backgroundColor: AppColors.info),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: AppTextStyles.labelSmall.copyWith(color: color)),
      );

  Widget _mini(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 15, color: AppColors.textSecondary), const SizedBox(width: 4), Text(text, style: AppTextStyles.bodySmallSecondary)],
      );

  String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _AddWorkButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionServiceProvider);
    return PopupMenuButton<String>(
      tooltip: 'إضافة عمل',
      onSelected: (value) {
        switch (value) {
          case 'case':
            context.push('/cases/create');
            break;
          case 'procedure':
            context.push('/procedures/create');
            break;
          case 'company':
            context.push('/companies/create');
            break;
          case 'contract':
            context.push('/contracts/create');
            break;
          case 'work_order':
            showDialog(context: context, builder: (_) => const CreateWorkOrderDialog());
            break;
          case 'manual':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('سيتم تفعيل المهام المخصصة وقوالب نتائجها في المرحلة التالية.'), backgroundColor: AppColors.info),
            );
            break;
        }
      },
      itemBuilder: (_) => [
        if (permissions.can(PermissionKeys.casesCreateNew)) const PopupMenuItem(value: 'case', child: Text('دعوى جديدة')),
        if (permissions.can(PermissionKeys.proceduresCreate)) const PopupMenuItem(value: 'procedure', child: Text('إجراء / معاملة')),
        if (permissions.can(PermissionKeys.companiesCreate)) const PopupMenuItem(value: 'company', child: Text('شركة')),
        if (permissions.can(PermissionKeys.contractsCreate)) const PopupMenuItem(value: 'contract', child: Text('عقد')),
        if (permissions.can(PermissionKeys.workOrdersCreate)) const PopupMenuItem(value: 'work_order', child: Text('أمر عمل')),
        const PopupMenuItem(value: 'manual', child: Text('مهمة مخصصة')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton.icon(onPressed: null, icon: const Icon(Icons.add), label: const Text('إضافة عمل')),
      ),
    );
  }
}

List<_WorkItem> _collectItemsForDay(BuildContext context, WidgetRef ref, DateTime day, {bool includeAttention = false}) {
  final permissions = ref.watch(permissionServiceProvider);
  final items = <_WorkItem>[];

  bool sameDay(DateTime d) => d.year == day.year && d.month == day.month && d.day == day.day;

  if (permissions.can(PermissionKeys.casesView)) {
    final cases = ref.watch(uiCasesProvider).maybeWhen(data: (v) => v, orElse: () => const []);
    for (final c in cases) {
      for (final s in c.sessions) {
        if (sameDay(s.sessionDate)) {
          items.add(_WorkItem(
            id: 'session_${s.id}',
            type: 'جلسة',
            title: 'جلسة: ${c.caseNumber}',
            subtitle: '${c.title} • ${s.court}',
            entityRoute: '/cases/${c.id}',
            assignedTo: '',
            date: s.sessionDate,
            time: s.sessionTime,
            color: AppColors.primaryNavy,
            icon: Icons.gavel,
            priority: c.status == CaseStatus.completed ? 'عادية' : 'هامة',
            status: s.status.displayName,
            needsResult: permissions.can(PermissionKeys.casesResultEnter),
            onResult: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('سيتم فتح نافذة نتيجة الجلسة التفصيلية في مرحلة مكتب العمل.'), backgroundColor: AppColors.info),
            ),
          ));
        }
      }
    }
  }

  final tasks = ref.watch(tasksByDateProvider(day)).maybeWhen(data: (v) => v, orElse: () => const <db.DailyTask>[]);
  for (final t in tasks) {
    final allowed = switch (t.taskType) {
      'work_order_followup' => permissions.can(PermissionKeys.workOrdersView),
      'contract_reminder' => permissions.can(PermissionKeys.contractsView),
      'company_phase' => permissions.can(PermissionKeys.companiesView),
      'admin_step' => permissions.can(PermissionKeys.proceduresView),
      'session' => permissions.can(PermissionKeys.casesView),
      _ => true,
    };
    if (!allowed) continue;
    items.add(_WorkItem(
      id: 'task_${t.id}',
      type: _taskTypeLabel(t.taskType),
      title: t.title,
      subtitle: t.notes ?? t.taskType,
      entityRoute: _taskRoute(t),
      assignedTo: t.assignedTo ?? '',
      date: t.taskDate,
      time: _parseTime(t.taskTime),
      color: _taskColor(t.taskType),
      icon: _taskIcon(t.taskType),
      priority: t.priority >= 2 ? 'حرجة' : 'عادية',
      status: t.status == 2 ? 'تم' : 'مجدول',
      needsResult: true,
      onResult: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('سيتم تفعيل نتيجة المهمة والترحيل التلقائي في المرحلة التالية.'), backgroundColor: AppColors.info),
      ),
    ));
  }

  if (permissions.can(PermissionKeys.workOrdersView)) {
    final workOrders = ref.watch(uiWorkOrdersProvider).maybeWhen(data: (v) => v, orElse: () => const <WorkOrder>[]);
    for (final w in workOrders) {
      if (!sameDay(w.dueDate)) continue;
      items.add(_WorkItem(
        id: 'wo_${w.id}',
        type: 'أمر عمل',
        title: '${w.internalNumber} — ${w.orderTypeText}',
        subtitle: '${w.instructions} • المكلف: ${w.assignedToName}',
        entityRoute: '/work-orders',
        assignedTo: w.assignedToName,
        date: w.dueDate,
        color: AppColors.success,
        icon: Icons.assignment_ind,
        priority: w.priorityText,
        status: w.statusText,
        needsResult: permissions.can(PermissionKeys.workOrdersResultEnter),
        onResult: () => showDialog(context: context, builder: (_) => EnterWorkOrderResultDialog(workOrder: w)),
      ));
    }
  }

  if (includeAttention) {
    final deficiencies = ref.watch(openDeficienciesProvider(null)).maybeWhen(data: (v) => v, orElse: () => const <db.Deficiency>[]);
    for (final d in deficiencies.take(8)) {
      final allowed = d.entityType == 0 ? permissions.can(PermissionKeys.casesView) : true;
      if (!allowed) continue;
      items.add(_WorkItem(
        id: 'def_${d.id}',
        type: 'نقص',
        title: d.description ?? 'نقص في الملف',
        subtitle: d.fieldName ?? 'يحتاج استكمال',
        entityRoute: d.entityType == 0 ? '/cases/${d.entityId}' : '',
        assignedTo: '',
        date: day,
        color: AppColors.error,
        icon: Icons.warning_amber,
        priority: 'حرجة',
        status: 'مفتوح',
        needsResult: true,
        onResult: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('سيتم تفعيل إغلاق النواقص من مكتب العمل في المرحلة التالية.'), backgroundColor: AppColors.info),
        ),
      ));
    }
  }

  items.sort((a, b) {
    final at = a.time == null ? 9999 : a.time!.hour * 60 + a.time!.minute;
    final bt = b.time == null ? 9999 : b.time!.hour * 60 + b.time!.minute;
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : at.compareTo(bt);
  });
  return items;
}

String _taskTypeLabel(String raw) {
  switch (raw) {
    case 'session':
      return 'جلسة';
    case 'contract_reminder':
      return 'تذكير عقد';
    case 'company_phase':
      return 'تحضير';
    case 'admin_step':
      return 'إجراء';
    case 'work_order_followup':
      return 'أمر عمل';
    default:
      return 'مهمة';
  }
}

IconData _taskIcon(String raw) {
  switch (raw) {
    case 'session':
      return Icons.gavel;
    case 'contract_reminder':
      return Icons.description;
    case 'company_phase':
      return Icons.business;
    case 'admin_step':
      return Icons.assignment;
    case 'work_order_followup':
      return Icons.assignment_ind;
    default:
      return Icons.task_alt;
  }
}

Color _taskColor(String raw) {
  switch (raw) {
    case 'session':
      return AppColors.primaryNavy;
    case 'contract_reminder':
      return AppColors.info;
    case 'company_phase':
      return AppColors.secondaryGold;
    case 'admin_step':
      return AppColors.warning;
    case 'work_order_followup':
      return AppColors.success;
    default:
      return AppColors.textSecondary;
  }
}

String _taskRoute(db.DailyTask t) {
  switch (t.sourceType) {
    case 'cases':
      return '/cases/${t.sourceId ?? 0}';
    case 'contracts':
      return '/contracts/${t.sourceId ?? 0}';
    case 'companies':
      return '/companies/${t.sourceId ?? 0}';
    case 'admin_procedures':
      return '/procedures/${t.sourceId ?? 0}';
    case 'work_order':
      return '/work-orders';
    default:
      return '';
  }
}

TimeOfDay? _parseTime(String? raw) {
  if (raw == null || !raw.contains(':')) return null;
  final parts = raw.split(':');
  return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
}
