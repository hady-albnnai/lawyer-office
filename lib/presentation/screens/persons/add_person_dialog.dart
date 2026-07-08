import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/app_enums.dart';
import '../../../data/database/database.dart';
import '../../providers/app_providers.dart';

/// معالج وإستمارة إضافة شخص جديد أو جهة اعتبارية إلى قاعدة بيانات المكتب
class AddPersonDialog extends ConsumerStatefulWidget {
  final PersonRoleType? defaultRole;
  const AddPersonDialog({super.key, this.defaultRole});

  @override
  ConsumerState<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends ConsumerState<AddPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  PersonType _selectedType = PersonType.natural;
  late List<PersonRoleType> _selectedRoles;

  final _nameController = TextEditingController();
  final _fatherController = TextEditingController();
  final _motherController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // بيانات الشخص الاعتباري (الشركة / المؤسسة)
  final _entityNameController = TextEditingController();
  final _regNumController = TextEditingController();
  final _taxNumController = TextEditingController();
  final _capacityController = TextEditingController();
  File? _representationDocFile;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedRoles = widget.defaultRole != null ? [widget.defaultRole!] : [PersonRoleType.client];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('إضافة سجل شخص أو جهة اعتبارية جديدة'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اختيار النوع (شخص طبيعي أو اعتباري)
                  Row(
                    children: [
                      const Text('نوع السجل:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 20),
                      ChoiceChip(
                        label: const Text('شخص طبيعي'),
                        selected: _selectedType == PersonType.natural,
                        onSelected: (_) => setState(() => _selectedType = PersonType.natural),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('شخص اعتباري (جهة / شركة)'),
                        selected: _selectedType == PersonType.legal,
                        onSelected: (_) => setState(() => _selectedType = PersonType.legal),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // تحديد أدوار الشخص في المكتب
                  const Text('صفة الشخص في المكتب:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: PersonRoleType.values.map((role) {
                      final isSelected = _selectedRoles.contains(role);
                      return FilterChip(
                        label: Text(role.label),
                        selected: isSelected,
                        selectedColor: AppConstants.accentGold.withOpacity(0.3),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedRoles.add(role);
                            } else if (_selectedRoles.length > 1) {
                              _selectedRoles.remove(role);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // الحقول المشتركة والخاصة بالشخص الطبيعي
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: _selectedType == PersonType.natural ? 'الاسم الكامل *' : 'اسم الممثل القانوني للجهة *',
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'هذا الحقل إلزامي' : null,
                  ),
                  const SizedBox(height: 16),

                  if (_selectedType == PersonType.natural) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fatherController,
                            decoration: const InputDecoration(labelText: 'اسم الأب', prefixIcon: Icon(Icons.family_restroom)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _motherController,
                            decoration: const InputDecoration(labelText: 'اسم الأم', prefixIcon: Icon(Icons.escalator_warning)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nationalIdController,
                          decoration: const InputDecoration(labelText: 'الرقم الوطني / الهوية', prefixIcon: Icon(Icons.badge)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'رقم الهاتف الأساسي', prefixIcon: Icon(Icons.phone)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _whatsappController,
                          decoration: const InputDecoration(labelText: 'رقم الواتساب', prefixIcon: Icon(Icons.chat)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'العنوان الدائم / المحافظة', prefixIcon: Icon(Icons.location_on)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // حقول خاصة بالشخص الاعتباري (الشركة / الجهة)
                  if (_selectedType == PersonType.legal) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryNavy.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.primaryNavy.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('بيانات الشخص الاعتباري (الشركة / الجهة):', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryNavy)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _entityNameController,
                            decoration: const InputDecoration(labelText: 'اسم الشركة أو الجهة الاعتبارية *', prefixIcon: Icon(Icons.business)),
                            validator: (val) => _selectedType == PersonType.legal && (val == null || val.isEmpty) ? 'اسم الجهة إلزامي' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _regNumController,
                                  decoration: const InputDecoration(labelText: 'رقم السجل التجاري / الإشهار'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _taxNumController,
                                  decoration: const InputDecoration(labelText: 'الرقم الضريبي'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _capacityController,
                            decoration: const InputDecoration(labelText: 'صفة الممثل القانوني (مدير عام / مفوض...)', prefixIcon: Icon(Icons.work)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(_representationDocFile == null
                                    ? 'سند التمثيل (سجل تجاري / تفويض): لم يتم اختيار ملف'
                                    : 'تم اختيار ملف: ${p.basename(_representationDocFile!.path)}'),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.upload_file),
                                label: const Text('إرفاق سند التمثيل'),
                                onPressed: _pickRepresentationDoc,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'ملاحظات خاصة بالسجل', prefixIcon: Icon(Icons.note)),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                      label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ السجل في المكتب'),
                      onPressed: _isSaving ? null : _savePerson,
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

  Future<void> _pickRepresentationDoc() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png', 'doc', 'docx']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _representationDocFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _savePerson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(personRepositoryProvider);

      final personCompanion = PersonsCompanion.insert(
        type: drift.Value(_selectedType.index),
        fullName: _nameController.text.trim(),
        fatherName: drift.Value(_fatherController.text.trim()),
        motherName: drift.Value(_motherController.text.trim()),
        nationalId: drift.Value(_nationalIdController.text.trim()),
        phone1: drift.Value(_phoneController.text.trim()),
        whatsapp: drift.Value(_whatsappController.text.trim()),
        permanentAddress: drift.Value(_addressController.text.trim()),
        notes: drift.Value(_notesController.text.trim()),
      );

      LegalEntitiesCompanion? legalCompanion;
      if (_selectedType == PersonType.legal) {
        legalCompanion = LegalEntitiesCompanion.insert(
          personId: 0, // سيتم تعيينه تلقائياً داخل المستودع
          legalEntityName: _entityNameController.text.trim(),
          registrationNumber: drift.Value(_regNumController.text.trim()),
          taxNumber: drift.Value(_taxNumController.text.trim()),
          representativeCapacity: drift.Value(_capacityController.text.trim()),
        );
      }

      await repo.createPerson(
        person: personCompanion,
        legalEntity: legalCompanion,
        representationDocFile: _representationDocFile,
        initialRoles: _selectedRoles,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ السجل بنجاح!'), backgroundColor: AppConstants.statusSuccess),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: AppConstants.statusDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// أداة صغيرة لاستخراج اسم الملف من المسار بدون استيراد حزمة path الثقيلة داخل الواجهة
class p {
  static String basename(String path) => path.split('/').last.split('\\').last;
}
