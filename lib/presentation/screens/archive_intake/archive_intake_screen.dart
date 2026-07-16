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
                _sectionTitle('ابدأ دفعة إدخال'),
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
