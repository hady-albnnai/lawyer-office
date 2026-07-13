/// شاشة الأجندة لتطبيق مكتب المحامي
///
/// هذه الشاشة تعرض الجدول الزمني للمحامي
/// حسب مواصفات PRODUCT_REDESIGN_MASTER_PLAN.md - القسم 5
///
/// آخر تحديث: 2026-07-10

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/case_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../dashboard/today_dashboard_screen.dart';
import 'result_entry_dialog.dart';

/// شاشة الأجندة
class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأجندة'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.secondaryGold, width: 3),
                ),
                labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                unselectedLabelStyle: AppTextStyles.labelMedium,
                tabs: const [
                  Tab(text: 'جدول المحكمة'),
                  Tab(text: 'المراجعات'),
                  Tab(text: 'المتأخرات'),
                  Tab(text: 'منجز اليوم'),
                  Tab(text: 'مصاريف اليوم'),
                  Tab(text: 'تحضير الغد'),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.refresh(agendaProvider), tooltip: 'تحديث'),
            IconButton(icon: const Icon(Icons.today), onPressed: () => context.go('/today'), tooltip: 'لوحة اليوم'),
          ],
        ),
        body: const TabBarView(children: [CourtScheduleTab(), ReviewsTab(), OverdueTab(), TodayCompletedTab(), TodayExpensesTab(), PrepareTomorrowTab()]),
        floatingActionButton: FloatingActionButton(onPressed: () => showDialog(context: context, builder: (c) => const AddSessionDialog()), tooltip: 'إضافة جلسة', child: const Icon(Icons.add)),
      ),
    );
  }
}

/// مزود الأجندة الحقيقي من قاعدة البيانات
final agendaProvider = FutureProvider<AgendaData>((ref) async {
  final caseRepo = ref.watch(caseRepositoryProvider);
  final taskRepo = ref.watch(taskRepositoryProvider);

  final today = DateTime.now();
  final allCases = await caseRepo.getAllCases();
  final todayTasks = await taskRepo.watchTasksByDate(today).first;

  // جلسات اليوم من الدعاوى
  final courtSessions = <CourtSession>[];
  for (final c in allCases) {
    if (c.nextSessionDate != null && c.nextSessionDate!.day == today.day) {
      courtSessions.add(CourtSession(
        id: c.id.toString(),
        time: TimeOfDay(hour: 9, minute: 0),
        caseNumber: c.internalNumber,
        caseTitle: c.subject ?? 'دعوى',
        court: 'المحكمة',
        status: SessionStatus.scheduled,
      ));
    }
  }

  // المهام المجدولة اليوم
  final reviews = todayTasks
      .where((t) => t.status == 0)
      .map((t) => ReviewItem(
            id: t.id.toString(),
            time: TimeOfDay(hour: 14, minute: 0),
            title: t.title,
            caseNumber: '',
            status: ReviewStatus.scheduled,
          ))
      .toList();

  return AgendaData(
    courtSessions: courtSessions,
    reviews: reviews,
    overdueItems: [],
    completedItems: [],
    expenses: [],
    tomorrowPreparations: [],
  );
});

class AgendaData {
  final List<CourtSession> courtSessions;
  final List<ReviewItem> reviews;
  final List<OverdueItem> overdueItems;
  final List<CompletedItem> completedItems;
  final List<ExpenseItem> expenses;
  final List<TomorrowPreparation> tomorrowPreparations;
  AgendaData({required this.courtSessions, required this.reviews, required this.overdueItems, required this.completedItems, required this.expenses, required this.tomorrowPreparations});
}

enum SessionStatus { scheduled, completed, postponed, cancelled }
enum ReviewStatus { scheduled, completed, postponed, cancelled }

class CourtSession {
  final String id, caseNumber, caseTitle, court;
  final TimeOfDay time;
  final SessionStatus status;
  final bool? isClientAttended, isOpponentAttended;
  CourtSession({required this.id, required this.time, required this.caseNumber, required this.caseTitle, required this.court, required this.status, this.isClientAttended, this.isOpponentAttended});
}

class ReviewItem {
  final String id, title, caseNumber;
  final TimeOfDay time;
  final ReviewStatus status;
  ReviewItem({required this.id, required this.time, required this.title, required this.caseNumber, required this.status});
}

class OverdueItem {
  final String id, title, type;
  final DateTime dueDate;
  final int daysOverdue;
  OverdueItem({required this.id, required this.title, required this.dueDate, required this.daysOverdue, required this.type});
}

class CompletedItem {
  final String id, title, result;
  final DateTime completionDate;
  CompletedItem({required this.id, required this.title, required this.completionDate, required this.result});
}

class ExpenseItem {
  final String id, description;
  final double amount;
  final DateTime date;
  ExpenseItem({required this.id, required this.description, required this.amount, required this.date});
}

class TomorrowPreparation {
  final String id, title, description;
  final bool isPrepared;
  TomorrowPreparation({required this.id, required this.title, required this.description, this.isPrepared = false});
}

class CourtScheduleTab extends ConsumerWidget {
  const CourtScheduleTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(agendaProvider);
    return agendaAsync.when(
      data: (data) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.courtSessions.length,
        itemBuilder: (c, i) => _buildSessionCard(data.courtSessions[i], c),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildSessionCard(CourtSession s, BuildContext c) {
    Color col; String txt;
    switch(s.status) { case SessionStatus.completed: col=AppColors.success; txt='منجزة'; break; case SessionStatus.postponed: col=AppColors.warning; txt='مؤجلة'; break; case SessionStatus.cancelled: col=AppColors.error; txt='ملغاة'; default: col=AppColors.info; txt='مجدولة'; }
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      SizedBox(width: 60, child: Text('${s.time.hour}:${s.time.minute.toString().padLeft(2, "0")}', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy))),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.caseTitle, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('رقم ${s.caseNumber}', style: AppTextStyles.bodySmallSecondary),
        Text(s.court, style: AppTextStyles.bodySmallSecondary),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(txt, style: AppTextStyles.labelSmall.copyWith(color: col))),
      if(s.status == SessionStatus.scheduled) ...[const SizedBox(width: 8), IconButton(icon: const Icon(Icons.check_circle, color: AppColors.success), onPressed: () => showDialog(context: c, builder: (x) => const ResultEntryDialog()))],
    ])));
  }
}

class ReviewsTab extends ConsumerWidget {
  const ReviewsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(agendaProvider);
    return agendaAsync.when(
      data: (data) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.reviews.length,
        itemBuilder: (c, i) => _buildReviewCard(data.reviews[i]),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildReviewCard(ReviewItem r) {
    Color col; String txt;
    switch(r.status) { case ReviewStatus.completed: col=AppColors.success; txt='منجزة'; break; case ReviewStatus.postponed: col=AppColors.warning; txt='مؤجلة'; break; case ReviewStatus.cancelled: col=AppColors.error; txt='ملغاة'; default: col=AppColors.info; txt='مجدولة'; }
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      SizedBox(width: 60, child: Text('${r.time.hour}:${r.time.minute.toString().padLeft(2, "0")}', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy))),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('الدعوى ${r.caseNumber}', style: AppTextStyles.bodySmallSecondary)])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(txt, style: AppTextStyles.labelSmall.copyWith(color: col))),
    ])));
  }
}

class OverdueTab extends ConsumerWidget {
  const OverdueTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(agendaProvider);
    return agendaAsync.when(
      data: (data) {
        if (data.overdueItems.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, size: 64, color: AppColors.success), const SizedBox(height: 16), Text('لا يوجد متأخرات', style: AppTextStyles.headline5)]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.overdueItems.length,
          itemBuilder: (c, i) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Icon(Icons.warning, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data.overdueItems[i].title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.error)), const SizedBox(height: 4), Text('متأخر ${data.overdueItems[i].daysOverdue} يوم', style: AppTextStyles.bodySmallSecondary), Text('${data.overdueItems[i].dueDate.year}-${data.overdueItems[i].dueDate.month}-${data.overdueItems[i].dueDate.day}', style: AppTextStyles.bodySmallSecondary)])),Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(data.overdueItems[i].type, style: AppTextStyles.labelSmall.copyWith(color: AppColors.error))),
          ]))),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }
}

class TodayCompletedTab extends ConsumerWidget {
  const TodayCompletedTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(agendaProvider);
    return agendaAsync.when(
      data: (data) {
        if (data.completedItems.isEmpty) return Center(child: Text('لا يوجد منجزات', style: AppTextStyles.bodyMediumSecondary));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.completedItems.length,
          itemBuilder: (c, i) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(data.completedItems[i].title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
            const SizedBox(height: 4), Text(data.completedItems[i].result, style: AppTextStyles.bodySmall),
            const SizedBox(height: 8), Text('${data.completedItems[i].completionDate.year}-${data.completedItems[i].completionDate.month}-${data.completedItems[i].completionDate.day}', style: AppTextStyles.bodySmallSecondary),
          ]))),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }
}

class TodayExpensesTab extends ConsumerWidget {
  const TodayExpensesTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(agendaProvider);
    return agendaAsync.when(
      data: (data) {
        if (data.expenses.isEmpty) return Center(child: Text('لا يوجد مصاريف', style: AppTextStyles.bodyMediumSecondary));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.expenses.length,
          itemBuilder: (c, i) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Icon(Icons.attach_money, color: AppColors.secondaryGold, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data.expenses[i].description, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('${data.expenses[i].amount.toStringAsFixed(0)} ل.س', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold))]) ),
          ]))),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }
}

class PrepareTomorrowTab extends ConsumerWidget {
  const PrepareTomorrowTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(agendaProvider);
    return agendaAsync.when(
      data: (data) {
        if (data.tomorrowPreparations.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.date_range, size: 64, color: AppColors.primaryNavy), const SizedBox(height: 16), Text('لا يوجد تحضيرات', style: AppTextStyles.bodyMedium), const SizedBox(height: 8), Text('اضغط + لإضافة', style: AppTextStyles.bodySmallSecondary, textAlign: TextAlign.center)]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.tomorrowPreparations.length,
          itemBuilder: (c, i) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Checkbox(value: data.tomorrowPreparations[i].isPrepared, onChanged: (v) {}),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data.tomorrowPreparations[i].title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(data.tomorrowPreparations[i].description, style: AppTextStyles.bodySmallSecondary)]) ),
          ]))),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }
}

class AddSessionDialog extends StatefulWidget {
  const AddSessionDialog({super.key});
  @override
  State<AddSessionDialog> createState() => _AddSessionDialogState();
}

class _AddSessionDialogState extends State<AddSessionDialog> {
  final _caseNumberCtrl = TextEditingController();
  final _caseTitleCtrl = TextEditingController();
  final _courtCtrl = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();
  @override
  void dispose() { _caseNumberCtrl.dispose(); _caseTitleCtrl.dispose(); _courtCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Dialog(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('إضافة جلسة جديدة', style: AppTextStyles.headline5.copyWith(color: AppColors.primaryNavy), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      TextField(controller: _caseNumberCtrl, decoration: InputDecoration(labelText: 'رقم الدعوى', hintText: '2026/001', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextField(controller: _caseTitleCtrl, decoration: InputDecoration(labelText: 'عنوان الدعوى', hintText: 'دعوى تعويض', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextField(controller: _courtCtrl, decoration: InputDecoration(labelText: 'المحكمة', hintText: 'محكمة دمشق الأولى', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      Row(children: [Expanded(child: Text('وقت الجلسة:', style: AppTextStyles.bodyMedium)), TextButton.icon(onPressed: () => _selectTime(context), icon: const Icon(Icons.access_time), label: Text('${_time.hour}:${_time.minute.toString().padLeft(2, "0")}', style: AppTextStyles.bodyMedium))]),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')), const SizedBox(width: 12), ElevatedButton(onPressed: _submit, child: const Text('حفظ'))]),
    ])));
  }
  Future<void> _selectTime(BuildContext context) async {
    final t = await showTimePicker(context: context, initialTime: _time, builder: (c, ch) => Theme(data: Theme.of(c).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primaryNavy, onPrimary: AppColors.textOnLight, surface: AppColors.cardBackground, onSurface: AppColors.textPrimary)), child: ch!));
    if(t != null) setState(() => _time = t);
  }
  void _submit() async {
    try {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تسجيل الجلسة في الواجهة — استخدم لوحة اليوم/المهام للمتابعة'), backgroundColor: AppColors.success));
    } catch (_) {
      Navigator.of(context).pop();
    }
  }
}