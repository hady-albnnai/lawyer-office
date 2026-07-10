/// شاشة الملفات الموحدة.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../documents/document_models.dart' as doc_models;
import '../documents/document_viewer.dart';

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

final filesProvider = Provider<List<FileItem>>(
  (ref) => [
    FileItem(
      id: '1',
      fileNumber: '2026/001',
      title: 'دعوى تعويض',
      type: FileType.caseFile,
      court: 'محكمة دمشق الأولى',
      status: FileStatus.active,
      hasDeficiencies: true,
      deficiencyCount: 2,
      nextSessionDate: DateTime(2026, 7, 15),
      baseNumber: '12345',
      createdAt: DateTime(2026, 7, 1),
      lastUpdated: DateTime(2026, 7, 9),
      documentCount: 3,
      documentIds: const ['doc_1', 'doc_2', 'doc_3'],
    ),
    FileItem(
      id: '2',
      fileNumber: '2026/002',
      title: 'دعوى استئناف',
      type: FileType.caseFile,
      court: 'محكمة الاستئناف',
      status: FileStatus.active,
      hasDeficiencies: true,
      deficiencyCount: 1,
      nextSessionDate: DateTime(2026, 7, 10),
      hasBaseNumber: false,
      createdAt: DateTime(2026, 7, 2),
      lastUpdated: DateTime(2026, 7, 8),
      documentCount: 2,
      documentIds: const ['doc_4', 'doc_5'],
    ),
    FileItem(
      id: '3',
      fileNumber: '2026/003',
      title: 'دعوى تجارية',
      type: FileType.caseFile,
      court: 'محكمة دمشق الأولى',
      status: FileStatus.completed,
      nextSessionDate: null,
      baseNumber: '67890',
      createdAt: DateTime(2026, 6, 15),
      lastUpdated: DateTime(2026, 7, 5),
      documentCount: 5,
      documentIds: const ['doc_6', 'doc_7', 'doc_8', 'doc_9', 'doc_10'],
    ),
  ],
);

class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 8,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('الملفات'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(color: AppColors.secondaryGold, width: 3),
                  ),
                  labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: AppTextStyles.labelMedium,
                  tabs: const [
                    Tab(text: 'الكل'),
                    Tab(text: 'عاملة'),
                    Tab(text: 'ناقصة'),
                    Tab(text: 'متأخرة'),
                    Tab(text: 'منتهية'),
                    Tab(text: 'جلسة قريب'),
                    Tab(text: 'بانتظار رقم أساس'),
                    Tab(text: 'بانتظار مستند'),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () => context.go('/search-reports'), tooltip: 'بحث'),
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: () => showDialog<void>(context: context, builder: (context) => const FilesFilterDialog()),
                tooltip: 'فلترة',
              ),
              IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/new-work'), tooltip: 'جديد'),
            ],
          ),
          body: const TabBarView(
            children: [
              AllFilesTab(),
              ActiveFilesTab(),
              DeficientFilesTab(),
              OverdueFilesTab(),
              CompletedFilesTab(),
              NearSessionFilesTab(),
              WaitingBaseFilesTab(),
              WaitingDocFilesTab(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.go('/new-work'),
            tooltip: 'عمل جديد',
            child: const Icon(Icons.add),
          ),
        ),
      ),
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
        'لا يوجد ملفات تعمل',
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
        onTap: () => _showMsg(context, 'فتح الملف: ${file.fileNumber}'),
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

class FileDocsDialog extends StatelessWidget {
  final FileItem file;

  const FileDocsDialog({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final docs = _getDocs(file);
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
            entityType: file.type.name,
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
