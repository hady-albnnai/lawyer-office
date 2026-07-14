import 'dart:typed_data';
/// حوارات أوامر العمل — تنفيذ حقيقي على SQLite + PDF + واتساب.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../providers/office_settings_provider.dart';
import '../../providers/ui_data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'work_order_models.dart';

String workOrderTypeToDb(WorkOrderType t) {
  switch (t) {
    case WorkOrderType.courtAttendance:
      return 'court_attendance';
    case WorkOrderType.documentPhotocopy:
      return 'document_photocopy';
    case WorkOrderType.feePayment:
      return 'fee_payment';
    case WorkOrderType.extractCopy:
      return 'extract_copy';
    case WorkOrderType.organizeAgency:
      return 'organize_agency';
    case WorkOrderType.notaryReview:
      return 'notary_review';
    case WorkOrderType.notificationFollowup:
      return 'notification_followup';
    case WorkOrderType.executionFollowup:
      return 'execution_followup';
    case WorkOrderType.commercialRegistry:
      return 'commercial_registry';
    case WorkOrderType.financialReview:
      return 'financial_review';
    case WorkOrderType.other:
      return 'other';
  }
}

String workOrderPriorityToDb(WorkOrderPriority p) {
  switch (p) {
    case WorkOrderPriority.high:
      return 'high';
    case WorkOrderPriority.low:
      return 'low';
    case WorkOrderPriority.medium:
      return 'medium';
  }
}

class CreateWorkOrderDialog extends ConsumerStatefulWidget {
  const CreateWorkOrderDialog({super.key});

  @override
  ConsumerState<CreateWorkOrderDialog> createState() => _CreateWorkOrderDialogState();
}

class _CreateWorkOrderDialogState extends ConsumerState<CreateWorkOrderDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _instructions = TextEditingController();
  final _entityId = TextEditingController(text: '1');
  WorkOrderType _type = WorkOrderType.courtAttendance;
  WorkOrderPriority _priority = WorkOrderPriority.medium;
  DateTime _due = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;

  @override
  void dispose() {
    // name.dispose();
    // phone.dispose();
    // instructions.dispose();
    // entityId.dispose();
    // super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إنشاء أمر عمل للمعقب'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'اسم المكلف *')),
              const SizedBox(height: 10),
              TextField(controller: _phone, decoration: const InputDecoration(labelText: 'هاتف المكلف')),
              const SizedBox(height: 10),
              DropdownButtonFormField<WorkOrderType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'نوع التكليف'),
                items: WorkOrderType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<WorkOrderPriority>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'الأولوية'),
                items: WorkOrderPriority.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName)))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v ?? _priority),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _entityId,
                decoration: const InputDecoration(labelText: 'معرف الملف المرتبط (دعوى/إجراء)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('موعد التنفيذ: ${_due.toString().substring(0, 10)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _due,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('ar', 'SY'),
                  );
                  if (picked != null) setState(() => _due = picked);
                },
              ),
              TextField(
                controller: _instructions,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'تعليمات الأستاذ'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'جارٍ الحفظ...' : 'إنشاء وحفظ'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('اسم المكلف إلزامي'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(workOrderRepositoryProvider);
      await repo.create(
        assignedToName: _name.text.trim(),
        assignedToPhone: _phone.text.trim(),
        orderType: workOrderTypeToDb(_type),
        priority: workOrderPriorityToDb(_priority),
        status: 'draft',
        dueDate: _due,
        instructions: _instructions.text.trim(),
        createdBy: 'المحامي',
        linkedEntityType: 0,
        linkedEntityId: int.tryParse(_entityId.text.trim()) ?? 0,
      );
      ref.invalidate(uiWorkOrdersProvider);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('تم إنشاء أمر العمل وحفظه'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحفظ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class EnterWorkOrderResultDialog extends ConsumerStatefulWidget {
  final WorkOrder workOrder;
  const EnterWorkOrderResultDialog({super.key, required this.workOrder});

  @override
  ConsumerState<EnterWorkOrderResultDialog> createState() => _EnterWorkOrderResultDialogState();
}

class _EnterWorkOrderResultDialogState extends ConsumerState<EnterWorkOrderResultDialog> {
  WorkOrderResultStatus? _status = WorkOrderResultStatus.completed;
  final _result = TextEditingController();
  DateTime? _nextDate;
  bool _saving = false;

  @override
  void dispose() {
    // result.dispose();
    // super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('نتيجة أمر ${widget.workOrder.internalNumber}'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<WorkOrderResultStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'نتيجة التنفيذ'),
              items: WorkOrderResultStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 10),
            TextField(controller: _result, maxLines: 3, decoration: const InputDecoration(labelText: 'تفاصيل النتيجة')),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_nextDate == null ? 'موعد لاحق (اختياري)' : 'موعد لاحق: ${_nextDate!.toString().substring(0, 10)}'),
              trailing: const Icon(Icons.event),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _nextDate = picked);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _saving ? null : _save, child: const Text('حفظ النتيجة')),
      ],
    );
  }

  Future<void> _save() async {
    if (_status == null) return;
    setState(() => _saving = true);
    try {
      final id = int.tryParse(widget.workOrder.id);
      if (id == null) throw Exception('معرف غير صالح');
      await ref.read(workOrderRepositoryProvider).enterResult(
            id: id,
            resultStatus: _status!.toString().split('.').last,
            resultText: _result.text.trim().isEmpty ? _status!.displayName : _result.text.trim(),
            nextDate: _nextDate,
            userRef: 'المكتب',
          );
      // بعد إدخال النتيجة تصبح بانتظار الاعتماد
      await ref.read(workOrderRepositoryProvider).setStatus(id, 'waiting_for_approval', userRef: 'المكتب');
      ref.invalidate(uiWorkOrdersProvider);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('تم حفظ النتيجة في قاعدة البيانات'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ApproveWorkOrderDialog extends ConsumerWidget {
  final WorkOrder workOrder;
  const ApproveWorkOrderDialog({super.key, required this.workOrder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('اعتماد نتيجة أمر العمل'),
      content: Text('اعتماد ${workOrder.internalNumber}؟\n${workOrder.resultText ?? ''}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: AppColors.textOnLight),
          onPressed: () async {
            final id = int.tryParse(workOrder.id);
            if (id == null) return;
            await ref.read(workOrderRepositoryProvider).approve(id, userRef: 'الأستاذ');
            ref.invalidate(uiWorkOrdersProvider);
            if (context.mounted) {
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('تم الاعتماد وحفظه'), backgroundColor: AppColors.success),
              );
            }
          },
          child: const Text('اعتماد'),
        ),
      ],
    );
  }
}

class PrintWorkOrderDialog extends ConsumerWidget {
  final WorkOrder workOrder;
  const PrintWorkOrderDialog({super.key, required this.workOrder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text('طباعة ${workOrder.internalNumber}'),
      content: const Text('سيتم توليد PDF رسمي وتحديث حالة الأمر إلى «مطبوع».'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('توليد PDF وحفظ الحالة'),
          onPressed: () async {
            final settings = ref.read(officeSettingsProvider).maybeWhen(
                  data: (s) => s,
                  orElse: () => const OfficeSettingsModel(
                    officeTitle: AppConstants.defaultOfficeTitle,
                    lawyerName: AppConstants.defaultLawyerName,
                    officeAddress: AppConstants.defaultAddress,
                    officePhone: AppConstants.defaultPhone,
                  ),
                );
            final bytes = await WorkOrderPdfBuilder.build(settings: settings, order: workOrder);
            final id = int.tryParse(workOrder.id);
            if (id != null) {
              await ref.read(workOrderRepositoryProvider).markPrinted(id, userRef: 'المكتب');
              ref.invalidate(uiWorkOrdersProvider);
            }
            await Printing.layoutPdf(onLayout: (_) async => bytes, name: '${workOrder.internalNumber}.pdf');
            if (context.mounted) {
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('تم توليد PDF وتحديث الحالة'), backgroundColor: AppColors.success),
              );
            }
          },
        ),
      ],
    );
  }
}

class WhatsAppDialog extends ConsumerWidget {
  final WorkOrder workOrder;
  const WhatsAppDialog({super.key, required this.workOrder});

  String _message(OfficeSettingsModel settings) {
    final due = '${workOrder.dueDate.year}-${workOrder.dueDate.month.toString().padLeft(2, '0')}-${workOrder.dueDate.day.toString().padLeft(2, '0')}';
    return '''
السلام عليكم ${workOrder.assignedToName}،
أمر عمل من ${settings.officeTitle}
الأستاذ: ${settings.lawyerName}
رقم الأمر: ${workOrder.internalNumber}
الملف: ${workOrder.linkedEntityType} ${workOrder.linkedEntityId}
المطلوب: ${workOrder.orderTypeText}
الموعد: $due
التعليمات: ${workOrder.instructions}
يرجى تنفيذ المطلوب وإرسال صور المرفقات إن وجدت.
'''.trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(officeSettingsProvider).maybeWhen(
          data: (s) => s,
          orElse: () => const OfficeSettingsModel(
            officeTitle: AppConstants.defaultOfficeTitle,
            lawyerName: AppConstants.defaultLawyerName,
            officeAddress: AppConstants.defaultAddress,
            officePhone: AppConstants.defaultPhone,
          ),
        );
    final msg = _message(settings);
    return AlertDialog(
      title: const Text('رسالة واتساب للمعقب'),
      content: SizedBox(
        width: 480,
        child: SelectableText(msg, style: AppTextStyles.bodyMedium),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('نسخ'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: msg));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('تم نسخ الرسالة'), backgroundColor: AppColors.info),
              );
            }
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.message),
          label: const Text('فتح واتساب وتحديث الحالة'),
          onPressed: () async {
            final phone = workOrder.assignedToPhone.replaceAll(RegExp(r'[^0-9]'), '');
            final uri = Uri.parse(
              phone.isEmpty
                  ? 'https://wa.me/?text=${Uri.encodeComponent(msg)}'
                  : 'https://wa.me/$phone?text=${Uri.encodeComponent(msg)}',
            );
            final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
            final id = int.tryParse(workOrder.id);
            if (id != null) {
              await ref.read(workOrderRepositoryProvider).markWhatsAppSent(id, userRef: 'المكتب');
              ref.invalidate(uiWorkOrdersProvider);
            }
            if (context.mounted) {
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'تم فتح واتساب وتحديث الحالة' : 'تم تحديث الحالة (تعذر فتح واتساب تلقائياً — انسخ الرسالة)'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class WorkOrderPdfBuilder {
  static Future<Uint8List> build({
    required OfficeSettingsModel settings,
    required WorkOrder order,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: bold),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(settings.officeTitle, style: pw.TextStyle(font: bold, fontSize: 18), textAlign: pw.TextAlign.center),
            pw.Text('الأستاذ: ${settings.lawyerName}', textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.Text('أمر عمل للمعقب', style: pw.TextStyle(font: bold, fontSize: 16), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 12),
            _row('رقم الأمر', order.internalNumber, bold),
            _row('المكلف', '${order.assignedToName} — ${order.assignedToPhone}', font),
            _row('النوع', order.orderTypeText, font),
            _row('الأولوية', order.priorityText, font),
            _row('الملف', '${order.linkedEntityType} ${order.linkedEntityId}', font),
            _row('الموعد', order.dueDate.toString().substring(0, 10), font),
            _row('الحالة', order.statusText, font),
            pw.SizedBox(height: 10),
            pw.Text('التعليمات:', style: pw.TextStyle(font: bold)),
            pw.Text(order.instructions.isEmpty ? '—' : order.instructions),
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('توقيع المعقب: ............'),
                pw.Text('ختم المكتب: ............'),
              ],
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  static pw.Widget _row(String k, String v, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(k, style: pw.TextStyle(font: font)), pw.Text(v, style: pw.TextStyle(font: font))],
      ),
    );
  }
}
