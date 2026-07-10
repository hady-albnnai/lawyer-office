import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../documents/document_viewer.dart';
import '../persons/person_models.dart';

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
      final principal = state.persons.where((person) => person.id == agency.principalPersonId).firstOrNull;
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
              tooltip: 'إضافة وكالة تجريبية',
              icon: const Icon(Icons.add),
              onPressed: () => _showAddAgencyInfo(context),
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
                        final principal = state.persons.where((person) => person.id == agency.principalPersonId).firstOrNull;
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

  void _showAddAgencyInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة وكالة'),
        content: Text(
          'تم تجهيز واجهة أرشيف الوكالات للمرحلة 6. إضافة وكالة جديدة ستبقى عبر استمارة AddPoaDialog/Drift الحالية أو التطوير التالي.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق')),
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
              ],
            ),
          ],
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
