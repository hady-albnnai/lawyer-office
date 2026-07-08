/// شاشة المستندات
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

enum DocumentType { caseDocument, powerOfAttorney, contract, companyDocument, adminProcedure, receipt, memo, decision, courtRecord, other
String get displayName => const ['مستندات الدعاوى','الوكالات','العقود','مستندات الشركات','مستندات الإجراءات','الإيصالات','المذكرات','القرارات','ضابط المحكمة','أخرى'][index]; }

enum FileType { pdf, docx, doc, jpg, png, txt, rtf, other
String get displayName => const ['PDF','Word (DOCX)','Word (DOC)','JPG','PNG','TXT','RTF','آخر'][index];
IconData get icon => const [Icons.picture_as_pdf, Icons.description, Icons.description, Icons.image, Icons.image, Icons.text_snippet, Icons.text_snippet, Icons.insert_drive_file][index]; }

class DocumentItem {
  final String id, title, filePath, fileName, entityType, entityId, entityTitle, physicalLocation, uploadedBy, notes;
  final DocumentType documentType; final FileType fileType; final int fileSize; final DateTime uploadDate;
  final bool hasOriginal, isMissingOriginal;
  DocumentItem({required this.id, required this.title, required this.documentType, required this.entityType, required this.entityId, required this.entityTitle, required this.filePath, required this.fileName, required this.fileSize, required this.fileType, required this.uploadDate, required this.uploadedBy, required this.physicalLocation, this.hasOriginal=true, this.isMissingOriginal=false, this.notes=''});
  String get formattedSize => fileSize < 1024 ? '$fileSize B' : fileSize < 1024*1024 ? '${(fileSize/1024).toStringAsFixed(2)} KB' : '${(fileSize/(1024*1024)).toStringAsFixed(2)} MB';
}

final documentsProvider = Provider<List<DocumentItem>>((ref) => [
  DocumentItem(id: '1', title: 'وكالة عام 2026', documentType: DocumentType.powerOfAttorney, entityType: 'case', entityId: '1', entityTitle: 'الدعوى 2026/001', filePath: 'docs/poa/poa1.pdf', fileName: 'poa1.pdf', fileSize: 1024*1024, fileType: FileType.pdf, uploadDate: DateTime(2026,7,5), uploadedBy: 'هادي البني', physicalLocation: 'ديوان المحامي'),
  DocumentItem(id: '2', title: 'عقد بيع', documentType: DocumentType.contract, entityType: 'contract', entityId: '1', entityTitle: 'عقد 2026/CONT/001', filePath: 'docs/contracts/cont1.docx', fileName: 'cont1.docx', fileSize: 2*1024*1024, fileType: FileType.docx, uploadDate: DateTime(2026,7,8), uploadedBy: 'هادي البني', physicalLocation: 'مكتب المحامي'),
  DocumentItem(id: '3', title: 'قرار المحكمة', documentType: DocumentType.decision, entityType: 'case', entityId: '1', entityTitle: 'الدعوى 2026/001', filePath: 'docs/cases/dec1.pdf', fileName: 'dec1.pdf', fileSize: 512*1024, fileType: FileType.pdf, uploadDate: DateTime(2026,7,9), uploadedBy: 'أحمد محمد', physicalLocation: 'ديوان المحكمة'),
  DocumentItem(id: '4', title: 'سند التوكيل', documentType: DocumentType.powerOfAttorney, entityType: 'case', entityId: '2', entityTitle: 'الدعوى 2026/002', filePath: 'docs/poa/poa2.pdf', fileName: 'poa2.pdf', fileSize: 1024*1024, fileType: FileType.pdf, uploadDate: DateTime(2026,7,7), uploadedBy: 'هادي البني', physicalLocation: 'ديوان المحامي'),
  DocumentItem(id: '5', title: 'إيصال دفع', documentType: DocumentType.receipt, entityType: 'case', entityId: '3', entityTitle: 'الدعوى 2026/003', filePath: 'docs/receipts/rec1.pdf', fileName: 'rec1.pdf', fileSize: 256*1024, fileType: FileType.pdf, uploadDate: DateTime(2026,7,8), uploadedBy: 'محمد أحمد', physicalLocation: 'محكمة دمشق'),
]);

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(length: 7, child: Scaffold(
      appBar: AppBar(title: const Text('المستندات'), bottom: PreferredSize(preferredSize: const Size.fromHeight(48), child: Container(height: 48, margin: const EdgeInsets.symmetric(horizontal: 16), child: TabBar(isScrollable: true, indicatorSize: TabBarIndicatorSize.tab, indicator: UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.secondaryGold, width: 3)), labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold), unselectedLabelStyle: AppTextStyles.labelMedium, tabs: const [Tab(text: 'جميع المستندات'), Tab(text: 'مستندات الدعاوى'), Tab(text: 'الوكالات'), Tab(text: 'العقود'), Tab(text: 'الشركات'), Tab(text: 'الإجراءات'), Tab(text: 'الإيصالات')]))), actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => context.go('/search-reports'), tooltip: 'بحث'), IconButton(icon: const Icon(Icons.upload), onPressed: () => showDialog(context: context, builder: (c) => const UploadDocDialog()), tooltip: 'رفع')]),
      body: const TabBarView(children: [AllDocsTab(), CaseDocsTab(), PoaDocsTab(), ContractDocsTab(), CompanyDocsTab(), ProcedureDocsTab(), ReceiptDocsTab()]),
    ));
  }
}

class AllDocsTab extends ConsumerWidget { const AllDocsTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final docs = ref.watch(documentsProvider); return _buildList(docs, context); } }
class CaseDocsTab extends ConsumerWidget { const CaseDocsTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final docs = ref.watch(documentsProvider).where((d) => d.entityType == 'case').toList(); return _buildList(docs, context, 'لا يوجد مستندات دعاوى'); } }
class PoaDocsTab extends ConsumerWidget { const PoaDocsTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final docs = ref.watch(documentsProvider).where((d) => d.documentType == DocumentType.powerOfAttorney).toList(); return _buildList(docs, context, 'لا يوجد وكالات'); } }
class ContractDocsTab extends ConsumerWidget { const ContractDocsTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final docs = ref.watch(documentsProvider).where((d) => d.documentType == DocumentType.contract).toList(); return _buildList(docs, context, 'لا يوجد عقود'); } }
class CompanyDocsTab extends ConsumerWidget { const CompanyDocsTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final docs = ref.watch(documentsProvider).where((d) => d.documentType == DocumentType.companyDocument).toList(); return _buildList(docs, context, 'لا يوجد مستندات شركات'); } }
class ProcedureDocsTab extends ConsumerWidget { const ProcedureDocsTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final docs = ref.watch(documentsProvider).where((d) => d.documentType == DocumentType.adminProcedure).toList(); return _buildList(docs, context, 'لا يوجد مستندات إجراءات'); } }
class ReceiptDocsTab extends ConsumerWidget { const ReceiptDocsTab({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final docs = ref.watch(documentsProvider).where((d) => d.documentType == DocumentType.receipt).toList(); return _buildList(docs, context, 'لا يوجد إيصالات'); } }

Widget _buildList(List<DocumentItem> docs, BuildContext ctx, [String empty = 'لا يوجد مستندات']) {
  if(docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.description, size: 64, color: AppColors.textSecondary), const SizedBox(height: 16), Text(empty, style: AppTextStyles.bodyMedium)]));
  docs.sort((a,b) => b.uploadDate.compareTo(a.uploadDate));
  return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (c, i) => DocCard(doc: docs[i]));
}

class DocCard extends StatelessWidget {
  final DocumentItem doc;
  const DocCard({super.key, required this.doc});
  @override Widget build(BuildContext context) {
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Icon(doc.fileType.icon, color: AppColors.primaryNavy, size: 24), const SizedBox(width: 8), Expanded(child: Text(doc.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold))), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(4)), child: Text(doc.fileType.displayName, style: AppTextStyles.bodySmallSecondary))]),
      const SizedBox(height: 8),
      Row(children: [Icon(Icons.folder, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('النوع: ${doc.documentType.displayName}', style: AppTextStyles.bodySmall), const SizedBox(width: 16), Icon(Icons.link, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('مرتبط: ${doc.entityTitle}', style: AppTextStyles.bodySmall)]),
      const SizedBox(height: 4),
      Row(children: [Icon(Icons.storage, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('الحجم: ${doc.formattedSize}', style: AppTextStyles.bodySmallSecondary), const SizedBox(width: 16), Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('تاريخ: ${doc.uploadDate.year}-${doc.uploadDate.month.toString().padLeft(2,"0")}-${doc.uploadDate.day.toString().padLeft(2,"0")}', style: AppTextStyles.bodySmallSecondary)]),
      const SizedBox(height: 4),
      Row(children: [Icon(Icons.location_on, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('الموقع: ${doc.physicalLocation}', style: AppTextStyles.bodySmallSecondary)]),
      if(doc.isMissingOriginal) ...[const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.warning, color: AppColors.error, size: 16), const SizedBox(width: 4), Text('بانتظار الأصل', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))]))],
      if(doc.notes.isNotEmpty) ...[const SizedBox(height: 8), Text('ملاحظات: ${doc.notes}', style: AppTextStyles.bodySmallSecondary)],
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فتح: ${doc.fileName}'), backgroundColor: AppColors.info)), icon: Icon(doc.fileType.icon, size: 16), label: const Text('فتح')), TextButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ربط ب: ${doc.entityTitle}'), backgroundColor: AppColors.success)), icon: const Icon(Icons.link, size: 16), label: const Text('ربط')), IconButton(icon: const Icon(Icons.delete, color: AppColors.error), onPressed: () => showDialog(context: context, builder: (c) => AlertDialog(title: const Text('حذف'), content: Text('حذف ${doc.title}؟'), actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('إلغاء')), TextButton(onPressed: () { Navigator.of(c).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حذف ${doc.title}'), backgroundColor: AppColors.error)); }, style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('حذف'))]))])])
    ])));
  }
}

class UploadDocDialog extends StatefulWidget { const UploadDocDialog({super.key}); @override State<UploadDocDialog> createState() => _UploadDocDialogState(); }
class _UploadDocDialogState extends State<UploadDocDialog> {
  final _titleCtrl = TextEditingController(); String _type = 'case'; final _entityIdCtrl = TextEditingController();
  FileType _fileType = FileType.pdf; DocumentType _docType = DocumentType.caseDocument;
  final _locationCtrl = TextEditingController(); final _notesCtrl = TextEditingController();
  @override void dispose() { _titleCtrl.dispose(); _entityIdCtrl.dispose(); _locationCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Dialog(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('رفع مستند جديد', style: AppTextStyles.headline4.copyWith(color: AppColors.primaryNavy), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      TextField(controller: _titleCtrl, decoration: InputDecoration(labelText: 'عنوان المستند', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      DropdownButtonFormField(value: _docType, items: DocumentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(), onChanged: (v) => setState(() => _docType = v!), decoration: InputDecoration(labelText: 'نوع المستند', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      Row(children: [Expanded(child: DropdownButtonFormField(value: _type, items: const [DropdownMenuItem(value: 'case', child: Text('دعوى')), DropdownMenuItem(value: 'contract', child: Text('عقد')), DropdownMenuItem(value: 'company', child: Text('شركة')), DropdownMenuItem(value: 'procedure', child: Text('إجراء'))], onChanged: (v) => setState(() => _type = v!), decoration: InputDecoration(labelText: 'نوع الكيان', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))), const SizedBox(width: 12), Expanded(child: TextField(controller: _entityIdCtrl, decoration: InputDecoration(labelText: 'رقم الكيان', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))]),
      const SizedBox(height: 16),
      DropdownButtonFormField(value: _fileType, items: FileType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(), onChanged: (v) => setState(() => _fileType = v!), decoration: InputDecoration(labelText: 'نوع الملف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextField(controller: _locationCtrl, decoration: InputDecoration(labelText: 'الموقع الفيزيائي', hintText: 'مثال: ديوان المحكمة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextField(controller: _notesCtrl, decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), maxLines: 2),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')), const SizedBox(width: 12), ElevatedButton(onPressed: () { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم رفع المستند'), backgroundColor: AppColors.success)); }, child: const Text('رفع'))])
    ])));
  }
}
