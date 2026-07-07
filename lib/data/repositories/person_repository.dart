import 'dart:io';
import 'package:drift/drift.dart';
import '../../core/enums/app_enums.dart';
import '../database/database.dart';
import '../database/daos/person_dao.dart';
import '../services/file_storage_service.dart';

/// مستودع إدارة الأشخاص، الكيانات الاعتبارية، ودليل المحامين وكتاب العدل (PersonRepository)
class PersonRepository {
  final PersonDao _personDao;
  final FileStorageService _storageService;

  PersonRepository(this._personDao, this._storageService);

  Stream<List<PersonEntity>> watchAllPersons({PersonType? type}) {
    return _personDao.watchAllPersons(type: type?.index);
  }

  Future<PersonEntity?> getPersonById(int id) {
    return _personDao.getPersonById(id);
  }

  /// حفظ شخص جديد مع إمكانية حفظ سند تمثيل إذا كان كياناً اعتبارياً
  Future<int> createPerson({
    required PersonsCompanion person,
    LegalEntitiesCompanion? legalEntity,
    File? representationDocFile,
    List<PersonRoleType>? initialRoles,
  }) async {
    return await _personDao.db.transaction(() async {
      final personId = await _personDao.insertPerson(person);

      if (person.type.value == PersonType.legal.index && legalEntity != null) {
        String? docPath;
        if (representationDocFile != null) {
          docPath = await _storageService.saveAttachment(
            sourceFile: representationDocFile,
            folderType: 'legal_entities',
            entityId: personId,
          );
        }

        await _personDao.insertLegalEntity(
          legalEntity.copyWith(
            personId: Value(personId),
            representationDocPath: Value(docPath),
          ),
        );
      }

      if (initialRoles != null) {
        for (final role in initialRoles) {
          await _personDao.insertPersonRole(
            PersonRolesCompanion.insert(
              personId: personId,
              roleType: role.index,
            ),
          );
        }
      }

      return personId;
    });
  }

  Stream<List<PersonRole>> watchPersonRoles(int personId) => _personDao.watchPersonRoles(personId);
  Stream<List<TeamMember>> watchTeamMembers() => _personDao.watchTeamMembers();
  Stream<List<OpponentLawyer>> watchOpponentLawyers() => _personDao.watchOpponentLawyers();
  Stream<List<Notary>> watchNotaries() => _personDao.watchNotaries();
}
