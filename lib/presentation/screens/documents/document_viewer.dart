/// نظام فتح وعرض المرفقات
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'document_models.dart';

class DocumentViewerScreen extends StatelessWidget {
  final String documentId;
  const DocumentViewerScreen({super.key, required this.documentId});
  @override Widget build(BuildContext context) {
    final doc = _getDoc(documentId);
    if(doc == null) return Scaffold(appBar: AppBar(title: const Text('غير موجود')), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, size: 64, color: AppColors.error), const SizedBox(height: 16), Text('المستند غير موجود', style: AppTextStyles.headline4), const SizedBox(height: 8), Text('الرقم: $documentId', style: AppTextStyles.bodyMediumSecondary), const SizedBox(height: 16), ElevatedButton(onPressed: () => context.pop(), child: const Text('العودة'))])));
    return Scaffold(appBar: AppBar(title: Text(doc.title), actions: [IconButton(icon: const Icon(Icons.download), onPressed: () => _showMsg(context, 'تم تنزيل ${doc.fileName}'), tooltip: 'تنزيل'), IconButton(icon: const Icon(Icons.share), onPressed: () => _showMsg(context, 'تم مشاركة ${doc.fileName}'), tooltip: 'مشاركة')]), body: Column(children: [_buildInfo(doc), Expanded(child: _buildViewer(doc, context))]));
  }
  Widget _buildInfo(DocumentItem d) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.cardBackground, border: Border.all(color: AppColors.cardBorder, width: 0.5)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Icon(d.fileType.icon, color: AppColors.primaryNavy, size: 24), const SizedBox(width: 8), Text(d.fileName, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)), const Spacer(), Text(d.formattedSize, style: AppTextStyles.bodyMedium)]), const SizedBox(height: 8), Row(children: [Icon(Icons.folder, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('النوع: ${d.documentType.displayName}', style: AppTextStyles.bodySmall), const SizedBox(width: 16), Icon(Icons.link, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('مرتبط: ${d.entityTitle}', style: AppTextStyles.bodySmall)]), const SizedBox(height: 4), Row(children: [Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('تاريخ: ${d.uploadDate.year}-${d.uploadDate.month.toString().padLeft(2,"0")}-${d.uploadDate.day.toString().padLeft(2,"0")}', style: AppTextStyles.bodySmallSecondary), const SizedBox(width: 16), Icon(Icons.person, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('مرفوع: ${d.uploadedBy}', style: AppTextStyles.bodySmallSecondary)]), const SizedBox(height: 4), Row(children: [Icon(Icons.location_on, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('الموقع: ${d.physicalLocation}', style: AppTextStyles.bodySmallSecondary)]), if(d.notes.isNotEmpty) ...[const SizedBox(height: 8), Text('ملاحظات: ${d.notes}', style: AppTextStyles.bodySmallSecondary)]]));
  Widget _buildViewer(DocumentItem d, BuildContext c) {
    IconData icon; String title, subtitle;
    switch(d.fileType) { case FileType.pdf: icon=Icons.picture_as_pdf; title='ملف PDF'; subtitle='فتح في معاين PDF'; break; case FileType.docx: case FileType.doc: icon=Icons.description; title='ملف Word'; subtitle='فتح في Word'; break; case FileType.jpg: case FileType.png: icon=Icons.image; title='صورة'; subtitle='فتح الصورة'; break; case FileType.txt: case FileType.rtf: icon=Icons.text_snippet; title='ملف نصي'; subtitle='فتح الملف'; break; default: icon=Icons.insert_drive_file; title='ملف'; subtitle='فتح الملف الخارجي'; }
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 64, color: AppColors.primaryNavy), const SizedBox(height: 16), Text(title, style: AppTextStyles.headline5), const SizedBox(height: 8), Text(d.fileName, style: AppTextStyles.bodyMedium), const SizedBox(height: 16), ElevatedButton.icon(onPressed: () => _showMsg(c, 'تم فتح ${d.fileName}'), icon: const Icon(Icons.open_in_new), label: Text(subtitle)), const SizedBox(height: 8), OutlinedButton.icon(onPressed: () => _showMsg(c, 'تم تنزيل ${d.fileName}'), icon: const Icon(Icons.download), label: const Text('تنزيل'))]));
  }
  void _showMsg(BuildContext c, String msg) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));
  DocumentItem? _getDoc(String id) => DocumentItem(id: id, title: 'مستند $id', documentType: DocumentType.decision, entityType: 'case', entityId: '1', entityTitle: 'الدعوى 2026/001', filePath: 'docs/test.pdf', fileName: 'test_$id.pdf', fileSize: 512*1024, fileType: FileType.pdf, uploadDate: DateTime.now(), uploadedBy: 'هادي البني', physicalLocation: 'مكتب المحامي');
}

void openDocument(BuildContext context, String documentId) => context.push('/documents/$documentId');
