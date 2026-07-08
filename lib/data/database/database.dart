import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';
import 'schema.dart';
import 'daos/case_dao.dart';
import 'daos/person_dao.dart';
import 'daos/task_dao.dart';
import 'daos/finance_dao.dart';
import 'daos/document_dao.dart';
import 'daos/lookup_dao.dart';
import 'daos/company_dao.dart';
import 'daos/contract_dao.dart';
import 'daos/admin_procedure_dao.dart';

part 'database.g.dart';

/// قاعدة البيانات المحلية الموحدة لنظام إدارة مكتب المحاماة السوري (Drift + SQLite)
@DriftDatabase(
  tables: [
    // 1. النظام والإعدادات
    AppSettings, Security, ActivityLog, Backups, YearlySequences,
    // 2. الأشخاص والأدوار
    Persons, LegalEntities, PersonRoles, TeamMembers, OpponentLawyers, Notaries,
    // 3. الوكالات القضائية
    PowersOfAttorney, PoaParties, CasePoaLinks,
    // 4. الجداول المرجعية
    Courts, CaseSubjects, PartyRolesLookup, ContractTypesLookup, CompanyTypesLookup,
    // 5. الدعاوى والجلسات
    Cases, CaseParties, CasePhases, CaseSessions, CaseActions,
    // 6. الشركات
    Companies, CompanyPhases, CompanyManagement, CompanyPartners, CompanyDirectors,
    // 7. العقود
    Contracts, ContractParties, ContractReminders, ContractTemplates, ContractVersions,
    // 8. الإجراءات الإدارية
    AdminProcedures, AdminSteps, AdminProcedureTypes,
    // 9. المهام والأعمال اليومية
    DailyTasks, TaskHistory,
    // 10. المستندات
    Documents, DocumentLinks,
    // 11. المالية الموحدة
    FeeAgreements, FeePayments, Expenses,
    // 12. النواقص والخط الزمني
    Deficiencies, TimelineEvents,
  ],
  daos: [
    CaseDao,
    PersonDao,
    TaskDao,
    FinanceDao,
    DocumentDao,
    LookupDao,
    CompanyDao,
    ContractDao,
    AdminProcedureDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openDatabase());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // 1. إنشاء كافة الجداول الـ 22 في قاعدة البيانات
      await m.createAll();
      
      // 2. بناء فهارس البحث السريع (Indexes)
      await _createCustomIndexes();
      
      // 3. حقن البيانات السورية المرجعية الافتراضية (المحاكم، الدوائر، وفروع النقابة)
      await _seedDefaultLookups();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // مخطط الترقية المستقبلية وتعديل الجداول (Migrations)
    },
    beforeOpen: (details) async {
      // تفعيل القيود الخارجية (Foreign Keys) عند كل اتصال
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  /// إنشاء الفهارس السريعة للحقول الأكثر استخداماً في البحث والمتابعة اليومية
  Future<void> _createCustomIndexes() async {
    await customStatement('CREATE INDEX IF NOT EXISTS idx_persons_name ON persons(full_name);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_persons_nat_id ON persons(national_id);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_persons_phone ON persons(phone1);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_cases_internal ON cases(internal_number);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_cases_year_num ON cases(year, internal_number);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_cases_next_session ON cases(next_session_date);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_cases_status ON cases(status);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_daily_tasks_date ON daily_tasks(task_date, status);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_daily_tasks_assigned ON daily_tasks(assigned_to);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_doc_links_entity ON document_links(entity_type, entity_id);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_timeline_entity ON timeline_events(entity_type, entity_id, event_date);');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_deficiencies_entity ON deficiencies(entity_type, entity_id, status);');
  }

  /// حقن القوائم السورية الجاهزة الافتراضية عند أول تشغيل للمكتب
  Future<void> _seedDefaultLookups() async {
    await batch((b) {
      // محاكم سورية افتراضية
      b.insertAll(courts, [
        CourtsCompanion.insert(name: 'محكمة البداية المدنية الأولى بدمشق', type: const Value('بداية'), city: const Value('دمشق')),
        CourtsCompanion.insert(name: 'محكمة الصلح المدنية الأولى بدمشق', type: const Value('صلح'), city: const Value('دمشق')),
        CourtsCompanion.insert(name: 'محكمة الاستئناف المدنية بدمشق', type: const Value('استئناف'), city: const Value('دمشق')),
        CourtsCompanion.insert(name: 'محكمة النقض السورية - الغرفة المدنية', type: const Value('نقض'), city: const Value('دمشق')),
        CourtsCompanion.insert(name: 'محكمة البداية التجارية بدمشق', type: const Value('تجارية'), city: const Value('دمشق')),
        CourtsCompanion.insert(name: 'المحكمة الشرعية الأولى بدمشق', type: const Value('شرعية'), city: const Value('دمشق')),
        CourtsCompanion.insert(name: 'محكمة البداية المدنية بالسويداء', type: const Value('بداية'), city: const Value('السويداء')),
        CourtsCompanion.insert(name: 'محكمة الصلح المدنية بالسويداء', type: const Value('صلح'), city: const Value('السويداء')),
        CourtsCompanion.insert(name: 'محكمة الاستئناف المدنية بالسويداء', type: const Value('استئناف'), city: const Value('السويداء')),
        CourtsCompanion.insert(name: 'المحكمة الشرعية بالسويداء', type: const Value('شرعية'), city: const Value('السويداء')),
      ]);

      // مواضيع دعاوى جاهزة
      b.insertAll(caseSubjects, [
        CaseSubjectsCompanion.insert(name: 'مطالبة مالية', category: const Value('مدني')),
        CaseSubjectsCompanion.insert(name: 'تثبيت بيع عقار', category: const Value('مدني')),
        CaseSubjectsCompanion.insert(name: 'إخلاء مأجور', category: const Value('مدني')),
        CaseSubjectsCompanion.insert(name: 'تثبيت زواج ونسب', category: const Value('شرعي')),
        CaseSubjectsCompanion.insert(name: 'تثبيت طلاق ومخالعة رضائية', category: const Value('شرعي')),
        CaseSubjectsCompanion.insert(name: 'نفقة زوجية وأولاد', category: const Value('شرعي')),
        CaseSubjectsCompanion.insert(name: 'فسخ عقد تجاري ومطالبة بالعطل والضرر', category: const Value('تجاري')),
        CaseSubjectsCompanion.insert(name: 'إساءة أمانة', category: const Value('جزائي')),
        CaseSubjectsCompanion.insert(name: 'شيك بلا رصيد', category: const Value('جزائي')),
      ]);

      // صفات الأطراف
      b.insertAll(partyRolesLookup, [
        PartyRolesLookupCompanion.insert(roleName: 'مدعي', category: 'civil'),
        PartyRolesLookupCompanion.insert(roleName: 'مدعى عليه', category: 'civil'),
        PartyRolesLookupCompanion.insert(roleName: 'متدخل / شخص ثالث', category: 'civil'),
        PartyRolesLookupCompanion.insert(roleName: 'مستأنف', category: 'civil'),
        PartyRolesLookupCompanion.insert(roleName: 'مستأنف عليه', category: 'civil'),
        PartyRolesLookupCompanion.insert(roleName: 'طاعن', category: 'civil'),
        PartyRolesLookupCompanion.insert(roleName: 'مطعون ضده', category: 'civil'),
        PartyRolesLookupCompanion.insert(roleName: 'مدعي شخصي / شاكي', category: 'criminal'),
        PartyRolesLookupCompanion.insert(roleName: 'مشكو منه / متهم / ظنين', category: 'criminal'),
      ]);

      // مندوبو فروع النقابة وكتاب العدل الافتراضيون (سوريا)
      b.insertAll(notaries, [
        NotariesCompanion.insert(name: 'مندوب نقابة المحامين - فرع دمشق', branch: const Value('دمشق'), type: 'delegate'),
        NotariesCompanion.insert(name: 'مندوب نقابة المحامين - فرع ريف دمشق', branch: const Value('ريف دمشق'), type: 'delegate'),
        NotariesCompanion.insert(name: 'مندوب نقابة المحامين - فرع السويداء', branch: const Value('السويداء'), type: 'delegate'),
        NotariesCompanion.insert(name: 'مندوب نقابة المحامين - فرع درعا', branch: const Value('درعا'), type: 'delegate'),
        NotariesCompanion.insert(name: 'مندوب نقابة المحامين - فرع حمص', branch: const Value('حمص'), type: 'delegate'),
        NotariesCompanion.insert(name: 'مندوب نقابة المحامين - فرع حلب', branch: const Value('حلب'), type: 'delegate'),
        NotariesCompanion.insert(name: 'مندوب نقابة المحامين - فرع اللاذقية', branch: const Value('اللاذقية'), type: 'delegate'),
        NotariesCompanion.insert(name: 'دائرة الكاتب بالعدل الأول بدمشق', branch: const Value('دمشق'), type: 'public_notary'),
        NotariesCompanion.insert(name: 'دائرة الكاتب بالعدل الأول بالسويداء', branch: const Value('السويداء'), type: 'public_notary'),
      ]);
    });
  }
}

/// إنشاء الاتصال مع قاعدة البيانات المحلية في Isolate خلفي على Windows دون اعتماد OpenSSL خارجي
LazyDatabase _openDatabase() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final lawOfficeDir = Directory(p.join(dbFolder.path, AppConstants.appDataDirectoryName));
    if (!await lawOfficeDir.exists()) {
      await lawOfficeDir.create(recursive: true);
    }

    final file = File(p.join(lawOfficeDir.path, AppConstants.defaultDatabaseName));

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        // فرض سلامة العلاقات الخارجية عند فتح قاعدة البيانات المحلية.
        rawDb.execute("PRAGMA foreign_keys = ON;");
      },
    );
  });
}
