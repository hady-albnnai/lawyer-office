/// شاشة الملفات الموحدة
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../documents/document_models.dart' as doc_models;
import '../documents/document_viewer.dart';

enum FileType { caseFile, contract, company, adminProcedure, agency;
String get displayName => const ['دعوى','عقد','شركة','إجراء إداري','وكالة'][index]; }
enum FileStatus { active, completed, archived;
String get displayName => const ['عاملة','منتهية','مؤرشفة'][index];
Color get color => const [AppColors.info, AppColors.success, AppColors.textSecondary][index]; }

class FileItem {
  final String id, fileNumber, title, court;
  final FileType type; final FileStatus status;
  final bool hasDeficiencies, hasBaseNumber, hasMissingDocuments, isOverdue;
  final int deficiencyCount; final DateTime? nextSessionDate;
  final String? baseNumber; final DateTime createdAt, lastUpdated;
  final int documentCount; final List<String>? documentIds;
  FileItem({required this.id, required this.fileNumber, required this.title, required this.type, required this.court, required this.status, this.hasDeficiencies=false, this.deficiencyCount=0, this.nextSessionDate, this.hasBaseNumber=true, this.baseNumber, this.hasMissingDocuments=false, this.isOverdue=false, required this.createdAt, required this.lastUpdated, this.documentCount=0, this.documentIds});
  Color get statusColor => status.color;
}

final filesProvider = Provider<List<FileItem>>((ref) => [
  FileItem(id: '1', fileNumber: '2026/001', title: 'دعوى تعويض', type: FileType.caseFile, court: 'محكمة دمشق الأولى', status: FileStatus.active, hasDeficiencies: true, deficiencyCount: 2, nextSessionDate: DateTime(2026, 7, 15), hasBaseNumber: true, baseNumber: '12345', createdAt: DateTime(2026, 7, 1), lastUpdated: DateTime(2026, 7, 9), documentCount: 3, documentIds: ['doc_1', 'doc_2', 'doc_3']),
  FileItem(id: '2', fileNumber: '2026/002', title: 'دعوى استئناف', type: FileType.caseFile, court: 'محكمة الاستئناف', status: FileStatus.active, hasDeficiencies: true, deficiencyCount: 1, nextSessionDate: DateTime(2026, 7, 10), hasBaseNumber: false, createdAt: DateTime(2026, 7, 2), lastUpdated: DateTime(2026, 7, 8), documentCount: 2, documentIds: ['doc_4', 'doc_5']),
  FileItem(id: '3', fileNumber: '2026/003', title: 'دعوى تجارية', type: FileType.caseFile, court: 'محكمة دمشق الأولى', status: FileStatus.completed, hasDeficiencies: false, nextSessionDate: null, hasBaseNumber: true, baseNumber: '67890', createdAt: DateTime(2026, 6, 15), lastUpdated: DateTime(2026, 7, 5), documentCount: 5, documentIds: ['doc_6', 'doc_7', 'doc_8', 'doc_9', 'doc_10']),
]);

class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(length: 8, child: Scaffold(
      appBar: AppBar(title: const Text('الملفات'), bottom: PreferredSize(preferredSize: const Size.fromHeight(48), child: Container(height: 48, margin: const EdgeInsets.symmetric(horizontal: 16), child: TabBar(isScrollable: true, indicatorSize: TabBarIndicatorSize.tab, indicator: UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.secondaryGold, width: 3)), labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold), unselectedLabelStyle: AppTextStyles.labelMedium, tabs: const [Tab(text: 'الكل'), Tab(text: 'عاملة'), Tab(text: 'ناقصة'), Tab(text: 'متأخرة'), Tab(text: 'منتهية'), Tab(text: 'جلسة قريب'), Tab(text: 'بانتظار رقم أساس'), Tab(text: 'بانتظار مستند')]))), actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => context.go('/search-reports'), tooltip: 'بحث'), IconButton(icon: const Icon(Icons.filter_alt), onPressed: () => showDialog(context: context, builder: (c) => const FilesFilterDialog()), tooltip: 'فلترة'), IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/new-work'), tooltip: 'جديد')]),
      body: const TabBarView(children: [AllFilesTab(), ActiveFilesTab(), DeficientFilesTab(), OverdueFilesTab(), CompletedFilesTab(), NearSessionFilesTab(), WaitingBaseFilesTab(), WaitingDocFilesTab()]),
      floatingActionButton: FloatingActionButton(onPressed: () => context.go('/new-work'), tooltip: 'عمل جديد', child: const Icon(Icons.add)),
    ));
  }
}

class AllFilesTab extends ConsumerWidget { const AllFilesTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final files = ref.watch(filesProvider); return _buildList(files, context); } }
class ActiveFilesTab extends ConsumerWidget { const ActiveFilesTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final files = ref.watch(filesProvider).where((f) => f.status == FileStatus.active).toList(); return _buildList(files, context, 'لا يوجد ملفات تعمل'); } }
class DeficientFilesTab extends ConsumerWidget { const DeficientFilesTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final files = ref.watch(filesProvider).where((f) => f.hasDeficiencies).toList(); return _buildList(files, context, 'لا يوجد ملفات ناقصة'); } }
class OverdueFilesTab extends ConsumerWidget { const OverdueFilesTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final files = ref.watch(filesProvider).where((f) => f.isOverdue).toList(); return _buildList(files, context, 'لا يوجد ملفات متأخرة'); } }
class CompletedFilesTab extends ConsumerWidget { const CompletedFilesTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final files = ref.watch(filesProvider).where((f) => f.status == FileStatus.completed).toList(); return _buildList(files, context, 'لا يوجد ملفات منتهية'); } }
class NearSessionFilesTab extends ConsumerWidget { const NearSessionFilesTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final files = ref.watch(filesProvider).where((f) => f.nextSessionDate != null).toList(); return _buildList(files, context, 'لا يوجد ملفات بجلسة قريب'); } }
class WaitingBaseFilesTab extends ConsumerWidget { const WaitingBaseFilesTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final files = ref.watch(filesProvider).where((f) => !f.hasBaseNumber).toList(); return _buildList(files, context, 'لا يوجد ملفات بانتظار رقم أساس'); } }
class WaitingDocFilesTab extends ConsumerWidget { const WaitingDocFilesTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final files = ref.watch(filesProvider).where((f) => f.hasMissingDocuments).toList(); return _buildList(files, context, 'لا يوجد ملفات بانتظار مستند'); } }

Widget _buildList(List<FileItem> files, BuildContext ctx, [String empty = 'لا يوجد ملفات']) {
  if(files.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.folder_open, size: 64, color: AppColors.textSecondary), const SizedBox(height: 16), Text(empty, style: AppTextStyles.bodyMedium)]));
  files.sort((a,b) => (a.nextSessionDate ?? DateTime(9999)).compareTo(b.nextSessionDate ?? DateTime(9999)));
  return ListView.builder(padding: const EdgeInsets.all(16), itemCount: files.length, itemBuilder: (c, i) => FileCard(file: files[i]));
}

class FileCard extends StatelessWidget {
  final FileItem file;
  const FileCard({super.key, required this.file});
  @override Widget build(BuildContext context) {
    return Card(margin: const EdgeInsets.only(bottom: 12), child: InkWell(onTap: () => _showMsg(context, 'فتح الملف: ${file.fileNumber}'), borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Text(file.fileNumber, style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(4)), child: Text(file.type.displayName, style: AppTextStyles.bodySmallSecondary)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: file.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(file.status.displayName, style: AppTextStyles.labelSmall.copyWith(color: file.statusColor)))]),
      const SizedBox(height: 8),
      Text(file.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      if(file.type == FileType.caseFile && file.court.isNotEmpty) ...[Row(children: [Icon(Icons.balance, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text(file.court, style: AppTextStyles.bodySmallSecondary)]), const SizedBox(height: 4)],
      if(file.hasBaseNumber && file.baseNumber != null) ...[Row(children: [Icon(Icons.confirmation_number, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('رقم الأساس: ${file.baseNumber}', style: AppTextStyles.bodySmallSecondary)]), const SizedBox(height: 4)] else ...[Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text('بانتظار رقم أساس', style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning))), const SizedBox(height: 4)],
      if(file.nextSessionDate != null) ...[Row(children: [Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('الجلسة: ${file.nextSessionDate!.year}-${file.nextSessionDate!.month.toString().padLeft(2,"0")}-${file.nextSessionDate!.day.toString().padLeft(2,"0")}', style: AppTextStyles.bodySmall.copyWith(color: file.isOverdue ? AppColors.error : AppColors.textPrimary, fontWeight: file.isOverdue ? FontWeight.bold : FontWeight.normal))]), const SizedBox(height: 4)],
      if(file.hasDeficiencies) ...[Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text('نواقص: ${file.deficiencyCount}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))), const SizedBox(height: 4)],
      if(file.hasMissingDocuments) ...[Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text('مستندات ناقصة', style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning))), const SizedBox(height: 4)],
      Row(children: [Icon(Icons.attach_file, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('المستندات: ${file.documentCount}', style: AppTextStyles.bodySmallSecondary), const SizedBox(width: 8), if(file.documentCount > 0 && file.documentIds != null && file.documentIds!.isNotEmpty) TextButton(onPressed: () => _showDocsDialog(context, file), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: Text('عرض المستندات', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryNavy)))]),
      const SizedBox(height: 8),
      Text('آخر تحديث: ${file.lastUpdated.year}-${file.lastUpdated.month.toString().padLeft(2,"0")}-${file.lastUpdated.day.toString().padLeft(2,"0")}', style: AppTextStyles.bodySmallSecondary),
    ])));
  }
  void _showMsg(BuildContext c, String msg) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.info));
  void _showDocsDialog(BuildContext c, FileItem f) => showDialog(context: c, builder: (x) => FileDocsDialog(file: f));
}

class FileDocsDialog extends StatelessWidget {
  final FileItem file;
  const FileDocsDialog({super.key, required this.file});
  @override Widget build(BuildContext context) {
    final docs = _getDocs(file);
    return Dialog(insetPadding: const EdgeInsets.all(16), child: Container(constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.primaryNavy, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))), child: Row(children: [Icon(Icons.attach_file, color: AppColors.textOnLight, size: 24), const SizedBox(width: 8), Text('مستندات الملف: ${file.fileNumber}', style: AppTextStyles.headline6.copyWith(color: AppColors.textOnLight))])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (c, i) => ListTile(leading: Icon(docs[i].fileType.icon, color: AppColors.primaryNavy, size: 24), title: Text(docs[i].title, style: AppTextStyles.bodyMedium), subtitle: Text('${docs[i].fileType.displayName} - ${docs[i].formattedSize}', style: AppTextStyles.bodySmallSecondary), trailing: IconButton(icon: const Icon(Icons.open_in_new, size: 18), onPressed: () => openDocument(context, docs[i].id), tooltip: 'فتح'), onTap: () => openDocument(context, docs[i].id)))),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)), border: Border.all(color: AppColors.cardBorder, width: 0.5)), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))]))
    ])));
  }
  List<doc_models.DocumentItem> _getDocs(FileItem f) => [
    doc_models.DocumentItem(id: f.documentIds![0], title: 'وكالة ${f.fileNumber}', documentType: doc_models.DocumentType.powerOfAttorney, entityType: f.type.name, entityId: f.id, entityTitle: f.title, filePath: 'docs/poa/${f.id}_1.pdf', fileName: 'poa_${f.id}_1.pdf', fileSize: 1024*1024, fileType: doc_models.FileType.pdf, uploadDate: DateTime(2026,7,5), uploadedBy: 'هادي البني', physicalLocation: 'ديوان المحامي'),
    doc_models.DocumentItem(id: f.documentIds![1], title: 'قرار ${f.fileNumber}', documentType: doc_models.DocumentType.decision, entityType: f.type.name, entityId: f.id, entityTitle: f.title, filePath: 'docs/cases/dec${f.id}_1.pdf', fileName: 'dec_${f.id}_1.pdf', fileSize: 512*1024, fileType: doc_models.FileType.pdf, uploadDate: DateTime(2026,7,9), uploadedBy: 'أحمد محمد', physicalLocation: 'ديوان المحكمة'),
    if(f.documentIds!.length > 2) doc_models.DocumentItem(id: f.documentIds![2], title: 'مذكرة ${f.fileNumber}', documentType: doc_models.DocumentType.memo, entityType: f.type.name, entityId: f.id, entityTitle: f.title, filePath: 'docs/memos/memo${f.id}_1.docx', fileName: 'memo_${f.id}_1.docx', fileSize: 256*1024, fileType: doc_models.FileType.docx, uploadDate: DateTime(2026,7,8), uploadedBy: 'هادي البني', physicalLocation: 'مكتب المحامي'),
  ];
}

class FilesFilterDialog extends StatefulWidget { const FilesFilterDialog({super.key}); @override State<FilesFilterDialog> createState() => _FilesFilterDialogState(); }
class _FilesFilterDialogState extends State<FilesFilterDialog> {
  FileType? _type; FileStatus? _status; bool _def=false, _doc=false, _over=false, _base=false;
  @override Widget build(BuildContext context) => Dialog(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text('فلترة الملفات', style: AppTextStyles.headline4.copyWith(color: AppColors.primaryNavy), textAlign: TextAlign.center),
    const SizedBox(height: 24),
    DropdownButtonFormField<FileType?>(value: _type, items: [const DropdownMenuItem(value: null, child: Text('جميع الأنواع')), ...FileType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))], onChanged: (v) => setState(() => _type = v), decoration: InputDecoration(labelText: 'نوع الملف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
    const SizedBox(height: 16),
    DropdownButtonFormField<FileStatus?>(value: _status, items: [const DropdownMenuItem(value: null, child: Text('جميع الحالات')), ...FileStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))], onChanged: (v) => setState(() => _status = v), decoration: InputDecoration(labelText: 'حالة الملف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
    const SizedBox(height: 16),
    Text('فلاتر إضافية:', style: AppTextStyles.labelLarge),
    const SizedBox(height: 8),
    CheckboxListTile(title: const Text('الملفات الناقصة'), value: _def, onChanged: (v) => setState(() => _def = v!), contentPadding: EdgeInsets.zero, dense: true),
    CheckboxListTile(title: const Text('المستندات الناقصة'), value: _doc, onChanged: (v) => setState(() => _doc = v!), contentPadding: EdgeInsets.zero, dense: true),
    CheckboxListTile(title: const Text('الملفات المتأخرة'), value: _over, onChanged: (v) => setState(() => _over = v!), contentPadding: EdgeInsets.zero, dense: true),
    CheckboxListTile(title: const Text('بانتظار رقم أساس'), value: _base, onChanged: (v) => setState(() => _base = v!), contentPadding: EdgeInsets.zero, dense: true),
    const SizedBox(height: 24),
    Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')), const SizedBox(width: 12), ElevatedButton(onPressed: () { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تطبيق الفلاتر'), backgroundColor: AppColors.success)); }, child: const Text('تطبيق'))])
  ])));
}
