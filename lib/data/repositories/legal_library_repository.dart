import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/daos/legal_library_dao.dart';

/// مستودع المكتبة القانونية — SQLite عبر Drift.
class LegalLibraryRepository {
  final LegalLibraryDao _dao;

  LegalLibraryRepository(this._dao);

  Stream<List<LegalLibraryItem>> watchAllItems() => _dao.watchAllItems();
  Future<List<LegalLibraryItem>> getAllItems() => _dao.getAllItems();
  Stream<List<LegalLibraryLink>> watchAllLinks() => _dao.watchAllLinks();
  Future<List<LegalLibraryLink>> getAllLinks() => _dao.getAllLinks();

  Future<int> addItem(LegalLibraryItemsCompanion companion) => _dao.insertItem(companion);

  Future<void> toggleFavorite(int id, bool value) => _dao.setFavorite(id, value);

  Future<void> setPrinciple(int id, bool value) => _dao.setPrinciple(id, value);

  Future<int> linkToEntity({
    required int libraryItemId,
    required int entityType,
    required int entityId,
    String? entityTitle,
    String? note,
  }) {
    return _dao.insertLink(
      LegalLibraryLinksCompanion.insert(
        libraryItemId: libraryItemId,
        entityType: entityType,
        entityId: entityId,
        entityTitle: Value(entityTitle),
        note: Value(note),
      ),
    );
  }

  Future<void> removeLink(int id) => _dao.deleteLink(id);

  Future<void> seedDemoIfEmpty() async {
    final items = await _dao.getAllItems();
    if (items.isNotEmpty) return;

    final law1 = await _dao.insertItem(
      LegalLibraryItemsCompanion.insert(
        itemType: 'law',
        title: 'قانون أصول المحاكمات المدنية',
        category: const Value('قوانين إجرائية'),
        source: const Value('الجريدة الرسمية'),
        year: const Value(2016),
        lawNumber: const Value('1'),
        lawKind: const Value('قانون'),
        tags: const Value('أصول,محاكمات,مدني'),
        extractedText: const Value('ينظم إجراءات التقاضي أمام المحاكم المدنية السورية.'),
        isFavorite: const Value(true),
        fileName: const Value('civil_procedure_2016.pdf'),
        filePath: const Value('library/laws/civil_procedure_2016.pdf'),
        createdBy: const Value('النظام'),
      ),
    );
    await _dao.insertItem(
      LegalLibraryItemsCompanion.insert(
        itemType: 'law',
        title: 'القانون المدني السوري',
        category: const Value('قوانين موضوعية'),
        source: const Value('الجريدة الرسمية'),
        year: const Value(1949),
        lawNumber: const Value('84'),
        lawKind: const Value('قانون'),
        tags: const Value('مدني,التزامات,عقود'),
        createdBy: const Value('النظام'),
      ),
    );
    final prec1 = await _dao.insertItem(
      LegalLibraryItemsCompanion.insert(
        itemType: 'precedent',
        title: 'عبء الإثبات في دعاوى التعويض',
        category: const Value('اجتهادات مدنية'),
        source: const Value('محكمة النقض السورية'),
        year: const Value(2022),
        court: const Value('محكمة النقض'),
        chamber: const Value('الغرفة المدنية'),
        decisionNumber: const Value('445'),
        baseNumber: const Value('1120/2021'),
        principle: const Value(
          'يقع عبء إثبات الضرر والعلاقة السببية على المدعي في دعوى التعويض.',
        ),
        isPrinciple: const Value(true),
        isFavorite: const Value(true),
        journalYear: const Value(2023),
        journalIssue: const Value('2'),
        page: const Value('145'),
        tags: const Value('تعويض,إثبات,نقض'),
        createdBy: const Value('النظام'),
      ),
    );
    await _dao.insertItem(
      LegalLibraryItemsCompanion.insert(
        itemType: 'bar_journal',
        title: 'مجلة المحامون - العدد 3/2024',
        category: const Value('مجلة المحامون'),
        source: const Value('نقابة المحامين'),
        year: const Value(2024),
        journalYear: const Value(2024),
        journalIssue: const Value('3'),
        page: const Value('1-220'),
        tags: const Value('مجلة,محامون'),
        isFavorite: const Value(true),
        createdBy: const Value('النظام'),
      ),
    );
    await _dao.insertItem(
      LegalLibraryItemsCompanion.insert(
        itemType: 'memo',
        title: 'نموذج مذكرة دفاع في دعوى تعويض',
        category: const Value('مذكرات'),
        source: const Value('مكتب المحامي'),
        year: const Value(2026),
        tags: const Value('مذكرة,دفاع,تعويض'),
        createdBy: const Value('النظام'),
      ),
    );

    await _dao.insertLink(
      LegalLibraryLinksCompanion.insert(
        libraryItemId: prec1,
        entityType: 0,
        entityId: 1,
        entityTitle: const Value('دعوى تعويض 2026/001'),
        note: const Value('مرجع في عبء الإثبات'),
      ),
    );
    await _dao.insertLink(
      LegalLibraryLinksCompanion.insert(
        libraryItemId: law1,
        entityType: 0,
        entityId: 1,
        entityTitle: const Value('دعوى تعويض 2026/001'),
        note: const Value('أصول التقاضي'),
      ),
    );
  }
}
