import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/app_enums.dart';
import '../../../data/database/database.dart';
import '../../providers/app_providers.dart';

/// استمارة تنظيم وإرفاق سند توكيل قضائي (كاتب عدل أو مندوب فرع النقابة)
class AddPoaDialog extends ConsumerStatefulWidget {
  const AddPoaDialog({super.key});

  @override
  ConsumerState<AddPoaDialog> createState() => _AddPoaDialogState();
}

class _AddPoaDialogState extends ConsumerState<AddPoaDialog> {
  final _formKey = GlobalKey<FormState>();
  String _sourceType = 'delegate'; // delegate: مندوب نقابة, notary: كاتب عدل
  String _selectedBranch = 'دمشق';
  PoaType _selectedPoaType = PoaType.general;
  
  int? _selectedPrincipalId;
  int? _selectedAgentId;

  final _poaNumController = TextEditingController();
  final _scopeController = TextEditingController();
  DateTime _poaDate = DateTime.now();
  File? _poaFile;

  bool _isSaving = false;

  final List<String> _syrianBranches = [
    'دمشق', 'ريف دمشق', 'حلب', 'حمص', 'حماة', 'اللاذقية', 'طرطوس',
    'السويداء', 'درعا', 'القنيطرة', 'إدلب', 'الرقة', 'دير الزور', 'الحسكة'
  ];

  @override
  Widget build(BuildContext context) {
    final personsAsync = ref.watch(allPersonsProvider(null));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 750),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('إصدار وإرفاق سند توكيل قضائي جديد'),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // جهة التنظيم
                  const Text('جهة تنظيم سند التوكيل:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'delegate',
                        groupValue: _sourceType,
                        onChanged: (val) => setState(() => _sourceType = val!),
                      ),
                      const Text('مندوب فرع النقابة'),
                      const SizedBox(width: 24),
                      Radio<String>(
                        value: 'notary',
                        groupValue: _sourceType,
                        onChanged: (val) => setState(() => _sourceType = val!),
                      ),
                      const Text('دائرة الكاتب بالعدل'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedBranch,
                          decoration: InputDecoration(
                            labelText: _sourceType == 'delegate' ? 'فرع النقابة المندوب عنه' : 'دائرة الكاتب بالعدل في محافظة',
                            prefixIcon: const Icon(Icons.account_balance),
                          ),
                          items: _syrianBranches.map((b) => DropdownMenuItem(value: b, child: Text('فرع $b'))).toList(),
                          onChanged: (val) => setState(() => _selectedBranch = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _poaNumController,
                          decoration: const InputDecoration(labelText: 'رقم سند التوكيل / التوثيق', prefixIcon: Icon(Icons.numbers)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // نوع الوكالة
                  const Text('نوع الوكالة القضائية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<PoaType>(
                    segments: const [
                      ButtonSegment(value: PoaType.general, label: Text('عامة')),
                      ButtonSegment(value: PoaType.special, label: Text('خاصة')),
                      ButtonSegment(value: PoaType.specialSharia, label: Text('خاصة شرعية')),
                    ],
                    selected: {_selectedPoaType},
                    onSelectionChanged: (set) => setState(() => _selectedPoaType = set.first),
                  ),
                  const SizedBox(height: 16),

                  if (_selectedPoaType == PoaType.special || _selectedPoaType == PoaType.specialSharia) ...[
                    TextFormField(
                      controller: _scopeController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'نطاق وتفاصيل الوكالة الخاصة * (مثال: بيع العقار رقم...)',
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (val) => (_selectedPoaType != PoaType.general) && (val == null || val.trim().isEmpty) ? 'وصف نطاق الوكالة الخاصة إلزامي' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // اختيار الموكل والوكيل من قائمة الأشخاص
                  personsAsync.when(
                    data: (persons) => Column(
                      children: [
                        DropdownButtonFormField<int>(
                          value: _selectedPrincipalId,
                          decoration: const InputDecoration(labelText: 'الموكل (صاحب التوكيل) *', prefixIcon: Icon(Icons.person)),
                          items: persons.map((p) => DropdownMenuItem(value: p.id, child: Text(p.fullName))).toList(),
                          onChanged: (val) => setState(() => _selectedPrincipalId = val),
                          validator: (val) => val == null ? 'يجب اختيار الموكل' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedAgentId,
                          decoration: const InputDecoration(labelText: 'الوكيل (المحامي الأستاذ أو الزميل)', prefixIcon: Icon(Icons.gavel)),
                          items: persons.map((p) => DropdownMenuItem(value: p.id, child: Text(p.fullName))).toList(),
                          onChanged: (val) => setState(() => _selectedAgentId = val),
                        ),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('خطأ في تحميل أسماء الموكلين'),
                  ),
                  const SizedBox(height: 24),

                  // إرفاق صورة السند
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppConstants.accentGold),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, color: AppConstants.accentGold, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_poaFile == null
                              ? 'صورة سند التوكيل: لم يتم الرفع بعد (تنبيه: سيولد نقصاً إذا ربط بدعوى دون إرفاق)'
                              : 'تم اختيار السند: ${_poaFile!.path.split('/').last.split('\\').last}'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGold),
                          onPressed: _pickFile,
                          child: const Text('رفع الصورة'),
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
                      label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ سند التوكيل في الأرشيف'),
                      onPressed: _isSaving ? null : _savePoa,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg']);
    if (res != null && res.files.single.path != null) {
      setState(() => _poaFile = File(res.files.single.path!));
    }
  }

  Future<void> _savePoa() async {
    if (!_formKey.currentState!.validate() || _selectedPrincipalId == null) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(poaRepositoryProvider);

      final poaCompanion = PowersOfAttorneyCompanion.insert(
        sourceType: _sourceType,
        delegateBranch: drift.Value(_selectedBranch),
        poaNumber: drift.Value(_poaNumController.text.trim()),
        poaDate: drift.Value(_poaDate),
        poaType: _selectedPoaType.index,
        scopeText: drift.Value(_scopeController.text.trim()),
      );

      await repo.createPoa(
        poa: poaCompanion,
        principalId: _selectedPrincipalId!,
        agentId: _selectedAgentId,
        poaFile: _poaFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إصدار وحفظ سند التوكيل بنجاح!'), backgroundColor: AppConstants.statusSuccess),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ الوكالة: $e'), backgroundColor: AppConstants.statusDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
