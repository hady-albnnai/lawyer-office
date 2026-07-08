import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/constants/app_constants.dart';
import '../../../data/database/database.dart';
import '../../providers/app_providers.dart';
import 'case_detail_screen.dart';

/// معالج إنشاء دعوى قضائية جديدة بتسلسل الخطوات الإلزامي (CreateCaseWizard V6.2)
class CreateCaseWizard extends ConsumerStatefulWidget {
  const CreateCaseWizard({super.key});

  @override
  ConsumerState<CreateCaseWizard> createState() => _CreateCaseWizardState();
}

class _CreateCaseWizardState extends ConsumerState<CreateCaseWizard> {
  int _currentStep = 0;

  // الخطوة 1: الموكل
  int? _selectedClientId;
  
  // الخطوة 2: الوكالة
  int? _selectedPoaId;

  // الخطوة 3: التصنيف والمحكمة ورقم الأساس
  String _caseType = 'مدني';
  String _subType = 'بداية';
  int? _selectedCourtId;
  final _baseNumController = TextEditingController();
  final _yearController = TextEditingController(text: DateTime.now().year.toString());
  bool _isUrgent = false;

  // الخطوة 4: موضوع الدعوى
  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();

  // الخطوة 5: الخصم
  int? _selectedOpponentId;

  // الخطوة 6: ★ الموعد القادم (إلزامي أو يولد نقصاً) ★
  DateTime? _nextSessionDate;
  final _nextActionController = TextEditingController(text: 'مرافعة أولى / تقديم لائحة دعوى');

  bool _isSaving = false;

  final List<String> _caseTypes = ['مدني', 'جزائي', 'شرعي', 'تجاري', 'إداري'];
  final List<String> _subTypes = ['صلح', 'بداية', 'استئناف', 'نقض', 'مخاصمة'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معالج فتح ملف دعوى قضائية جديدة (V6.2)'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onContinue,
        onStepCancel: _onCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(_currentStep == 5 ? Icons.check_circle : Icons.arrow_forward),
                  label: Text(_currentStep == 5 ? (_isSaving ? 'جارٍ فتح الملف...' : 'اعتماد وفتح الملف في المكتب') : 'التالي'),
                  onPressed: _isSaving ? null : details.onStepContinue,
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('السابق'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('الموكل الرئيسي'),
            subtitle: Text(_selectedClientId != null ? 'تم الاختيار ✓' : 'إلزامي *'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            content: _buildClientStep(),
          ),
          Step(
            title: const Text('سند التوكيل'),
            subtitle: Text(_selectedPoaId != null ? 'تم إرفاق وكالة ✓' : 'اختياري (سيعتبر نقصاً إن ترك فارغاً)'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
            content: _buildPoaStep(),
          ),
          Step(
            title: const Text('التصنيف والمحكمة'),
            subtitle: Text('$_caseType • $_subType'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.editing,
            content: _buildCourtStep(),
          ),
          Step(
            title: const Text('موضوع الدعوى والطلبات'),
            subtitle: Text(_subjectController.text.isNotEmpty ? _subjectController.text : 'إلزامي *'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.editing,
            content: _buildSubjectStep(),
          ),
          Step(
            title: const Text('الطرف الخصم'),
            subtitle: Text(_selectedOpponentId != null ? 'تم الاختيار ✓' : 'اختياري في هذه الخطوة'),
            isActive: _currentStep >= 4,
            state: _currentStep > 4 ? StepState.complete : StepState.editing,
            content: _buildOpponentStep(),
          ),
          Step(
            title: const Text('★ موعد الجلسة / التنفيذ القادم ★'),
            subtitle: Text(_nextSessionDate != null ? 'تم تحديد الموعد ✓' : 'تنبيه: سيولد نقصاً في الملف إن لم يحدد ⚠️'),
            isActive: _currentStep >= 5,
            state: _currentStep == 5 ? StepState.editing : StepState.indexed,
            content: _buildNextSessionStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildClientStep() {
    final personsAsync = ref.watch(allPersonsProvider(null));

    return personsAsync.when(
      data: (persons) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('اختر الموكل صاحب الدعوى من أرشيف المكتب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedClientId,
            decoration: const InputDecoration(labelText: 'قائمة الموكلين *', prefixIcon: Icon(Icons.person)),
            items: persons.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.fullName} (${p.type == 1 ? "شركة/جهة" : "شخص طبيعي"})'))).toList(),
            onChanged: (val) => setState(() => _selectedClientId = val),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('خطأ في جلب الموكلين'),
    );
  }

  Widget _buildPoaStep() {
    final poasAsync = ref.watch(poaRepositoryProvider).watchAllPoas();

    return StreamBuilder<List<PowersOfAttorneyData>>(
      stream: poasAsync,
      builder: (context, snapshot) {
        final poas = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر سند التوكيل المرتبط بهذا الملف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedPoaId,
              decoration: const InputDecoration(labelText: 'الوكالات المتاحة في الأرشيف', prefixIcon: Icon(Icons.gavel)),
              items: poas.map((p) => DropdownMenuItem(value: p.id, child: Text('وكالة رقم: ${p.poaNumber ?? "بدون رقم"} • ${p.sourceType == "delegate" ? "مندوب نقابة" : "كاتب عدل"}'))).toList(),
              onChanged: (val) => setState(() => _selectedPoaId = val),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCourtStep() {
    final courtsAsync = ref.watch(activeCourtsProvider(null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _caseType,
                decoration: const InputDecoration(labelText: 'التصنيف الرئيسي *'),
                items: _caseTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _caseType = val!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _subType,
                decoration: const InputDecoration(labelText: 'المرحلة / الدرجة *'),
                items: _subTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _subType = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        courtsAsync.when(
          data: (courts) => DropdownButtonFormField<int>(
            value: _selectedCourtId,
            decoration: const InputDecoration(labelText: 'المحكمة المختصة', prefixIcon: Icon(Icons.account_balance)),
            items: courts.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} - ${c.city ?? ""}'))).toList(),
            onChanged: (val) => setState(() => _selectedCourtId = val),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('خطأ في تحميل المحاكم'),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _baseNumController,
                decoration: const InputDecoration(labelText: 'رقم الأساس في المحكمة (إن وجد)', prefixIcon: Icon(Icons.numbers)),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'سنة الأساس *'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _isUrgent,
          title: const Text('قضية مستعجلة / طلب مستعجل ⚠️', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.statusDanger)),
          onChanged: (val) => setState(() => _isUrgent = val ?? false),
        ),
      ],
    );
  }

  Widget _buildSubjectStep() {
    return Column(
      children: [
        TextFormField(
          controller: _subjectController,
          decoration: const InputDecoration(labelText: 'موضوع الدعوى * (مثال: مطالبة مالية وتثبيت بيع)', prefixIcon: Icon(Icons.title)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _detailsController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'تفاصيل الوقائع والطلبات الختامية', prefixIcon: Icon(Icons.notes)),
        ),
      ],
    );
  }

  Widget _buildOpponentStep() {
    final personsAsync = ref.watch(allPersonsProvider(null));

    return personsAsync.when(
      data: (persons) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('اختر الطرف الخصم (مدعى عليه):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedOpponentId,
            decoration: const InputDecoration(labelText: 'قائمة الخصوم', prefixIcon: Icon(Icons.person_off)),
            items: persons.map((p) => DropdownMenuItem(value: p.id, child: Text(p.fullName))).toList(),
            onChanged: (val) => setState(() => _selectedOpponentId = val),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('خطأ في جلب الخصوم'),
    );
  }

  Widget _buildNextSessionStep() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _nextSessionDate != null ? AppConstants.statusSuccess.withOpacity(0.1) : AppConstants.statusDanger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _nextSessionDate != null ? AppConstants.statusSuccess : AppConstants.statusDanger, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_nextSessionDate != null ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: _nextSessionDate != null ? AppConstants.statusSuccess : AppConstants.statusDanger, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _nextSessionDate != null
                      ? 'موعد الجلسة / الإجراء القادم: ${_nextSessionDate!.toString().substring(0, 10)}'
                      : 'لم يتم تحديد موعد الجلسة القادمة بعد!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _nextSessionDate != null ? AppConstants.statusSuccess : AppConstants.statusDanger,
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryNavy),
                icon: const Icon(Icons.calendar_month),
                label: const Text('تحديد التاريخ'),
                onPressed: _pickDate,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nextActionController,
            decoration: const InputDecoration(labelText: 'المطلوب للجلسة أو الإجراء القادم *'),
          ),
          const SizedBox(height: 12),
          const Text(
            'تطبيقاً لقاعدة النواقص في الدستور (V6.2): في حال ترك هذا التاريخ فارغاً، سيتم فتح الملف ولكن النظام سينشئ تلقائياً نقصاً في تبويب "الملفات الناقصة".',
            style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _nextSessionDate = picked);
    }
  }

  void _onContinue() {
    if (_currentStep == 0 && _selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب اختيار الموكل الرئيسي أولاً!'), backgroundColor: AppConstants.statusDanger));
      return;
    }
    if (_currentStep == 3 && _subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('موضوع الدعوى إلزامي!'), backgroundColor: AppConstants.statusDanger));
      return;
    }

    if (_currentStep < 5) {
      setState(() => _currentStep++);
    } else {
      _submitCase();
    }
  }

  void _onCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitCase() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(caseRepositoryProvider);

      final companion = CasesCompanion.insert(
        internalNumber: 'TEMP-${DateTime.now().microsecondsSinceEpoch}',
        year: int.tryParse(_yearController.text.trim()) ?? DateTime.now().year,
        caseType: _caseType,
        subType: drift.Value(_subType),
        courtId: drift.Value(_selectedCourtId),
        baseNumber: drift.Value(_baseNumController.text.trim()),
        subject: drift.Value(_subjectController.text.trim()),
        subjectDetails: drift.Value(_detailsController.text.trim()),
        isUrgent: drift.Value(_isUrgent),
        nextSessionDate: drift.Value(_nextSessionDate),
      );

      final caseId = await repo.createCase(
        caseData: companion,
        clientId: _selectedClientId!,
        opponentId: _selectedOpponentId,
        poaId: _selectedPoaId,
        userRef: AppConstants.defaultLawyerName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم فتح ملف الدعوى وترقيمها بنجاح في المكتب!'), backgroundColor: AppConstants.statusSuccess),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => CaseDetailScreen(caseId: caseId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء فتح الملف: $e'), backgroundColor: AppConstants.statusDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
