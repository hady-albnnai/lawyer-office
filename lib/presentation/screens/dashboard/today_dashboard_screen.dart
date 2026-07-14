/// لوحة اليوم — بيانات حقيقية من SQLite (جلسات/مهام/أوامر عمل/نواقص).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../providers/ui_data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../agenda/result_entry_dialog.dart';
import '../work_orders/work_order_dialogs.dart';
import '../work_orders/work_order_models.dart';
import '../cases/case_models.dart';

class TodayDashboardScreen extends ConsumerWidget {
  const TodayDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(uiCasesProvider);
    final woAsync = ref.watch(uiWorkOrdersProvider);
    final tasksAsync = ref.watch(tasksByDateProvider(DateTime.now()));
    final deficienciesAsync = ref.watch(openDeficienciesProvider(null));

    return Theme(
      data: AppTheme.lightTheme,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('لوحة اليوم'),
            actions: [
              IconButton(
                tooltip: 'تحديث',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(uiCasesProvider);
                  ref.invalidate(uiWorkOrdersProvider);
                  ref.invalidate(tasksByDateProvider(DateTime.now()));
                  ref.invalidate(openDeficienciesProvider(null));
                },
              ),
              IconButton(
                tooltip: 'الأجندة',
                icon: const Icon(Icons.calendar_month),
                onPressed: () => context.go('/agenda'),
              ),
            ],
          ),
          body: casesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ: $e')),
            data: (cases) {
              final today = DateTime.now();
              bool sameDay(DateTime d) =>
                  d.year == today.year && d.month == today.month && d.day == today.day;

              final todaySessions = <_TodayItem>[];
              for (final c in cases) {
                for (final s in c.sessions) {
                  if (sameDay(s.sessionDate)) {
                    todaySessions.add(
                      _TodayItem(
                        time: s.sessionTime,
                        title: 'جلسة ${c.caseNumber}',
                        subtitle: '${c.title} • ${s.court}',
                        kind: 'جلسة',
                      ),
                    );
                  }
                }
                final next = c.nextSession?.sessionDate;
                if (next != null && sameDay(next) && c.sessions.isEmpty) {
                  todaySessions.add(
                    _TodayItem(
                      time: const TimeOfDay(hour: 9, minute: 0),
                      title: 'موعد ${c.caseNumber}',
                      subtitle: c.title,
                      kind: 'موعد',
                    ),
                  );
                }
              }

              final workOrders = woAsync.maybeWhen(data: (w) => w, orElse: () => const []);
              final pendingWo = workOrders
                  .where((w) =>
                      w.status == WorkOrderStatus.waitingForResult ||
                      w.status == WorkOrderStatus.waitingForApproval ||
                      w.status == WorkOrderStatus.draft ||
                      w.status == WorkOrderStatus.resultEntered)
                  .length;
              final overdueCases = cases.where((c) {
                final n = c.nextSession?.sessionDate;
                return n != null && n.isBefore(DateTime.now()) && c.status != CaseStatus.completed;
              }).length;
              final openDefs = deficienciesAsync.maybeWhen(data: (d) => d.length, orElse: () => 0);
              final tasksCount = tasksAsync.maybeWhen(data: (t) => t.length, orElse: () => 0);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'ملخص اليوم — ${today.toString().substring(0, 10)}',
                    style: AppTextStyles.headline5.copyWith(color: AppColors.primaryNavy),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _metric('جلسات اليوم', '${todaySessions.length}', Icons.gavel, AppColors.primaryNavy),
                      _metric('مهام اليوم', '$tasksCount', Icons.task_alt, AppColors.info),
                      _metric('أوامر بانتظار', '$pendingWo', Icons.assignment_ind, AppColors.warning),
                      _metric('ملفات متأخرة', '$overdueCases', Icons.schedule, AppColors.error),
                      _metric('نواقص مفتوحة', '$openDefs', Icons.warning_amber, AppColors.warning),
                      _metric('إجمالي الدعاوى', '${cases.length}', Icons.folder, AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('خط سير اليوم', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy)),
                  const SizedBox(height: 8),
                  if (todaySessions.isEmpty)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.event_available),
                        title: const Text('لا جلسات مسجّلة لهذا اليوم'),
                        subtitle: const Text('أضف جلسة من الأجندة أو حدّث مواعيد الدعاوى'),
                        trailing: TextButton(
                          onPressed: () => context.go('/agenda'),
                          child: const Text('الأجندة'),
                        ),
                      ),
                    )
                  else
                    ...todaySessions.map(
                      (item) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                            child: Text(
                              '${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(item.title),
                          subtitle: Text('${item.kind} • ${item.subtitle}'),
                          trailing: IconButton(
                            tooltip: 'تسجيل نتيجة',
                            icon: const Icon(Icons.edit_note),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => const ResultEntryDialog(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text('أوامر عمل تحتاج متابعة', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy)),
                  const SizedBox(height: 8),
                  ...workOrders.take(5).map(
                        (w) => Card(
                          child: ListTile(
                            title: Text('${w.internalNumber} — ${w.orderTypeText}'),
                            subtitle: Text('${w.assignedToName} • ${w.statusText}'),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () => context.go('/work-orders'),
                          ),
                        ),
                      ),
                  const SizedBox(height: 16),
                  Text('إجراءات سريعة', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => showDialog(context: context, builder: (_) => const ResultEntryDialog()),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('تسجيل نتيجة'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => showDialog(context: context, builder: (_) => const CreateWorkOrderDialog()),
                        icon: const Icon(Icons.assignment_add),
                        label: const Text('أمر عمل للمعقب'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/new-work'),
                        icon: const Icon(Icons.add),
                        label: const Text('عمل جديد'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/finance'),
                        icon: const Icon(Icons.payments),
                        label: const Text('المالية'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/cases'),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('الدعاوى'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _metric(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(title, style: AppTextStyles.bodySmallSecondary),
              Text(value, style: AppTextStyles.headline5.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayItem {
  final TimeOfDay time;
  final String title;
  final String subtitle;
  final String kind;
  _TodayItem({required this.time, required this.title, required this.subtitle, required this.kind});
}
