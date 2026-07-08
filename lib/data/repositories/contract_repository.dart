import 'dart:io';
import 'package:drift/drift.dart';
import '../../core/enums/app_enums.dart';
import '../database/database.dart';
import '../database/daos/contract_dao.dart';
import '../services/sequence_service.dart';
import '../services/task_sync_service.dart';
import '../services/file_storage_service.dart';

/// مستودع إدارة العقود، التنبيهات الزمنية، ونماذج Word (ContractRepository)
class ContractRepository {
  final ContractDao _contractDao;
  final SequenceService _sequenceService;
  final TaskSyncService _taskSyncService;
  final FileStorageService _storageService;

  ContractRepository(
    this._contractDao,
    this._sequenceService,
    this._taskSyncService,
    this._storageService,
  );

  Stream<List<Contract>> watchAllContracts() => _contractDao.watchAllContracts();
  Future<Contract?> getContractById(int id) => _contractDao.getContractById(id);
  Stream<List<ContractParty>> watchContractParties(int contractId) => _contractDao.watchContractParties(contractId);
  Stream<List<ContractReminder>> watchContractReminders(int contractId) => _contractDao.watchContractReminders(contractId);
  Stream<List<ContractTemplate>> watchContractTemplates({String? type}) => _contractDao.watchContractTemplates(contractType: type);
  Stream<List<ContractVersion>> watchContractVersions(int contractId) => _contractDao.watchContractVersions(contractId);

  /// تنظيم عقد جديد وربط التنبيهات بجدول الأعمال اليومية مع رفع ملف Word
  Future<int> createContract({
    required ContractsCompanion contract,
    required List<ContractPartiesCompanion> parties,
    List<ContractRemindersCompanion>? reminders,
    File? wordFile,
    required String userRef,
  }) async {
    return await _contractDao.db.transaction(() async {
      final String internalNum = await _sequenceService.generateNextInternalNumber();
      
      final contractId = await _contractDao.insertContract(
        contract.copyWith(
          internalNumber: Value(internalNum),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      for (final party in parties) {
        await _contractDao.insertContractParty(party.copyWith(contractId: Value(contractId)));
      }

      if (wordFile != null) {
        final filePath = await _storageService.saveAttachment(
          sourceFile: wordFile,
          folderType: 'contracts',
          entityId: contractId,
        );

        await _contractDao.insertContractVersion(
          ContractVersionsCompanion.insert(
            contractId: contractId,
            versionNumber: 1,
            filePath: Value(filePath),
            editedBy: Value(userRef),
            notes: const Value('النسخة الأولى عند إبرام العقد'),
          ),
        );
      }

      if (reminders != null) {
        for (final r in reminders) {
          final companion = r.copyWith(contractId: Value(contractId));
          await _taskSyncService.syncContractReminder(
            reminder: companion,
            contractTitle: contract.title.value,
            contractId: contractId,
          );
        }
      }

      await _contractDao.into(_contractDao.db.timelineEvents).insert(
        TimelineEventsCompanion.insert(
          entityType: EntityType.contract.index,
          entityId: contractId,
          eventType: 'contract_created',
          eventDate: Value(DateTime.now()),
          description: 'تم تنظيم عقد جديد [${contract.title.value}] برقم ملف: $internalNum',
          userRef: Value(userRef),
        ),
      );

      return contractId;
    });
  }
}
