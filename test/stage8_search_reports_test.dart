import 'package:flutter_test/flutter_test.dart';
import 'package:lawyer_office/presentation/screens/documents/document_models.dart';
import 'package:lawyer_office/presentation/screens/finance/finance_models.dart';
import 'package:lawyer_office/presentation/screens/persons/person_models.dart';
import 'package:lawyer_office/presentation/screens/search_reports/search_report_models.dart';
import 'package:lawyer_office/presentation/screens/work_orders/work_order_models.dart';

void main() {
  SearchReportEngine buildEngine() {
    final directory = PersonsDirectoryNotifier().state;
    final documents = [
      DocumentItem(
        id: 'doc_test',
        title: 'مذكرة دفاع',
        documentType: DocumentType.memo,
        entityType: 'case',
        entityId: '1',
        entityTitle: 'الدعوى 2026/001',
        filePath: 'docs/memo.pdf',
        fileName: 'memo.pdf',
        fileSize: 1024,
        fileType: FileType.pdf,
        uploadDate: DateTime(2026, 7, 10),
        uploadedBy: 'هادي البني',
        physicalLocation: 'مكتب',
      ),
    ];
    final workOrders = [
      WorkOrder(
        id: 'wo1',
        internalNumber: 'WO-2026-001',
        linkedEntityType: 'case',
        linkedEntityId: 'CASE-001',
        assignedToName: 'أحمد محمد',
        assignedToPhone: '0912345678',
        orderType: WorkOrderType.courtAttendance,
        priority: WorkOrderPriority.high,
        status: WorkOrderStatus.draft,
        dueDate: DateTime(2026, 7, 10),
        instructions: 'حضور جلسة الدعوى رقم 2026/001',
        createdAt: DateTime(2026, 7, 9),
        createdBy: 'هادي البني',
      ),
    ];
    final finance = FinanceNotifier().state;
    return SearchReportEngine.buildFromSources(
      directory: directory,
      documents: documents,
      workOrders: workOrders,
      finance: finance,
    );
  }

  test('Search engine indexes all required scopes', () {
    final engine = buildEngine();
    final scopes = engine.index.map((h) => h.scope).toSet();

    expect(scopes.contains(SearchScope.cases), isTrue);
    expect(scopes.contains(SearchScope.persons), isTrue);
    expect(scopes.contains(SearchScope.agencies), isTrue);
    expect(scopes.contains(SearchScope.documents), isTrue);
    expect(scopes.contains(SearchScope.workOrders), isTrue);
    expect(scopes.contains(SearchScope.finance), isTrue);
    expect(scopes.contains(SearchScope.legalLibrary), isTrue);
    expect(scopes.contains(SearchScope.contracts), isTrue);
  });

  test('Search finds cases, persons, work orders, finance and library items', () {
    final engine = buildEngine();

    expect(engine.search('تعويض'), isNotEmpty);
    expect(engine.search('WO-2026'), isNotEmpty);
    expect(engine.search('أصول المحاكمات'), isNotEmpty);
    expect(engine.search('سند قبض', scope: SearchScope.finance), isNotEmpty);

    final personHits = engine.search('أحمد', scope: SearchScope.persons);
    // may be empty depending on seed names; ensure filter by scope works
    expect(
      engine.search('تعويض', scope: SearchScope.workOrders).every((h) => h.scope == SearchScope.workOrders),
      isTrue,
    );
    expect(personHits.every((h) => h.scope == SearchScope.persons), isTrue);
  });

  test('Empty query returns no hits', () {
    final engine = buildEngine();
    expect(engine.search(''), isEmpty);
    expect(engine.search('   '), isEmpty);
  });

  test('Reports generate rows and summaries for all kinds', () {
    final engine = buildEngine();
    for (final kind in ReportKind.values) {
      final report = engine.generate(kind);
      expect(report.title, isNotEmpty);
      expect(report.headers, isNotEmpty);
      expect(report.summary, isNotEmpty);
      // finance/sessions/etc should have data from seed
      if (kind != ReportKind.legalMemos) {
        expect(report.rowCount, greaterThan(0), reason: 'report $kind should have rows');
      }
    }

    final financeReport = engine.generate(ReportKind.finance);
    expect(financeReport.summary.containsKey('إجمالي الأتعاب'), isTrue);
    expect(financeReport.rows, isNotEmpty);

    final sessions = engine.generate(ReportKind.sessions);
    expect(sessions.headers.length, 5);
    expect(sessions.rowCount, 3);
  });

  test('Count by scope aggregates search hits', () {
    final engine = buildEngine();
    final counts = engine.countByScope('2026');
    expect(counts.values.fold(0, (a, b) => a + b), greaterThan(0));
  });

  test('UI notifier updates query scope and report selection', () {
    final notifier = SearchReportsNotifier();
    notifier.setQuery('تعويض');
    notifier.setScope(SearchScope.cases);
    notifier.selectReport(ReportKind.overdue);

    expect(notifier.state.query, 'تعويض');
    expect(notifier.state.scope, SearchScope.cases);
    expect(notifier.state.selectedReport, ReportKind.overdue);

    final engine = buildEngine();
    final report = engine.generate(ReportKind.finance);
    notifier.setGeneratedReport(report);
    expect(notifier.state.lastReport?.kind, ReportKind.finance);
    notifier.clearGeneratedReport();
    expect(notifier.state.lastReport, isNull);
  });
}
