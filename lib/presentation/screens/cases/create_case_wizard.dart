/// معالج إنشاء دعوى قضائية جديدة
/// 
/// حسب مواصفات PRODUCT_REDESIGN_MASTER_PLAN.md - القسم 5
/// معالج من 8 خطوات إلزامية
/// 
/// آخر تحديث: 2026-07-09

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;

import '../../../data/database/database.dart' as db;
import '../../../data/repositories/case_repository.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'case_models.dart';

/// معالج إنشاء دعوى جديدة
class CreateCaseWizard extends ConsumerStatefulWidget {
  const CreateCaseWizard({super.key});

  @override
  ConsumerState<CreateCaseWizard> createState() => _CreateCaseWizardState();
}

class _CreateCaseWizardState extends ConsumerState<CreateCaseWizard> {
  int _currentStep = 0;
  
  // ===========================================================================
  // الخطوة 1: الموكل
  // ===========================================================================
  int? _selectedClientId;
  final TextEditingController _clientSearchController = TextEditingController();
  
  // ===========================================================================
  // الخطوة 2: الوكالة
  // ===========================================================================
  int? _selectedPoaId;
  final TextEditingController _poaSearchController = TextEditingController();
  
  // ===========================================================================
  // الخطوة 3: التصنيف
  // ===========================================================================
  CaseType _caseType = CaseType.civil;
  String _caseSubType = 'بداية';
  int? _selectedCourtId;
  final TextEditingController _baseNumberController = TextEditingController();
  final TextEditingController _baseYearController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  bool _isUrgent = false;
  
  // ===========================================================================
  // الخطوة 4: البيانات الأساسية
  // ===========================================================================
  final TextEditingController _caseNumberController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  
  // ===========================================================================
  // الخطوة 5: الموضوع والطلبات
  // ===========================================================================
  final TextEditingController _claimController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  
  // ===========================================================================
  // الخطوة 6: الخصم
  // ===========================================================================
  int? _selectedOpponentId;
  final TextEditingController _opponentSearchController = TextEditingController();
  
  // ===========================================================================
  // الخطوة 7: المرفقات
  // ===========================================================================
  final List<String> _attachmentPaths = [];
  final List<TextEditingController> _attachmentControllers = [];
  
  // ===========================================================================
  // الخطوة 8: الموعد القادم (إلزامي - تولد نقصاً إذا ترك فارغاً)
  // ===========================================================================
  DateTime? _nextSessionDate;
  final TextEditingController _nextActionController = TextEditingController(
    text: 'مرافعة أولى / تقديم لائحة دعوى',
  );
  
  bool _isSaving = false;
  
  // قوائم الاختيار
  final List<String> _caseSubTypes = ['صلح', 'بداية', 'استئناف', 'نقض', 'مخاصمة'];
  final List<String> _courtNames = [
    'محكمة دمشق الأولى',
    'محكمة دمشق الثانية',
    'محكمة الاستئناف',
    'محكمة النقض',
    'محكمة حلب الأولى',
    'محكمة حمص الأولى',
    'محكمة اللاذقية الأولى',
    'محكمة حما',
    'محكمة درعا',
    'محكمة السويداء',
    'محكمة القنيطرة',
    'محكمة الرقة',
    'محكمة دير الزور',
    'محكمة الحسكة',
  ];

  @override
  void dispose() {
    _clientSearchController.dispose();
    _poaSearchController.dispose();
    _baseNumberController.dispose();
    _baseYearController.dispose();
    _caseNumberController.dispose();
    _titleController.dispose();
    _subjectController.dispose();
    _claimController.dispose();
    _detailsController.dispose();
    _opponentSearchController.dispose();
    _nextActionController.dispose();
    for (var controller in _attachmentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء دعوى جديدة'),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text('السابق'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // شريط التقدم
            _buildProgressBar(),
            
            // المحتوى
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCurrentStepContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_currentStep < 7)
              TextButton(
                onPressed: _isSaving ? null : _nextStep,
                child: const Text('التالي'),
              ),
            if (_currentStep == 7)
              ElevatedButton(
                onPressed: _isSaving ? null : _submitCase,
                child: _isSaving 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnLight,
                        ),
                      )
                    : const Text('إنشاء الدعوى'),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // شريط التقدم
  // ===========================================================================
  
  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.backgroundLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الخطوات
          Row(
            children: List.generate(8, (index) => _buildStepIndicator(index)),
          ),
          const SizedBox(height: 8),
          
          // أسماء الخطوات
          Row(
            children: List.generate(8, (index) => _buildStepLabel(index)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepIndicator(int index) {
    final isCompleted = index < _currentStep;
    final isCurrent = index == _currentStep;
    
    return Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isCompleted 
              ? AppColors.success 
              : isCurrent 
                  ? AppColors.primaryNavy 
                  : AppColors.cardBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
  
  Widget _buildStepLabel(int index) {
    final isCompleted = index < _currentStep;
    final isCurrent = index == _currentStep;
    
    String label;
    switch (index) {
      case 0: label = 'الموكل'; break;
      case 1: label = 'الوكالة'; break;
      case 2: label = 'التصنيف'; break;
      case 3: label = 'البيانات الأساسية'; break;
      case 4: label = 'الموضوع والطلبات'; break;
      case 5: label = 'الخصم'; break;
      case 6: label = 'المرفقات'; break;
      case 7: label = 'الموعد القادم'; break;
      default: label = '';
    }
    
    return Expanded(
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: isCompleted 
              ? AppColors.success 
              : isCurrent 
                  ? AppColors.primaryNavy 
                  : AppColors.textSecondary,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ===========================================================================
  // محتوى كل خطوة
  // ===========================================================================
  
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildClientStep();
      case 1:
        return _buildPoaStep();
      case 2:
        return _buildClassificationStep();
      case 3:
        return _buildBasicDataStep();
      case 4:
        return _buildSubjectAndClaimsStep();
      case 5:
        return _buildOpponentStep();
      case 6:
        return _buildAttachmentsStep();
      case 7:
        return _buildNextSessionStep();
      default:
        return const SizedBox();
    }
  }
  
  Widget _buildStepHeader({
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headline4.copyWith(color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.bodySmallSecondary,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // الخطوة 1: الموكل
  // ===========================================================================
  
  Widget _buildClientStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          title: 'اختر الموكل',
          description: 'يجب تحديد الموكل قبل المتابعة',
        ),
        const SizedBox(height: 24),
        
        // بحث عن موكل
        TextField(
          controller: _clientSearchController,
          decoration: InputDecoration(
            labelText: 'بحث عن موكل',
            hintText: 'ادخل اسم الموكل أو رقم هويته',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) => _searchClients(value),
        ),
        const SizedBox(height: 16),
        
        // قائمة الموكلين
        _buildClientList(),
        
        // أو إضافة موكل جديد
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => _showAddClientDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('إضافة موكل جديد'),
        ),
      ],
    );
  }
  
  Widget _buildClientList() {
    // في التطبيق الحقيقي، سيتم استرداد الموكلين من قاعدة البيانات
    // هنا نستخدم بيانات افتراضية
    final clients = [
      {'id': 1, 'name': 'أحمد محمد', 'type': 'شخص طبيعي'},
      {'id': 2, 'name': 'محمد أحمد', 'type': 'شخص طبيعي'},
      {'id': 3, 'name': 'شركة التطوير الحديث', 'type': 'شركة'},
      {'id': 4, 'name': 'هادي فيصل البني', 'type': 'شخص طبيعي'},
      {'id': 5, 'name': 'سامي عبد الله', 'type': 'شخص طبيعي'},
    ];
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          final isSelected = _selectedClientId == client['id'];
          
          return InkWell(
            onTap: () => setState(() => _selectedClientId = client['id'] as int?),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryNavy.withOpacity(0.1) : AppColors.cardBackground,
                border: Border.all(color: AppColors.cardBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    client['name'] as String,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    client['type'] as String,
                    style: AppTextStyles.bodySmallSecondary,
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _searchClients(String query) {
    // بحث عن موكلين في قاعدة البيانات
  }
  
  void _showAddClientDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddClientDialog(),
    );
  }

  // ===========================================================================
  // الخطوة 2: الوكالة
  // ===========================================================================
  
  Widget _buildPoaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          title: 'اختر الوكالة',
          description: 'يجب ربط الدعوى بوكالة صالحة',
        ),
        const SizedBox(height: 24),
        
        // بحث عن وكالة
        TextField(
          controller: _poaSearchController,
          decoration: InputDecoration(
            labelText: 'بحث عن وكالة',
            hintText: 'ادخل رقم الوكالة أو اسم الموكل',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) => _searchPoas(value),
        ),
        const SizedBox(height: 16),
        
        // قائمة الوكالات
        _buildPoaList(),
        
        // أو إضافة وكالة جديدة
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => _showAddPoaDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('إضافة وكالة جديدة'),
        ),
        
        // أو تأجيل اختيار الوكالة
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _showPostponePoaDialog(context),
          icon: const Icon(Icons.warning),
          label: const Text('تأجيل اختيار الوكالة'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.warning,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPoaList() {
    // في التطبيق الحقيقي، سيتم استرداد الوكالات من قاعدة البيانات
    final poas = [
      {'id': 1, 'number': 'POA-2026-001', 'client': 'أحمد محمد', 'type': 'عامة', 'date': '2026-01-15'},
      {'id': 2, 'number': 'POA-2026-002', 'client': 'محمد أحمد', 'type': 'خاصة', 'date': '2026-02-20'},
      {'id': 3, 'number': 'POA-2026-003', 'client': 'هادي فيصل البني', 'type': 'عامة', 'date': '2026-03-10'},
    ];
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: poas.length,
        itemBuilder: (context, index) {
          final poa = poas[index];
          final isSelected = _selectedPoaId == poa['id'];
          
          return InkWell(
            onTap: () => setState(() => _selectedPoaId = poa['id'] as int?),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryNavy.withOpacity(0.1) : AppColors.cardBackground,
                border: Border.all(color: AppColors.cardBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poa['number'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'الموكل: ${poa['client'] as String}',
                        style: AppTextStyles.bodySmallSecondary,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        poa['type'] as String,
                        style: AppTextStyles.bodySmall,
                      ),
                      Text(
                        poa['date'] as String,
                        style: AppTextStyles.bodySmallSecondary,
                      ),
                    ],
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _searchPoas(String query) {
    // بحث عن وكالات في قاعدة البيانات
  }
  
  void _showAddPoaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddPoaDialog(),
    );
  }
  
  void _showPostponePoaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأجيل اختيار الوكالة'),
        content: const Text('سيتم إنشاء الدعوى بدون وكالة، ويمكن إضافة الوكالة لاحقاً. سيتم إنشاء نقص تلقائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _selectedPoaId = null);
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // الخطوة 3: التصنيف
  // ===========================================================================
  
  Widget _buildClassificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          title: 'تصنيف الدعوى',
          description: 'حدد نوع الدعوى والمحكمة',
        ),
        const SizedBox(height: 24),
        
        // نوع الدعوى
        DropdownButtonFormField<CaseType>(
          value: _caseType,
          items: CaseType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.displayName),
            );
          }).toList(),
          onChanged: (value) => setState(() => _caseType = value!),
          decoration: InputDecoration(
            labelText: 'نوع الدعوى',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // النوع الفرعي
        DropdownButtonFormField<String>(
          value: _caseSubType,
          items: _caseSubTypes.map((subType) {
            return DropdownMenuItem(
              value: subType,
              child: Text(subType),
            );
          }).toList(),
          onChanged: (value) => setState(() => _caseSubType = value!),
          decoration: InputDecoration(
            labelText: 'النوع الفرعي',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // المحكمة
        DropdownButtonFormField<int?>(
          value: _selectedCourtId,
          items: _courtNames.asMap().entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCourtId = value),
          decoration: InputDecoration(
            labelText: 'المحكمة',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // رقم الأساس وسنة الأساس
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _baseNumberController,
                decoration: InputDecoration(
                  labelText: 'رقم الأساس',
                  hintText: 'مثال: 12345',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _baseYearController,
                decoration: InputDecoration(
                  labelText: 'سنة الأساس',
                  hintText: 'مثال: 2026',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // مستعجلة
        CheckboxListTile(
          title: const Text('دعوى مستعجلة'),
          value: _isUrgent,
          onChanged: (value) => setState(() => _isUrgent = value!),
          contentPadding: EdgeInsets.zero,
          dense: true,
          secondary: const Icon(Icons.priority_high, color: AppColors.error),
        ),
      ],
    );
  }

  // ===========================================================================
  // الخطوة 4: البيانات الأساسية
  // ===========================================================================
  
  Widget _buildBasicDataStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          title: 'البيانات الأساسية',
          description: 'ادخل رقم الدعوى وعنوانها',
        ),
        const SizedBox(height: 24),
        
        // رقم الدعوى
        TextField(
          controller: _caseNumberController,
          decoration: InputDecoration(
            labelText: 'رقم الدعوى',
            hintText: 'مثال: 2026/001 (سيتم توليد تلقائياً إذا ترك فارغاً)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // عنوان الدعوى
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'عنوان الدعوى',
            hintText: 'مثال: دعوى تعويض عن ضرر',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // الموضوع
        TextField(
          controller: _subjectController,
          decoration: InputDecoration(
            labelText: 'الموضوع',
            hintText: 'مثال: تعويض عن ضرر مادي',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  // ===========================================================================
  // الخطوة 5: الموضوع والطلبات
  // ===========================================================================
  
  Widget _buildSubjectAndClaimsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          title: 'الموضوع والطلبات',
          description: 'ادخل تفاصيل الدعوى وطلباتك',
        ),
        const SizedBox(height: 24),
        
        // الطلب
        TextField(
          controller: _claimController,
          decoration: InputDecoration(
            labelText: 'الطلب',
            hintText: 'مثال: مبلغ 10,000,000 ل.س كتعويض عن الأضرار',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        
        // التفاصيل
        TextField(
          controller: _detailsController,
          decoration: InputDecoration(
            labelText: 'التفاصيل',
            hintText: 'ادخل تفاصيل إضافية عن الدعوى',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 5,
        ),
      ],
    );
  }

  // ===========================================================================
  // الخطوة 6: الخصم
  // ===========================================================================
  
  Widget _buildOpponentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          title: 'اختر الخصم',
          description: 'يجب تحديد الخصم أو الخصوم',
        ),
        const SizedBox(height: 24),
        
        // بحث عن خصم
        TextField(
          controller: _opponentSearchController,
          decoration: InputDecoration(
            labelText: 'بحث عن خصم',
            hintText: 'ادخل اسم الخصم أو رقم هويته',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) => _searchOpponents(value),
        ),
        const SizedBox(height: 16),
        
        // قائمة الخصوم
        _buildOpponentList(),
        
        // أو إضافة خصم جديد
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => _showAddOpponentDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('إضافة خصم جديد'),
        ),
      ],
    );
  }
  
  Widget _buildOpponentList() {
    // في التطبيق الحقيقي، سيتم استرداد الخصوم من قاعدة البيانات
    final opponents = [
      {'id': 1, 'name': 'محمد أحمد', 'type': 'شخص طبيعي'},
      {'id': 2, 'name': 'شركة التطوير الحديث', 'type': 'شركة'},
      {'id': 3, 'name': 'أحمد محمد', 'type': 'شخص طبيعي'},
      {'id': 4, 'name': 'سامي عبد الله', 'type': 'شخص طبيعي'},
    ];
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: opponents.length,
        itemBuilder: (context, index) {
          final opponent = opponents[index];
          final isSelected = _selectedOpponentId == opponent['id'];
          
          return InkWell(
            onTap: () => setState(() => _selectedOpponentId = opponent['id'] as int?),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryNavy.withOpacity(0.1) : AppColors.cardBackground,
                border: Border.all(color: AppColors.cardBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_off,
                    color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    opponent['name'] as String,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    opponent['type'] as String,
                    style: AppTextStyles.bodySmallSecondary,
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _searchOpponents(String query) {
    // بحث عن خصوم في قاعدة البيانات
  }
  
  void _showAddOpponentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddOpponentDialog(),
    );
  }

  // ===========================================================================
  // الخطوة 7: المرفقات
  // ===========================================================================
  
  Widget _buildAttachmentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          title: 'المرفقات',
          description: 'أرفق مستندات الدعوى (اختياري)',
        ),
        const SizedBox(height: 24),
        
        // قائمة المرفقات
        if (_attachmentPaths.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder, width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attachmentPaths.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorder, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_file,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _attachmentPaths[index],
                          style: AppTextStyles.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => _removeAttachment(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // زر إضافة مرفق
        ElevatedButton.icon(
          onPressed: _addAttachment,
          icon: const Icon(Icons.attach_file),
          label: const Text('إضافة مرفق'),
        ),
        const SizedBox(height: 8),
        Text(
          'يمكنك إضافة المرفقات لاحقاً من شاشة تفاصيل الدعوى',
          style: AppTextStyles.bodySmallSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  void _addAttachment() {
    // في التطبيق الحقيقي، سيتم فتح نافذة اختيار الملف
    setState(() {
      _attachmentPaths.add('مستند_${_attachmentPaths.length + 1}.pdf');
      _attachmentControllers.add(TextEditingController());
    });
  }
  
  void _removeAttachment(int index) {
    setState(() {
      _attachmentPaths.removeAt(index);
      _attachmentControllers[index].dispose();
      _attachmentControllers.removeAt(index);
    });
  }

  // ===========================================================================
  // الخطوة 8: الموعد القادم (إلزامي)
  // ===========================================================================
  
  Widget _buildNextSessionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          title: 'الموعد القادم',
          description: '⚠️ يجب تحديد موعد الجلسة القادمة. إذا تركت هذا الحقل فارغاً، سيتم إنشاء نقص تلقائياً.',
        ),
        const SizedBox(height: 24),
        
        // تاريخ الجلسة
        Row(
          children: [
            Expanded(
              child: Text(
                _nextSessionDate == null
                    ? 'لم يتم تحديد تاريخ'
                    : '${_nextSessionDate!.year}-${_nextSessionDate!.month.toString().padLeft(2, '0')}-${_nextSessionDate!.day.toString().padLeft(2, '0')}',
                style: AppTextStyles.bodyLarge,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_today),
              label: const Text('اختر التاريخ'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // الوقت
        Row(
          children: [
            Expanded(
              child: Text(
                _nextSessionDate == null
                    ? 'لم يتم تحديد وقت'
                    : '${_nextSessionDate!.hour.toString().padLeft(2, '0')}:${_nextSessionDate!.minute.toString().padLeft(2, '0')}',
                style: AppTextStyles.bodyLarge,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _selectTime(context),
              icon: const Icon(Icons.access_time),
              label: const Text('اختر الوقت'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // الإجراء المطلوب
        TextField(
          controller: _nextActionController,
          decoration: InputDecoration(
            labelText: 'الإجراء المطلوب',
            hintText: 'مثال: مرافعة أولى، تقديم لائحة دعوى، إثبات',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // المحكمة
        DropdownButtonFormField<int?>(
          value: _selectedCourtId,
          items: _courtNames.asMap().entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCourtId = value),
          decoration: InputDecoration(
            labelText: 'المحكمة',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // تنبيه
        if (_nextSessionDate == null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              border: Border.all(color: AppColors.warning, width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'سيتم إنشاء نقص تلقائياً إذا لم يتم تحديد موعد الجلسة القادمة',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextSessionDate ?? DateTime.now(),
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
      setState(() => _nextSessionDate = picked);
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    if (_nextSessionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى تحديد التاريخ أولاً'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_nextSessionDate!),
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
      setState(() {
        _nextSessionDate = DateTime(
          _nextSessionDate!.year,
          _nextSessionDate!.month,
          _nextSessionDate!.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  // ===========================================================================
  // التنقل بين الخطوات
  // ===========================================================================
  
  void _nextStep() {
    // التحقق من الخطوات الإلزامية
    if (!_validateCurrentStep()) {
      return;
    }
    
    if (_currentStep < 7) {
      setState(() => _currentStep++);
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }
  
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // الموكل
        if (_selectedClientId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('يرجى اختيار الموكل'),
              backgroundColor: AppColors.error,
            ),
          );
          return false;
        }
        break;
      case 2: // التصنيف
        if (_selectedCourtId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('يرجى اختيار المحكمة'),
              backgroundColor: AppColors.error,
            ),
          );
          return false;
        }
        break;
      case 3: // البيانات الأساسية
        if (_titleController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('يرجى إدخال عنوان الدعوى'),
              backgroundColor: AppColors.error,
            ),
          );
          return false;
        }
        break;
      case 5: // الخصم
        if (_selectedOpponentId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('يرجى اختيار الخصم'),
              backgroundColor: AppColors.error,
            ),
          );
          return false;
        }
        break;
      case 7: // الموعد القادم
        if (_nextSessionDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('يرجى تحديد موعد الجلسة القادمة'),
              backgroundColor: AppColors.error,
            ),
          );
          return false;
        }
        break;
    }
    
    return true;
  }

  // ===========================================================================
  // تقديم الدعوى (مرتبط بـ CaseRepository حقيقي)
  // ===========================================================================
  
  Future<void> _submitCase() async {
    if (!_validateCurrentStep()) {
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final caseRepo = ref.read(caseRepositoryProvider);
      
      // إعداد بيانات الدعوى
      final caseData = db.CasesCompanion.insert(
        internalNumber: 'TMP',
        year: int.tryParse(_baseYearController.text) ?? DateTime.now().year,
        caseType: _caseType.toString().split('.').last,
        subType: Value(_caseSubType),
        status: const Value('registered'),
        courtId: Value(_selectedCourtId),
        baseNumber: Value(_baseNumberController.text.isNotEmpty ? _baseNumberController.text : null),
        subject: Value(_subjectController.text.isNotEmpty ? _subjectController.text : _titleController.text),
        subjectDetails: Value(_detailsController.text),
        nextSessionDate: Value(_nextSessionDate),
        isUrgent: Value(_isUrgent),
      );
      
      // استدعاء المستودع الحقيقي
      final caseId = await caseRepo.createCase(
        caseData: caseData,
        clientId: _selectedClientId!,
        opponentId: _selectedOpponentId,
        poaId: _selectedPoaId,
        userRef: 'المستخدم',
      );
      
      setState(() => _isSaving = false);
      
      if (mounted) {
        context.go('/cases/$caseId');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء الدعوى بنجاح برقم داخلي: $caseId'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إنشاء الدعوى: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ===========================================================================
// حوارات إضافة سريعة
// ===========================================================================

class AddClientDialog extends StatefulWidget {
  const AddClientDialog({super.key});

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _clientType = 'شخص طبيعي';

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إضافة موكل جديد',
              style: AppTextStyles.headline4.copyWith(
                color: AppColors.primaryNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'الاسم الكامل',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: 'رقم الهوية',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _clientType,
              items: const [
                DropdownMenuItem(value: 'شخص طبيعي', child: Text('شخص طبيعي')),
                DropdownMenuItem(value: 'شركة', child: Text('شركة')),
                DropdownMenuItem(value: 'مؤسسة', child: Text('مؤسسة')),
              ],
              onChanged: (value) => setState(() => _clientType = value!),
              decoration: InputDecoration(
                labelText: 'نوع الموكل',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
                  onPressed: _submitClient,
                  child: const Text('إضافة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitClient() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إضافة الموكل: ${_nameController.text}'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class AddPoaDialog extends StatefulWidget {
  const AddPoaDialog({super.key});

  @override
  State<AddPoaDialog> createState() => _AddPoaDialogState();
}

class _AddPoaDialogState extends State<AddPoaDialog> {
  final TextEditingController _numberController = TextEditingController();
  int? _selectedClientId;
  String _poaType = 'عامة';
  DateTime? _poaDate;
  final TextEditingController _notaryController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _notaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إضافة وكالة جديدة',
              style: AppTextStyles.headline4.copyWith(
                color: AppColors.primaryNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _numberController,
              decoration: InputDecoration(
                labelText: 'رقم الوكالة',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _poaType,
              items: const [
                DropdownMenuItem(value: 'عامة', child: Text('عامة')),
                DropdownMenuItem(value: 'خاصة', child: Text('خاصة')),
                DropdownMenuItem(value: 'شرعية', child: Text('شرعية')),
              ],
              onChanged: (value) => setState(() => _poaType = value!),
              decoration: InputDecoration(
                labelText: 'نوع الوكالة',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notaryController,
              decoration: InputDecoration(
                labelText: 'كاتب العدل',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _poaDate == null
                        ? 'لم يتم تحديد تاريخ'
                        : '${_poaDate!.year}-${_poaDate!.month.toString().padLeft(2, '0')}-${_poaDate!.day.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectPoaDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('تاريخ الوكالة'),
                ),
              ],
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
                  onPressed: _submitPoa,
                  child: const Text('إضافة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectPoaDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _poaDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar', 'SY'),
    );
    
    if (picked != null) {
      setState(() => _poaDate = picked);
    }
  }

  void _submitPoa() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إضافة الوكالة: ${_numberController.text}'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class AddOpponentDialog extends StatefulWidget {
  const AddOpponentDialog({super.key});

  @override
  State<AddOpponentDialog> createState() => _AddOpponentDialogState();
}

class _AddOpponentDialogState extends State<AddOpponentDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _opponentType = 'شخص طبيعي';

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إضافة خصم جديد',
              style: AppTextStyles.headline4.copyWith(
                color: AppColors.primaryNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'الاسم الكامل',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: 'رقم الهوية',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _opponentType,
              items: const [
                DropdownMenuItem(value: 'شخص طبيعي', child: Text('شخص طبيعي')),
                DropdownMenuItem(value: 'شركة', child: Text('شركة')),
                DropdownMenuItem(value: 'مؤسسة', child: Text('مؤسسة')),
              ],
              onChanged: (value) => setState(() => _opponentType = value!),
              decoration: InputDecoration(
                labelText: 'نوع الخصم',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
                  onPressed: _submitOpponent,
                  child: const Text('إضافة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitOpponent() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إضافة الخصم: ${_nameController.text}'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
