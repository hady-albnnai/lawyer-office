/// نماذج نظام المستندات والمرفقات المشتركة بين شاشات المستندات والدعاوى.
///
/// يعتمد الملف على AppColors عبر الأيقونات المعتمدة في الثيم، وتبقى النصوص
/// عربية جاهزة للعرض داخل واجهات RTL.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// نوع المستند القانوني داخل المكتب.
enum DocumentType {
  caseDocument,
  powerOfAttorney,
  contract,
  companyDocument,
  adminProcedure,
  receipt,
  memo,
  decision,
  courtRecord,
  other;

  String get displayName => const [
        'مستندات الدعاوى',
        'الوكالات',
        'العقود',
        'مستندات الشركات',
        'مستندات الإجراءات',
        'الإيصالات',
        'المذكرات',
        'القرارات',
        'ضبوط المحكمة',
        'أخرى',
      ][index];
}

/// نوع الملف الفيزيائي المحفوظ ضمن الأرشيف.
enum FileType {
  pdf,
  docx,
  doc,
  jpg,
  png,
  txt,
  rtf,
  other;

  String get displayName => const [
        'PDF',
        'Word (DOCX)',
        'Word (DOC)',
        'JPG',
        'PNG',
        'TXT',
        'RTF',
        'آخر',
      ][index];

  IconData get icon => const [
        Icons.picture_as_pdf,
        Icons.description,
        Icons.description,
        Icons.image,
        Icons.image,
        Icons.text_snippet,
        Icons.text_snippet,
        Icons.insert_drive_file,
      ][index];
}

/// عنصر مستند واحد مرتبط بكيان في المكتب؛ دعوى، عقد، شركة، أو إجراء.
class DocumentItem {
  final String id;
  final String title;
  final String filePath;
  final String fileName;
  final String entityType;
  final String entityId;
  final String entityTitle;
  final String physicalLocation;
  final String uploadedBy;
  final String notes;
  final DocumentType documentType;
  final FileType fileType;
  final int fileSize;
  final DateTime uploadDate;
  final bool hasOriginal;
  final bool isMissingOriginal;

  const DocumentItem({
    required this.id,
    required this.title,
    required this.documentType,
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.uploadDate,
    required this.uploadedBy,
    required this.physicalLocation,
    this.hasOriginal = true,
    this.isMissingOriginal = false,
    this.notes = '',
  });

  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    }
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// بيانات افتراضية موحدة للمستندات لحين ربط الشاشة بمستودع Drift نهائياً.
final documentsProvider = Provider<List<DocumentItem>>((ref) => [
      DocumentItem(
        id: 'doc_1',
        title: 'وكالة عامة لعام 2026',
        documentType: DocumentType.powerOfAttorney,
        entityType: 'case',
        entityId: '1',
        entityTitle: 'الدعوى 2026/001',
        filePath: 'docs/poa/poa1.pdf',
        fileName: 'poa_2026_001.pdf',
        fileSize: 1024 * 1024,
        fileType: FileType.pdf,
        uploadDate: DateTime(2026, 7, 5),
        uploadedBy: 'هادي البني',
        physicalLocation: 'ديوان المحامي',
      ),
      DocumentItem(
        id: 'doc_2',
        title: 'قرار المحكمة',
        documentType: DocumentType.decision,
        entityType: 'case',
        entityId: '1',
        entityTitle: 'الدعوى 2026/001',
        filePath: 'docs/cases/dec1.pdf',
        fileName: 'decision_2026_001.pdf',
        fileSize: 512 * 1024,
        fileType: FileType.pdf,
        uploadDate: DateTime(2026, 7, 9),
        uploadedBy: 'أحمد محمد',
        physicalLocation: 'ديوان المحكمة',
      ),
      DocumentItem(
        id: 'doc_3',
        title: 'مذكرة قانونية',
        documentType: DocumentType.memo,
        entityType: 'case',
        entityId: '1',
        entityTitle: 'الدعوى 2026/001',
        filePath: 'docs/memos/memo1.docx',
        fileName: 'memo_2026_001.docx',
        fileSize: 256 * 1024,
        fileType: FileType.docx,
        uploadDate: DateTime(2026, 7, 8),
        uploadedBy: 'هادي البني',
        physicalLocation: 'مكتب المحامي',
      ),
      DocumentItem(
        id: 'doc_4',
        title: 'سند التوكيل',
        documentType: DocumentType.powerOfAttorney,
        entityType: 'case',
        entityId: '2',
        entityTitle: 'الدعوى 2026/002',
        filePath: 'docs/poa/poa2.pdf',
        fileName: 'poa_2026_002.pdf',
        fileSize: 1024 * 1024,
        fileType: FileType.pdf,
        uploadDate: DateTime(2026, 7, 7),
        uploadedBy: 'هادي البني',
        physicalLocation: 'ديوان المحامي',
        isMissingOriginal: true,
      ),
      DocumentItem(
        id: 'doc_5',
        title: 'عقد بيع',
        documentType: DocumentType.contract,
        entityType: 'contract',
        entityId: '1',
        entityTitle: 'عقد 2026/CONT/001',
        filePath: 'docs/contracts/cont1.docx',
        fileName: 'contract_2026_001.docx',
        fileSize: 2 * 1024 * 1024,
        fileType: FileType.docx,
        uploadDate: DateTime(2026, 7, 8),
        uploadedBy: 'هادي البني',
        physicalLocation: 'مكتب المحامي',
      ),
    ]);

/// استنتاج نوع الملف من الامتداد عند رفع مستند جديد.
FileType inferFileType(String? extension) {
  switch ((extension ?? '').toLowerCase()) {
    case 'pdf':
      return FileType.pdf;
    case 'docx':
      return FileType.docx;
    case 'doc':
      return FileType.doc;
    case 'jpg':
    case 'jpeg':
      return FileType.jpg;
    case 'png':
      return FileType.png;
    case 'txt':
      return FileType.txt;
    case 'rtf':
      return FileType.rtf;
    default:
      return FileType.other;
  }
}
