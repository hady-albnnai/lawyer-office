import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../documents/document_viewer.dart';
import '../persons/person_models.dart';
import 'poa_detail_screen.dart';

/// شاشة إدارة الوكالات القضائية والقانونية في المرحلة 6.
class PoaListScreen extends ConsumerStatefulWidget {
  const PoaListScreen({super.key});

  @override
  ConsumerState<PoaListScreen> createState() => _PoaListScreenState();
}

class _PoaListScreenState extends ConsumerState<PoaListScreen> {
  String _query = '';
  AgencySource? _sourceFilter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personsDirectoryProvider);
    final agencies = state.agencies.where((agency) {
      final principal = state.personById(agency.principalPersonId);
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          agency.number.toLowerCase().contains(q) ||
          agency.branch.toLowerCase().contains(q) ||
          agency.agentName.toLowerCase().contains(q) ||
          (principal?.fullName.toLowerCase().contains(q) ?? false);
      final matchesSource = _sourceFilter == null || agency.source == _sourceFilter;
      return matchesQuery && matchesSource;
    }).toList();

    return Theme(
      data: AppTheme.lightTheme,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('أرشيف الوكالات'),
            actions: [
              IconButton(
                tooltip: 'إضافة وكالة',
                icon: const Icon(Icons.add),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => const AddAgencyDialog(),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _toolbar(),
              Expanded(
                child: agencies.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: agencies.length,
                        itemBuilder: (context, index) {
                          final agency = agencies[index];
                          final principal = state.personById(agency.principalPersonId);
                          return _AgencyCard(
                            agency: agency,
                            principalName: principal?.fullName ?? 'غير محدد',
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'بحث برقم الوكالة، الموكل، الفرع، الوكيل...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<AgencySource?>(
            value: _sourceFilter,
            items: const [
              DropdownMenuItem<AgencySource?>(value: null, child: Text('كل الجهات')),
              DropdownMenuItem<AgencySource?>(value: AgencySource.notary, child: Text('كاتب عدل')),
              DropdownMenuItem<AgencySource?>(value: AgencySource.barDelegate, child: Text('مندوب نقابة')),
            ],
            onChanged: (value) => setState(() => _sourceFilter = value),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_shared_outlined, size: 72, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('لا توجد وكالات مطابقة', style: AppTextStyles.headline5),
          const SizedBox(height: 8),
          Text('غيّر البحث أو فلتر جهة التنظيم.', style: AppTextStyles.bodySmallSecondary),
        ],
      ),
    );
  }
}

class _AgencyCard extends ConsumerWidget {
  final AgencyRecord agency;
  final String principalName;

  const _AgencyCard({required this.agency, required this.principalName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PoaDetailScreen(agencyId: agency.id)),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: agency.hasDocument ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                    child: Icon(Icons.verified_user, color: agency.hasDocument ? AppColors.success : AppColors.warning),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${agency.type.displayName} • ${agency.number}',
                      style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy),
                    ),
                  ),
                  _badge(agency.hasDocument ? 'صورة مرفقة' : 'صورة ناقصة', agency.hasDocument ? AppColors.success : AppColors.warning),
                ],
              ),
              const SizedBox(height: 12),
              _line(Icons.person, 'الموكل: $principalName'),
              _line(Icons.gavel, 'الوكيل: ${agency.agentName}'),
              _line(Icons.account_balance, '${agency.source.displayName} - ${agency.branch}'),
              _line(Icons.calendar_today, 'تاريخ التنظيم: ${_formatDate(agency.issuedAt)}'),
              _line(Icons.link, 'الدعاوى المرتبطة: ${agency.linkedCaseIds.isEmpty ? 'لا توجد' : agency.linkedCaseIds.join(', ')}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.description),
                    label: const Text('فتح السند'),
                    onPressed: agency.hasDocument ? () => openDocument(context, agency.documentId) : null,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text('ربط بدعوى'),
                    onPressed: () => _showLinkDialog(context, ref),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('تفاصيل'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => PoaDetailScreen(agencyId: agency.id)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: AppTextStyles.bodySmallSecondary)),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: AppTextStyles.labelSmall.copyWith(color: color)),
    );
  }

  void _showLinkDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ربط وكالة بدعوى'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'رقم الدعوى')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final caseId = controller.text.trim();
              if (caseId.isNotEmpty) {
                ref.read(personsDirectoryProvider.notifier).linkAgencyToCase(agency.id, caseId);
              }
              Navigator.of(context).pop();
            },
            child: const Text('ربط'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class AddAgencyDialog extends ConsumerStatefulWidget {
  const AddAgencyDialog({super.key});

  @override
  ConsumerState<AddAgencyDialog> createState() => _AddAgencyDialogState();
}

class _AddAgencyDialogState extends ConsumerState<AddAgencyDialog> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _agentController = TextEditingController(text: 'الأستاذ هادي فيصل البني');
  final TextEditingController _branchController = TextEditingController(text: 'دمشق');
  final TextEditingController _scopeController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  AgencyType _type = AgencyType.general;
  AgencySource _source = AgencySource.barDelegate;
  String? _principalPersonId;
  DateTime _issuedAt = DateTime.now();

  @override
  void dispose() {
    _numberController.dispose();
    _agentController.dispose();
    _branchController.dispose();
    _scopeController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final persons = ref.watch(personsDirectoryProvider).persons;
    _principalPersonId ??= persons.isNotEmpty ? persons.first.id : null;

    return AlertDialog(
      title: const Text('إضافة وكالة جديدة'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _numberController, decoration: const InputDecoration(labelText: 'رقم الوكالة / التوثيق')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _principalPersonId,
                decoration: const InputDecoration(labelText: 'الموكل'),
                items: persons.map((person) => DropdownMenuItem(value: person.id, child: Text(person.fullName))).toList(),
                onChanged: (value) => setState(() => _principalPersonId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AgencyType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'نوع الوكالة'),
                items: AgencyType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(),
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AgencySource>(
                value: _source,
                decoration: const InputDecoration(labelText: 'جهة التنظيم'),
                items: AgencySource.values.map((source) => DropdownMenuItem(value: source, child: Text(source.displayName))).toList(),
                onChanged: (value) => setState(() => _source = value ?? _source),
              ),
              const SizedBox(height: 12),
              TextField(controller: _branchController, decoration: const InputDecoration(labelText: 'الفرع / المحافظة')),
              const SizedBox(height: 12),
              TextField(controller: _agentController, decoration: const InputDecoration(labelText: 'الوكيل')),
              const SizedBox(height: 12),
              TextField(controller: _scopeController, maxLines: 2, decoration: const InputDecoration(labelText: 'النطاق')),
              const SizedBox(height: 12),
              TextField(controller: _documentController, decoration: const InputDecoration(labelText: 'معرف المستند المرفق')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('تاريخ التنظيم: ${_formatDate(_issuedAt)}', style: AppTextStyles.bodyMedium)),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _issuedAt,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => _issuedAt = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('اختيار'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }

  void _save() {
    final principalId = _principalPersonId;
    if (principalId == null || _numberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('رقم الوكالة والموكل إلزاميان'), backgroundColor: AppColors.error));
      return;
    }

    final now = DateTime.now();
    ref.read(personsDirectoryProvider.notifier).addAgency(
          AgencyRecord(
            id: 'agency_${now.microsecondsSinceEpoch}',
            number: _numberController.text.trim(),
            type: _type,
            source: _source,
            branch: _branchController.text.trim().isEmpty ? 'دمشق' : _branchController.text.trim(),
            principalPersonId: principalId,
            agentName: _agentController.text.trim().isEmpty ? 'الأستاذ هادي فيصل البني' : _agentController.text.trim(),
            issuedAt: _issuedAt,
            scope: _scopeController.text.trim(),
            documentId: _documentController.text.trim(),
          ),
        );
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
