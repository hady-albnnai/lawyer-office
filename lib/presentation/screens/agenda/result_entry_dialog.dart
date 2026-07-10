/// حوار تسجيل نتيجة عمل — يحفظ في SQLite (مهمة يومية + خط زمني/نشاط).

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/app_enums.dart';
import '../../../data/database/database.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

enum WorkResultType {
  completed,
  completedWithNext,
  postponed,
  impossible,
  cancelled,
}

extension on WorkResultType {
  String get label {
    switch (this) {
      case WorkResultType.completed:
        return 'منجز نهائياً';
      case WorkResultType.completedWithNext:
        return 'منجز وولّد موعداً جديداً';
      case WorkResultType.postponed:
        return 'مؤجل بسبب';
      case WorkResultType.impossible:
        return 'متعذر بسبب';
      case WorkResultType.cancelled:
        return 'ملغى بسبب';
    }
  }

  int get lifecycleStatus {
    switch (this) {
      case WorkResultType.completed:
      case WorkResultType.completedWithNext:
        return LifecycleStatus.completed.index;
      case WorkResultType.postponed:
        return LifecycleStatus.postponed.index;
      case WorkResultType.cancelled:
        return LifecycleStatus.cancelled.index;
      case WorkResultType.impossible:
        return LifecycleStatus.cancelled.index;
    }
  }
}

class ResultEntryDialog extends ConsumerStatefulWidget {
  final int? taskId;
  final String? initialTitle;

  const ResultEntryDialog({super.key, this.taskId, this.initialTitle});

  @override
  ConsumerState<ResultEntryDialog> createState() => _ResultEntryDialogState();
}

class _ResultEntryDialogState extends ConsumerState<ResultEntryDialog> {
  WorkResultType? _selectedResult = WorkResultType.completed;
  final _notesController = TextEditingController();
  final _nextDateController = TextEditingController();
  final _titleController = TextEditingController();
  bool _clientAttended = false;
  bool _opponentAttended = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? 'نتيجة عمل يومي';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _nextDateController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit_note, color: AppColors.primaryNavy),
          const SizedBox(width: 8),
          Text('تسجيل نتيجة العمل', style: AppTextStyles.headline6),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'عنوان العمل/الجلسة'),
              ),
              const SizedBox(height: 12),
              Text('نتيجة العمل *', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              ...WorkResultType.values.map(
                (type) => RadioListTile<WorkResultType>(
                  title: Text(type.label, style: AppTextStyles.bodyMedium),
                  value: type,
                  groupValue: _selectedResult,
                  onChanged: (v) => setState(() => _selectedResult = v),
                  activeColor: AppColors.primaryNavy,
                ),
              ),
              if (_selectedResult == WorkResultType.completedWithNext ||
                  _selectedResult == WorkResultType.postponed) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _nextDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'الموعد القادم',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                  ),
                  onTap: _pickDate,
                ),
              ],
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('حضور الموكل'),
                value: _clientAttended,
                onChanged: (v) => setState(() => _clientAttended = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('حضور الخصم'),
                value: _opponentAttended,
                onChanged: (v) => setState(() => _opponentAttended = v ?? false),
              ),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'الملاحظات / السبب / قرار المحكمة',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _saving ? null : _submitResult,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: AppColors.textOnLight,
          ),
          child: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ النتيجة'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'SY'),
    );
    if (picked != null) {
      _nextDateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submitResult() async {
    final result = _selectedResult;
    if (result == null) return;
    if ((result == WorkResultType.completedWithNext || result == WorkResultType.postponed) &&
        _nextDateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('حدد الموعد القادم'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      final title = _titleController.text.trim().isEmpty ? 'نتيجة عمل' : _titleController.text.trim();
      final notes =
          '${result.label}\nحضور موكل: ${_clientAttended ? 'نعم' : 'لا'} | حضور خصم: ${_opponentAttended ? 'نعم' : 'لا'}\n${_notesController.text.trim()}';

      // حفظ كمهمة يومية مكتملة/مؤجلة
      final taskId = await db.into(db.dailyTasks).insert(
            DailyTasksCompanion.insert(
              taskType: 'manual_result',
              title: title,
              taskDate: DateTime(now.year, now.month, now.day),
              taskTime: Value('${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'),
              status: Value(result.lifecycleStatus),
              assignedTo: const Value('المحامي'),
              priority: const Value(1),
              sourceType: const Value('manual'),
              notes: Value(notes),
            ),
          );

      // موعد قادم كمهمة جديدة
      if (_nextDateController.text.trim().isNotEmpty) {
        final parts = _nextDateController.text.trim().split('-');
        if (parts.length == 3) {
          final next = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          await db.into(db.dailyTasks).insert(
                DailyTasksCompanion.insert(
                  taskType: 'follow_up',
                  title: 'متابعة: $title',
                  taskDate: next,
                  status: Value(LifecycleStatus.scheduled.index),
                  assignedTo: const Value('المحامي'),
                  priority: const Value(1),
                  sourceType: const Value('manual'),
                  notes: Value('مولَّد من نتيجة العمل #$taskId'),
                ),
              );
        }
      }

      await db.into(db.activityLog).insert(
            ActivityLogCompanion.insert(
              affectedTable: 'daily_tasks',
              recordId: taskId,
              action: 'insert',
              userRef: const Value('المحامي'),
              details: Value('تسجيل نتيجة عمل: ${result.label}'),
            ),
          );

      await db.into(db.timelineEvents).insert(
            TimelineEventsCompanion.insert(
              entityType: EntityType.caseEntity.index,
              entityId: 0,
              eventType: 'work_result_logged',
              eventDate: Value(now),
              description: 'تسجيل نتيجة: $title — ${result.label}',
              userRef: const Value('المحامي'),
            ),
          );

      ref.invalidate(tasksByDateProvider(DateTime.now()));

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حفظ نتيجة العمل في قاعدة البيانات'),
            backgroundColor: AppColors.success,
          ),
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
