/// شاشة المستندات.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'document_models.dart';
import 'document_viewer.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 7,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('المستندات'),
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
                    Tab(text: 'جميع المستندات'),
                    Tab(text: 'مستندات الدعاوى'),
                    Tab(text: 'الوكالات'),
                    Tab(text: 'العقود'),
                    Tab(text: 'الشركات'),
                    Tab(text: 'الإجراءات'),
                    Tab(text: 'الإيصالات'),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => context.go('/search-reports'),
                tooltip: 'بحث',
              ),
              IconButton(
                icon: const Icon(Icons.upload),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => const UploadDocDialog(),
                ),
                tooltip: 'رفع',
              ),
            ],
          ),
          body: const TabBarView(
            children: [
              AllDocsTab(),
              CaseDocsTab(),
              PoaDocsTab(),
              ContractDocsTab(),
              CompanyDocsTab(),
              ProcedureDocsTab(),
              ReceiptDocsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class AllDocsTab extends ConsumerWidget {
  const AllDocsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _buildList(ref.watch(documentsProvider), context);
}

class CaseDocsTab extends ConsumerWidget {
  const CaseDocsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildList(
      ref.watch(documentsProvider).where((document) => document.entityType == 'case').toList(),
      context,
      'لا يوجد مستندات دعاوى',
    );
  }
}

class PoaDocsTab extends ConsumerWidget {
  const PoaDocsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildList(
      ref.watch(documentsProvider).where((document) => document.documentType == DocumentType.powerOfAttorney).toList(),
      context,
      'لا يوجد وكالات',
    );
  }
}

class ContractDocsTab extends ConsumerWidget {
  const ContractDocsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildList(
      ref.watch(documentsProvider).where((document) => document.documentType == DocumentType.contract).toList(),
      context,
      'لا يوجد عقود',
    );
  }
}

class CompanyDocsTab extends ConsumerWidget {
  const CompanyDocsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildList(
      ref.watch(documentsProvider).where((document) => document.documentType == DocumentType.companyDocument).toList(),
      context,
      'لا يوجد مستندات شركات',
    );
  }
}

class ProcedureDocsTab extends ConsumerWidget {
  const ProcedureDocsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildList(
      ref.watch(documentsProvider).where((document) => document.documentType == DocumentType.adminProcedure).toList(),
      context,
      'لا يوجد مستندات إجراءات',
    );
  }
}

class ReceiptDocsTab extends ConsumerWidget {
  const ReceiptDocsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildList(
      ref.watch(documentsProvider).where((document) => document.documentType == DocumentType.receipt).toList(),
      context,
      'لا يوجد إيصالات',
    );
  }
}

Widget _buildList(List<DocumentItem> docs, BuildContext context, [String empty = 'لا يوجد مستندات']) {
  if (docs.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(empty, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  final orderedDocs = [...docs]..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: orderedDocs.length,
    itemBuilder: (context, index) => DocCard(doc: orderedDocs[index]),
  );
}

class DocCard extends StatelessWidget {
  final DocumentItem doc;

  const DocCard({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(doc.fileType.icon, color: AppColors.primaryNavy, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text(doc.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold))),
                _tag(doc.fileType.displayName, AppColors.primaryNavy),
              ],
            ),
            const SizedBox(height: 8),
            Text('النوع: ${doc.documentType.displayName}', style: AppTextStyles.bodySmall),
            Text('الملف المرتبط: ${doc.entityTitle}', style: AppTextStyles.bodySmallSecondary),
            Text('الحجم: ${doc.formattedSize} • التاريخ: ${_formatDate(doc.uploadDate)}', style: AppTextStyles.bodySmallSecondary),
            Text('الموقع: ${doc.physicalLocation}', style: AppTextStyles.bodySmallSecondary),
            if (doc.isMissingOriginal) ...[
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: _tag('بانتظار الأصل', AppColors.warning)),
            ],
            if (doc.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('ملاحظات: ${doc.notes}', style: AppTextStyles.bodySmallSecondary),
            ],
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => openDocument(context, doc.id),
                  icon: Icon(doc.fileType.icon, size: 16),
                  label: const Text('فتح'),
                ),
                TextButton.icon(
                  onPressed: () => _showMsg(context, 'الملف: ${doc.entityTitle}'),
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('الملف المرتبط'),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: AppColors.error),
                  onPressed: () => _showDeleteDialog(context, doc),
                  tooltip: 'حذف',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showMsg(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.info));
  }

  void _showDeleteDialog(BuildContext context, DocumentItem document) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف'),
        content: Text('حذف ${document.title}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showMsg(context, 'تم حذف ${document.title}');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class UploadDocDialog extends StatefulWidget {
  const UploadDocDialog({super.key});

  @override
  State<UploadDocDialog> createState() => _UploadDocDialogState();
}

class _UploadDocDialogState extends State<UploadDocDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _entityIdController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _entityType = 'case';
  DocumentType _docType = DocumentType.caseDocument;
  FileType _fileType = FileType.pdf;

  @override
  void dispose() {
    _titleController.dispose();
    _entityIdController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('رفع مستند جديد', style: AppTextStyles.headline4.copyWith(color: AppColors.primaryNavy)),
              const SizedBox(height: 24),
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'عنوان المستند')),
              const SizedBox(height: 16),
              DropdownButtonFormField<DocumentType>(
                value: _docType,
                items: DocumentType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(),
                onChanged: (value) => setState(() => _docType = value ?? _docType),
                decoration: const InputDecoration(labelText: 'نوع المستند'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _entityType,
                      items: const [
                        DropdownMenuItem(value: 'case', child: Text('دعوى')),
                        DropdownMenuItem(value: 'contract', child: Text('عقد')),
                        DropdownMenuItem(value: 'company', child: Text('شركة')),
                        DropdownMenuItem(value: 'procedure', child: Text('إجراء')),
                      ],
                      onChanged: (value) => setState(() => _entityType = value ?? _entityType),
                      decoration: const InputDecoration(labelText: 'نوع الكيان'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _entityIdController, decoration: const InputDecoration(labelText: 'رقم الكيان'))),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FileType>(
                value: _fileType,
                items: FileType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(),
                onChanged: (value) => setState(() => _fileType = value ?? _fileType),
                decoration: const InputDecoration(labelText: 'نوع الملف'),
              ),
              const SizedBox(height: 16),
              TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'الموقع الفيزيائي')),
              const SizedBox(height: 16),
              TextField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات')),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('تم رفع المستند'), backgroundColor: AppColors.success),
                      );
                    },
                    child: const Text('رفع'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
