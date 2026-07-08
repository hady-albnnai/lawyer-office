/// شاشة الأجندة لتطبيق مكتب المحامي
/// 
/// هذه الشاشة تعرض الجدول الزمني للمحامي
/// حسب مواصفات PRODUCT_REDESIGN_MASTER_PLAN.md - القسم 5
/// 
/// آخر تحديث: 2026-07-09

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

final agendaProvider = Provider<AgendaData>((ref) => AgendaData(
  courtSessions: [
    CourtSession(id: '1', time: TimeOfDay(hour: 9, minute: 0), caseNumber: '2026/001', caseTitle: 'دعوى تعويض', court: 'محكمة دمشق الأولى', status: SessionStatus.scheduled),
    CourtSession(id: '2', time: TimeOfDay(hour: 10, minute: 30), caseNumber: '2026/002', caseTitle: 'استئناف', court: 'محكمة الاستئناف', status: SessionStatus.scheduled),
    CourtSession(id: '3', time: TimeOfDay(hour: 12, minute: 0), caseNumber: '2026/003', caseTitle: 'تجارية', court: 'محكمة دمشق الأولى', status: SessionStatus.scheduled),
  ],
  reviews: [ReviewItem(id: '1', time: TimeOfDay(hour: 14, minute: 0), title: 'مراجعة ديوان', caseNumber: '2026/004', status: ReviewStatus.scheduled)],
  overdueItems: [OverdueItem(id: '1', title: 'الدعوى 2026/006', dueDate: DateTime(2026, 7, 8), daysOverdue: 1, type: 'جلسة')],
  completedItems: [],
  expenses: [],
  tomorrowPreparations: [],
));

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
    final sessions = ref.watch(agendaProvider).courtSessions;
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: sessions.length, itemBuilder: (c, i) => _buildSessionCard(sessions[i], c));
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
    final reviews = ref.watch(agendaProvider).reviews;
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: reviews.length, itemBuilder: (c, i) => _buildReviewCard(reviews[i]));
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
    final items = ref.watch(agendaProvider).overdueItems;
    if(items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, size: 64, color: AppColors.success), const SizedBox(height: 16), Text('لا يوجد متأخرات', style: AppTextStyles.headline5)]));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Icon(Icons.warning, color: AppColors.error, size: 24),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(items[i].title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.error)), const SizedBox(height: 4), Text('متأخر ${items[i].daysOverdue} يوم', style: AppTextStyles.bodySmallSecondary), Text('${items[i].dueDate.year}-${items[i].dueDate.month}-${items[i].dueDate.day}', style: AppTextStyles.bodySmallSecondary)])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(items[i].type, style: AppTextStyles.labelSmall.copyWith(color: AppColors.error))),
    ]))));
  }
}

class TodayCompletedTab extends ConsumerWidget {
  const TodayCompletedTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(agendaProvider).completedItems;
    if(items.isEmpty) return Center(child: Text('لا يوجد منجزات', style: AppTextStyles.bodyMediumSecondary));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(items[i].title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
      const SizedBox(height: 4), Text(items[i].result, style: AppTextStyles.bodySmall),
      const SizedBox(height: 8), Text('${items[i].completionDate.year}-${items[i].completionDate.month}-${items[i].completionDate.day}', style: AppTextStyles.bodySmallSecondary),
    ]))));
  }
}

class TodayExpensesTab extends ConsumerWidget {
  const TodayExpensesTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(agendaProvider).expenses;
    if(items.isEmpty) return Center(child: Text('لا يوجد مصاريف', style: AppTextStyles.bodyMediumSecondary));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Icon(Icons.attach_money, color: AppColors.financeAlt, size: 24),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(items[i].description, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('${items[i].amount.toStringAsFixed(0)} ل.س', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold))])),
    ]))));
  }
}

class PrepareTomorrowTab extends ConsumerWidget {
  const PrepareTomorrowTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(agendaProvider).tomorrowPreparations;
    if(items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.date_range, size: 64, color: AppColors.primaryNavy), const SizedBox(height: 16), Text('لا يوجد تحضيرات', style: AppTextStyles.bodyMedium), const SizedBox(height: 8), Text('اضغط + لإضافة', style: AppTextStyles.bodySmallSecondary, textAlign: TextAlign.center)]));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Checkbox(value: items[i].isPrepared, onChanged: (v) {}),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(items[i].title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(items[i].description, style: AppTextStyles.bodySmallSecondary)])),
    ]))));
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
  void _submit() { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إضافة الجلسة'), backgroundColor: AppColors.success)); }
}
