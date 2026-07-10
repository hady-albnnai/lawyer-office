/// شاشة أوامر العمل
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'work_order_models.dart';
import '../../providers/ui_data_providers.dart';
import 'work_order_dialogs.dart';

class WorkOrdersScreen extends ConsumerWidget {
  const WorkOrdersScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(length: 5, child: Scaffold(
      appBar: AppBar(title: const Text('أوامر العمل'), bottom: PreferredSize(preferredSize: const Size.fromHeight(48), child: Container(height: 48, margin: const EdgeInsets.symmetric(horizontal: 16), child: TabBar(isScrollable: true, indicatorSize: TabBarIndicatorSize.tab, indicator: UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.secondaryGold, width: 3)), labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold), unselectedLabelStyle: AppTextStyles.labelMedium, tabs: const [Tab(text: 'جميع الأوامر'), Tab(text: 'مسودة'), Tab(text: 'بانتظار نتيجة'), Tab(text: 'بانتظار اعتماد'), Tab(text: 'منجزة')]))), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.refresh(woProvider), tooltip: 'تحديث'), IconButton(icon: const Icon(Icons.add), onPressed: () => showDialog(context: context, builder: (c) => const CreateWorkOrderDialog()), tooltip: 'جديد')]),
      body: const TabBarView(children: [AllTab(), DraftTab(), PendingResultTab(), PendingApprovalTab(), CompletedTab()]),
    ));
  }
}

final woProvider = Provider<List<WorkOrder>>((ref) {
  final asyncWo = ref.watch(uiWorkOrdersProvider);
  return asyncWo.maybeWhen(data: (items) => items, orElse: () => const <WorkOrder>[]);
});


class AllTab extends ConsumerWidget { const AllTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final list = ref.watch(woProvider); return ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (c, i) => WOCard(wo: list[i])); } }
class DraftTab extends ConsumerWidget { const DraftTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final list = ref.watch(woProvider).where((w) => w.status == WorkOrderStatus.draft).toList(); return _buildList(list, context, 'لا يوجد مسودات'); } }
class PendingResultTab extends ConsumerWidget { const PendingResultTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final list = ref.watch(woProvider).where((w) => w.status == WorkOrderStatus.waitingForResult).toList(); return _buildList(list, context, 'لا يوجد بانتظار نتيجة'); } }
class PendingApprovalTab extends ConsumerWidget { const PendingApprovalTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final list = ref.watch(woProvider).where((w) => w.status == WorkOrderStatus.waitingForApproval).toList(); return _buildList(list, context, 'لا يوجد بانتظار اعتماد'); } }
class CompletedTab extends ConsumerWidget { const CompletedTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final list = ref.watch(woProvider).where((w) => w.status == WorkOrderStatus.approved).toList(); return _buildList(list, context, 'لا يوجد منجزة'); } }

Widget _buildList(List<WorkOrder> list, BuildContext ctx, String empty) => list.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.assignment, size: 64, color: AppColors.textSecondary), const SizedBox(height: 16), Text(empty, style: AppTextStyles.bodyMedium)])) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (c, i) => WOCard(wo: list[i]));

class WOCard extends StatelessWidget {
  final WorkOrder wo;
  const WOCard({super.key, required this.wo});
  @override Widget build(BuildContext context) {
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Text(wo.internalNumber, style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: wo.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(wo.statusText, style: AppTextStyles.labelSmall.copyWith(color: wo.statusColor)))]),
      const SizedBox(height: 8),
      Row(children: [Icon(Icons.person, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('المكلف: ${wo.assignedToName}', style: AppTextStyles.bodySmall), const SizedBox(width: 16), Icon(Icons.phone, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text(wo.assignedToPhone, style: AppTextStyles.bodySmall)]),
      const SizedBox(height: 4),
      Row(children: [Icon(Icons.work, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('النوع: ${wo.orderTypeText}', style: AppTextStyles.bodySmall), const SizedBox(width: 16), Icon(Icons.priority_high, color: _getPriorityColor(wo.priority), size: 16), const SizedBox(width: 4), Text('الأولوية: ${wo.priorityText}', style: AppTextStyles.bodySmall.copyWith(color: _getPriorityColor(wo.priority)))]),
      const SizedBox(height: 8), Text(wo.instructions, style: AppTextStyles.bodyMedium),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(4)), child: Text('الملف: ${wo.linkedEntityType == 'case' ? 'الدعوى' : 'الإجراء'} رقم ${wo.linkedEntityId}', style: AppTextStyles.bodySmallSecondary)),
      const SizedBox(height: 8),
      Row(children: [Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('الموعد: ${wo.dueDate.year}-${wo.dueDate.month.toString().padLeft(2, "0")}-${wo.dueDate.day.toString().padLeft(2, "0")}', style: AppTextStyles.bodySmall)]),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        if(wo.status == WorkOrderStatus.draft) TextButton.icon(onPressed: () => showDialog(context: context, builder: (c) => PrintWorkOrderDialog(workOrder: wo)), icon: const Icon(Icons.print, size: 16), label: const Text('طباعة')),
        if(wo.status == WorkOrderStatus.printed) TextButton.icon(onPressed: () => showDialog(context: context, builder: (c) => WhatsAppDialog(workOrder: wo)), icon: const Icon(Icons.message, size: 16), label: const Text('واتساب')),
        if(wo.status == WorkOrderStatus.whatsappSent || wo.status == WorkOrderStatus.printed) TextButton.icon(onPressed: () => showDialog(context: context, builder: (c) => EnterWorkOrderResultDialog(workOrder: wo)), icon: const Icon(Icons.input, size: 16), label: const Text('نتيجة')),
        if(wo.status == WorkOrderStatus.resultEntered) ElevatedButton.icon(onPressed: () => showDialog(context: context, builder: (c) => ApproveWorkOrderDialog(workOrder: wo)), icon: const Icon(Icons.check, size: 16), label: const Text('اعتماد'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: AppColors.textOnLight)),
      ])
    ])));
  }
  Color _getPriorityColor(WorkOrderPriority p) => p == WorkOrderPriority.high ? AppColors.error : p == WorkOrderPriority.medium ? AppColors.warning : AppColors.success;
}
