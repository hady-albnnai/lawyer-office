import 'dart:io';
import 'package:drift/drift.dart';
import '../../core/enums/app_enums.dart';
import '../database/database.dart';
import '../database/daos/document_dao.dart';
import '../services/file_storage_service.dart';

/// مستودع إدارة المستندات والمبرزات القانونية الموحدة وروابطها (DocumentRepository)
class DocumentRepository {
  final DocumentDao _documentDao;
  final FileStorageService _storageService;

  DocumentRepository(this._documentDao, this._storageService);

  Stream<List<Document>> watchDocumentsByEntity(EntityType entityType, int entityId) {
    return _documentDao.watchDocumentsByEntity(entityType.index, entityId);
  }

  /// إدراج مستند جديد في المكتب، حفظه في النظام الفيزيائي، وربطه بالدعوى أو العقد أو الجلسة
  Future<int> addDocument({
    required DocumentsCompanion document,
    required File sourceFile,
    required EntityType entityType,
    required int entityId,
    String? linkType,
    required String userRef,
  }) async {
    return await _documentDao.db.transaction(() async {
      // 1. حفظ الملف في مجلد التخزين المحلي AppData/LawOffice/files/
      final filePath = await _storageService.saveAttachment(
        sourceFile: sourceFile,
        folderType: 'documents_${entityType.name}',
        entityId: entityId,
      );

      // 2. إدراج البيانات الوصفية للمستند
      final docId = await _documentDao.insertDocument(
        document.copyWith(
          filePath: Value(filePath),
          createdAt: Value(DateTime.now()),
        ),
      );

      // 3. إنشاء الربط المنفصل (DocumentLinks)
      await _documentDao.linkDocument(
        docId,
        entityType.index,
        entityId,
        linkType: linkType,
      );

      // 4. تسجيل حركة في الخط الزمني للكيان
      await _documentDao.into(_documentDao.db.timelineEvents).insert(
        TimelineEventsCompanion.insert(
          entityType: entityType.index,
          entityId: entityId,
          eventType: 'document_added',
          eventDate: Value(DateTime.now()),
          description: 'تم إرفاق مستند جديد: ${document.docName.value} (${document.docType.value ?? "عام"})',
          userRef: Value(userRef),
        ),
      );

      return docId;
    });
  }

  Future<bool> deleteDocument(int id, String? relativePath) async {
    await _storageService.deleteAttachment(relativePath);
    await _documentDao.deleteDocument(id);
    return true;
  }
}
