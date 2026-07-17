/// نظام فتح وعرض المرفقات
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'document_models.dart';

class DocumentViewerScreen extends ConsumerWidget {
  final String documentId;
  const DocumentViewerScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsFutureProvider);
    return docsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('تحميل المستند')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('تعذر تحميل المستند')),
        body: Center(child: Text('تعذر تحميل بيانات المستند: $error')),
      ),
      data: (docs) {
        final doc = _getDoc(docs, documentId);
        if (doc == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('غير موجود')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('المستند غير موجود', style: AppTextStyles.headline4),
                  const SizedBox(height: 8),
                  Text('الرقم: $documentId', style: AppTextStyles.bodyMediumSecondary),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => context.pop(), child: const Text('العودة')),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(doc.title),
            actions: [
              IconButton(icon: const Icon(Icons.download), onPressed: () => _showMsg(context, 'تم تنزيل ${doc.fileName}'), tooltip: 'تنزيل'),
              IconButton(icon: const Icon(Icons.share), onPressed: () => _showMsg(context, 'تم مشاركة ${doc.fileName}'), tooltip: 'مشاركة'),
            ],
          ),
          body: Column(
            children: [
              _buildInfo(context, doc),
              Expanded(child: _buildViewer(doc, context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfo(BuildContext context, DocumentItem d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBackground, border: Border.all(color: AppColors.cardBorder, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(d.fileType.icon, color: AppColors.primaryNavy, size: 24),
              const SizedBox(width: 8),
              Expanded(child: Text(d.fileName, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold))),
              Text(d.formattedSize, style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _info(Icons.folder, 'النوع: ${d.documentType.displayName}'),
              _info(Icons.link, 'مرتبط: ${d.entityTitle}'),
              _info(Icons.calendar_today, 'تاريخ: ${_formatDate(d.uploadDate)}'),
              _info(Icons.person, 'مرفوع: ${d.uploadedBy}'),
              _info(Icons.location_on, 'الموقع: ${d.physicalLocation}'),
              if (_linkedEntityRoute(d) != null)
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('فتح الملف المرتبط'),
                  onPressed: () => context.go(_linkedEntityRoute(d)!),
                ),
            ],
          ),
          if (d.notes.contains('الأصل الورقي')) ...[
            const SizedBox(height: 10),
            _paperArchiveBox(d.notes),
          ] else if (d.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('ملاحظات: ${d.notes}', style: AppTextStyles.bodySmallSecondary),
          ],
        ],
      ),
    );
  }

  Widget _paperArchiveBox(String notes) {
    final lines = notes.split('\n').where((line) => line.trim().isNotEmpty).toList();
    String pick(String prefix) {
      final line = lines.firstWhere((item) => item.startsWith(prefix), orElse: () => '');
      return line.replaceFirst(prefix, '').trim();
    }

    final locationParts = [
      pick('مكان الأصل:'),
      if (pick('الصندوق:').isNotEmpty) 'صندوق ${pick('الصندوق:')}',
      if (pick('الرف:').isNotEmpty) 'رف ${pick('الرف:')}',
      if (pick('المجلد الورقي:').isNotEmpty) 'مجلد ${pick('المجلد الورقي:')}',
    ].where((value) => value.isNotEmpty).toList();
    final extraLines = lines.where((line) =>
        !line.startsWith('مكان الأصل:') &&
        !line.startsWith('الصندوق:') &&
        !line.startsWith('الرف:') &&
        !line.startsWith('المجلد الورقي:'));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('بيانات الأصل الورقي', style: AppTextStyles.labelLarge.copyWith(color: AppColors.info, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (locationParts.isNotEmpty)
            Text('الموقع الكامل: ${locationParts.join(' • ')}', style: AppTextStyles.bodySmallSecondary.copyWith(fontWeight: FontWeight.bold)),
          if (locationParts.isNotEmpty) const SizedBox(height: 6),
          ...extraLines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(line, style: AppTextStyles.bodySmallSecondary),
              )),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.bodySmallSecondary),
      ],
    );
  }

  Widget _buildViewer(DocumentItem d, BuildContext c) {
    IconData icon;
    String title;
    String subtitle;
    switch (d.fileType) {
      case FileType.pdf:
        icon = Icons.picture_as_pdf;
        title = 'ملف PDF';
        subtitle = 'فتح في معاين PDF';
        break;
      case FileType.docx:
      case FileType.doc:
        icon = Icons.description;
        title = 'ملف Word';
        subtitle = 'فتح في Word';
        break;
      case FileType.jpg:
      case FileType.png:
        icon = Icons.image;
        title = 'صورة';
        subtitle = 'فتح الصورة';
        break;
      case FileType.txt:
      case FileType.rtf:
        icon = Icons.text_snippet;
        title = 'ملف نصي';
        subtitle = 'فتح الملف';
        break;
      default:
        icon = Icons.insert_drive_file;
        title = 'ملف';
        subtitle = 'فتح الملف الخارجي';
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.primaryNavy),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.headline5),
          const SizedBox(height: 8),
          Text(d.fileName, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: () => _showMsg(c, 'تم فتح ${d.fileName}'), icon: const Icon(Icons.open_in_new), label: Text(subtitle)),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => _showMsg(c, 'تم تنزيل ${d.fileName}'), icon: const Icon(Icons.download), label: const Text('تنزيل')),
        ],
      ),
    );
  }

  void _showMsg(BuildContext c, String msg) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));

  String? _linkedEntityRoute(DocumentItem doc) {
    if (doc.entityId == '0') return null;
    switch (doc.entityType) {
      case 'case':
        return '/cases/${doc.entityId}';
      case 'contract':
        return '/contracts/${doc.entityId}';
      case 'company':
        return '/companies/${doc.entityId}';
      case 'adminProcedure':
        return '/procedures/${doc.entityId}';
      case 'poa':
        return '/poa/${doc.entityId}';
      case 'person':
        return '/persons/${doc.entityId}';
      default:
        return null;
    }
  }

  DocumentItem? _getDoc(List<DocumentItem> docs, String id) {
    for (final doc in docs) {
      if (doc.id == id) return doc;
    }
    return null;
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

void openDocument(BuildContext context, String documentId) => GoRouter.of(context).push('/documents/$documentId');
