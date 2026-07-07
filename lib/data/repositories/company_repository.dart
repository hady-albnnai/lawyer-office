import 'package:drift/drift.dart';
import '../../core/enums/app_enums.dart';
import '../database/database.dart';
import '../database/daos/company_dao.dart';
import '../services/sequence_service.dart';
import '../services/task_sync_service.dart';
import '../services/deficiency_service.dart';

/// مستودع إدارة الشركات التجارية والمدنية ومراحل التأسيس (CompanyRepository)
class CompanyRepository {
  final CompanyDao _companyDao;
  final SequenceService _sequenceService;
  final TaskSyncService _taskSyncService;
  final DeficiencyService _deficiencyService;

  CompanyRepository(
    this._companyDao,
    this._sequenceService,
    this._taskSyncService,
    this._deficiencyService,
  );

  Stream<List<Company>> watchAllCompanies() => _companyDao.watchAllCompanies();
  Future<Company?> getCompanyById(int id) => _companyDao.getCompanyById(id);
  Stream<List<CompanyPhase>> watchCompanyPhases(int companyId) => _companyDao.watchCompanyPhases(companyId);
  Stream<List<CompanyManagementData>> watchCompanyManagement(int companyId) => _companyDao.watchCompanyManagement(companyId);
  Stream<List<CompanyPartner>> watchCompanyPartners(int companyId) => _companyDao.watchCompanyPartners(companyId);
  Stream<List<CompanyDirector>> watchCompanyDirectors(int companyId) => _companyDao.watchCompanyDirectors(companyId);

  /// تأسيس شركة جديدة وتوليد المراحل الابتدائية وأتمتة المهام وتدقيق النواقص
  Future<int> createCompany({
    required CompaniesCompanion company,
    required List<CompanyPartnersCompanion> partners,
    required List<CompanyDirectorsCompanion> directors,
    required String userRef,
  }) async {
    return await _companyDao.db.transaction(() async {
      final String internalNum = await _sequenceService.generateNextInternalNumber();
      
      final companyId = await _companyDao.insertCompany(
        company.copyWith(
          internalNumber: Value(internalNum),
          createdAt: Value(DateTime.now()),
        ),
      );

      for (final p in partners) {
        await _companyDao.insertCompanyPartner(p.copyWith(companyId: Value(companyId)));
      }

      for (final d in directors) {
        await _companyDao.insertCompanyDirector(d.copyWith(companyId: Value(companyId)));
      }

      // إضافة مرحلة التأسيس الأولى تلقائياً
      await _taskSyncService.syncCompanyPhase(
        phase: CompanyPhasesCompanion.insert(
          companyId: companyId,
          phaseName: const Value('صياغة عقد التأسيس وتصديق النقابة'),
          phaseOrder: 1,
          status: const Value(0),
          scheduledDate: Value(DateTime.now().add(const Duration(days: 2))),
        ),
        companyName: company.name.value,
        companyId: companyId,
        userRef: userRef,
      );

      // تدقيق النواقص
      await _deficiencyService.auditCompanyDeficiencies(
        companyId: companyId,
        companyData: company,
        hasPartners: partners.isNotEmpty,
        hasDirectors: directors.isNotEmpty,
      );

      await _companyDao.into(_companyDao.db.timelineEvents).insert(
        TimelineEventsCompanion.insert(
          entityType: EntityType.company,
          entityId: companyId,
          eventType: 'company_created',
          eventDate: Value(DateTime.now()),
          description: 'تم البدء بتأسيس شركة جديدة [${company.name.value}] برقم ملف: $internalNum',
          userRef: Value(userRef),
        ),
      );

      return companyId;
    });
  }
}
