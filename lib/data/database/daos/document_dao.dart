import 'package:drift/drift.dart';
import '../database.dart';
import '../schema.dart';

part 'document_dao.g.dart';

/// كائن الوصول لبيانات المستندات والمبرزات القانونية الموحدة (DocumentDao)
@DriftAccessor(tables: [
  Documents,
  DocumentLinks,
])
class DocumentDao extends DatabaseAccessor<AppDatabase> with _$DocumentDaoMixin {
  DocumentDao(super.db);

  // ---------------------------------------------------------------------------
  // إدارة المستندات وروابطها (Documents & DocumentLinks)
  // ---------------------------------------------------------------------------

  /// مراقبة المستندات المرتبطة بكيان محدد (دعوى، جلسة، شخص، شركة...)
  Stream<List<Document>> watchDocumentsByEntity(int entityType, int entityId) {
    final query = select(documents).join([
      innerJoin(
        documentLinks,
        documentLinks.documentId.equalsExp(documents.id) &
            documentLinks.entityType.equals(entityType) &
            documentLinks.entityId.equals(entityId),
      ),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(documents)).toList();
    });
  }

  /// إدخال مستند جديد في قاعدة البيانات
  Future<int> insertDocument(DocumentsCompanion companion) {
    return into(documents).insert(companion);
  }

  /// ربط مستند قائم بكيان معين في النظام (دعم الربط المتعدد للمستند الواحد)
  Future<int> linkDocument(int documentId, int entityType, int entityId, {String? linkType}) {
    return into(documentLinks).insert(
      DocumentLinksCompanion.insert(
        documentId: documentId,
        entityType: entityType,
        entityId: entityId,
        linkType: Value(linkType),
      ),
    );
  }

  /// إزالة مستند من قاعدة البيانات (ستقوم القيود الخارجية بحذف روابطه)
  Future<int> deleteDocument(int id) {
    return (delete(documents)..where((t) => t.id.equals(id))).go();
  }
}
