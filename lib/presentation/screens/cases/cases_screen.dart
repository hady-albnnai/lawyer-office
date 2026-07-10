/// شاشة قائمة الدعاوى.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../documents/document_models.dart';
import '../documents/document_viewer.dart';
import 'case_models.dart';

class CasesScreen extends ConsumerWidget {
  const CasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدعاوى'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.go('/search-reports'),
              tooltip: 'بحث',
            ),
            IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => const CasesFilterDialog(),
              ),
              tooltip: 'فلترة',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.go('/cases/create'),
              tooltip: 'دعوى جديدة',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildQuickFilterBar(context, ref),
            Expanded(child: _buildCaseList(context, ref)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.go('/cases/create'),
          tooltip: 'دعوى جديدة',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildQuickFilterBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(ref, 'الكل', null),
            _buildChip(ref, 'عاملة', CaseStatus.scheduled),
            _buildChip(ref, 'ناقصة', null, deficient: true),
            _buildChip(ref, 'متأخرة', null, overdue: true),
            _buildChip(ref, 'منتهية', CaseStatus.completed),
            _buildChip(ref, 'بانتظار رقم أساس', null, pendingBase: true),
            _buildChip(ref, 'جلسة قريب', null, nearSession: true),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    WidgetRef ref,
    String label,
    CaseStatus? status, {
    bool deficient = false,
    bool overdue = false,
    bool pendingBase = false,
    bool nearSession = false,
  }) {
    final caseItems = ref.watch(casesProvider);
    int count;
    if (status != null) {
      count = caseItems.where((item) => item.status == status).length;
    } else if (deficient) {
      count = caseItems.where((item) => item.openDeficienciesCount > 0).length;
    } else if (overdue) {
      count = caseItems
          .where((item) => item.nextSession?.sessionDate.isBefore(DateTime.now()) ?? false)
          .length;
    } else if (pendingBase) {
      count = caseItems.where((item) => item.baseNumber == null || item.baseNumber!.isEmpty).length;
    } else if (nearSession) {
      count = caseItems.where((item) => item.nextSession != null).length;
    } else {
      count = caseItems.length;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text('$label${count > 0 ? ' ($count)' : ''}'),
        selected: false,
        onSelected: (_) {},
        backgroundColor: AppColors.cardBackground,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: count > 0 ? AppColors.primaryNavy : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCaseList(BuildContext context, WidgetRef ref) {
    final caseItems = [...ref.watch(casesProvider)]
      ..sort(
        (a, b) => (a.nextSession?.sessionDate ?? DateTime(9999))
            .compareTo(b.nextSession?.sessionDate ?? DateTime(9999)),
      );

    if (caseItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('لا يوجد دعاوى', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('اضغط + لإضافة دعوى', style: AppTextStyles.bodySmallSecondary),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: caseItems.length,
      itemBuilder: (context, index) => CaseCard(caseItem: caseItems[index]),
    );
  }
}

final casesProvider = Provider<List<Case>>(
  (ref) => [
    Case(
      id: '1',
      caseNumber: '2026/001',
      title: 'دعوى تعويض',
      type: CaseType.civil,
      status: CaseStatus.scheduled,
      court: 'محكمة دمشق الأولى',
      baseNumber: '12345',
      baseYear: 2026,
      subject: 'تعويض عن ضرر',
      claim: '10,000,000 ل.س',
      creationDate: DateTime(2026, 7, 1),
      lastUpdated: DateTime(2026, 7, 9),
      clientIds: const ['client_1'],
      opponentIds: const ['opponent_1'],
      lawyerIds: const ['lawyer_1'],
      poaIds: const ['poa_1'],
      sessions: [
        CaseSession(
          id: 's1',
          sessionDate: DateTime(2026, 7, 15),
          sessionTime: const TimeOfDay(hour: 9, minute: 0),
          type: SessionType.ordinary,
          status: SessionStatus.scheduled,
          court: 'محكمة دمشق الأولى',
        ),
      ],
      phases: [
        CasePhase(
          id: 'p1',
          type: CasePhaseType.initial,
          court: 'محكمة دمشق الأولى',
          baseNumber: '12345',
          baseYear: 2026,
          startDate: DateTime(2026, 7, 1),
        ),
      ],
      deficiencies: [
        CaseDeficiency(
          id: 'd1',
          field: 'baseNumber',
          description: 'تأكيد رقم الأساس',
          createdAt: DateTime(2026, 7, 1),
          severity: 'high',
        ),
      ],
      fees: [
        CaseFee(
          id: 'f1',
          clientId: 'client_1',
          amount: 5000000,
          agreementDate: DateTime(2026, 7, 1),
        ),
      ],
      expenses: [
        CaseExpense(
          id: 'e1',
          description: 'رسم دعوى',
          amount: 100000,
          expenseDate: DateTime(2026, 7, 2),
        ),
      ],
      documentIds: const ['doc_1', 'doc_2', 'doc_3'],
    ),
    Case(
      id: '2',
      caseNumber: '2026/002',
      title: 'دعوى استئناف',
      type: CaseType.commercial,
      status: CaseStatus.scheduled,
      court: 'محكمة الاستئناف',
      subject: 'استئناف حكم',
      claim: 'إلغاء الحكم',
      creationDate: DateTime(2026, 7, 2),
      lastUpdated: DateTime(2026, 7, 8),
      clientIds: const ['client_2'],
      opponentIds: const ['opponent_2'],
      sessions: [
        CaseSession(
          id: 's2',
          sessionDate: DateTime(2026, 7, 10),
          sessionTime: const TimeOfDay(hour: 10, minute: 30),
          type: SessionType.ordinary,
          status: SessionStatus.scheduled,
          court: 'محكمة الاستئناف',
        ),
      ],
      deficiencies: [
        CaseDeficiency(
          id: 'd2',
          field: 'baseNumber',
          description: 'حصول على رقم أساس',
          createdAt: DateTime(2026, 7, 2),
          severity: 'high',
        ),
        CaseDeficiency(
          id: 'd3',
          field: 'poa',
          description: 'رفع الوكالة',
          createdAt: DateTime(2026, 7, 3),
          severity: 'high',
        ),
      ],
      documentIds: const ['doc_4', 'doc_5'],
    ),
    Case(
      id: '3',
      caseNumber: '2026/003',
      title: 'دعوى تجارية',
      type: CaseType.commercial,
      status: CaseStatus.completed,
      court: 'محكمة دمشق الأولى',
      baseNumber: '67890',
      baseYear: 2026,
      subject: 'منازعة تجارية',
      claim: '5,000,000 ل.س',
      creationDate: DateTime(2026, 6, 15),
      lastUpdated: DateTime(2026, 7, 5),
      clientIds: const ['client_3'],
      opponentIds: const ['opponent_3'],
      sessions: [
        CaseSession(
          id: 's3',
          sessionDate: DateTime(2026, 7, 5),
          sessionTime: const TimeOfDay(hour: 11, minute: 0),
          type: SessionType.judgment,
          status: SessionStatus.held,
          court: 'محكمة دمشق الأولى',
          decision: 'حكم لصالح الموكل',
          result: const SessionResult(decision: 'حكم لصالح الموكل', expenses: 50000),
        ),
      ],
      fees: [
        CaseFee(
          id: 'f2',
          clientId: 'client_3',
          amount: 2500000,
          agreementDate: DateTime(2026, 6, 15),
          paymentDate: DateTime(2026, 7, 5),
          status: 'paid',
        ),
      ],
      expenses: [
        CaseExpense(
          id: 'e2',
          description: 'رسم دعوى',
          amount: 75000,
          expenseDate: DateTime(2026, 6, 16),
        ),
        CaseExpense(
          id: 'e3',
          description: 'مصاريف معقب',
          amount: 25000,
          expenseDate: DateTime(2026, 6, 20),
        ),
      ],
      documentIds: const ['doc_6', 'doc_7', 'doc_8', 'doc_9', 'doc_10'],
    ),
  ],
);

class CaseCard extends StatelessWidget {
  final Case caseItem;

  const CaseCard({super.key, required this.caseItem});

  @override
  Widget build(BuildContext context) {
    final nextSession = caseItem.nextSession;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/cases/${caseItem.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      caseItem.caseNumber,
                      style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy),
                    ),
                  ),
                  _tag(caseItem.type.displayName, AppColors.primaryNavy),
                  const SizedBox(width: 8),
                  _tag(caseItem.status.displayName, caseItem.status.color),
                ],
              ),
              const SizedBox(height: 8),
              Text(caseItem.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('الموضوع: ${caseItem.subject}', style: AppTextStyles.bodySmall),
              Text('الطلب: ${caseItem.claim}', style: AppTextStyles.bodySmallSecondary),
              const SizedBox(height: 8),
              _iconLine(Icons.balance, caseItem.court),
              if (caseItem.baseNumber == null || caseItem.baseNumber!.isEmpty)
                _warningLine('بانتظار رقم أساس')
              else
                _iconLine(Icons.confirmation_number, 'رقم الأساس: ${caseItem.baseNumber}'),
              if (nextSession != null)
                _iconLine(
                  Icons.calendar_today,
                  'الجلسة: ${_formatDate(nextSession.sessionDate)} ${_formatTime(nextSession.sessionTime)}',
                  color: nextSession.sessionDate.isBefore(DateTime.now()) ? AppColors.error : AppColors.textPrimary,
                ),
              if (caseItem.openDeficienciesCount > 0) _warningLine('نواقص: ${caseItem.openDeficienciesCount}', isError: true),
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  Text('أتعاب: ${caseItem.totalFees.toStringAsFixed(0)} ل.س', style: AppTextStyles.bodySmallSecondary),
                  Text('مصاريف: ${caseItem.totalExpenses.toStringAsFixed(0)} ل.س', style: AppTextStyles.bodySmallSecondary),
                  Text(
                    'الرصيد: ${caseItem.balance.toStringAsFixed(0)} ل.س',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: caseItem.balance >= 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_file, color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text('مستندات: ${caseItem.documentIds.length}', style: AppTextStyles.bodySmallSecondary),
                  const SizedBox(width: 8),
                  if (caseItem.documentIds.isNotEmpty)
                    TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (context) => CaseDocsDialog(caseItem: caseItem),
                      ),
                      child: const Text('عرض المستندات'),
                    ),
                ],
              ),
              Text(
                'آخر تحديث: ${_formatDate(caseItem.lastUpdated ?? caseItem.creationDate)}',
                style: AppTextStyles.bodySmallSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
    );
  }

  Widget _iconLine(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 4),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: color ?? AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _warningLine(String text, {bool isError = false}) {
    final color = isError ? AppColors.error : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: color)),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class CaseDocsDialog extends StatelessWidget {
  final Case caseItem;

  const CaseDocsDialog({super.key, required this.caseItem});

  @override
  Widget build(BuildContext context) {
    final docs = caseItem.documentIds
        .map(
          (documentId) => DocumentItem(
            id: documentId,
            title: 'مستند $documentId',
            documentType: DocumentType.caseDocument,
            entityType: 'case',
            entityId: caseItem.id,
            entityTitle: caseItem.title,
            filePath: 'docs/cases/$documentId.pdf',
            fileName: '${caseItem.caseNumber}_$documentId.pdf',
            fileSize: 512 * 1024,
            fileType: FileType.pdf,
            uploadDate: DateTime.now(),
            uploadedBy: 'هادي البني',
            physicalLocation: 'ديوان المحكمة',
          ),
        )
        .toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: AppColors.textOnLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'مستندات الدعوى: ${caseItem.caseNumber}',
                      style: AppTextStyles.headline6.copyWith(color: AppColors.textOnLight),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) => ListTile(
                  leading: Icon(docs[index].fileType.icon, color: AppColors.primaryNavy),
                  title: Text(docs[index].title, style: AppTextStyles.bodyMedium),
                  subtitle: Text(
                    '${docs[index].fileType.displayName} - ${docs[index].formattedSize}',
                    style: AppTextStyles.bodySmallSecondary,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    onPressed: () => openDocument(context, docs[index].id),
                    tooltip: 'فتح',
                  ),
                  onTap: () => openDocument(context, docs[index].id),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إغلاق'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CasesFilterDialog extends StatefulWidget {
  const CasesFilterDialog({super.key});

  @override
  State<CasesFilterDialog> createState() => _CasesFilterDialogState();
}

class _CasesFilterDialogState extends State<CasesFilterDialog> {
  CaseType? _type;
  CaseStatus? _status;
  bool _deficient = false;
  bool _nearSession = false;
  bool _pendingBase = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('فلترة الدعاوى', style: AppTextStyles.headline4.copyWith(color: AppColors.primaryNavy)),
            const SizedBox(height: 24),
            DropdownButtonFormField<CaseType?>(
              value: _type,
              items: [
                const DropdownMenuItem<CaseType?>(value: null, child: Text('جميع الأنواع')),
                ...CaseType.values.map((type) => DropdownMenuItem<CaseType?>(value: type, child: Text(type.displayName))),
              ],
              onChanged: (value) => setState(() => _type = value),
              decoration: const InputDecoration(labelText: 'نوع الدعوى'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CaseStatus?>(
              value: _status,
              items: [
                const DropdownMenuItem<CaseStatus?>(value: null, child: Text('جميع الحالات')),
                ...CaseStatus.values.map((status) => DropdownMenuItem<CaseStatus?>(value: status, child: Text(status.displayName))),
              ],
              onChanged: (value) => setState(() => _status = value),
              decoration: const InputDecoration(labelText: 'حالة الدعوى'),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('الدعاوى الناقصة'),
              value: _deficient,
              onChanged: (value) => setState(() => _deficient = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('جلسة قريب'),
              value: _nearSession,
              onChanged: (value) => setState(() => _nearSession = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('بانتظار رقم أساس'),
              value: _pendingBase,
              onChanged: (value) => setState(() => _pendingBase = value ?? false),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('تم تطبيق الفلاتر'), backgroundColor: AppColors.success),
                    );
                  },
                  child: const Text('تطبيق'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
