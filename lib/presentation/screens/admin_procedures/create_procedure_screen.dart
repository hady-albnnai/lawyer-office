import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/constants/app_constants.dart';
import '../../../data/database/database.dart';
import '../../providers/app_providers.dart';
import 'procedure_detail_screen.dart';

/// شاشة تسجيل معاملة وإجراء إداري جديد مع توليد الـ Checklist التلقائي (CreateProcedureScreen V6.2)
class CreateProcedureScreen extends ConsumerStatefulWidget {
  const CreateProcedureScreen({super.key});

  @override
  ConsumerState<CreateProcedureScreen> createState() => _CreateProcedureScreenState();
}

class _CreateProcedureScreenState extends ConsumerState<CreateProcedureScreen> {
  final _formKey = GlobalKey<FormState>();

  String _category = 'أحوال شخصية';
  String _subType = 'حصر إرث شرعي / مدني';
  int? _selectedClientId;

  final _titleController = TextEditingController();
  final _transNumController = TextEditingController();
  final _deptController = TextEditingController(text: 'محكمة الصلح / السجل المدني');
  DateTime _startDate = DateTime.now();
  DateTime? _nextDate = DateTime.now().add(const Duration(days: 3));

  bool _isSaving = false;

  final Map<String, List<String>> _subTypesMap = {
    'أحوال شخصية': ['حصر إرث شرعي / مدني', 'تصحيح قيد مدني', 'تغيير اسم أو كنية', 'وصاية / ولاية قاصر', 'إذن سفر قاصر', 'بيان قيد عائلي / فردي'],
    'إجراءات عقارية': ['نقل ملكية وفراغ عقاري', 'رهن عقاري / فك رهن', 'إفراز وضم عقاري', 'تسجيل عقار في السجل المؤقت', 'بيان قيد عقاري / مساحة', 'تسوية عقارية'],
    'إجراءات تجارية': ['تسجيل في السجل التجاري', 'تعديل أو شطب سجل تجاري', 'تسجيل علامة تجارية / براءة اختراع', 'تجديد علامة تجارية', 'ترخيص وكالة تجارية', 'ترخيص استيراد وتصدير'],
  };

  @override
  void initState() {
    super.initState();
    _titleController.text = 'معاملة حصر إرث وتصحيح قيد';
  }

  @override
  Widget build(BuildContext context) {
    final personsAsync = ref.watch(allPersonsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل معاملة وإجراء إداري جديد في المكتب (V6.2)'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1. تصنيف الإجراء والنوع الفرعي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(labelText: 'التصنيف الرئيسي *'),
                        items: _subTypesMap.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _category = val!;
                            _subType = _subTypesMap[_category]!.first;
                            if (_category == 'إجراءات عقارية') _deptController.text = 'مديرية المصالح العقارية / المالية';
                            if (_category == 'إجراءات تجارية') _deptController.text = 'مديرية الشركات / غرفة التجارة';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _subType,
                        decoration: const InputDecoration(labelText: 'النوع الفرعي *'),
                        items: _subTypesMap[_category]!.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _subType = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text('2. الموكل والعنوان والدائرة المختصة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy)),
                const SizedBox(height: 12),
                personsAsync.when(
                  data: (persons) => DropdownButtonFormField<int>(
                    value: _selectedClientId,
                    decoration: const InputDecoration(labelText: 'الموكل صاحب المعاملة *', prefixIcon: Icon(Icons.person)),
                    items: persons.map((p) => DropdownMenuItem(value: p.id, child: Text(p.fullName))).toList(),
                    onChanged: (val) => setState(() => _selectedClientId = val),
                    validator: (val) => val == null ? 'يجب اختيار الموكل' : null,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('خطأ في تحميل أسماء الموكلين'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'عنوان المعاملة *', prefixIcon: Icon(Icons.title)),
                  validator: (val) => val == null || val.trim().isEmpty ? 'العنوان إلزامي' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _deptController,
                        decoration: const InputDecoration(labelText: 'الدائرة أو الجهة المسجل لديها *', prefixIcon: Icon(Icons.account_balance)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _transNumController,
                        decoration: const InputDecoration(labelText: 'رقم الطلب / المعاملة (إن وجد)', prefixIcon: Icon(Icons.numbers)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text('3. ★ الموعد القادم للمراجعة (إلزامي وفقاً للدستور V6.2) ★:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _nextDate != null ? AppConstants.statusSuccess.withOpacity(0.1) : AppConstants.statusDanger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _nextDate != null ? AppConstants.statusSuccess : AppConstants.statusDanger),
                  ),
                  child: Row(
                    children: [
                      Icon(_nextDate != null ? Icons.check_circle : Icons.warning_amber, color: _nextDate != null ? AppConstants.statusSuccess : AppConstants.statusDanger),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _nextDate != null ? 'موعد المراجعة القادم: ${_nextDate!.toString().substring(0, 10)}' : 'لم يتم تحديد موعد (سيولد إشعار نقص في تبويب النواقص)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: _nextDate != null ? AppConstants.statusSuccess : AppConstants.statusDanger),
                        ),
                      ),
                      ElevatedButton(
                        child: const Text('تحديد التاريخ'),
                        onPressed: () async {
                          final p = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 3)), firstDate: DateTime.now(), lastDate: DateTime(2030));
                          if (p != null) setState(() => _nextDate = p);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                    label: Text(_isSaving ? 'جارٍ الحفظ وتوليد الـ Checklist...' : 'اعتماد وحفظ المعاملة في المكتب مع خطوات التنفيذ التلقائية'),
                    onPressed: _isSaving ? null : _saveProcedure,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProcedure() async {
    if (!_formKey.currentState!.validate() || _selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار الموكل وتعبئة الحقول المطلوبة!'), backgroundColor: AppConstants.statusDanger));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(adminProcedureRepositoryProvider);

      final companion = AdminProceduresCompanion.insert(
        internalNumber: 'TEMP-${DateTime.now().microsecondsSinceEpoch}',
        procedureType: _category,
        subType: drift.Value(_subType),
        clientId: _selectedClientId!,
        title: _titleController.text.trim(),
        department: drift.Value(_deptController.text.trim()),
        transactionNumber: drift.Value(_transNumController.text.trim()),
        startDate: drift.Value(_startDate),
        nextDate: drift.Value(_nextDate),
      );

      final List<AdminStepsCompanion> initialSteps = [
        AdminStepsCompanion.insert(procedureId: 0, stepTitle: 'تقديم الطلب الأولي واستيفاء الشروط', stepDate: drift.Value(DateTime.now()), status: const drift.Value(1)),
        AdminStepsCompanion.insert(procedureId: 0, stepTitle: 'مراجعة الدائرة المختصة ودفع الرسوم المقررة', status: const drift.Value(0)),
        AdminStepsCompanion.insert(procedureId: 0, stepTitle: 'استلام البيان أو السند النهائي وتدقيقه', status: const drift.Value(0)),
      ];

      final procId = await repo.createProcedure(
        procedure: companion,
        initialSteps: initialSteps,
        userRef: AppConstants.defaultLawyerName,
      );

      if (mounted) {
        ref.invalidate(allProceduresProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل المعاملة وتوليد خطوات الـ Checklist بنجاح!'), backgroundColor: AppConstants.statusSuccess));
        context.pushReplacement('/procedures/$procId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في حفظ المعاملة: $e'), backgroundColor: AppConstants.statusDanger));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
