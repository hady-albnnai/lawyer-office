import 'dart:io';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/daos/person_dao.dart';
import '../services/file_storage_service.dart';

/// مستودع إدارة الوكالات القضائية والقانونية (PoaRepository)
class PoaRepository {
  final PersonDao _personDao;
  final FileStorageService _storageService;

  PoaRepository(this._personDao, this._storageService);

  Stream<List<PowersOfAttorneyData>> watchAllPoas() => _personDao.watchAllPoas();

  /// إصدار وحفظ سند توكيل جديد وربط الموكل والوكيل مع إرفاق صورة السند
  Future<int> createPoa({
    required PowersOfAttorneyCompanion poa,
    required int principalId,
    int? agentId,
    File? poaFile,
  }) async {
    return await _personDao.db.transaction(() async {
      final poaId = await _personDao.insertPoa(poa);

      if (poaFile != null) {
        final filePath = await _storageService.saveAttachment(
          sourceFile: poaFile,
          folderType: 'powers_of_attorney',
          entityId: poaId,
        );
        await (_personDao.update(_personDao.db.powersOfAttorney)..where((t) => t.id.equals(poaId))).write(
          PowersOfAttorneyCompanion(filePath: Value(filePath)),
        );
      }

      // إضافة الموكل الأساسي
      await _personDao.insertPoaParty(
        PoaPartiesCompanion.insert(
          poaId: poaId,
          personId: principalId,
          partyRole: const Value('principal'),
          isPrimary: const Value(true),
        ),
      );

      // إضافة الوكيل إن وجد
      if (agentId != null) {
        await _personDao.insertPoaParty(
          PoaPartiesCompanion.insert(
            poaId: poaId,
            personId: agentId,
            partyRole: const Value('agent'),
            isPrimary: const Value(false),
          ),
        );
      }

      return poaId;
    });
  }

  Future<int> linkPoaToCase(int caseId, int poaId) {
    return _personDao.linkPoaToCase(caseId, poaId);
  }
}
