/// نماذج ومحرك المرحلة 8: البحث الشامل والتقارير.
///
/// محرك بحث موحد قابل للاختبار يغطي الدعاوى والعقود والشركات والإجراءات
/// والأشخاص والوكالات والمستندات وأوامر العمل والمالية وبنود المكتبة.
/// التقارير تولَّد من نفس مصادر seed/providers الحالية offline.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../documents/document_models.dart';
import '../finance/finance_models.dart';
import '../persons/person_models.dart';
import '../work_orders/work_order_models.dart';
import '../work_orders/work_orders_screen.dart' show woProvider;

/// نطاق البحث.
enum SearchScope {
  all,
  cases,
  contracts,
  companies,
  procedures,
  persons,
  agencies,
  documents,
  workOrders,
  finance,
  legalLibrary;

  String get displayName => const [
        'الكل',
        'دعاوى',
        'عقود',
        'شركات',
        'إجراءات',
        'أشخاص',
        'وكالات',
        'مستندات',
        'أوامر عمل',
        'مالية',
        'مكتبة قانونية',
      ][index];

  IconData get icon => const [
        Icons.manage_search,
        Icons.gavel,
        Icons.description,
        Icons.business,
        Icons.assignment,
        Icons.person,
        Icons.verified_user,
        Icons.folder_open,
        Icons.assignment_ind,
        Icons.account_balance_wallet,
        Icons.menu_book,
      ][index];
}

/// نوع التقرير.
enum ReportKind {
  sessions,
  overdue,
  deficient,
  finance,
  workOrders,
  legalMemos;

  String get displayName => const [
        'كشف الجلسات',
        'كشف المتأخرات',
        'كشف الملفات الناقصة',
        'كشف مالية',
        'كشف أوامر العمل',
        'مذكرات قانونية',
      ][index];

  String get description => const [
        'جلسات المحكمة القادمة واليوم مع الحالة والمحكمة.',
        'الملفات والمهام المتأخرة عن موعدها.',
        'الملفات ذات النواقص أو بانتظار رقم أساس أو مستند.',
        'ملخص الأتعاب والمقبوض والمتبقي والمصاريف وذمم الموكلين.',
        'أوامر عمل المعقب حسب الحالة والأولوية.',
        'المذكرات والمستندات القانونية المرتبطة بالملفات.',
      ][index];

  IconData get icon => const [
        Icons.event,
        Icons.schedule,
        Icons.warning_amber,
        Icons.payments,
        Icons.assignment_turned_in,
        Icons.article,
      ][index];
}

/// نتيجة بحث واحدة.
class SearchHit {
  final String id;
  final SearchScope scope;
  final String title;
  final String subtitle;
  final String routeHint;
  final Map<String, String> meta;
  final List<String> keywords;

  const SearchHit({
    required this.id,
    required this.scope,
    required this.title,
    required this.subtitle,
    required this.routeHint,
    this.meta = const {},
    this.keywords = const [],
  });

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;
    if (title.toLowerCase().contains(q)) return true;
    if (subtitle.toLowerCase().contains(q)) return true;
    if (routeHint.toLowerCase().contains(q)) return true;
    for (final value in meta.values) {
      if (value.toLowerCase().contains(q)) return true;
    }
    for (final keyword in keywords) {
      if (keyword.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}

/// صف تقرير جدولي.
class ReportRow {
  final List<String> cells;

  const ReportRow(this.cells);
}

/// تقرير جاهز للعرض/التصدير.
class GeneratedReport {
  final ReportKind kind;
  final String title;
  final DateTime generatedAt;
  final List<String> headers;
  final List<ReportRow> rows;
  final Map<String, String> summary;

  const GeneratedReport({
    required this.kind,
    required this.title,
    required this.generatedAt,
    required this.headers,
    required this.rows,
    this.summary = const {},
  });

  int get rowCount => rows.length;
}

/// عنصر مكتبة قانونية مصغّر للبحث (نواة المرحلة 8 قبل اكتمال المرحلة 9).
class LegalLibraryHitSeed {
  final String id;
  final String title;
  final String type;
  final String source;
  final int year;
  final String tags;

  const LegalLibraryHitSeed({
    required this.id,
    required this.title,
    required this.type,
    required this.source,
    required this.year,
    required this.tags,
  });
}

/// محرك فهرسة وبحث وتوليد تقارير — قابل للاختبار بدون UI.
class SearchReportEngine {
  final List<SearchHit> index;
  final List<Map<String, String>> sessions;
  final List<Map<String, String>> overdue;
  final List<Map<String, String>> deficient;
  final List<Map<String, String>> workOrders;
  final List<Map<String, String>> memos;
  final FinanceState financeState;

  const SearchReportEngine({
    required this.index,
    required this.sessions,
    required this.overdue,
    required this.deficient,
    required this.workOrders,
    required this.memos,
    required this.financeState,
  });

  List<SearchHit> search(String query, {SearchScope scope = SearchScope.all}) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    return index.where((hit) {
      final scopeOk = scope == SearchScope.all || hit.scope == scope;
      return scopeOk && hit.matches(q);
    }).toList();
  }

  Map<SearchScope, int> countByScope(String query) {
    final hits = search(query);
    final map = <SearchScope, int>{};
    for (final hit in hits) {
      map[hit.scope] = (map[hit.scope] ?? 0) + 1;
    }
    return map;
  }

  GeneratedReport generate(ReportKind kind) {
    final now = DateTime.now();
    switch (kind) {
      case ReportKind.sessions:
        return GeneratedReport(
          kind: kind,
          title: 'كشف الجلسات',
          generatedAt: now,
          headers: const ['الوقت', 'رقم الدعوى', 'الموضوع', 'المحكمة', 'الحالة'],
          rows: sessions
              .map(
                (s) => ReportRow([
                  s['time'] ?? '',
                  s['caseNumber'] ?? '',
                  s['title'] ?? '',
                  s['court'] ?? '',
                  s['status'] ?? '',
                ]),
              )
              .toList(),
          summary: {'عدد الجلسات': '${sessions.length}'},
        );
      case ReportKind.overdue:
        return GeneratedReport(
          kind: kind,
          title: 'كشف المتأخرات',
          generatedAt: now,
          headers: const ['النوع', 'المرجع', 'العنوان', 'الاستحقاق', 'الملاحظات'],
          rows: overdue
              .map(
                (s) => ReportRow([
                  s['type'] ?? '',
                  s['ref'] ?? '',
                  s['title'] ?? '',
                  s['due'] ?? '',
                  s['notes'] ?? '',
                ]),
              )
              .toList(),
          summary: {'عدد المتأخرات': '${overdue.length}'},
        );
      case ReportKind.deficient:
        return GeneratedReport(
          kind: kind,
          title: 'كشف الملفات الناقصة',
          generatedAt: now,
          headers: const ['الملف', 'العنوان', 'النواقص', 'رقم الأساس', 'مستندات ناقصة'],
          rows: deficient
              .map(
                (s) => ReportRow([
                  s['fileNumber'] ?? '',
                  s['title'] ?? '',
                  s['deficiencies'] ?? '',
                  s['baseNumber'] ?? '',
                  s['missingDocs'] ?? '',
                ]),
              )
              .toList(),
          summary: {'ملفات ناقصة': '${deficient.length}'},
        );
      case ReportKind.finance:
        final summary = financeState.summary;
        final clients = financeState.clientReceivables;
        return GeneratedReport(
          kind: kind,
          title: 'كشف مالية الموكلين',
          generatedAt: now,
          headers: const ['الموكل', 'اتفاقيات', 'المقبوض', 'المتبقي', 'الحالة'],
          rows: clients
              .map(
                (c) => ReportRow([
                  c.partyName,
                  _money(c.agreementsTotal),
                  _money(c.paymentsTotal),
                  _money(c.remaining),
                  c.isSettled ? 'مسدّد' : 'ذمة قائمة',
                ]),
              )
              .toList(),
          summary: {
            'إجمالي الأتعاب': _money(summary.agreementsTotal),
            'المقبوض': _money(summary.paymentsTotal),
            'المتبقي': _money(summary.remainingFees),
            'المصاريف': _money(summary.expensesTotal),
            'الصافي': _money(summary.netBalance),
          },
        );
      case ReportKind.workOrders:
        return GeneratedReport(
          kind: kind,
          title: 'كشف أوامر العمل',
          generatedAt: now,
          headers: const ['الرقم', 'المكلف', 'النوع', 'الحالة', 'الموعد'],
          rows: workOrders
              .map(
                (s) => ReportRow([
                  s['number'] ?? '',
                  s['assignee'] ?? '',
                  s['type'] ?? '',
                  s['status'] ?? '',
                  s['due'] ?? '',
                ]),
              )
              .toList(),
          summary: {'عدد الأوامر': '${workOrders.length}'},
        );
      case ReportKind.legalMemos:
        return GeneratedReport(
          kind: kind,
          title: 'كشف المذكرات القانونية',
          generatedAt: now,
          headers: const ['العنوان', 'الملف', 'النوع', 'التاريخ', 'بواسطة'],
          rows: memos
              .map(
                (s) => ReportRow([
                  s['title'] ?? '',
                  s['entity'] ?? '',
                  s['type'] ?? '',
                  s['date'] ?? '',
                  s['by'] ?? '',
                ]),
              )
              .toList(),
          summary: {'عدد المذكرات': '${memos.length}'},
        );
    }
  }

  static String _money(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ل.س';
  }

  static String _date(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// بناء فهرس البحث من مصادر المرحلة الحالية.
  static SearchReportEngine buildFromSources({
    required PersonsDirectoryState directory,
    required List<DocumentItem> documents,
    required List<WorkOrder> workOrders,
    required FinanceState finance,
  }) {
    final index = <SearchHit>[];

    // دعاوى/ملفات seed متوافقة مع شاشات الملفات والدعاوى.
    final cases = [
      {
        'id': '1',
        'number': '2026/001',
        'title': 'دعوى تعويض',
        'court': 'محكمة دمشق الأولى',
        'base': '12345',
        'status': 'عاملة',
      },
      {
        'id': '2',
        'number': '2026/002',
        'title': 'دعوى استئناف',
        'court': 'محكمة الاستئناف',
        'base': '',
        'status': 'ناقصة',
      },
      {
        'id': '3',
        'number': '2026/003',
        'title': 'دعوى تجارية',
        'court': 'محكمة دمشق الأولى',
        'base': '67890',
        'status': 'منتهية',
      },
    ];
    for (final c in cases) {
      index.add(
        SearchHit(
          id: 'case_${c['id']}',
          scope: SearchScope.cases,
          title: 'دعوى ${c['number']}: ${c['title']}',
          subtitle: '${c['court']} • ${c['status']}',
          routeHint: '/cases/${c['id']}',
          meta: {
            'رقم الأساس': (c['base'] as String).isEmpty ? 'بانتظار' : c['base'] as String,
            'المحكمة': c['court'] as String,
          },
          keywords: [c['number'] as String, c['title'] as String, c['court'] as String],
        ),
      );
    }

    index.add(
      const SearchHit(
        id: 'contract_1',
        scope: SearchScope.contracts,
        title: 'عقد بيع عقار 2026/CONT/001',
        subtitle: 'عقد • موكل: أحمد محمد الخطيب',
        routeHint: '/contracts/1',
        meta: {'النوع': 'بيع', 'السنة': '2026'},
        keywords: ['عقد', 'بيع', 'عقار', 'CONT'],
      ),
    );
    index.add(
      const SearchHit(
        id: 'company_1',
        scope: SearchScope.companies,
        title: 'شركة التطوير الحديث',
        subtitle: 'تأسيس شركة • السجل التجاري',
        routeHint: '/companies/1',
        meta: {'النوع': 'شركة محدودة'},
        keywords: ['شركة', 'تطوير', 'سجل'],
      ),
    );
    index.add(
      const SearchHit(
        id: 'proc_1',
        scope: SearchScope.procedures,
        title: 'إجراء إداري: استخراج قيد',
        subtitle: 'دائرة السجل المدني',
        routeHint: '/procedures/1',
        meta: {'الجهة': 'السجل المدني'},
        keywords: ['إجراء', 'قيد', 'إداري'],
      ),
    );

    for (final person in directory.persons) {
      index.add(
        SearchHit(
          id: 'person_${person.id}',
          scope: SearchScope.persons,
          title: person.fullName,
          subtitle:
              'أدوار: ${person.roles.map((r) => r.displayName).join(', ')} • ${person.city}',
          routeHint: '/persons/${person.id}',
          meta: {
            'الهاتف': person.phone,
            'الهوية': person.nationalId,
            'واتساب': person.whatsapp,
          },
          keywords: [person.fullName, person.phone, person.nationalId, person.city],
        ),
      );
    }

    for (final agency in directory.agencies) {
      final principal = directory.personById(agency.principalPersonId);
      index.add(
        SearchHit(
          id: 'agency_${agency.id}',
          scope: SearchScope.agencies,
          title: 'وكالة ${agency.number}',
          subtitle: '${agency.type.displayName} • ${agency.agentName}',
          routeHint: '/poa/${agency.id}',
          meta: {
            'الموكل': principal?.fullName ?? '',
            'الفرع': agency.branch,
            'المصدر': agency.source.displayName,
          },
          keywords: [agency.number, agency.agentName, agency.branch, principal?.fullName ?? ''],
        ),
      );
    }

    for (final doc in documents) {
      index.add(
        SearchHit(
          id: 'doc_${doc.id}',
          scope: SearchScope.documents,
          title: doc.title,
          subtitle: '${doc.documentType.displayName} • ${doc.entityTitle}',
          routeHint: 'document:${doc.id}',
          meta: {
            'الملف': doc.fileName,
            'الموقع': doc.physicalLocation,
            'الرافع': doc.uploadedBy,
          },
          keywords: [doc.title, doc.fileName, doc.entityTitle, doc.documentType.displayName],
        ),
      );
    }

    for (final wo in workOrders) {
      index.add(
        SearchHit(
          id: 'wo_${wo.id}',
          scope: SearchScope.workOrders,
          title: '${wo.internalNumber} • ${wo.orderTypeText}',
          subtitle: '${wo.assignedToName} • ${wo.statusText}',
          routeHint: 'work-order:${wo.id}',
          meta: {
            'الهاتف': wo.assignedToPhone,
            'التعليمات': wo.instructions,
            'الملف': wo.linkedEntityId,
          },
          keywords: [wo.internalNumber, wo.assignedToName, wo.instructions, wo.orderTypeText],
        ),
      );
    }

    for (final agreement in finance.agreements) {
      index.add(
        SearchHit(
          id: 'fin_ag_${agreement.id}',
          scope: SearchScope.finance,
          title: 'اتفاق أتعاب: ${agreement.entityTitle}',
          subtitle: '${agreement.partyName} • ${_money(agreement.totalAmount)}',
          routeHint: '/finance',
          meta: {
            'النوع': agreement.agreementType.displayName,
            'الكيان': agreement.entityType.displayName,
          },
          keywords: [agreement.entityTitle, agreement.partyName, agreement.id],
        ),
      );
    }
    for (final payment in finance.payments) {
      final agreement = finance.agreementById(payment.agreementId);
      index.add(
        SearchHit(
          id: 'fin_pay_${payment.id}',
          scope: SearchScope.finance,
          title: 'سند قبض ${payment.displayReceiptNumber}',
          subtitle: '${agreement?.partyName ?? ''} • ${_money(payment.amount)}',
          routeHint: '/finance',
          meta: {'الطريقة': payment.method.displayName},
          keywords: [payment.displayReceiptNumber, agreement?.partyName ?? ''],
        ),
      );
    }

    const librarySeeds = [
      LegalLibraryHitSeed(
        id: 'lib_1',
        title: 'قانون أصول المحاكمات المدنية',
        type: 'قانون',
        source: 'الجريدة الرسمية',
        year: 2016,
        tags: 'أصول,محاكمات,مدني',
      ),
      LegalLibraryHitSeed(
        id: 'lib_2',
        title: 'اجتهاد نقض: عبء الإثبات في دعاوى التعويض',
        type: 'اجتهاد',
        source: 'محكمة النقض - الغرفة المدنية',
        year: 2022,
        tags: 'تعويض,إثبات,نقض',
      ),
      LegalLibraryHitSeed(
        id: 'lib_3',
        title: 'مجلة المحامون - العدد 3/2024',
        type: 'مجلة المحامون',
        source: 'نقابة المحامين',
        year: 2024,
        tags: 'مجلة,محامون',
      ),
    ];
    for (final item in librarySeeds) {
      index.add(
        SearchHit(
          id: item.id,
          scope: SearchScope.legalLibrary,
          title: item.title,
          subtitle: '${item.type} • ${item.source} • ${item.year}',
          routeHint: 'legal-library:${item.id}',
          meta: {'الوسوم': item.tags},
          keywords: [item.title, item.type, item.source, item.tags, '${item.year}'],
        ),
      );
    }

    final sessions = [
      {
        'time': '09:00',
        'caseNumber': '2026/001',
        'title': 'دعوى تعويض',
        'court': 'محكمة دمشق الأولى',
        'status': 'مجدولة',
      },
      {
        'time': '10:30',
        'caseNumber': '2026/002',
        'title': 'استئناف',
        'court': 'محكمة الاستئناف',
        'status': 'مجدولة',
      },
      {
        'time': '12:00',
        'caseNumber': '2026/003',
        'title': 'تجارية',
        'court': 'محكمة دمشق الأولى',
        'status': 'مجدولة',
      },
    ];

    final overdue = [
      {
        'type': 'ملف',
        'ref': '2026/002',
        'title': 'دعوى استئناف',
        'due': _date(DateTime(2026, 7, 8)),
        'notes': 'نواقص مفتوحة + بانتظار رقم أساس',
      },
      {
        'type': 'أمر عمل',
        'ref': 'WO-2026-003',
        'title': 'دفع رسم الدعوى',
        'due': _date(DateTime(2026, 7, 9)),
        'notes': 'بانتظار نتيجة المعقب',
      },
    ];

    final deficient = [
      {
        'fileNumber': '2026/001',
        'title': 'دعوى تعويض',
        'deficiencies': '2',
        'baseNumber': '12345',
        'missingDocs': 'لا',
      },
      {
        'fileNumber': '2026/002',
        'title': 'دعوى استئناف',
        'deficiencies': '2',
        'baseNumber': 'بانتظار',
        'missingDocs': 'نعم',
      },
    ];

    final woRows = workOrders
        .map(
          (wo) => {
            'number': wo.internalNumber,
            'assignee': wo.assignedToName,
            'type': wo.orderTypeText,
            'status': wo.statusText,
            'due': _date(wo.dueDate),
          },
        )
        .toList();

    final memoRows = documents
        .where((d) => d.documentType == DocumentType.memo || d.documentType == DocumentType.decision)
        .map(
          (d) => {
            'title': d.title,
            'entity': d.entityTitle,
            'type': d.documentType.displayName,
            'date': _date(d.uploadDate),
            'by': d.uploadedBy,
          },
        )
        .toList();

    return SearchReportEngine(
      index: index,
      sessions: sessions,
      overdue: overdue,
      deficient: deficient,
      workOrders: woRows,
      memos: memoRows,
      financeState: finance,
    );
  }
}

/// مزود محرك البحث والتقارير المركّب من مصادر الواجهة الحالية.
final searchReportEngineProvider = Provider<SearchReportEngine>((ref) {
  final directory = ref.watch(personsDirectoryProvider);
  final documents = ref.watch(documentsProvider);
  final workOrders = ref.watch(woProvider);
  final finance = ref.watch(financeProvider);
  return SearchReportEngine.buildFromSources(
    directory: directory,
    documents: documents,
    workOrders: workOrders,
    finance: finance,
  );
});

/// حالة واجهة البحث والتقارير.
class SearchReportsUiState {
  final String query;
  final SearchScope scope;
  final ReportKind? selectedReport;
  final GeneratedReport? lastReport;

  const SearchReportsUiState({
    this.query = '',
    this.scope = SearchScope.all,
    this.selectedReport,
    this.lastReport,
  });

  SearchReportsUiState copyWith({
    String? query,
    SearchScope? scope,
    ReportKind? selectedReport,
    GeneratedReport? lastReport,
    bool clearReport = false,
  }) {
    return SearchReportsUiState(
      query: query ?? this.query,
      scope: scope ?? this.scope,
      selectedReport: selectedReport ?? this.selectedReport,
      lastReport: clearReport ? null : lastReport ?? this.lastReport,
    );
  }
}

class SearchReportsNotifier extends StateNotifier<SearchReportsUiState> {
  SearchReportsNotifier() : super(const SearchReportsUiState());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setScope(SearchScope scope) {
    state = state.copyWith(scope: scope);
  }

  void selectReport(ReportKind kind) {
    state = state.copyWith(selectedReport: kind);
  }

  void setGeneratedReport(GeneratedReport report) {
    state = state.copyWith(selectedReport: report.kind, lastReport: report);
  }

  void clearGeneratedReport() {
    state = state.copyWith(clearReport: true);
  }
}

final searchReportsUiProvider =
    StateNotifierProvider<SearchReportsNotifier, SearchReportsUiState>((ref) {
  return SearchReportsNotifier();
});

/// لون نطاق البحث.
Color scopeColor(SearchScope scope) {
  switch (scope) {
    case SearchScope.all:
      return AppColors.primaryNavy;
    case SearchScope.cases:
      return AppColors.primaryNavy;
    case SearchScope.contracts:
      return AppColors.info;
    case SearchScope.companies:
      return AppColors.secondaryGold;
    case SearchScope.procedures:
      return AppColors.warning;
    case SearchScope.persons:
      return AppColors.success;
    case SearchScope.agencies:
      return AppColors.info;
    case SearchScope.documents:
      return AppColors.primaryNavy;
    case SearchScope.workOrders:
      return AppColors.warning;
    case SearchScope.finance:
      return AppColors.success;
    case SearchScope.legalLibrary:
      return AppColors.secondaryGold;
  }
}
