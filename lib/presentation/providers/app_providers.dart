import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/app_enums.dart';
import '../../data/database/database.dart';
import '../../data/services/sequence_service.dart';
import '../../data/services/task_sync_service.dart';
import '../../data/services/deficiency_service.dart';
import '../../data/services/file_storage_service.dart';
import '../../data/services/backup_service.dart';
import '../../data/repositories/person_repository.dart';
import '../../data/repositories/poa_repository.dart';
import '../../data/repositories/case_repository.dart';
import '../../data/repositories/company_repository.dart';
import '../../data/repositories/contract_repository.dart';
import '../../data/repositories/admin_procedure_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/finance_repository.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/lookup_repository.dart';
import '../../data/repositories/legal_library_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/work_order_repository.dart';

// =============================================================================
// 1. مزود قاعدة البيانات الموحدة (Database Provider)
// =============================================================================
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// =============================================================================
// 2. مزودات المحركات والخدمات الخلفية (Services & Engines Providers)
// =============================================================================
final sequenceServiceProvider = Provider<SequenceService>((ref) {
  return SequenceService(ref.watch(databaseProvider));
});

final taskSyncServiceProvider = Provider<TaskSyncService>((ref) {
  return TaskSyncService(ref.watch(databaseProvider));
});

final deficiencyServiceProvider = Provider<DeficiencyService>((ref) {
  return DeficiencyService(ref.watch(databaseProvider));
});

final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

// =============================================================================
// 3. مزودات المستودعات (Repositories Providers)
// =============================================================================
final personRepositoryProvider = Provider<PersonRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PersonRepository(db.personDao, ref.watch(fileStorageServiceProvider));
});

final poaRepositoryProvider = Provider<PoaRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PoaRepository(db.personDao, ref.watch(fileStorageServiceProvider));
});

final caseRepositoryProvider = Provider<CaseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CaseRepository(
    db.caseDao,
    ref.watch(sequenceServiceProvider),
    ref.watch(taskSyncServiceProvider),
    ref.watch(deficiencyServiceProvider),
    ref.watch(fileStorageServiceProvider),
  );
});

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CompanyRepository(
    db.companyDao,
    ref.watch(sequenceServiceProvider),
    ref.watch(taskSyncServiceProvider),
    ref.watch(deficiencyServiceProvider),
  );
});

final contractRepositoryProvider = Provider<ContractRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ContractRepository(
    db.contractDao,
    ref.watch(sequenceServiceProvider),
    ref.watch(taskSyncServiceProvider),
    ref.watch(fileStorageServiceProvider),
  );
});

final adminProcedureRepositoryProvider = Provider<AdminProcedureRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AdminProcedureRepository(
    db.adminProcedureDao,
    ref.watch(sequenceServiceProvider),
  );
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskRepository(
    db.taskDao,
    ref.watch(taskSyncServiceProvider),
    ref.watch(deficiencyServiceProvider),
  );
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FinanceRepository(db.financeDao, ref.watch(fileStorageServiceProvider));
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DocumentRepository(db.documentDao, ref.watch(fileStorageServiceProvider));
});

final lookupRepositoryProvider = Provider<LookupRepository>((ref) {
  return LookupRepository(ref.watch(databaseProvider).lookupDao);
});

// =============================================================================
// 4. مزودات التدفق المباشر للبيانات للواجهات (Stream & UI Providers)
// =============================================================================

/// قائمة الدعاوى القضائية
final allCasesProvider = StreamProvider<List<Case>>((ref) {
  return ref.watch(caseRepositoryProvider).watchAllCases();
});

/// تفاصيل دعوى واحدة من المستودع الحقيقي (Drift)
final caseDetailFromRepoProvider = FutureProvider.family<Case?, int>((ref, caseId) {
  return ref.watch(caseRepositoryProvider).getCaseById(caseId);
});

final casePartiesProvider = StreamProvider.family<List<CaseParty>, int>((ref, caseId) {
  return ref.watch(caseRepositoryProvider).watchCaseParties(caseId);
});

final caseSessionsProvider = StreamProvider.family<List<CaseSession>, int>((ref, caseId) {
  return ref.watch(caseRepositoryProvider).watchCaseSessions(caseId);
});

final casePhasesProvider = StreamProvider.family<List<CasePhase>, int>((ref, caseId) {
  return ref.watch(caseRepositoryProvider).watchCasePhases(caseId);
});

final caseOpenDeficienciesProvider = StreamProvider.family<List<Deficiency>, int>((ref, caseId) {
  return ref.watch(taskRepositoryProvider).watchOpenDeficiencies(
    entityType: EntityType.caseEntity,
    entityId: caseId,
  );
});

final allPersonsProvider = StreamProvider.family<List<PersonEntity>, PersonType?>((ref, type) {
  return ref.watch(personRepositoryProvider).watchAllPersons(type: type);
});

final allCompaniesProvider = StreamProvider<List<Company>>((ref) {
  return ref.watch(companyRepositoryProvider).watchAllCompanies();
});

final allContractsProvider = StreamProvider<List<Contract>>((ref) {
  return ref.watch(contractRepositoryProvider).watchAllContracts();
});

final allProceduresProvider = StreamProvider<List<AdminProcedure>>((ref) {
  return ref.watch(adminProcedureRepositoryProvider).watchAllProcedures();
});

final tasksByDateProvider = StreamProvider.family<List<DailyTask>, DateTime?>((ref, date) {
  final target = date ?? DateTime.now();
  return ref.watch(taskRepositoryProvider).watchTasksByDate(target);
});

final openDeficienciesProvider = StreamProvider.family<List<Deficiency>, ({EntityType? type, int? id})?>((ref, filter) {
  return ref.watch(taskRepositoryProvider).watchOpenDeficiencies(
    entityType: filter?.type,
    entityId: filter?.id,
  );
});

final activeCourtsProvider = StreamProvider.family<List<Court>, String?>((ref, type) {
  return ref.watch(lookupRepositoryProvider).watchActiveCourts(type: type);
});


final legalLibraryRepositoryProvider = Provider<LegalLibraryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LegalLibraryRepository(db.legalLibraryDao);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsRepository(db.settingsDao, ref.watch(backupServiceProvider));
});


final workOrderRepositoryProvider = Provider<WorkOrderRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkOrderRepository(db.workOrderDao);
});
