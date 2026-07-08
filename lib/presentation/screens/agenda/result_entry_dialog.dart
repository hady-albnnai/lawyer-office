/// نافذة تسجيل نتيجة العمل
/// 
/// حسب مواصفات PRODUCT_REDESIGN_MASTER_PLAN.md - القسم 5
/// 
/// آخر تحديث: 2026-07-09

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// أنواع نتائج العمل
enum ResultStatus {
  completed,    // منجز نهائياً
  generated,    // منجز وولّد موعداً جديداً
  postponed,    // مؤجل بسبب
  impossible,   // متعذر بسبب
  cancelled,    // ملغى بسبب
}

/// نافذة تسجيل نتيجة الجلسة
class ResultEntryDialog extends StatefulWidget {
  const ResultEntryDialog({super.key});

  @override
  State<ResultEntryDialog> createState() => _ResultEntryDialogState();
}

class _ResultEntryDialogState extends State<ResultEntryDialog> {
  ResultStatus? _selectedResult;
  final TextEditingController _decisionController = TextEditingController();
  final TextEditingController _nextDateController = TextEditingController();
  final TextEditingController _requiredController = TextEditingController();
  final TextEditingController _expensesController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool _clientAttended = true;
  bool _opponentAttended = true;
  bool _opponentLawyerAttended = true;

  @override
  void dispose() {
    _decisionController.dispose();
    _nextDateController.dispose();
    _requiredController.dispose();
    _expensesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تسجيل نتيجة العمل',
                style: AppTextStyles.headline4.copyWith(color: AppColors.primaryNavy),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text('اختر نتيجة العمل:', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ResultStatus.values.map((status) => _buildResultOption(status)).toList(),
              ),
              const SizedBox(height: 16),
              if (_selectedResult == ResultStatus.completed || _selectedResult == ResultStatus.generated) ...[
                _buildSectionTitle('تفاصيل النتيجة'),
                const SizedBox(height: 8),
                TextField(
                  controller: _decisionController,
                  decoration: InputDecoration(
                    labelText: 'قرار المحكمة',
                    hintText: 'ادخل نص القرار',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('حضور الموكل'),
                        value: _clientAttended,
                        onChanged: (value) => setState(() => _clientAttended = value!),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('حضور الخصم'),
                        value: _opponentAttended,
                        onChanged: (value) => setState(() => _opponentAttended = value!),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  title: const Text('حضور محامي الخصم'),
                  value: _opponentLawyerAttended,
                  onChanged: (value) => setState(() => _opponentLawyerAttended = value!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: 12),
                if (_selectedResult == ResultStatus.generated) ...[
                  TextField(
                    controller: _nextDateController,
                    decoration: InputDecoration(
                      labelText: 'الموعد القادم',
                      hintText: 'ادخل تاريخ الموعد القادم',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _requiredController,
                    decoration: InputDecoration(
                      labelText: 'المطلوب القادم',
                      hintText: 'ما المطلوب في الموعد القادم؟',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 2,
                  ),
                ],
              ],
              if (_selectedResult == ResultStatus.postponed) ...[
                _buildSectionTitle('سبب التأجيل'),
                const SizedBox(height: 8),
                TextField(
                  controller: _requiredController,
                  decoration: InputDecoration(
                    labelText: 'سبب التأجيل',
                    hintText: 'ادخل سبب التأجيل',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nextDateController,
                  decoration: InputDecoration(
                    labelText: 'الموعد الجديد',
                    hintText: 'ادخل تاريخ الموعد الجديد',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
              ],
              if (_selectedResult == ResultStatus.impossible) ...[
                _buildSectionTitle('سبب التعذر'),
                const SizedBox(height: 8),
                TextField(
                  controller: _requiredController,
                  decoration: InputDecoration(
                    labelText: 'سبب التعذر',
                    hintText: 'ادخل سبب التعذر',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 3,
                ),
              ],
              if (_selectedResult == ResultStatus.cancelled) ...[
                _buildSectionTitle('سبب الإلغاء'),
                const SizedBox(height: 8),
                TextField(
                  controller: _requiredController,
                  decoration: InputDecoration(
                    labelText: 'سبب الإلغاء',
                    hintText: 'ادخل سبب الإلغاء',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 3,
                ),
              ],
              _buildSectionTitle('مصاريف'),
              const SizedBox(height: 8),
              TextField(
                controller: _expensesController,
                decoration: InputDecoration(
                  labelText: 'قيمة المصاريف',
                  hintText: 'ادخل قيمة المصاريف بالليرة السورية',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixText: 'ل.س ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildSectionTitle('ملاحظة للأستاذ'),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'ملاحظات',
                  hintText: 'ادخل أي ملاحظات إضافية',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _selectedResult == null ? null : _submitResult,
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultOption(ResultStatus status) {
    final isSelected = _selectedResult == status;
    final color = isSelected ? AppColors.primaryNavy : AppColors.textSecondary;
    final backgroundColor = isSelected ? AppColors.primaryNavy.withOpacity(0.1) : AppColors.cardBackground;
    
    String label;
    IconData icon;
    
    switch (status) {
      case ResultStatus.completed:
        label = 'منجز نهائياً';
        icon = Icons.check_circle;
        break;
      case ResultStatus.generated:
        label = 'منجز + موعد جديد';
        icon = Icons.add_circle;
        break;
      case ResultStatus.postponed:
        label = 'مؤجل';
        icon = Icons.pause_circle;
        break;
      case ResultStatus.impossible:
        label = 'متعذر';
        icon = Icons.cancel;
        break;
      case ResultStatus.cancelled:
        label = 'ملغى';
        icon = Icons.delete;
        break;
    }
    
    return InkWell(
      onTap: () => setState(() => _selectedResult = status),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.cardBorder,
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy),
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'SY'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryNavy,
              onPrimary: AppColors.textOnLight,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      _nextDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }
  
  void _submitResult() {
    if (_selectedResult == null) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ نتيجة العمل بنجاح'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
