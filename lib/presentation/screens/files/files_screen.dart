/// شاشة الملفات الموحدة.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/permission_catalog.dart';
import '../../providers/auth_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../documents/document_models.dart' as doc_models;
import '../documents/document_viewer.dart';
import '../../providers/ui_data_providers.dart';

enum FileType {
  caseFile,
  contract,
  company,
  adminProcedure,
  agency;

  String get displayName => const ['دعوى', 'عقد', 'شركة', 'إجراء إداري', 'وكالة'][index];
}

enum FileStatus {
  active,
  completed,
  archived;

  String get displayName => const ['عاملة', 'منتهية', 'مؤرشفة'][index];

  Color get color => const [AppColors.info, AppColors.success, AppColors.textSecondary][index];
}

class FileItem {
  final String id;
  final String fileNumber;
  final String title;
  final String court;
  final String subCategory;
  final FileType type;
  final FileStatus status;
  final bool hasDeficiencies;
  final bool hasBaseNumber;
  final bool hasMissingDocuments;
  final bool isOverdue;
  final int deficiencyCount;
  final DateTime? nextSessionDate;
  final String? baseNumber;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final int documentCount;
  final List<String>? documentIds;

  const FileItem({
    required this.id,
    required this.fileNumber,
    required this.title,
    required this.type,
    required this.court,
    this.subCategory = '',
    required this.status,
    this.hasDeficiencies = false,
    this.deficiencyCount = 0,
    this.nextSessionDate,
    this.hasBaseNumber = true,
    this.baseNumber,
    this.hasMissingDocuments = false,
    this.isOverdue = false,
    required this.createdAt,
    required this.lastUpdated,
    this.documentCount = 0,
    this.documentIds,
  });

  Color get statusColor => status.color;
}

final filesProvider = Provider<List<FileItem>>((ref) {
  final asyncFiles = ref.watch(uiFilesProvider);
  return asyncFiles.maybeWhen(data: (items) => items, orElse: () => const <FileItem>[]);
});


class FilesScreen extends ConsumerStatefulWidget {
  final String? initialStatus;
  const FilesScreen({super.key, this.initialStatus});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  late String _statusFilter;
  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatus == 'completed' ? 'completed' : 'active';
  }

  @override
  void didUpdateWidget(covariant FilesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialStatus == 'completed' ? 'completed' : 'active';
    if (oldWidget.initialStatus != widget.initialStatus && _statusFilter != next) {
      _statusFilter = next;
    }
  }
  FileType? _typeFilter;
  String? _subCategoryFilter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final canCreate = ref.watch(permissionServiceProvider).canAny(const [
      PermissionKeys.casesCreateNew,
      PermissionKeys.contractsCreate,
      PermissionKeys.companiesCreate,
      PermissionKeys.proceduresCreate,
      PermissionKeys.workOrdersCreate,
      PermissionKeys.personsCreate,
      PermissionKeys.poaCreate,
      PermissionKeys.documentsUpload,
    ]);
    final allFiles = ref.watch(filesProvider);
    final files = _filteredFiles(allFiles);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ملفات المكتب'),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () => context.go('/search-reports'), tooltip: 'بحث'),
            if (ref.watch(permissionServiceProvider).can(PermissionKeys.archiveIntakeView))
              IconButton(icon: const Icon(Icons.archive_outlined), onPressed: () => context.go(_archiveIntakeRouteForCurrentTab()), tooltip: 'إدخال الأرشيف القديم'),
            if (canCreate)
              IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/new-work'), tooltip: 'جديد'),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilters(allFiles),
            _buildSummary(allFiles, files),
            Expanded(child: _buildOfficeFilesList(files)),
          ],
        ),
        floatingActionButton: canCreate
            ? FloatingActionButton.extended(
                onPressed: () => context.go('/new-work'),
                tooltip: 'عمل جديد',
                icon: const Icon(Icons.add),
                label: const Text('إضافة ملف / عمل'),
              )
            : null,
      ),
    );
  }

  List<FileItem> _filteredFiles(List<FileItem> all) {
    final q = _query.trim().toLowerCase();
    return all.where((file) {
      final statusOk = switch (_statusFilter) {
        'all' => true,
        'active' => file.status == FileStatus.active,
        'completed' => file.status == FileStatus.completed || file.status == FileStatus.archived,
        'needs_completion' => file.hasDeficiencies || file.hasMissingDocuments || !file.hasBaseNumber,
        _ => true,
      };
      final typeOk = _typeFilter == null || file.type == _typeFilter;
      final subCategoryOk = _subCategoryFilter == null || file.subCategory == _subCategoryFilter;
      final queryOk = q.isEmpty ||
          file.fileNumber.toLowerCase().contains(q) ||
          file.title.toLowerCase().contains(q) ||
          file.court.toLowerCase().contains(q) ||
          (file.baseNumber ?? '').toLowerCase().contains(q);
      return statusOk && typeOk && subCategoryOk && queryOk;
    }).toList()
      ..sort((a, b) => (a.nextSessionDate ?? DateTime(9999)).compareTo(b.nextSessionDate ?? DateTime(9999)));
  }

  Widget _buildFilters(List<FileItem> allFiles) {
    final subCategories = allFiles
        .where((f) => _typeFilter == null || f.type == _typeFilter)
        .map((f) => f.subCategory)
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (_subCategoryFilter != null && !subCategories.contains(_subCategoryFilter)) {
      _subCategoryFilter = null;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'بحث برقم الملف، الاسم، المحكمة/الجهة، رقم الأساس أو القيد...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<FileType?>(
                value: _typeFilter,
                items: [
                  const DropdownMenuItem<FileType?>(value: null, child: Text('كل الأنواع')),
                  ...FileType.values.map((type) => DropdownMenuItem<FileType?>(value: type, child: Text(type.displayName))),
                ],
                onChanged: (value) => setState(() {
                  _typeFilter = value;
                  _subCategoryFilter = null;
                }),
              ),
              const SizedBox(width: 12),
              DropdownButton<String?>(
                value: _subCategoryFilter,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('كل التصنيفات')),
                  ...subCategories.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
                ],
                onChanged: (value) => setState(() => _subCategoryFilter = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statusTab('active', 'الملفات الجارية', 'تؤثر على مكتب العمل والمواعيد القادمة')),
              const SizedBox(width: 10),
              Expanded(child: _statusTab('completed', 'الملفات المنتهية', 'للحفظ والبحث فقط دون أثر على المواعيد')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusTab(String value, String label, String subtitle) {
    final selected = _statusFilter == value;
    return InkWell(
      onTap: () {
        setState(() => _statusFilter = value);
        context.go('/files?status=$value');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryNavy.withOpacity(0.10) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primaryNavy : AppColors.cardBorder, width: selected ? 1.5 : 0.7),
        ),
        child: Row(
          children: [
            Icon(value == 'active' ? Icons.pending_actions : Icons.inventory_2, color: selected ? AppColors.primaryNavy : AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelLarge.copyWith(color: selected ? AppColors.primaryNavy : AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTextStyles.bodySmallSecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.success),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(List<FileItem> all, List<FileItem> filtered) {
    final active = all.where((f) => f.status == FileStatus.active).length;
    final completed = all.where((f) => f.status == FileStatus.completed || f.status == FileStatus.archived).length;
    final needs = all.where((f) => f.hasDeficiencies || f.hasMissingDocuments || !f.hasBaseNumber).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          _metric('المعروض', filtered.length, Icons.folder_open, AppColors.primaryNavy),
          _metric('جارية', active, Icons.play_circle_outline, AppColors.info),
          _metric('منتهية', completed, Icons.check_circle_outline, AppColors.success),
          _metric('تحتاج استكمال', needs, Icons.warning_amber, AppColors.warning),
        ],
      ),
    );
  }

  Widget _metric(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(0.22))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text('$label: ', style: AppTextStyles.labelSmall),
          Text('$count', style: AppTextStyles.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }

  String _archiveIntakeRouteForCurrentTab() {
    return _statusFilter == 'completed' ? '/archive-intake?status=closed' : '/archive-intake?status=running';
  }

  Widget _buildOfficeFilesList(List<FileItem> files) {
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off, size: 72, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('لا توجد ملفات ضمن هذا التبويب', style: AppTextStyles.headline6),
            const SizedBox(height: 8),
            Text(_statusFilter == 'active' ? 'ابدأ بإدخال أرشيف جارٍ أو إضافة عمل جديد.' : 'يمكنك إدخال أرشيف منتهٍ ليظهر هنا للبحث والحفظ فقط.', style: AppTextStyles.bodySmallSecondary),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                if (ref.watch(permissionServiceProvider).can(PermissionKeys.archiveIntakeView))
                  ElevatedButton.icon(
                    icon: const Icon(Icons.archive_outlined),
                    label: const Text('إدخال الأرشيف القديم'),
                    onPressed: () => context.go(_archiveIntakeRouteForCurrentTab()),
                  ),
                if (_statusFilter == 'active')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('عمل جديد'),
                    onPressed: () => context.go('/new-work'),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) => FileCard(file: files[index]),
    );
  }
}

class AllFilesTab extends ConsumerWidget {
  const AllFilesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _buildList(ref.watch(filesProvider), context);
}

class ActiveFilesTab extends ConsumerWidget {
  const ActiveFilesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _buildList(
        ref.watch(filesProvider).where((file) => file.status == FileStatus.active).toList(),
        context,
        'لا يوجد ملفات جارية',
      );
}

class DeficientFilesTab extends ConsumerWidget {
  const DeficientFilesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _buildList(
        ref.watch(filesProvider).where((file) => file.hasDeficiencies).toList(),
        context,
        'لا يوجد ملفات ناقصة',
      );
}

class OverdueFilesTab extends ConsumerWidget {
  const OverdueFilesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _buildList(
        ref.watch(filesProvider).where((file) => file.isOverdue).toList(),
        context,
        'لا يوجد ملفات متأخرة',
      );
}

class CompletedFilesTab extends ConsumerWidget {
  const CompletedFilesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _buildList(
        ref.watch(filesProvider).where((file) => file.status == FileStatus.completed).toList(),
        context,
        'لا يوجد ملفات منتهية',
      );
}

class NearSessionFilesTab extends ConsumerWidget {
  const NearSessionFilesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _buildList(
        ref.watch(filesProvider).where((file) => file.nextSessionDate != null).toList(),
        context,
        'لا يوجد ملفات بجلسة قريب',
      );
}

class WaitingBaseFilesTab extends ConsumerWidget {
  const WaitingBaseFilesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _buildList(
        ref.watch(filesProvider).where((file) => !file.hasBaseNumber).toList(),
        context,
        'لا يوجد ملفات بانتظار رقم أساس',
      );
}

class WaitingDocFilesTab extends ConsumerWidget {
  const WaitingDocFilesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _buildList(
        ref.watch(filesProvider).where((file) => file.hasMissingDocuments).toList(),
        context,
        'لا يوجد ملفات بانتظار مستند',
      );
}

Widget _buildList(List<FileItem> files, BuildContext context, [String empty = 'لا يوجد ملفات']) {
  if (files.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(empty, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  final ordered = [...files]
    ..sort((a, b) => (a.nextSessionDate ?? DateTime(9999)).compareTo(b.nextSessionDate ?? DateTime(9999)));
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: ordered.length,
    itemBuilder: (context, index) => FileCard(file: ordered[index]),
  );
}

class FileCard extends StatelessWidget {
  final FileItem file;

  const FileCard({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openFile(context),
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
                      file.fileNumber,
                      style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy),
                    ),
                  ),
                  _tag(file.type.displayName, AppColors.primaryNavy),
                  if (file.subCategory.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _tag(file.subCategory, AppColors.info),
                  ],
                  const SizedBox(width: 8),
                  _tag(file.status.displayName, file.statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Text(file.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              if (file.type == FileType.caseFile && file.court.isNotEmpty) _line(Icons.balance, file.court),
              if (file.hasBaseNumber && file.baseNumber != null)
                _line(Icons.confirmation_number, 'رقم الأساس: ${file.baseNumber}')
              else
                _tagLine('بانتظار رقم أساس', AppColors.warning),
              if (file.nextSessionDate != null) _line(Icons.calendar_today, 'الجلسة: ${_formatDate(file.nextSessionDate!)}'),
              if (file.hasDeficiencies) _tagLine('نواقص: ${file.deficiencyCount}', AppColors.error),
              if (file.hasMissingDocuments) _tagLine('مستندات ناقصة', AppColors.warning),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_file, color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text('المستندات: ${file.documentCount}', style: AppTextStyles.bodySmallSecondary),
                  const SizedBox(width: 8),
                  if (file.documentCount > 0 && (file.documentIds?.isNotEmpty ?? false))
                    TextButton(onPressed: () => _showDocsDialog(context, file), child: const Text('عرض المستندات')),
                ],
              ),
              Text('آخر تحديث: ${_formatDate(file.lastUpdated)}', style: AppTextStyles.bodySmallSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _openFile(BuildContext context) {
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

  Widget _line(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 4),
          Expanded(child: Text(text, style: AppTextStyles.bodySmallSecondary)),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: AppTextStyles.labelSmall.copyWith(color: color)),
    );
  }

  Widget _tagLine(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(alignment: Alignment.centerRight, child: _tag(text, color)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showMsg(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.info));
  }

  void _showDocsDialog(BuildContext context, FileItem file) {
    showDialog<void>(context: context, builder: (context) => FileDocsDialog(file: file));
  }
}

class FileDocsDialog extends ConsumerWidget {
  final FileItem file;

  const FileDocsDialog({super.key, required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = _getDocs(file);
    final canOpenDocs = ref.watch(permissionServiceProvider).can(PermissionKeys.documentsOpen);
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
                      'مستندات الملف: ${file.fileNumber}',
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
                  subtitle: Text('${docs[index].fileType.displayName} - ${docs[index].formattedSize}', style: AppTextStyles.bodySmallSecondary),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    onPressed: canOpenDocs ? () => openDocument(context, docs[index].id) : null,
                    tooltip: 'فتح',
                  ),
                  onTap: canOpenDocs ? () => openDocument(context, docs[index].id) : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<doc_models.DocumentItem> _getDocs(FileItem file) {
    final ids = file.documentIds ?? const <String>[];
    return ids
        .asMap()
        .entries
        .map(
          (entry) => doc_models.DocumentItem(
            id: entry.value,
            title: 'مستند ${entry.key + 1} - ${file.fileNumber}',
            documentType: entry.key == 0 ? doc_models.DocumentType.powerOfAttorney : doc_models.DocumentType.caseDocument,
            entityType: file.type.toString().split('.').last,
            entityId: file.id,
            entityTitle: file.title,
            filePath: 'docs/files/${file.id}_${entry.key + 1}.pdf',
            fileName: '${file.id}_${entry.key + 1}.pdf',
            fileSize: 512 * 1024,
            fileType: doc_models.FileType.pdf,
            uploadDate: DateTime(2026, 7, 5 + entry.key),
            uploadedBy: 'مكتب المحامي',
            physicalLocation: 'أرشيف المكتب',
          ),
        )
        .toList();
  }
}

class FilesFilterDialog extends StatefulWidget {
  const FilesFilterDialog({super.key});

  @override
  State<FilesFilterDialog> createState() => _FilesFilterDialogState();
}

class _FilesFilterDialogState extends State<FilesFilterDialog> {
  FileType? _type;
  FileStatus? _status;
  bool _deficient = false;
  bool _missingDocuments = false;
  bool _overdue = false;
  bool _pendingBase = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('فلترة الملفات', style: AppTextStyles.headline4.copyWith(color: AppColors.primaryNavy)),
            const SizedBox(height: 24),
            DropdownButtonFormField<FileType?>(
              value: _type,
              items: [
                const DropdownMenuItem<FileType?>(value: null, child: Text('جميع الأنواع')),
                ...FileType.values.map((type) => DropdownMenuItem<FileType?>(value: type, child: Text(type.displayName))),
              ],
              onChanged: (value) => setState(() => _type = value),
              decoration: const InputDecoration(labelText: 'نوع الملف'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FileStatus?>(
              value: _status,
              items: [
                const DropdownMenuItem<FileStatus?>(value: null, child: Text('جميع الحالات')),
                ...FileStatus.values.map((status) => DropdownMenuItem<FileStatus?>(value: status, child: Text(status.displayName))),
              ],
              onChanged: (value) => setState(() => _status = value),
              decoration: const InputDecoration(labelText: 'حالة الملف'),
            ),
            CheckboxListTile(title: const Text('الملفات الناقصة'), value: _deficient, onChanged: (value) => setState(() => _deficient = value ?? false)),
            CheckboxListTile(title: const Text('المستندات الناقصة'), value: _missingDocuments, onChanged: (value) => setState(() => _missingDocuments = value ?? false)),
            CheckboxListTile(title: const Text('الملفات المتأخرة'), value: _overdue, onChanged: (value) => setState(() => _overdue = value ?? false)),
            CheckboxListTile(title: const Text('بانتظار رقم أساس'), value: _pendingBase, onChanged: (value) => setState(() => _pendingBase = value ?? false)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم تطبيق الفلاتر'), backgroundColor: AppColors.success));
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
