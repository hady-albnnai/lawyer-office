import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../providers/app_providers.dart';
/// شاشة المستندات (Smart File Explorer)
/// بناءً على الخطة الماسية لإعادة الهيكلة 2026 (المرحلة 4)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'document_models.dart' as doc_models;
import 'document_models.dart' show DocumentItem, DocumentType, documentsProvider, inferFileType;
import 'document_viewer.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.cardBackground,
        appBar: AppBar(
          title: const Text('مستعرض المستندات الذكي'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.go('/search-reports'),
              tooltip: 'بحث متقدم',
            ),
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => const UploadDocDialog(),
              ),
              tooltip: 'رفع مستند',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: const _SmartExplorerView(),
      ),
    );
  }
}

class _SmartExplorerView extends ConsumerStatefulWidget {
  const _SmartExplorerView();

  @override
  ConsumerState<_SmartExplorerView> createState() => _SmartExplorerViewState();
}

class _SmartExplorerViewState extends ConsumerState<_SmartExplorerView> {
  // للتحكم في التنقل بين المجلدات (Navigation History)
  DocumentType? _currentFolder;
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(documentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // شريط المسار أدوات العرض (Breadcrumbs & View Controls)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Row(
            children: [
              // Breadcrumbs
              InkWell(
                onTap: () => setState(() => _currentFolder = null),
                child: Row(
                  children: [
                    const Icon(Icons.home, color: AppColors.primaryNavy, size: 20),
                    const SizedBox(width: 8),
                    Text('الرئيسية', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryNavy)),
                  ],
                ),
              ),
              if (_currentFolder != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(_currentFolder!.displayName, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
              ],
              
              const Spacer(),
              
              // View Toggles
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.grid_view, color: _isGridView ? AppColors.primaryNavy : AppColors.textSecondary),
                      onPressed: () => setState(() => _isGridView = true),
                      tooltip: 'عرض شبكي',
                    ),
                    IconButton(
                      icon: Icon(Icons.view_list, color: !_isGridView ? AppColors.primaryNavy : AppColors.textSecondary),
                      onPressed: () => setState(() => _isGridView = false),
                      tooltip: 'عرض القائمة',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // منطقة العرض الرئيسية (Main Content Area)
        Expanded(
          child: _currentFolder == null 
              ? _buildFoldersGrid(docs) // عرض المجلدات الرئيسية
              : _buildFilesView(docs.where((d) => d.documentType == _currentFolder).toList()), // عرض الملفات داخل المجلد
        ),
      ],
    );
  }

  // بناء شبكة المجلدات الذكية (Smart Folders)
  Widget _buildFoldersGrid(List<DocumentItem> allDocs) {
    // تجميع المستندات لمعرفة عددها داخل كل نوع
    final counts = <DocumentType, int>{};
    for (final doc in allDocs) {
      counts[doc.documentType] = (counts[doc.documentType] ?? 0) + 1;
    }

    // المجلدات الرئيسية المعتمدة في النظام
    final folders = [
      _FolderModel(type: DocumentType.caseDocument, icon: Icons.folder_shared, color: AppColors.primaryNavy),
      _FolderModel(type: DocumentType.powerOfAttorney, icon: Icons.verified_user, color: AppColors.info),
      _FolderModel(type: DocumentType.decision, icon: Icons.gavel, color: AppColors.error),
      _FolderModel(type: DocumentType.contract, icon: Icons.description, color: AppColors.secondaryGold),
      _FolderModel(type: DocumentType.receipt, icon: Icons.receipt_long, color: AppColors.success),
      _FolderModel(type: DocumentType.companyDocument, icon: Icons.business, color: Colors.blueGrey),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.1,
      ),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        final count = counts[folder.type] ?? 0;
        
        return InkWell(
          onTap: () => setState(() => _currentFolder = folder.type),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(folder.icon, size: 64, color: folder.color.withOpacity(0.8)),
                const SizedBox(height: 12),
                Text(folder.type.displayName, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('$count ملف', style: AppTextStyles.bodySmallSecondary),
              ],
            ),
          ),
        );
      },
    );
  }

  // بناء عرض الملفات (Grid أو List)
  Widget _buildFilesView(List<DocumentItem> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: AppColors.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('هذا المجلد فارغ', style: AppTextStyles.headline6.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final orderedDocs = [...docs]..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: orderedDocs.length,
        itemBuilder: (context, index) => _buildGridFileCard(orderedDocs[index]),
      );
    } else {
      return ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: orderedDocs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildListFileCard(orderedDocs[index]),
      );
    }
  }

  // بطاقة عرض شبكي للملف (تُشبه Windows Explorer Icon)
  Widget _buildGridFileCard(DocumentItem doc) {
    return RepaintBoundary(
      child: InkWell(
      onDoubleTap: () => openDocument(context, doc.id),
      onTap: () {
        // يمكن إضافة Select State لاحقاً
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.transparent),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(doc.fileType.icon, size: 64, color: _getFileColor(doc.fileType)),
                if (doc.isMissingOriginal)
                  const Icon(Icons.warning, color: AppColors.warning, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              doc.title,
              style: AppTextStyles.labelMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Text(doc.formattedSize, style: AppTextStyles.bodySmallSecondary.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // بطاقة عرض طولي للملف (List View Details)
  Widget _buildListFileCard(DocumentItem doc) {
    return RepaintBoundary(
      child: ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      leading: Icon(doc.fileType.icon, size: 36, color: _getFileColor(doc.fileType)),
      title: Text(doc.title, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text('المرتبط بـ: ${doc.entityTitle} • الحجم: ${doc.formattedSize} • التاريخ: ${_formatDate(doc.uploadDate)}', style: AppTextStyles.bodySmallSecondary),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (doc.isMissingOriginal) _tag('بانتظار الأصل', AppColors.warning),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.visibility, color: AppColors.primaryNavy),
            onPressed: () => openDocument(context, doc.id),
            tooltip: 'عرض الملف',
          ),
        ],
      ),
      onTap: () => openDocument(context, doc.id),
    );
  }

  Color _getFileColor(FileType type) {
    switch (type) {
      case doc_models.FileType.pdf: return AppColors.error;
      case doc_models.FileType.docx:
      case doc_models.FileType.doc: return Colors.blue;
      case doc_models.FileType.jpg:
      case doc_models.FileType.png: return Colors.green;
      default: return Colors.grey;
    }
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
}

class _FolderModel {
  final DocumentType type;
  final IconData icon;
  final Color color;
  const _FolderModel({required this.type, required this.icon, required this.color});
}

// نافذة الرفع بقيت كما هي لضمان عدم كسر أي دوال، سيتم تطويرها لاحقاً لربطها بـ FileStorageService


class UploadDocDialog extends StatefulWidget {
  const UploadDocDialog({super.key});
  @override
  State<UploadDocDialog> createState() => _UploadDocDialogState();
}
class _UploadDocDialogState extends State<UploadDocDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('رفع مستند'),
      content: const Text('سيتم تفعيل الرفع الآمن لاحقاً.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))
      ]
    );
  }
}

