import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/permission_catalog.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/app_enums.dart';
import '../../../data/repositories/archive_intake_repository.dart';
import '../../providers/auth_providers.dart';
import '../../providers/app_providers.dart';
import '../../providers/ui_data_providers.dart';
import '../files/files_screen.dart' show FileItem, FileStatus, FileType, filesProvider;
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

final _archiveIntakeRefreshProvider = StateProvider<int>((ref) => 0);
final _archiveWizardQuerySeedProvider = StateProvider<String?>((ref) => null);

final _archiveWizardProvider = StateProvider<_ArchiveWizardSelection>((ref) => const _ArchiveWizardSelection());

class _ArchiveWizardSelection {
  final String? archiveStatus; // running / closed
  final String? fileKind;
  final String? caseType;
  final String? courtLevel;
  final String? companyGroup;
  final String? companyType;
  final String? procedureType;
  final String? contractType;
  final String? poaType;
  final List<String> customFileKinds;
  final List<String> customCaseTypes;
  final Map<String, List<String>> customCourtsByCaseType;
  final List<String> customCompanyTypes;
  final List<String> customProcedureTypes;
  final List<String> customContractTypes;
  final List<String> customPoaTypes;
  final List<String> customDocumentTypes;

  const _ArchiveWizardSelection({
    this.archiveStatus,
    this.fileKind,
    this.caseType,
    this.courtLevel,
    this.companyGroup,
    this.companyType,
    this.procedureType,
    this.contractType,
    this.poaType,
    this.customFileKinds = const [],
    this.customCaseTypes = const [],
    this.customCourtsByCaseType = const {},
    this.customCompanyTypes = const [],
    this.customProcedureTypes = const [],
    this.customContractTypes = const [],
    this.customPoaTypes = const [],
    this.customDocumentTypes = const [],
  });

  _ArchiveWizardSelection copyWith({
    Object? archiveStatus = _sentinel,
    Object? fileKind = _sentinel,
    Object? caseType = _sentinel,
    Object? courtLevel = _sentinel,
    Object? companyGroup = _sentinel,
    Object? companyType = _sentinel,
    Object? procedureType = _sentinel,
    Object? contractType = _sentinel,
    Object? poaType = _sentinel,
    List<String>? customFileKinds,
    List<String>? customCaseTypes,
    Map<String, List<String>>? customCourtsByCaseType,
    List<String>? customCompanyTypes,
    List<String>? customProcedureTypes,
    List<String>? customContractTypes,
    List<String>? customPoaTypes,
    List<String>? customDocumentTypes,
  }) {
    return _ArchiveWizardSelection(
      archiveStatus: archiveStatus == _sentinel ? this.archiveStatus : archiveStatus as String?,
      fileKind: fileKind == _sentinel ? this.fileKind : fileKind as String?,
      caseType: caseType == _sentinel ? this.caseType : caseType as String?,
      courtLevel: courtLevel == _sentinel ? this.courtLevel : courtLevel as String?,
      companyGroup: companyGroup == _sentinel ? this.companyGroup : companyGroup as String?,
      companyType: companyType == _sentinel ? this.companyType : companyType as String?,
      procedureType: procedureType == _sentinel ? this.procedureType : procedureType as String?,
      contractType: contractType == _sentinel ? this.contractType : contractType as String?,
      poaType: poaType == _sentinel ? this.poaType : poaType as String?,
      customFileKinds: customFileKinds ?? this.customFileKinds,
      customCaseTypes: customCaseTypes ?? this.customCaseTypes,
      customCourtsByCaseType: customCourtsByCaseType ?? this.customCourtsByCaseType,
      customCompanyTypes: customCompanyTypes ?? this.customCompanyTypes,
      customProcedureTypes: customProcedureTypes ?? this.customProcedureTypes,
      customContractTypes: customContractTypes ?? this.customContractTypes,
      customPoaTypes: customPoaTypes ?? this.customPoaTypes,
      customDocumentTypes: customDocumentTypes ?? this.customDocumentTypes,
    );
  }

  bool get isClosed => archiveStatus == 'closed';
  bool get isRunning => archiveStatus == 'running';
}

class _UnsetValue {
  const _UnsetValue();
}

const _UnsetValue _sentinel = _UnsetValue();

const _archiveFileKindOptions = <String, String>{
  'case': 'دعوى',
  'company': 'شركة',
  'procedure': 'إجراء / معاملة',
  'contract': 'عقد',
  'poa': 'وكالة',
  'misc': 'أرشيف غير محدد',
};

const _caseCourtMap = <String, List<String>>{
  'مدنية': ['صلح مدني', 'بداية مدنية', 'استئناف مدني', 'نقض', 'مخاصمة'],
  'شرعية': ['صلح شرعي', 'نقض شرعي', 'مخاصمة شرعية'],
  'جزائية': ['نيابة عامة', 'تحقيق', 'إحالة', 'صلح جزاء', 'استئناف جنح', 'جنايات', 'نقض جزائي', 'مخاصمة جزائية'],
  'تجارية': ['بداية تجارية', 'استئناف تجاري', 'نقض تجاري'],
  'إدارية': ['محكمة عمالية', 'محكمة قضاء إداري', 'المحكمة الإدارية العليا', 'نقض إداري'],
};

const _companyTypeMap = <String, List<String>>{
  'شركات أشخاص': ['شركة تضامنية', 'شركة توصية بسيطة'],
  'شركات أموال': ['شركة محدودة المسؤولية', 'مساهمة مغفلة خاصة', 'مساهمة مغفلة عامة'],
};

const _procedureTypeOptions = ['أحوال شخصية', 'إجراءات عقارية', 'إجراءات تجارية', 'إجراءات تنفيذية', 'إجراءات إدارية عامة'];
const _contractTypeOptions = ['عقد بيع', 'عقد إيجار', 'عقد شراكة', 'عقد عمل', 'عقد مقاولة', 'مخالصة / إبراء'];
const _poaTypeOptions = ['وكالة عامة', 'وكالة خاصة', 'وكالة قضائية', 'وكالة بيع عقار', 'وكالة شركة'];

enum _ArchiveLinkTarget {
  caseFile,
  procedure,
  company,
  contract,
  person,
  poa;

  String get label => const ['دعوى', 'إجراء إداري', 'شركة', 'عقد', 'موكل / جهة', 'وكالة'][index];

  int get entityType {
    switch (this) {
      case _ArchiveLinkTarget.caseFile:
        return EntityType.caseEntity.index;
      case _ArchiveLinkTarget.procedure:
        return EntityType.adminProcedure.index;
      case _ArchiveLinkTarget.company:
        return EntityType.company.index;
      case _ArchiveLinkTarget.contract:
        return EntityType.contract.index;
      case _ArchiveLinkTarget.person:
        return EntityType.person.index;
      case _ArchiveLinkTarget.poa:
        return EntityType.powerOfAttorney.index;
    }
  }
}

const _documentTypeOptions = <String, String>{
  'case_document': 'مستند دعوى',
  'power_of_attorney': 'وكالة',
  'contract': 'عقد',
  'decision': 'قرار / حكم',
  'court_record': 'ضبط جلسة',
  'receipt': 'إيصال',
  'memo': 'مذكرة',
  'archive_document': 'مستند أرشيف',
};

/// مركز إدخال الأرشيف القديم.
///
/// يدير دفعات إدخال الأرشيف الورقي والإلكتروني، يحفظ الملفات المستوردة، يكشف
/// المكررات، ويسمح بمراجعة العناصر وربطها بملفات المكتب دون تجاوز مسارات العمل الرسمية.
class ArchiveIntakeScreen extends ConsumerWidget {
  const ArchiveIntakeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionServiceProvider);
    final query = GoRouterState.of(context).uri.queryParameters;
    final requestedStatus = query['status'];
    final requestedKind = query['kind'];
    final validStatus = requestedStatus == 'closed' || requestedStatus == 'running' ? requestedStatus : null;
    final validKind = _archiveFileKindOptions.containsKey(requestedKind) ? requestedKind : null;
    if (validStatus != null || validKind != null) {
      final seedSignature = '${validStatus ?? ''}|${validKind ?? ''}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final lastSeed = ref.read(_archiveWizardQuerySeedProvider);
        if (lastSeed == seedSignature) return;
        final current = ref.read(_archiveWizardProvider);
        ref.read(_archiveWizardQuerySeedProvider.notifier).state = seedSignature;
        ref.read(_archiveWizardProvider.notifier).state = current.copyWith(
          archiveStatus: validStatus ?? current.archiveStatus,
          fileKind: validKind,
          caseType: null,
          courtLevel: null,
          companyGroup: null,
          companyType: null,
          procedureType: null,
          contractType: null,
          poaType: null,
        );
      });
    }
    ref.watch(_archiveIntakeRefreshProvider);
    return Theme(
      data: AppTheme.lightTheme,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('مركز إدخال الأرشيف القديم'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _introCard(),
                const SizedBox(height: 16),
                _archiveGuidedEntryPanel(context, ref),
                const SizedBox(height: 24),
                _sectionTitle('دفعات رفع الملفات الخام'),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 900;
                    final cards = [
                      _actionCard(
                        icon: Icons.document_scanner,
                        title: 'أرشيف ورقي',
                        subtitle: 'ملفات ممسوحة ضوئياً PDF أو صور، مع بيانات الأصل الورقي.',
                        enabled: permissions.can(PermissionKeys.archiveIntakeCreate),
                        onTap: () => _showCreateBatch(context, ref, 'paper'),
                      ),
                      _actionCard(
                        icon: Icons.folder_copy,
                        title: 'أرشيف إلكتروني',
                        subtitle: 'استيراد مجلدات وملفات موجودة على الجهاز أو الفلاش.',
                        enabled: permissions.can(PermissionKeys.archiveIntakeImportFiles),
                        onTap: () => _showCreateBatch(context, ref, 'electronic'),
                      ),
                      _actionCard(
                        icon: Icons.table_chart,
                        title: 'Excel / CSV',
                        subtitle: 'استيراد الأشخاص والدعاوى والوكالات والمستندات من قوالب منظمة.',
                        enabled: permissions.can(PermissionKeys.archiveIntakeImportExcel),
                        onTap: () => _showCreateBatch(context, ref, 'excel'),
                      ),
                      _actionCard(
                        icon: Icons.all_inbox,
                        title: 'أرشيف مختلط',
                        subtitle: 'دفعة تجمع ورقي وإلكتروني وجداول قديمة في مسار مراجعة واحد.',
                        enabled: permissions.can(PermissionKeys.archiveIntakeCreate),
                        onTap: () => _showCreateBatch(context, ref, 'mixed'),
                      ),
                    ];
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: wide ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: wide ? 1.25 : 1.15,
                      children: cards,
                    );
                  },
                ),
                const SizedBox(height: 24),
                _sectionTitle('قوالب الاستيراد'),
                const SizedBox(height: 12),
                _importTemplatesPanel(context, ref),
                const SizedBox(height: 24),
                _sectionTitle('مراجعة الأرشيف'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _statusTile('دفعات الإدخال', 'متابعة دفعات الاستيراد وحالاتها.', Icons.inventory_2, AppColors.primaryNavy),
                    _statusTile('صندوق غير مصنف', 'ملفات تحتاج ربطاً أو تصنيفاً.', Icons.inbox, AppColors.warning, onTap: () => _showUnclassifiedInbox(context, ref)),
                    _statusTile('ملفات جارية تحتاج استكمال', 'دعاوى وإجراءات وملفات نشطة ناقصة بيانات تشغيلية.', Icons.pending_actions, AppColors.error, onTap: () => _showActiveNeedsCompletion(context, ref)),
                    _statusTile('المكررات', 'ملفات كشفها النظام كنسخ مكررة.', Icons.copy_all, AppColors.info, onTap: () => _showDuplicates(context, ref)),
                    _statusTile('تقارير الجودة', 'نتائج الاستيراد والأخطاء والعينات المطلوبة للمراجعة.', Icons.fact_check, AppColors.success, onTap: () => _showQualityReport(context, ref)),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle('دفعات الإدخال الحالية'),
                const SizedBox(height: 12),
                _batchesList(ref),
                const SizedBox(height: 24),
                _notice(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _introCard() {
    return Card(
      color: AppColors.primaryNavy,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.archive, color: AppColors.secondaryGold, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إدخال الأرشيف القديم بدون فوضى', style: AppTextStyles.headline5.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text(
                    'كل ملف مستورد يجب أن يصبح إما ملفاً جارياً يغذي مكتب العمل، أو ملفاً منتهياً للأرشفة والبحث، أو عنصراً يحتاج مراجعة.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
      );

  Widget _actionCard({required IconData icon, required String title, required String subtitle, required bool enabled, VoidCallback? onTap}) {
    return Card(
      elevation: enabled ? 2 : 0,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: (enabled ? AppColors.primaryNavy : AppColors.textSecondary).withOpacity(0.12),
                child: Icon(icon, color: enabled ? AppColors.primaryNavy : AppColors.textSecondary),
              ),
              const Spacer(),
              Text(title, style: AppTextStyles.headline6.copyWith(color: enabled ? AppColors.primaryNavy : AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text(subtitle, style: AppTextStyles.bodySmallSecondary, maxLines: 3, overflow: TextOverflow.ellipsis),
              if (!enabled) ...[
                const SizedBox(height: 6),
                Text('لا تملك الصلاحية', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusTile(String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return SizedBox(
      width: 300,
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color)),
          title: Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryNavy)),
          subtitle: Text(subtitle, style: AppTextStyles.bodySmallSecondary),
          trailing: onTap == null ? null : const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }

  Widget _archiveGuidedEntryPanel(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(_archiveWizardProvider);
    final notifier = ref.read(_archiveWizardProvider.notifier);
    final statusDone = selection.archiveStatus != null;
    final kindDone = selection.fileKind != null;
    final canStart = _archiveSelectionReady(selection);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: AppColors.primaryNavy.withOpacity(0.1), child: const Icon(Icons.account_tree, color: AppColors.primaryNavy)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('معالج إدخال الأرشيف القديم', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('ابدأ بتحديد هل الملف منتهٍ أم جارٍ، ثم اختر نوع الملف وتصنيفه. الجارية فقط تغذي مكتب العمل بالمواعيد القادمة.', style: AppTextStyles.bodySmallSecondary),
                    ],
                  ),
                ),
                TextButton.icon(icon: const Icon(Icons.refresh, size: 16), label: const Text('إعادة ضبط'), onPressed: () => notifier.state = const _ArchiveWizardSelection()),
              ],
            ),
            const Divider(height: 28),
            _wizardStep('1', 'نوع الأرشيف', 'هذا الاختيار يحدد أثر الملف على مكتب العمل.', Wrap(spacing: 10, runSpacing: 10, children: [
              _archiveChoice(selected: selection.archiveStatus == 'closed', icon: Icons.inventory_2, title: 'أرشيف منتهٍ', subtitle: 'للحفظ والبحث فقط، بلا مواعيد قادمة.', onTap: () => notifier.state = selection.copyWith(archiveStatus: 'closed')),
              _archiveChoice(selected: selection.archiveStatus == 'running', icon: Icons.pending_actions, title: 'أرشيف جارٍ', subtitle: 'أي موعد قادم سينعكس على مكتب العمل والتقويم.', onTap: () => notifier.state = selection.copyWith(archiveStatus: 'running')),
            ])),
            if (statusDone) ...[
              const SizedBox(height: 16),
              _wizardStep('2', 'النوع الفرعي للملف', 'اختر نوع الأرشيف المراد إدخاله، أو أضف نوعاً غير موجود.', Wrap(spacing: 8, runSpacing: 8, children: [
                ..._archiveFileKindOptions.entries.map((e) => _choiceChip(selection.fileKind == e.key, e.value, () => notifier.state = selection.copyWith(fileKind: e.key, caseType: null, courtLevel: null, companyGroup: null, companyType: null, procedureType: null, contractType: null, poaType: null))),
                ...selection.customFileKinds.map((v) => _choiceChip(selection.fileKind == v, v, () => notifier.state = selection.copyWith(fileKind: v))),
                ActionChip(avatar: const Icon(Icons.add, size: 16), label: const Text('إضافة نوع جديد'), onPressed: () => _addCustomValue(context, 'نوع ملف جديد', (value) => notifier.state = selection.copyWith(customFileKinds: [...selection.customFileKinds, value], fileKind: value))),
              ])),
            ],
            if (kindDone) ...[
              const SizedBox(height: 16),
              _wizardDetailsForKind(context, ref, selection),
            ],
            if (selection.fileKind != null) ...[
              const SizedBox(height: 16),
              _documentsHint(context, ref, selection),
            ],
            if (selection.archiveStatus != null || selection.fileKind != null) ...[
              const SizedBox(height: 16),
              _archiveCurrentPathCard(selection),
            ],
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: Icon(selection.isRunning ? Icons.play_circle : Icons.archive),
                label: Text(selection.isRunning ? 'فتح شاشة إدخال ملف جارٍ' : 'فتح شاشة أرشفة ملف منتهٍ'),
                onPressed: canStart ? () => _startArchiveEntry(context, ref, selection) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _archiveCurrentPathCard(_ArchiveWizardSelection s) {
    final summary = _archiveSummary(s);
    final color = s.isRunning ? AppColors.success : AppColors.primaryNavy;
    final effect = s.archiveStatus == null
        ? 'حدد هل الأرشيف جارٍ أو منتهٍ حتى يعرف النظام أثر الملف على مكتب العمل.'
        : s.isRunning
            ? 'هذا المسار سيُدخل ملفاً حياً: المواعيد القادمة ستظهر في مكتب العمل والتقويم.'
            : 'هذا المسار للحفظ والبحث فقط: لن تظهر مواعيده ضمن العمل القادم.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(s.archiveStatus == null ? Icons.help_outline : (s.isRunning ? Icons.route : Icons.inventory_2), color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary.isEmpty ? 'لم يكتمل مسار الأرشيف بعد' : summary, style: AppTextStyles.labelLarge.copyWith(color: color, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(effect, style: AppTextStyles.bodySmallSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wizardStep(String number, String title, String subtitle, Widget child) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(radius: 14, backgroundColor: AppColors.secondaryGold, child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryNavy)),
        const SizedBox(height: 3),
        Text(subtitle, style: AppTextStyles.bodySmallSecondary),
        const SizedBox(height: 10),
        child,
      ])),
    ]);
  }

  Widget _archiveChoice({required bool selected, required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return SizedBox(
      width: 300,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: selected ? AppColors.primaryNavy.withOpacity(0.08) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.primaryNavy : AppColors.cardBorder, width: selected ? 1.4 : 0.7)),
          child: Row(children: [
            CircleAvatar(backgroundColor: AppColors.primaryNavy.withOpacity(0.1), child: Icon(icon, color: AppColors.primaryNavy)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTextStyles.labelLarge), Text(subtitle, style: AppTextStyles.bodySmallSecondary)])),
            if (selected) const Icon(Icons.check_circle, color: AppColors.success),
          ]),
        ),
      ),
    );
  }

  Widget _choiceChip(bool selected, String label, VoidCallback onTap) {
    return ChoiceChip(selected: selected, label: Text(label), selectedColor: AppColors.primaryNavy.withOpacity(0.12), labelStyle: TextStyle(color: selected ? AppColors.primaryNavy : AppColors.textPrimary, fontWeight: selected ? FontWeight.bold : FontWeight.normal), onSelected: (_) => onTap());
  }

  Widget _wizardDetailsForKind(BuildContext context, WidgetRef ref, _ArchiveWizardSelection s) {
    final notifier = ref.read(_archiveWizardProvider.notifier);
    if (s.fileKind == 'case') {
      final caseTypes = [..._caseCourtMap.keys, ...s.customCaseTypes];
      final courts = s.caseType == null ? const <String>[] : [...(_caseCourtMap[s.caseType] ?? const <String>[]), ...(s.customCourtsByCaseType[s.caseType] ?? const <String>[])];
      return _wizardStep('3', 'تصنيف الدعوى والمحكمة', 'اختر نوع الدعوى ثم المحكمة/درجة التقاضي. يمكن إضافة أي تصنيف أو محكمة غير موجودة.', Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          ...caseTypes.map((v) => _choiceChip(s.caseType == v, v, () => notifier.state = s.copyWith(caseType: v, courtLevel: null))),
          ActionChip(avatar: const Icon(Icons.add, size: 16), label: const Text('إضافة نوع دعوى'), onPressed: () => _addCustomValue(context, 'نوع دعوى جديد', (value) => notifier.state = s.copyWith(customCaseTypes: [...s.customCaseTypes, value], caseType: value, courtLevel: null))),
        ]),
        if (s.caseType != null) ...[
          const SizedBox(height: 12),
          Text('المحكمة / درجة التقاضي', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryNavy)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ...courts.map((v) => _choiceChip(s.courtLevel == v, v, () => notifier.state = s.copyWith(courtLevel: v))),
            ActionChip(avatar: const Icon(Icons.add, size: 16), label: const Text('إضافة محكمة / درجة'), onPressed: () => _addCustomValue(context, 'محكمة أو درجة جديدة', (value) {
              final updated = Map<String, List<String>>.from(s.customCourtsByCaseType);
              updated[s.caseType!] = [...(updated[s.caseType!] ?? const <String>[]), value];
              notifier.state = s.copyWith(customCourtsByCaseType: updated, courtLevel: value);
            })),
          ]),
        ],
      ]));
    }
    if (s.fileKind == 'company') {
      final groups = _companyTypeMap.keys.toList();
      final subtypes = s.companyGroup == null ? const <String>[] : [...(_companyTypeMap[s.companyGroup] ?? const <String>[]), ...s.customCompanyTypes];
      return _wizardStep('3', 'نوع الشركة ووثائقها', 'حدد إن كانت شركة أشخاص أو أموال، ثم نوعها التفصيلي.', Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, runSpacing: 8, children: groups.map((v) => _choiceChip(s.companyGroup == v, v, () => notifier.state = s.copyWith(companyGroup: v, companyType: null))).toList()),
        if (s.companyGroup != null) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ...subtypes.map((v) => _choiceChip(s.companyType == v, v, () => notifier.state = s.copyWith(companyType: v))),
            ActionChip(avatar: const Icon(Icons.add, size: 16), label: const Text('إضافة نوع شركة'), onPressed: () => _addCustomValue(context, 'نوع شركة جديد', (value) => notifier.state = s.copyWith(customCompanyTypes: [...s.customCompanyTypes, value], companyType: value))),
          ]),
        ],
      ]));
    }
    if (s.fileKind == 'procedure') {
      final items = [..._procedureTypeOptions, ...s.customProcedureTypes];
      return _wizardSimpleClassifier(context, '3', 'نوع الإجراء / المعاملة', 'اختر تصنيف الإجراء أو أضف تصنيفاً جديداً.', items, s.procedureType, (v) => notifier.state = s.copyWith(procedureType: v), 'إضافة نوع إجراء', (v) => notifier.state = s.copyWith(customProcedureTypes: [...s.customProcedureTypes, v], procedureType: v));
    }
    if (s.fileKind == 'contract') {
      final items = [..._contractTypeOptions, ...s.customContractTypes];
      return _wizardSimpleClassifier(context, '3', 'نوع العقد', 'اختر نوع العقد أو أضف نوعاً جديداً.', items, s.contractType, (v) => notifier.state = s.copyWith(contractType: v), 'إضافة نوع عقد', (v) => notifier.state = s.copyWith(customContractTypes: [...s.customContractTypes, v], contractType: v));
    }
    if (s.fileKind == 'poa') {
      final items = [..._poaTypeOptions, ...s.customPoaTypes];
      return _wizardSimpleClassifier(context, '3', 'نوع الوكالة', 'اختر نوع الوكالة أو أضف نوعاً جديداً.', items, s.poaType, (v) => notifier.state = s.copyWith(poaType: v), 'إضافة نوع وكالة', (v) => notifier.state = s.copyWith(customPoaTypes: [...s.customPoaTypes, v], poaType: v));
    }
    return _wizardStep('3', 'أرشيف غير محدد', 'استخدم هذا المسار للمواد التي لا تنتمي لأي نوع معروف حالياً، مع إمكانية إضافة الوثائق المطلوبة يدوياً.', Text('سيتم حفظه كأرشيف يحتاج تصنيفاً لاحقاً.', style: AppTextStyles.bodyMediumSecondary));
  }

  Widget _wizardSimpleClassifier(BuildContext context, String number, String title, String subtitle, List<String> items, String? selected, ValueChanged<String> onSelect, String addLabel, ValueChanged<String> onAdd) {
    return _wizardStep(number, title, subtitle, Wrap(spacing: 8, runSpacing: 8, children: [
      ...items.map((v) => _choiceChip(selected == v, v, () => onSelect(v))),
      ActionChip(avatar: const Icon(Icons.add, size: 16), label: Text(addLabel), onPressed: () => _addCustomValue(context, addLabel, onAdd)),
    ]));
  }

  Widget _documentsHint(BuildContext context, WidgetRef ref, _ArchiveWizardSelection s) {
    final notifier = ref.read(_archiveWizardProvider.notifier);
    final docs = [..._defaultDocumentsFor(s), ...s.customDocumentTypes];
    return _wizardStep('4', 'الوثائق والثبوتيات المتوقعة', 'هذه قائمة مساعدة فقط، ويمكن إضافة أي وثيقة يحتاجها المستخدم داخل الأرشفة.', Wrap(spacing: 8, runSpacing: 8, children: [
      ...docs.map((d) => Chip(label: Text(d), avatar: const Icon(Icons.description, size: 16))),
      ActionChip(avatar: const Icon(Icons.add, size: 16), label: const Text('إضافة وثيقة'), onPressed: () => _addCustomValue(context, 'اسم الوثيقة', (value) => notifier.state = s.copyWith(customDocumentTypes: [...s.customDocumentTypes, value]))),
    ]));
  }

  List<String> _defaultDocumentsFor(_ArchiveWizardSelection s) {
    if (s.fileKind == 'case') return ['استدعاء الدعوى', 'الوكالة', 'الهوية / السجل', 'المبرزات', 'القرارات / الأحكام', if (s.isRunning) 'موعد الجلسة القادمة'];
    if (s.fileKind == 'company') {
      if (s.companyGroup == 'شركات أموال') return ['النظام الأساسي', 'طلب التأسيس', 'بيانات الشركاء', 'إيصال الرسوم', if (s.isRunning) 'موعد متابعة التأسيس'];
      if (s.companyGroup == 'شركات أشخاص') return ['عقد الشركة', 'بيانات الشركاء', 'السجل التجاري', 'إيصال الرسوم', if (s.isRunning) 'موعد متابعة'];
      return ['وثائق الشركة الأساسية'];
    }
    if (s.fileKind == 'procedure') return ['طلب المعاملة', 'الثبوتيات', 'الإيصالات', if (s.isRunning) 'موعد المراجعة القادمة'];
    if (s.fileKind == 'contract') return ['نسخة العقد', 'وثائق الأطراف', 'مرفقات العقد', if (s.isRunning) 'موعد تجديد / متابعة'];
    if (s.fileKind == 'poa') return ['سند الوكالة', 'هوية الموكل', 'بيانات الوكيل', 'فرع النقابة'];
    return ['اسم الوثيقة', 'وصف الوثيقة', 'مكان الأصل الورقي'];
  }

  bool _archiveSelectionReady(_ArchiveWizardSelection s) {
    if (s.archiveStatus == null || s.fileKind == null) return false;
    if (s.fileKind == 'case') return s.caseType != null && s.courtLevel != null;
    if (s.fileKind == 'company') return s.companyGroup != null && s.companyType != null;
    if (s.fileKind == 'procedure') return s.procedureType != null;
    if (s.fileKind == 'contract') return s.contractType != null;
    if (s.fileKind == 'poa') return s.poaType != null;
    return true;
  }

  Future<void> _addCustomValue(BuildContext context, String title, ValueChanged<String> onAdd) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'القيمة الجديدة')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('إضافة'))]));
    if (value == null || value.trim().isEmpty) return;
    onAdd(value.trim());
  }

  Future<void> _startArchiveEntry(BuildContext context, WidgetRef ref, _ArchiveWizardSelection s) async {
    final route = _routeForArchiveKind(s.fileKind ?? 'misc');
    final requiredPermission = _permissionForArchiveKind(s.fileKind ?? 'misc');
    if (requiredPermission != null && !ref.read(permissionServiceProvider).can(requiredPermission)) {
      await ref.read(auditServiceProvider).log(action: 'access_denied', category: 'archive', entityType: 'archive_wizard', description: 'محاولة بدء إدخال أرشيف دون صلاحية للنوع المحدد', severity: 'warning');
      return;
    }
    await ref.read(auditServiceProvider).log(action: 'start_entry', category: 'archive', entityType: 'archive_wizard', entityTitle: _archiveSummary(s), description: 'بدء إدخال أرشيف قديم من المعالج الهرمي', after: {'status': s.archiveStatus, 'kind': s.fileKind, 'summary': _archiveSummary(s)}, severity: 'info');
    if (!context.mounted) return;
    if (route == null) {
      await _showMiscArchiveEntry(context, ref, s);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('سيتم فتح شاشة الإدخال الرسمية. الاختيار: ${_archiveSummary(s)}'), backgroundColor: AppColors.success));
    context.go(_routeWithArchiveQuery(route, s));
  }

  String _routeWithArchiveQuery(String route, _ArchiveWizardSelection s) {
    final uri = Uri(path: route, queryParameters: {
      'archiveStatus': s.archiveStatus ?? '',
      'archiveKind': s.fileKind ?? '',
      'archiveSummary': _archiveSummary(s),
      if (s.caseType != null) 'caseType': s.caseType!,
      if (s.courtLevel != null) 'courtLevel': s.courtLevel!,
      if (s.companyGroup != null) 'companyGroup': s.companyGroup!,
      if (s.companyType != null) 'companyType': s.companyType!,
      if (s.procedureType != null) 'procedureType': s.procedureType!,
      if (s.contractType != null) 'contractType': s.contractType!,
      if (s.poaType != null) 'poaType': s.poaType!,
    });
    return uri.toString();
  }

  Future<void> _showMiscArchiveEntry(BuildContext context, WidgetRef ref, _ArchiveWizardSelection s) async {
    final titleController = TextEditingController(text: 'أرشيف غير محدد - ${DateTime.now().toString().substring(0, 10)}');
    final notesController = TextEditingController();
    final customDocs = <String>[...s.customDocumentTypes];
    final files = <File>[];
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('إدخال ${_archiveSummary(s)}'),
          content: SizedBox(
            width: 680,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('هذا المسار مخصص لأي أرشيف لا يطابق الأنواع المعروفة. يمكن تسمية الوثائق ورفع الملفات الآن ثم تصنيفها لاحقاً من صندوق غير مصنف.', style: AppTextStyles.bodySmallSecondary),
                  const SizedBox(height: 12),
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'اسم دفعة الأرشيف *')),
                  const SizedBox(height: 12),
                  TextField(controller: notesController, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات / وصف الأرشيف')),
                  const SizedBox(height: 12),
                  Text('أسماء الوثائق المطلوبة', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryNavy)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    ..._defaultDocumentsFor(s).map((d) => Chip(label: Text(d), avatar: const Icon(Icons.description, size: 16))),
                    ...customDocs.map((d) => Chip(label: Text(d), avatar: const Icon(Icons.description, size: 16))),
                    ActionChip(avatar: const Icon(Icons.add, size: 16), label: const Text('إضافة اسم وثيقة'), onPressed: () => _addCustomValue(ctx, 'اسم الوثيقة', (value) => setDialog(() => customDocs.add(value)))),
                  ]),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text(files.isEmpty ? 'اختيار ملفات' : 'الملفات المختارة: ${files.length}'),
                    onPressed: () async {
                      final result = await fp.FilePicker.platform.pickFiles(allowMultiple: true);
                      if (result == null) return;
                      setDialog(() {
                        files
                          ..clear()
                          ..addAll(result.paths.whereType<String>().map(File.new));
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('حفظ كأرشيف غير مصنف'),
              onPressed: titleController.text.trim().isEmpty
                  ? null
                  : () async {
                      final batchId = await ref.read(archiveIntakeRepositoryProvider).createBatch(
                            name: titleController.text.trim(),
                            sourceType: 'mixed',
                            createdBy: ref.read(authControllerProvider).user?.fullName,
                            notes: [
                              _archiveSummary(s),
                              if (customDocs.isNotEmpty) 'وثائق مخصصة: ${customDocs.join('، ')}',
                              if (notesController.text.trim().isNotEmpty) notesController.text.trim(),
                            ].join('\n'),
                          );
                      if (files.isNotEmpty) {
                        await ref.read(archiveIntakeRepositoryProvider).importFilesToBatch(batchId, files);
                      }
                      await ref.read(auditServiceProvider).log(action: 'create_misc', category: 'archive', entityType: 'archive_batch', entityId: '$batchId', entityTitle: titleController.text.trim(), description: 'إنشاء أرشيف غير محدد من المعالج', after: {'files': files.length, 'summary': _archiveSummary(s)}, severity: 'info');
                      ref.read(_archiveIntakeRefreshProvider.notifier).state++;
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
            ),
          ],
        ),
      ),
    );
  }

  String? _permissionForArchiveKind(String kind) {
    switch (kind) {
      case 'case': return PermissionKeys.casesCreateNew;
      case 'company': return PermissionKeys.companiesCreate;
      case 'procedure': return PermissionKeys.proceduresCreate;
      case 'contract': return PermissionKeys.contractsCreate;
      case 'poa': return PermissionKeys.poaCreate;
      default: return PermissionKeys.archiveIntakeCreate;
    }
  }

  String? _routeForArchiveKind(String kind) {
    switch (kind) {
      case 'case': return '/cases/create';
      case 'company': return '/companies/create';
      case 'procedure': return '/procedures/create';
      case 'contract': return '/contracts/create';
      case 'poa': return '/poa';
      default: return null;
    }
  }

  String _archiveSummary(_ArchiveWizardSelection s) {
    final parts = <String>[
      if (s.archiveStatus != null) (s.isRunning ? 'جارٍ' : 'منتهٍ'),
      _archiveFileKindOptions[s.fileKind] ?? s.fileKind ?? '',
      if (s.caseType != null) s.caseType!,
      if (s.courtLevel != null) s.courtLevel!,
      if (s.companyGroup != null) s.companyGroup!,
      if (s.companyType != null) s.companyType!,
      if (s.procedureType != null) s.procedureType!,
      if (s.contractType != null) s.contractType!,
      if (s.poaType != null) s.poaType!,
    ].where((p) => p.trim().isNotEmpty).toList();
    return parts.join(' > ');
  }

  Widget _importTemplatesPanel(BuildContext context, WidgetRef ref) {
    final canExport = ref.watch(permissionServiceProvider).can(PermissionKeys.archiveIntakeImportExcel);
    final templates = const [
      (key: 'contacts', title: 'الأشخاص والجهات', file: 'contacts_template.csv', icon: Icons.people_alt),
      (key: 'cases', title: 'الدعاوى', file: 'cases_template.csv', icon: Icons.gavel),
      (key: 'poa', title: 'الوكالات', file: 'poa_template.csv', icon: Icons.assignment_ind),
      (key: 'documents', title: 'المستندات', file: 'documents_template.csv', icon: Icons.description),
      (key: 'opening_balances', title: 'الأرصدة الافتتاحية', file: 'opening_balances_template.csv', icon: Icons.account_balance_wallet),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'صدّر القالب المناسب، املأه من الأرشيف القديم، ثم استورده لاحقاً ضمن دفعة Excel / CSV بعد تثبيت حقول المطابقة النهائية.',
              style: AppTextStyles.bodyMediumSecondary,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: templates
                  .map(
                    (t) => OutlinedButton.icon(
                      icon: Icon(t.icon, size: 18),
                      label: Text(t.title),
                      onPressed: canExport ? () => _exportImportTemplate(context, ref, t.key, t.file) : null,
                    ),
                  )
                  .toList(),
            ),
            if (!canExport) ...[
              const SizedBox(height: 8),
              Text('لا تملك صلاحية تصدير/استيراد قوالب الأرشيف.', style: AppTextStyles.bodySmallSecondary.copyWith(color: AppColors.error)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _exportImportTemplate(BuildContext context, WidgetRef ref, String templateKey, String fileName) async {
    if (!ref.read(permissionServiceProvider).can(PermissionKeys.archiveIntakeImportExcel)) {
      await ref.read(auditServiceProvider).log(
        action: 'access_denied',
        category: 'archive',
        entityType: 'archive_template',
        entityTitle: fileName,
        description: 'محاولة تصدير قالب استيراد أرشيف دون صلاحية',
        severity: 'warning',
      );
      return;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(docs.path, AppConstants.appDataDirectoryName, 'import_templates'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File(path.join(dir.path, fileName));
    await file.writeAsString(_templateContent(templateKey));
    await ref.read(auditServiceProvider).log(
      action: 'export_template',
      category: 'archive',
      entityType: 'archive_template',
      entityTitle: file.path,
      description: 'تصدير قالب استيراد للأرشيف القديم',
      after: {'template': templateKey},
      severity: 'info',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ القالب: ${file.path}'), backgroundColor: AppColors.success));
    }
  }

  String _templateContent(String key) {
    switch (key) {
      case 'contacts':
        return 'full_name,person_type,phone,email,national_id,address,notes\n"أحمد محمد","موكل","09xxxxxxxx","","","دمشق","مثال"\n';
      case 'cases':
        return 'internal_number,case_type,subject,court,base_number,status,client_name,opponent_name,next_session_date,notes\n"C-2026-001","مدني","مطالبة مالية","بداية مدني دمشق","123/2026","active","","","2026-01-01",""\n';
      case 'poa':
        return 'poa_number,poa_type,issued_at,delegate_name,bar_branch,principal_name,agent_name,notes\n"","عامة","2026-01-01","","دمشق","","",""\n';
      case 'documents':
        return 'file_name,document_type,related_file_type,related_file_number,paper_original_saved,paper_location,box,shelf,paper_folder,can_destroy_original,reviewed_by,notes\n"example.pdf","مستند أرشيف","دعوى","C-2026-001","yes","الخزانة 1","A-01","2","ملف ورقي 5","no","",""\n';
      case 'opening_balances':
        return 'client_name,file_number,fee_agreement_total,paid_amount,office_expenses,client_expenses,notes\n"","","0","0","0","0",""\n';
      default:
        return 'field_1,field_2,notes\n"","",""\n';
    }
  }

  Future<void> _showActiveNeedsCompletion(BuildContext context, WidgetRef ref) async {
    final permissions = ref.read(permissionServiceProvider);
    if (!permissions.can(PermissionKeys.archiveInboxView)) {
      await ref.read(auditServiceProvider).log(
        action: 'access_denied',
        category: 'archive',
        entityType: 'archive_completion',
        description: 'محاولة فتح ملفات الأرشيف التي تحتاج استكمال دون صلاحية',
        severity: 'warning',
      );
      return;
    }
    final files = ref.read(filesProvider)
        .where((file) => file.status == FileStatus.active && (file.hasDeficiencies || file.hasMissingDocuments || !file.hasBaseNumber))
        .toList()
      ..sort((a, b) => b.deficiencyCount.compareTo(a.deficiencyCount));
    await ref.read(auditServiceProvider).log(
      action: 'view',
      category: 'archive',
      entityType: 'archive_completion',
      description: 'عرض الملفات الجارية التي تحتاج استكمال',
      after: {'count': files.length},
      severity: 'info',
    );
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ملفات جارية تحتاج استكمال'),
        content: SizedBox(
          width: 900,
          height: 560,
          child: files.isEmpty
              ? const Center(child: Text('لا توجد ملفات جارية ناقصة حالياً.'))
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (_, index) {
                    final file = files[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: AppColors.error.withOpacity(0.12), child: Icon(_fileTypeIcon(file.type), color: AppColors.error)),
                        title: Text('${file.fileNumber} — ${file.title}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(_completionReasons(file).join(' • ')),
                        trailing: OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('فتح الملف'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openOfficeFile(context, file);
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }

  List<String> _completionReasons(FileItem file) {
    return [
      if (!file.hasBaseNumber) 'بانتظار رقم أساس/مرجع',
      if (file.hasDeficiencies) 'نواقص: ${file.deficiencyCount}',
      if (file.hasMissingDocuments) 'مستندات ناقصة',
      if (file.documentCount == 0) 'لا توجد مستندات رقمية',
    ];
  }

  IconData _fileTypeIcon(FileType type) {
    switch (type) {
      case FileType.caseFile:
        return Icons.gavel;
      case FileType.contract:
        return Icons.description;
      case FileType.company:
        return Icons.business;
      case FileType.adminProcedure:
        return Icons.assignment;
      case FileType.agency:
        return Icons.assignment_ind;
    }
  }

  void _openOfficeFile(BuildContext context, FileItem file) {
    switch (file.type) {
      case FileType.caseFile:
        context.go('/cases/${file.id}');
        return;
      case FileType.contract:
        context.go('/contracts/${file.id}');
        return;
      case FileType.company:
        context.go('/companies/${file.id}');
        return;
      case FileType.adminProcedure:
        context.go('/procedures/${file.id}');
        return;
      case FileType.agency:
        context.go('/poa/${file.id}');
        return;
    }
  }

  Widget _batchesList(WidgetRef ref) {
    final repo = ref.watch(archiveIntakeRepositoryProvider);
    return FutureBuilder(
      future: repo.getBatches(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final batches = snapshot.data!;
        if (batches.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text('لا توجد دفعات إدخال بعد. ابدأ بإنشاء دفعة من المسارات أعلاه.', style: AppTextStyles.bodyMediumSecondary),
            ),
          );
        }
        return Column(
          children: batches.map((b) {
            final canImport = ref.watch(permissionServiceProvider).can(PermissionKeys.archiveIntakeImportFiles);
            return Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.primaryNavy.withOpacity(0.12), child: Icon(_sourceIcon(b.sourceType), color: AppColors.primaryNavy)),
                title: Text(b.name, style: AppTextStyles.labelLarge),
                subtitle: Text('${_sourceLabel(b.sourceType)} • ${_statusLabel(b.status)} • ${b.createdAt.toString().substring(0, 16)}'),
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _mini('ملفات', b.totalFiles),
                    _mini('غير مصنف', b.unclassifiedFiles),
                    _mini('مكرر', b.duplicateFiles),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('فتح'),
                      onPressed: () => _showBatchDetails(context, ref, b.id, b.name),
                    ),
                    if (canImport)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: const Text('إضافة ملفات'),
                        onPressed: () => _importFiles(context, ref, b.id),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _mini(String label, int value) => Chip(label: Text('$label: $value'));

  IconData _sourceIcon(String source) {
    switch (source) {
      case 'paper': return Icons.document_scanner;
      case 'electronic': return Icons.folder_copy;
      case 'excel': return Icons.table_chart;
      case 'mixed': return Icons.all_inbox;
      default: return Icons.archive;
    }
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'paper': return 'أرشيف ورقي';
      case 'electronic': return 'أرشيف إلكتروني';
      case 'excel': return 'Excel / CSV';
      case 'mixed': return 'أرشيف مختلط';
      default: return source;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'new': return 'جديدة';
      case 'processing': return 'قيد المعالجة';
      case 'waiting_review': return 'بانتظار المراجعة';
      case 'completed': return 'مكتملة';
      case 'completed_with_errors': return 'مكتملة مع أخطاء';
      case 'cancelled': return 'ملغاة';
      default: return status;
    }
  }

  Future<void> _showCreateBatch(BuildContext context, WidgetRef ref, String sourceType) async {
    final name = TextEditingController(text: '${_sourceLabel(sourceType)} - ${DateTime.now().toString().substring(0, 10)}');
    final notes = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إنشاء دفعة ${_sourceLabel(sourceType)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الدفعة *')),
            const SizedBox(height: 12),
            TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إنشاء')),
        ],
      ),
    ) ?? false;
    if (!ok || name.text.trim().isEmpty) return;
    final user = ref.read(authControllerProvider).user;
    final id = await ref.read(archiveIntakeRepositoryProvider).createBatch(
      name: name.text.trim(),
      sourceType: sourceType,
      createdBy: user?.fullName,
      notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
    );
    await ref.read(auditServiceProvider).log(
      action: 'create',
      category: 'archive',
      entityType: 'archive_batch',
      entityId: '$id',
      entityTitle: name.text.trim(),
      description: 'إنشاء دفعة إدخال أرشيف',
      after: {'sourceType': sourceType},
      severity: 'info',
    );
    ref.read(_archiveIntakeRefreshProvider.notifier).state++;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء دفعة الأرشيف: ${name.text.trim()}'), backgroundColor: AppColors.success));
    }
  }

  Future<void> _importFiles(BuildContext context, WidgetRef ref, int batchId) async {
    if (!ref.read(permissionServiceProvider).can(PermissionKeys.archiveIntakeImportFiles)) {
      await ref.read(auditServiceProvider).log(action: 'access_denied', category: 'archive', entityType: 'archive_batch', entityId: '$batchId', description: 'محاولة استيراد ملفات أرشيف دون صلاحية', severity: 'warning');
      return;
    }
    final result = await fp.FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    final files = result.paths.whereType<String>().map(File.new).toList();
    if (files.isEmpty) return;
    final summary = await ref.read(archiveIntakeRepositoryProvider).importFilesToBatch(batchId, files);
    await ref.read(auditServiceProvider).log(
      action: 'import_files',
      category: 'archive',
      entityType: 'archive_batch',
      entityId: '$batchId',
      description: 'استيراد ملفات إلى دفعة أرشيف',
      after: {'files': files.length, 'imported': summary.imported, 'duplicates': summary.duplicates, 'failed': summary.failed},
      severity: 'info',
    );
    ref.read(_archiveIntakeRefreshProvider.notifier).state++;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت المعالجة: ${summary.imported} جديد، ${summary.duplicates} مكرر، ${summary.failed} فشل'),
          backgroundColor: summary.failed > 0 ? AppColors.warning : AppColors.success,
        ),
      );
    }
  }

  Future<void> _showDuplicates(BuildContext context, WidgetRef ref) async {
    final permissions = ref.read(permissionServiceProvider);
    if (!permissions.can(PermissionKeys.archiveDuplicatesView)) {
      await ref.read(auditServiceProvider).log(action: 'access_denied', category: 'archive', entityType: 'archive_duplicates', description: 'محاولة فتح المكررات دون صلاحية', severity: 'warning');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الملفات المكررة'),
        content: SizedBox(
          width: 860,
          height: 520,
          child: FutureBuilder<List<ArchiveItemRecord>>(
            future: ref.read(archiveIntakeRepositoryProvider).getItemsByStatus('duplicate'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final items = snapshot.data!;
              if (items.isEmpty) return const Center(child: Text('لا توجد ملفات مكررة حالياً.'));
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.copy_all, color: AppColors.info),
                      title: Text(item.originalFileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('دفعة #${item.batchId} • ${item.errorMessage ?? 'ملف مكرر محتمل'}'),
                      trailing: permissions.can(PermissionKeys.archiveDuplicatesResolve)
                          ? TextButton(
                              onPressed: () => _setItemReview(ctx, ref, item.id, item.batchId, 'rejected', 'rejected'),
                              child: const Text('تجاهل المكرر'),
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }

  Future<void> _showQualityReport(BuildContext context, WidgetRef ref) async {
    final permissions = ref.read(permissionServiceProvider);
    if (!permissions.can(PermissionKeys.archiveQualityView)) {
      await ref.read(auditServiceProvider).log(action: 'access_denied', category: 'archive', entityType: 'archive_quality', description: 'محاولة فتح تقرير جودة الأرشيف دون صلاحية', severity: 'warning');
      return;
    }
    final batches = await ref.read(archiveIntakeRepositoryProvider).getBatches();
    final files = batches.fold<int>(0, (sum, b) => sum + b.totalFiles);
    final processed = batches.fold<int>(0, (sum, b) => sum + b.processedFiles);
    final failed = batches.fold<int>(0, (sum, b) => sum + b.failedFiles);
    final duplicates = batches.fold<int>(0, (sum, b) => sum + b.duplicateFiles);
    final unclassified = batches.fold<int>(0, (sum, b) => sum + b.unclassifiedFiles);
    final approved = batches.fold<int>(0, (sum, b) => sum + b.approvedFiles);
    if (context.mounted) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تقرير جودة الأرشيف'),
          content: SizedBox(
            width: 620,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _qualityRow('عدد الدفعات', batches.length),
                _qualityRow('إجمالي الملفات', files),
                _qualityRow('تمت معالجتها', processed),
                _qualityRow('معتمدة', approved),
                _qualityRow('غير مصنفة', unclassified),
                _qualityRow('مكررة', duplicates),
                _qualityRow('فشلت', failed),
                const Divider(),
                ...batches.take(8).map((b) => ListTile(dense: true, title: Text(b.name), subtitle: Text('${_sourceLabel(b.sourceType)} • ${_statusLabel(b.status)}'), trailing: Text('${b.approvedFiles}/${b.totalFiles}'))),
              ],
            ),
          ),
          actions: [
            if (permissions.can(PermissionKeys.archiveQualityExport))
              OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('تصدير CSV'),
                onPressed: () async { Navigator.pop(ctx); await _exportQualityReport(context, ref, batches); },
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ],
        ),
      );
    }
    await ref.read(auditServiceProvider).log(action: 'view', category: 'archive', entityType: 'archive_quality', description: 'عرض تقرير جودة الأرشيف', severity: 'info');
  }

  Future<void> _exportQualityReport(BuildContext context, WidgetRef ref, List<ArchiveBatchRecord> batches) async {
    if (!ref.read(permissionServiceProvider).can(PermissionKeys.archiveQualityExport)) {
      await ref.read(auditServiceProvider).log(action: 'access_denied', category: 'archive', entityType: 'archive_quality', description: 'محاولة تصدير تقرير جودة الأرشيف دون صلاحية', severity: 'warning');
      return;
    }
    final buffer = StringBuffer('id,name,source,status,total,processed,approved,unclassified,duplicates,failed,createdAt\n');
    String esc(Object? v) => '"${(v ?? '').toString().replaceAll('"', '""')}"';
    for (final b in batches) {
      buffer.writeln([b.id, esc(b.name), esc(_sourceLabel(b.sourceType)), esc(_statusLabel(b.status)), b.totalFiles, b.processedFiles, b.approvedFiles, b.unclassifiedFiles, b.duplicateFiles, b.failedFiles, esc(b.createdAt.toIso8601String())].join(','));
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(docs.path, AppConstants.appDataDirectoryName, 'archive_quality_exports'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File(path.join(dir.path, 'archive_quality_${DateTime.now().millisecondsSinceEpoch}.csv'));
    await file.writeAsString(buffer.toString());
    await ref.read(auditServiceProvider).log(action: 'export', category: 'archive', entityType: 'archive_quality', entityTitle: file.path, description: 'تصدير تقرير جودة الأرشيف CSV', severity: 'warning');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تصدير تقرير الجودة: ${file.path}'), backgroundColor: AppColors.success));
    }
  }

  Widget _qualityRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [Expanded(child: Text(label, style: AppTextStyles.bodyMedium)), Text('$value', style: AppTextStyles.numberText.copyWith(color: AppColors.primaryNavy))]),
    );
  }

  Future<void> _showUnclassifiedInbox(BuildContext context, WidgetRef ref) async {
    final permissions = ref.read(permissionServiceProvider);
    if (!permissions.can(PermissionKeys.archiveInboxView)) {
      await ref.read(auditServiceProvider).log(action: 'access_denied', category: 'archive', entityType: 'archive_inbox', description: 'محاولة فتح صندوق الأرشيف غير المصنف دون صلاحية', severity: 'warning');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('صندوق الأرشيف غير المصنف'),
        content: SizedBox(
          width: 860,
          height: 560,
          child: FutureBuilder<List<ArchiveItemRecord>>(
            future: ref.read(archiveIntakeRepositoryProvider).getItemsByReviewStatus('needs_review'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return _itemsList(ctx, ref, snapshot.data!);
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }

  Future<void> _showBatchDetails(BuildContext context, WidgetRef ref, int batchId, String batchName) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تفاصيل الدفعة: $batchName'),
        content: SizedBox(
          width: 860,
          height: 560,
          child: FutureBuilder<List<ArchiveItemRecord>>(
            future: ref.read(archiveIntakeRepositoryProvider).getItemsForBatch(batchId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return _itemsList(ctx, ref, snapshot.data!);
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }

  Widget _itemsList(BuildContext dialogContext, WidgetRef ref, List<ArchiveItemRecord> items) {
    final permissions = ref.watch(permissionServiceProvider);
    if (items.isEmpty) return const Center(child: Text('لا توجد عناصر.'));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            leading: Icon(_itemIcon(item.status), color: _itemColor(item.status)),
            title: Text(item.originalFileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text([
              'دفعة #${item.batchId}',
              'الحالة: ${_itemStatusLabel(item.status)}',
              'المراجعة: ${_reviewStatusLabel(item.reviewStatus)}',
              if ((item.fileType ?? '').isNotEmpty) 'النوع: ${item.fileType}',
              if (item.errorMessage != null) 'ملاحظة: ${item.errorMessage}',
            ].join(' • ')),
            trailing: Wrap(
              spacing: 6,
              children: [
                if (permissions.can(PermissionKeys.archiveInboxLink) && item.status != 'duplicate' && item.status != 'failed' && item.reviewStatus != 'approved')
                  TextButton(onPressed: () => _showLinkItemDialog(dialogContext, ref, item), child: const Text('ربط بملف')),
                if (permissions.can(PermissionKeys.archiveInboxLink) && item.reviewStatus != 'approved')
                  TextButton(onPressed: () => _setItemReview(dialogContext, ref, item.id, item.batchId, 'imported', 'approved'), child: const Text('اعتماد عام')),
                if (permissions.can(PermissionKeys.archiveInboxReject) && item.status != 'rejected')
                  TextButton(onPressed: () => _setItemReview(dialogContext, ref, item.id, item.batchId, 'rejected', 'rejected'), child: const Text('رفض')),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setItemReview(BuildContext dialogContext, WidgetRef ref, int itemId, int batchId, String status, String reviewStatus) async {
    final permissions = ref.read(permissionServiceProvider);
    if (!permissions.can(PermissionKeys.archiveIntakeReview)) {
      await ref.read(auditServiceProvider).log(action: 'access_denied', category: 'archive', entityType: 'archive_item', entityId: '$itemId', description: 'محاولة مراجعة عنصر أرشيف دون صلاحية', severity: 'warning');
      return;
    }
    await ref.read(archiveIntakeRepositoryProvider).updateItemReview(itemId: itemId, status: status, reviewStatus: reviewStatus);
    await ref.read(archiveIntakeRepositoryProvider).refreshBatchCounters(batchId);
    await ref.read(auditServiceProvider).log(action: reviewStatus == 'approved' ? 'approve' : 'reject', category: 'archive', entityType: 'archive_item', entityId: '$itemId', description: reviewStatus == 'approved' ? 'اعتماد عنصر أرشيف' : 'رفض عنصر أرشيف', severity: reviewStatus == 'approved' ? 'info' : 'warning');
    ref.read(_archiveIntakeRefreshProvider.notifier).state++;
    if (dialogContext.mounted) Navigator.pop(dialogContext);
  }

  Future<void> _showLinkItemDialog(BuildContext context, WidgetRef ref, ArchiveItemRecord item) async {
    _ArchiveLinkTarget target = _ArchiveLinkTarget.caseFile;
    String documentType = _documentTypeOptions.containsKey(item.suggestedDocumentType) ? item.suggestedDocumentType! : 'archive_document';
    int? selectedId;
    String selectedTitle = '';
    final search = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('ربط ملف: ${item.originalFileName}'),
          content: SizedBox(
            width: 760,
            height: 560,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<_ArchiveLinkTarget>(
                        value: target,
                        decoration: const InputDecoration(labelText: 'يرتبط هذا المستند بـ'),
                        items: _ArchiveLinkTarget.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                        onChanged: (v) => setDialog(() { target = v ?? target; selectedId = null; selectedTitle = ''; search.clear(); }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: documentType,
                        decoration: const InputDecoration(labelText: 'نوع المستند'),
                        items: _documentTypeOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                        onChanged: (v) => setDialog(() => documentType = v ?? documentType),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: search, decoration: InputDecoration(labelText: 'بحث في ${target.label}', prefixIcon: const Icon(Icons.search)), onChanged: (_) => setDialog(() {})),
                const SizedBox(height: 8),
                Expanded(child: _linkChoices(ref, target, search.text, selectedId, (id, title) => setDialog(() { selectedId = id; selectedTitle = title; }))),
                if (selectedId != null) Align(alignment: Alignment.centerRight, child: Text('تم اختيار: $selectedTitle', style: AppTextStyles.bodySmallSecondary)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: selectedId == null
                  ? null
                  : () async {
                      try {
                        final docId = await ref.read(archiveIntakeRepositoryProvider).promoteItemToDocument(
                          itemId: item.id,
                          documentType: documentType,
                          entityType: target.entityType,
                          entityId: selectedId!,
                          userRef: ref.read(authControllerProvider).user?.fullName ?? 'المكتب',
                        );
                        await ref.read(auditServiceProvider).log(action: 'link', category: 'archive', entityType: 'archive_item', entityId: '${item.id}', entityTitle: item.originalFileName, description: 'ربط عنصر أرشيف بملف وإنشاء مستند رقم $docId', after: {'target': target.label, 'targetId': selectedId, 'documentType': documentType}, severity: 'info');
                        ref.read(_archiveIntakeRefreshProvider.notifier).state++;
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الربط: $e'), backgroundColor: AppColors.error));
                      }
                    },
              child: const Text('ربط واعتماد'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkChoices(WidgetRef ref, _ArchiveLinkTarget target, String rawQuery, int? selectedId, void Function(int id, String title) onSelect) {
    final query = rawQuery.trim().toLowerCase();
    switch (target) {
      case _ArchiveLinkTarget.caseFile:
        return ref.watch(allCasesProvider).when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Text('تعذر تحميل الدعاوى: $e'), data: (items) => _choiceList(items.where((c) => query.isEmpty || c.internalNumber.toLowerCase().contains(query) || (c.subject ?? '').toLowerCase().contains(query) || (c.baseNumber ?? '').toLowerCase().contains(query)).take(20).map((c) => (id: c.id, title: '${c.internalNumber} — ${c.subject ?? 'دعوى'}')).toList(), selectedId, onSelect));
      case _ArchiveLinkTarget.procedure:
        return ref.watch(allProceduresProvider).when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Text('تعذر تحميل الإجراءات: $e'), data: (items) => _choiceList(items.where((p) => query.isEmpty || p.title.toLowerCase().contains(query) || (p.transactionNumber ?? '').toLowerCase().contains(query)).take(20).map((p) => (id: p.id, title: '${p.title} — ${p.transactionNumber ?? p.procedureType}')).toList(), selectedId, onSelect));
      case _ArchiveLinkTarget.company:
        return ref.watch(allCompaniesProvider).when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Text('تعذر تحميل الشركات: $e'), data: (items) => _choiceList(items.where((c) => query.isEmpty || c.name.toLowerCase().contains(query) || c.internalNumber.toLowerCase().contains(query)).take(20).map((c) => (id: c.id, title: '${c.name} — ${c.internalNumber}')).toList(), selectedId, onSelect));
      case _ArchiveLinkTarget.contract:
        return ref.watch(allContractsProvider).when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Text('تعذر تحميل العقود: $e'), data: (items) => _choiceList(items.where((c) => query.isEmpty || c.title.toLowerCase().contains(query) || c.internalNumber.toLowerCase().contains(query)).take(20).map((c) => (id: c.id, title: '${c.title} — ${c.internalNumber}')).toList(), selectedId, onSelect));
      case _ArchiveLinkTarget.person:
        return ref.watch(allPersonsProvider(null)).when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Text('تعذر تحميل الأشخاص: $e'), data: (items) => _choiceList(items.where((p) => query.isEmpty || p.fullName.toLowerCase().contains(query) || (p.phone1 ?? '').contains(query) || (p.nationalId ?? '').contains(query)).take(20).map((p) => (id: p.id, title: p.fullName)).toList(), selectedId, onSelect));
      case _ArchiveLinkTarget.poa:
        return ref.watch(uiPersonsDirectoryProvider).when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Text('تعذر تحميل الوكالات: $e'), data: (state) => _choiceList(state.agencies.where((a) => query.isEmpty || a.number.toLowerCase().contains(query) || (state.personById(a.principalPersonId)?.fullName.toLowerCase().contains(query) ?? false)).take(20).map((a) => (id: int.tryParse(a.id) ?? 0, title: '${a.number} — ${state.personById(a.principalPersonId)?.fullName ?? 'موكل'}')).where((e) => e.id > 0).toList(), selectedId, onSelect));
    }
  }

  Widget _choiceList(List<({int id, String title})> choices, int? selectedId, void Function(int id, String title) onSelect) {
    if (choices.isEmpty) return const Center(child: Text('لا توجد نتائج مطابقة'));
    return ListView.builder(
      itemCount: choices.length,
      itemBuilder: (_, index) {
        final item = choices[index];
        final selected = selectedId == item.id;
        return ListTile(
          selected: selected,
          leading: Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, color: selected ? AppColors.success : AppColors.textSecondary),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => onSelect(item.id, item.title),
        );
      },
    );
  }

  IconData _itemIcon(String status) {
    switch (status) {
      case 'duplicate': return Icons.copy_all;
      case 'failed': return Icons.error_outline;
      case 'rejected': return Icons.block;
      default: return Icons.insert_drive_file;
    }
  }

  Color _itemColor(String status) {
    switch (status) {
      case 'duplicate': return AppColors.info;
      case 'failed': return AppColors.error;
      case 'rejected': return AppColors.error;
      default: return AppColors.primaryNavy;
    }
  }

  String _documentTypeLabel(String key) => _documentTypeOptions[key] ?? key;

  String _itemStatusLabel(String status) {
    switch (status) {
      case 'imported': return 'مستورد';
      case 'duplicate': return 'مكرر';
      case 'failed': return 'فشل';
      case 'rejected': return 'مرفوض';
      default: return status;
    }
  }

  String _reviewStatusLabel(String status) {
    switch (status) {
      case 'needs_review': return 'يحتاج مراجعة';
      case 'approved': return 'معتمد';
      case 'rejected': return 'مرفوض';
      default: return status;
    }
  }

  Widget _notice() {
    return Card(
      color: AppColors.warning.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.warning),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'يمكنك الآن إنشاء دفعات، إضافة ملفات، كشف المكررات، ربط العناصر بملفات المكتب، وتصدير قوالب CSV وتقارير الجودة. استيراد CSV المباشر سيُنفذ لاحقاً بحذر بعد تثبيت حقول المطابقة النهائية.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
