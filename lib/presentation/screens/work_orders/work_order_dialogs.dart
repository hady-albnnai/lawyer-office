/// حوارات أوامر العمل
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'work_order_models.dart';

class CreateWorkOrderDialog extends StatefulWidget {
  const CreateWorkOrderDialog({super.key});
  @override State<CreateWorkOrderDialog> createState() => _CreateWorkOrderDialogState();
}
class _CreateWorkOrderDialogState extends State<CreateWorkOrderDialog> {
  String _entityType = 'case'; final _entityIdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); final _phoneCtrl = TextEditingController();
  WorkOrderType _type = WorkOrderType.courtAttendance; WorkOrderPriority _priority = WorkOrderPriority.medium;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  final _instructionsCtrl = TextEditingController();
  @override void dispose() { _entityIdCtrl.dispose(); _nameCtrl.dispose(); _phoneCtrl.dispose(); _instructionsCtrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Dialog(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('إنشاء أمر عمل جديد', style: AppTextStyles.headline4.copyWith(color: AppColors.primaryNavy), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Text('الكيان المرتبط', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy)),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: DropdownButtonFormField(value: _entityType, items: const [DropdownMenuItem(value: 'case', child: Text('دعوى')), DropdownMenuItem(value: 'contract', child: Text('عقد')), DropdownMenuItem(value: 'company', child: Text('شركة')), DropdownMenuItem(value: 'procedure', child: Text('إجراء'))], onChanged: (v) => setState(() => _entityType = v!), decoration: InputDecoration(labelText: 'نوع الكيان', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))), const SizedBox(width: 12), Expanded(child: TextField(controller: _entityIdCtrl, decoration: InputDecoration(labelText: 'رقم الكيان', hintText: '2026/001', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))))]),
      const SizedBox(height: 16),
      Text('المكلف', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy)),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'الاسم', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))), const SizedBox(width: 12), Expanded(child: TextField(controller: _phoneCtrl, decoration: InputDecoration(labelText: 'الهاتف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), keyboardType: TextInputType.phone))]),
      const SizedBox(height: 16),
      DropdownButtonFormField(value: _type, items: WorkOrderType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(), onChanged: (v) => setState(() => _type = v!), decoration: InputDecoration(labelText: 'نوع الأمر', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      DropdownButtonFormField(value: _priority, items: WorkOrderPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName))).toList(), onChanged: (v) => setState(() => _priority = v!), decoration: InputDecoration(labelText: 'الأولوية', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      Row(children: [Expanded(child: Text('الموعد: ${_dueDate.year}-${_dueDate.month.toString().padLeft(2, "0")}-${_dueDate.day.toString().padLeft(2, "0")}', style: AppTextStyles.bodyMedium)), TextButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365))); if(d != null) setState(() => _dueDate = d); }, icon: const Icon(Icons.calendar_today), label: const Text('اختر'))]),
      const SizedBox(height: 16),
      TextField(controller: _instructionsCtrl, decoration: InputDecoration(labelText: 'التعليمات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), maxLines: 3),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')), const SizedBox(width: 12), ElevatedButton(onPressed: () { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء أمر العمل'), backgroundColor: AppColors.success)); }, child: const Text('إنشاء'))])
    ]))));
  }
}

class EnterWorkOrderResultDialog extends StatefulWidget {
  final WorkOrder workOrder;
  const EnterWorkOrderResultDialog({super.key, required this.workOrder});
  @override State<EnterWorkOrderResultDialog> createState() => _EnterWorkOrderResultDialogState();
}
class _EnterWorkOrderResultDialogState extends State<EnterWorkOrderResultDialog> {
  WorkOrderResultStatus? _status = WorkOrderResultStatus.completed;
  final _resultCtrl = TextEditingController(); final _nextDateCtrl = TextEditingController();
  final _expensesCtrl = TextEditingController(); final _notesCtrl = TextEditingController();
  @override void dispose() { _resultCtrl.dispose(); _nextDateCtrl.dispose(); _expensesCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Dialog(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('إدخال نتيجة أمر العمل', style: AppTextStyles.headline4.copyWith(color: AppColors.primaryNavy), textAlign: TextAlign.center),
      const SizedBox(height: 8), Text('الأمر: ${widget.workOrder.internalNumber}', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Text('نتيجة الأمر', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: WorkOrderResultStatus.values.map((s) => InkWell(onTap: () => setState(() => _status = s), borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: _status == s ? AppColors.primaryNavy.withOpacity(0.1) : AppColors.cardBackground, borderRadius: BorderRadius.circular(8), border: Border.all(color: _status == s ? AppColors.primaryNavy : AppColors.cardBorder, width: _status == s ? 2 : 0.5)), child: Text(s.displayName, style: AppTextStyles.bodySmall.copyWith(color: _status == s ? AppColors.primaryNavy : AppColors.textSecondary, fontWeight: _status == s ? FontWeight.bold : FontWeight.normal))))).toList()),
      const SizedBox(height: 16),
      Text('وصف النتيجة', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy)),
      const SizedBox(height: 8),
      TextField(controller: _resultCtrl, decoration: InputDecoration(labelText: 'النتيجة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), maxLines: 3),
      const SizedBox(height: 16),
      TextField(controller: _nextDateCtrl, decoration: InputDecoration(labelText: 'الموعد القادم', hintText: 'اختياري', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: Icon(Icons.calendar_today)), readOnly: true, onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365))); if(d != null) _nextDateCtrl.text = '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}'; }),
      const SizedBox(height: 16),
      TextField(controller: _expensesCtrl, decoration: InputDecoration(labelText: 'المصاريف', hintText: 'ل.س', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixText: 'ل.س '), keyboardType: TextInputType.number),
      const SizedBox(height: 16),
      TextField(controller: _notesCtrl, decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), maxLines: 3),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')), const SizedBox(width: 12), ElevatedButton(onPressed: () { if(_status != null) { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ النتيجة'), backgroundColor: AppColors.success)); } }, child: const Text('حفظ'))])
    ]))));
  }
}

class ApproveWorkOrderDialog extends StatelessWidget {
  final WorkOrder workOrder;
  const ApproveWorkOrderDialog({super.key, required this.workOrder});
  @override Widget build(BuildContext context) {
    return Dialog(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('اعتماد نتيجة أمر العمل', style: AppTextStyles.headline4.copyWith(color: AppColors.primaryNavy), textAlign: TextAlign.center),
      const SizedBox(height: 8), Text('الأمر: ${workOrder.internalNumber}', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      if(workOrder.resultStatus != null) ...[Column(children: [Text('النتيجة: ${workOrder.resultStatus!.displayName}', style: AppTextStyles.bodyMedium), const SizedBox(height: 8), if(workOrder.resultText != null) Text('الوصف: ${workOrder.resultText}', style: AppTextStyles.bodySmall), if(workOrder.nextDate != null) Text('الموعد القادم: ${workOrder.nextDate!.year}-${workOrder.nextDate!.month}-${workOrder.nextDate!.day}', style: AppTextStyles.bodySmall)])],
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.warning, width: 0.5)), child: Row(children: [Icon(Icons.info_outline, color: AppColors.warning, size: 20), const SizedBox(width: 8), Expanded(child: Text('بعد الاعتماد، سيتم معالجتها تلقائياً', style: AppTextStyles.bodySmall))])),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')), const SizedBox(width: 12), ElevatedButton(onPressed: () { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الاعتماد'), backgroundColor: AppColors.success)); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: AppColors.textOnLight), child: const Text('اعتماد'))])
    ])));
  }
}

class PrintWorkOrderDialog extends StatelessWidget {
  final WorkOrder workOrder;
  const PrintWorkOrderDialog({super.key, required this.workOrder});
  @override Widget build(BuildContext context) {
    return Dialog(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('طباعة أمر العمل', style: AppTextStyles.headline4.copyWith(color: AppColors.primaryNavy), textAlign: TextAlign.center),
      const SizedBox(height: 8), Text('الأمر: ${workOrder.internalNumber}', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Text('اختر طريقة الطباعة:', style: AppTextStyles.labelLarge),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: () { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم توليد PDF'), backgroundColor: AppColors.success)); }, icon: const Icon(Icons.picture_as_pdf), label: const Text('توليد PDF'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12))),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: () { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إرسال إلى الطابعة'), backgroundColor: AppColors.info)); }, icon: const Icon(Icons.print), label: const Text('طباعة مباشرة'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12))),
      const SizedBox(height: 24), TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء'))
    ])));
  }
}

class WhatsAppDialog extends StatelessWidget {
  final WorkOrder workOrder;
  const WhatsAppDialog({super.key, required this.workOrder});
  @override Widget build(BuildContext context) {
    final msg = 'مكتب المحامي - هادي فيصل البني\n\nرقم الأمر: ${workOrder.internalNumber}\nنوع الأمر: ${workOrder.orderTypeText}\n\nالمكلف: ${workOrder.assignedToName}\n\nالمطلوب: ${workOrder.instructions}\n\nالموعد: ${workOrder.dueDate.year}-${workOrder.dueDate.month.toString().padLeft(2, "0")}-${workOrder.dueDate.day.toString().padLeft(2, "0")}\n\nالرجاء إرسال صور المرفقات بعد الانتهاء.';
    return Dialog(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('إرسال عبر واتساب', style: AppTextStyles.headline4.copyWith(color: AppColors.primaryNavy), textAlign: TextAlign.center),
      const SizedBox(height: 8), Text('الأمر: ${workOrder.internalNumber}', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Text('نص الرسالة:', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder, width: 0.5)), child: Text(msg, style: AppTextStyles.bodySmall)),
      const SizedBox(height: 16),
      Row(children: [Icon(Icons.phone, color: AppColors.textSecondary, size: 18), const SizedBox(width: 8), Text('إلى: ${workOrder.assignedToName} - ${workOrder.assignedToPhone}', style: AppTextStyles.bodySmall)]),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')), const SizedBox(width: 12), ElevatedButton.icon(onPressed: () { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إرسال واتساب'), backgroundColor: AppColors.success)); }, icon: const Icon(Icons.message), label: const Text('إرسال واتساب'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: AppColors.textOnLight))])
    ])));
  }
}
