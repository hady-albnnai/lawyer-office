import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/app_enums.dart';
import '../../data/database/database.dart' as db;
import '../screens/cases/case_models.dart' as ui_case;
import '../screens/documents/document_models.dart' as ui_doc;
import '../screens/files/files_screen.dart' as ui_files;
import '../screens/persons/person_models.dart' as ui_person;
import '../screens/work_orders/work_order_models.dart' as ui_wo;
import 'app_providers.dart';

// =============================================================================
// Bootstrap seeds for remaining modules
// =============================================================================

/// هل يُسمح ببذر بيانات تجريبية؟ (يُفعّل فقط من معالج أول تشغيل عند اختيار الزبون)
final allowDemoSeedProvider = StateProvider<bool>((ref) => false);

final coreDataBootstrapProvider = FutureProvider<void>((ref) async {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  await settingsRepo.ensureDefaults();

  // لا تُزرع بيانات تجريبية تلقائياً — فقط عند السماح الصريح.
  final allowDemo = ref.watch(allowDemoSeedProvider);
  if (!allowDemo) return;

  final personRepo = ref.watch(personRepositoryProvider);
  final caseRepo = ref.watch(caseRepositoryProvider);
  final docRepo = ref.watch(documentRepositoryProvider);
  final woRepo = ref.watch(workOrderRepositoryProvider);
  final financeRepo = ref.watch(financeRepositoryProvider);
  final legalRepo = ref.watch(legalLibraryRepositoryProvider);

  await personRepo.seedDemoIfEmpty();
  await caseRepo.seedDemoIfEmpty();
  await docRepo.seedDemoIfEmpty();
  await woRepo.seedDemoIfEmpty();
  await financeRepo.seedDemoIfEmpty();
  await legalRepo.seedDemoIfEmpty();
});

// =============================================================================
// Cases (UI model)
// =============================================================================

ui_case.CaseType _mapCaseType(String raw) {
  final v = raw.trim();
  if (v.contains('جزائ')) return ui_case.CaseType.criminal;
  if (v.contains('تجار')) return ui_case.CaseType.commercial;
  if (v.contains('شرع')) return ui_case.CaseType.personalStatus;
  if (v.contains('إدار')) return ui_case.CaseType.civil;
  return ui_case.CaseType.civil;
}

ui_case.CaseStatus _mapCaseStatus(String raw) {
  switch (raw) {
    case 'closed':
      return ui_case.CaseStatus.completed;
    case 'pending_registration':
      return ui_case.CaseStatus.postponed;
    case 'preparing':
      return ui_case.CaseStatus.scheduled;
    default:
      return ui_case.CaseStatus.inProgress;
  }
}

final uiCasesProvider = StreamProvider<List<ui_case.Case>>((ref) async* {
  await ref.watch(coreDataBootstrapProvider.future);
  final caseRepo = ref.watch(caseRepositoryProvider);
  
  await for (final cases in ref.watch(allCasesProvider.stream)) {
    final result = await Future.wait(cases.map((c) async {
      final sessions = await caseRepo.getSessionsForCase(c.id);
      final phases = await caseRepo.getPhasesForCase(c.id);
      final court = c.courtId != null ? await caseRepo.getCourtById(c.courtId!) : null;
      final courtName = court?.name ?? 'محكمة';

      final uiSessions = sessions.map((s) => ui_case.CaseSession(
        id: '${s.id}',
        sessionDate: s.sessionDate,
        sessionTime: _parseTime(s.sessionTime) ?? const TimeOfDay(hour: 9, minute: 0),
        type: ui_case.SessionType.ordinary,
        status: s.status == 2 ? ui_case.SessionStatus.held : ui_case.SessionStatus.scheduled,
        court: courtName,
      )).toList();

      final uiPhases = phases.map((p) => ui_case.CasePhase(
        id: '${p.id}',
        type: ui_case.CasePhaseType.initial,
        court: courtName,
        baseNumber: p.baseNumber ?? '',
        baseYear: p.year ?? c.year,
        startDate: p.startDate ?? c.createdAt,
      )).toList();

      return ui_case.Case(
        id: '${c.id}',
        caseNumber: c.internalNumber,
        title: c.subject ?? c.internalNumber,
        type: _mapCaseType(c.caseType),
        status: _mapCaseStatus(c.status),
        court: courtName,
        subject: c.subject ?? '',
        claim: c.subjectDetails ?? '',
        notes: c.notes ?? '',
        creationDate: c.createdAt,
        lastUpdated: c.updatedAt,
        baseNumber: c.baseNumber,
        baseYear: c.year,
        sessions: uiSessions,
        phases: uiPhases,
      );
    }));
    yield result;
  }
});

TimeOfDay? _parseTime(String? raw) {
  if (raw == null || !raw.contains(':')) return null;
  final parts = raw.split(':');
  return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
}

// =============================================================================
// Documents
// =============================================================================

ui_doc.DocumentType _mapDocType(String? raw) {
  final v = (raw ?? '').toLowerCase();
  if (v.contains('poa') || v.contains('وكال') || v.contains('power')) return ui_doc.DocumentType.powerOfAttorney;
  if (v.contains('contract') || v.contains('عقد')) return ui_doc.DocumentType.contract;
  if (v.contains('memo') || v.contains('مذكر')) return ui_doc.DocumentType.memo;
  if (v.contains('decision') || v.contains('قرار')) return ui_doc.DocumentType.decision;
  if (v.contains('receipt') || v.contains('إيص')) return ui_doc.DocumentType.receipt;
  return ui_doc.DocumentType.caseDocument;
}

ui_doc.FileType _mapFileType(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'pdf':
      return ui_doc.FileType.pdf;
    case 'docx':
      return ui_doc.FileType.docx;
    case 'doc':
      return ui_doc.FileType.doc;
    case 'jpg':
    case 'jpeg':
      return ui_doc.FileType.jpg;
    case 'png':
      return ui_doc.FileType.png;
    case 'txt':
      return ui_doc.FileType.txt;
    case 'rtf':
      return ui_doc.FileType.rtf;
    default:
      return ui_doc.FileType.other;
  }
}

String _paperArchiveLocation(String? notes, int physicalLocation) {
  final raw = notes ?? '';
  String pick(String prefix) {
    final line = raw.split('\n').firstWhere(
          (item) => item.startsWith(prefix),
          orElse: () => '',
        );
    return line.replaceFirst(prefix, '').trim();
  }

  final parts = <String>[
    pick('مكان الأصل:'),
    if (pick('الصندوق:').isNotEmpty) 'صندوق ${pick('الصندوق:')}',
    if (pick('الرف:').isNotEmpty) 'رف ${pick('الرف:')}',
    if (pick('المجلد الورقي:').isNotEmpty) 'مجلد ${pick('المجلد الورقي:')}',
  ].where((value) => value.isNotEmpty).toList();
  if (parts.isNotEmpty) return parts.join(' • ');
  return physicalLocation == 0 ? 'مكتب المحامي' : 'خارج المكتب';
}

bool _isPaperOriginalMissing(String? notes, int status) {
  final raw = notes ?? '';
  return status != 0 || raw.contains('الأصل الورقي محفوظ: لا');
}

String _documentEntityKey(int entityType) {
  if (entityType == EntityType.contract.index) return 'contract';
  if (entityType == EntityType.company.index) return 'company';
  if (entityType == EntityType.adminProcedure.index) return 'adminProcedure';
  if (entityType == EntityType.person.index) return 'person';
  if (entityType == EntityType.powerOfAttorney.index) return 'poa';
  return 'case';
}

String _documentEntityTitle(int entityType, int entityId) {
  if (entityType == EntityType.contract.index) return 'عقد #$entityId';
  if (entityType == EntityType.company.index) return 'شركة #$entityId';
  if (entityType == EntityType.adminProcedure.index) return 'إجراء #$entityId';
  if (entityType == EntityType.person.index) return 'شخص / جهة #$entityId';
  if (entityType == EntityType.powerOfAttorney.index) return 'وكالة #$entityId';
  if (entityType == 99) return 'أرشيف غير مصنف';
  return 'دعوى #$entityId';
}

final uiDocumentsProvider = FutureProvider<List<ui_doc.DocumentItem>>((ref) async {
  await ref.watch(coreDataBootstrapProvider.future);
  final repo = ref.watch(documentRepositoryProvider);
  final docs = await repo.getAllDocuments();
  final links = await repo.getAllLinks();
  final byDoc = <int, db.DocumentLink>{};
  for (final l in links) {
    byDoc.putIfAbsent(l.documentId, () => l);
  }

  return docs.map((d) {
    final link = byDoc[d.id];
    final entityType = link?.entityType ?? 0;
    final entityId = link?.entityId ?? 0;
    final originalMissing = _isPaperOriginalMissing(d.notes, d.status);
    return ui_doc.DocumentItem(
      id: '${d.id}',
      title: d.docName,
      documentType: _mapDocType(d.docType),
      entityType: _documentEntityKey(entityType),
      entityId: '$entityId',
      entityTitle: _documentEntityTitle(entityType, entityId),
      filePath: d.filePath ?? '',
      fileName: d.filePath?.split('/').last ?? '${d.docName}.pdf',
      fileSize: 0,
      fileType: _mapFileType(d.fileType),
      uploadDate: d.dateAdded,
      uploadedBy: 'المكتب',
      physicalLocation: _paperArchiveLocation(d.notes, d.physicalLocation),
      hasOriginal: !originalMissing,
      isMissingOriginal: originalMissing,
      notes: d.notes ?? '',
    );
  }).toList();
});

// =============================================================================
// Files archive (unified)
// =============================================================================

final uiFilesProvider = FutureProvider<List<ui_files.FileItem>>((ref) async {
  await ref.watch(coreDataBootstrapProvider.future);
  final docs = await ref.watch(uiDocumentsProvider.future);
  final result = <ui_files.FileItem>[];

  final cases = await ref.watch(uiCasesProvider.future);
  for (final c in cases) {
    final relatedDocs = docs.where((d) => d.entityType == 'case' && d.entityId == c.id).toList();
    final next = c.nextSession?.sessionDate ?? c.sessions.where((s) => s.sessionDate.isAfter(DateTime.now())).map((s) => s.sessionDate).fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
    final hasBase = (c.baseNumber ?? '').isNotEmpty;
    final deficient = c.openDeficienciesCount > 0 || !hasBase;
    final overdue = next != null && next.isBefore(DateTime.now());
    result.add(ui_files.FileItem(
      id: c.id,
      fileNumber: c.caseNumber,
      title: c.title,
      type: ui_files.FileType.caseFile,
      court: c.court,
      subCategory: c.type.displayName,
      status: c.status == ui_case.CaseStatus.completed ? ui_files.FileStatus.completed : ui_files.FileStatus.active,
      hasDeficiencies: deficient,
      deficiencyCount: c.openDeficienciesCount,
      nextSessionDate: next,
      baseNumber: c.baseNumber,
      hasBaseNumber: hasBase,
      isOverdue: overdue,
      createdAt: c.creationDate,
      lastUpdated: c.lastUpdated ?? c.creationDate,
      documentCount: relatedDocs.length,
      documentIds: relatedDocs.map((d) => d.id).toList(),
      hasMissingDocuments: relatedDocs.any((d) => d.isMissingOriginal),
    ));
  }

  final contracts = await ref.watch(allContractsProvider.future);
  for (final c in contracts) {
    final relatedDocs = docs.where((d) => d.entityType == 'contract' && d.entityId == '${c.id}').toList();
    final end = c.dateEnd;
    final isCompleted = c.status != 'active' || (end != null && end.isBefore(DateTime.now()));
    result.add(ui_files.FileItem(
      id: '${c.id}',
      fileNumber: c.internalNumber,
      title: c.title,
      type: ui_files.FileType.contract,
      court: c.contractType,
      subCategory: c.contractType,
      status: isCompleted ? ui_files.FileStatus.completed : ui_files.FileStatus.active,
      nextSessionDate: c.needsFollowup ? end : null,
      hasBaseNumber: true,
      isOverdue: end != null && end.isBefore(DateTime.now()) && !isCompleted,
      createdAt: c.createdAt,
      lastUpdated: c.updatedAt,
      documentCount: relatedDocs.length,
      documentIds: relatedDocs.map((d) => d.id).toList(),
      hasMissingDocuments: relatedDocs.any((d) => d.isMissingOriginal),
    ));
  }

  final companies = await ref.watch(allCompaniesProvider.future);
  for (final c in companies) {
    final relatedDocs = docs.where((d) => d.entityType == 'company' && d.entityId == '${c.id}').toList();
    final completed = c.isArchived || c.legalStatus == 'dissolved' || c.legalStatus == 'archived';
    final deficient = (c.registrationNumber ?? '').isEmpty && !completed;
    result.add(ui_files.FileItem(
      id: '${c.id}',
      fileNumber: c.internalNumber,
      title: c.name,
      type: ui_files.FileType.company,
      court: c.companyType,
      subCategory: c.companyType,
      status: completed ? ui_files.FileStatus.completed : ui_files.FileStatus.active,
      hasDeficiencies: deficient,
      deficiencyCount: deficient ? 1 : 0,
      hasBaseNumber: (c.registrationNumber ?? '').isNotEmpty,
      baseNumber: c.registrationNumber,
      createdAt: c.createdAt,
      lastUpdated: c.createdAt,
      documentCount: relatedDocs.length,
      documentIds: relatedDocs.map((d) => d.id).toList(),
      hasMissingDocuments: deficient || relatedDocs.any((d) => d.isMissingOriginal),
    ));
  }

  final procedures = await ref.watch(allProceduresProvider.future);
  for (final p in procedures) {
    final relatedDocs = docs.where((d) => d.entityType == 'adminProcedure' && d.entityId == '${p.id}').toList();
    final completed = p.status == 2;
    final next = p.nextDate;
    result.add(ui_files.FileItem(
      id: '${p.id}',
      fileNumber: p.internalNumber,
      title: p.title,
      type: ui_files.FileType.adminProcedure,
      court: p.department ?? p.procedureType,
      subCategory: p.procedureType,
      status: completed ? ui_files.FileStatus.completed : ui_files.FileStatus.active,
      nextSessionDate: next,
      hasBaseNumber: (p.transactionNumber ?? '').isNotEmpty,
      baseNumber: p.transactionNumber,
      isOverdue: next != null && next.isBefore(DateTime.now()) && !completed,
      createdAt: p.createdAt,
      lastUpdated: p.createdAt,
      documentCount: relatedDocs.length,
      documentIds: relatedDocs.map((d) => d.id).toList(),
      hasMissingDocuments: relatedDocs.any((d) => d.isMissingOriginal),
    ));
  }

  final directory = await ref.watch(uiPersonsDirectoryProvider.future);
  for (final a in directory.agencies) {
    final relatedDocs = docs.where((d) => d.entityType == 'poa' && d.entityId == a.id).toList();
    final completed = a.isExpired || a.notes == 'archived' || a.scope.contains('أرشفة وكالة منتهية') || a.scope.contains('أرشيف منته');
    result.add(ui_files.FileItem(
      id: a.id,
      fileNumber: a.number,
      title: 'وكالة ${a.type.displayName} — ${directory.personById(a.principalPersonId)?.fullName ?? 'غير محدد'}',
      type: ui_files.FileType.agency,
      court: '${a.source.displayName} - ${a.branch}',
      subCategory: a.type.displayName,
      status: completed ? ui_files.FileStatus.completed : ui_files.FileStatus.active,
      nextSessionDate: a.expiresAt,
      hasBaseNumber: a.number.isNotEmpty,
      baseNumber: a.number,
      hasMissingDocuments: !a.hasDocument || relatedDocs.any((d) => d.isMissingOriginal),
      createdAt: a.issuedAt,
      lastUpdated: a.issuedAt,
      documentCount: relatedDocs.isNotEmpty ? relatedDocs.length : (a.hasDocument ? 1 : 0),
      documentIds: relatedDocs.isNotEmpty ? relatedDocs.map((d) => d.id).toList() : (a.hasDocument ? [a.documentId] : const []),
    ));
  }

  result.sort((a, b) => (a.nextSessionDate ?? DateTime(9999)).compareTo(b.nextSessionDate ?? DateTime(9999)));
  return result;
});

// =============================================================================
// Persons directory
// =============================================================================

final uiPersonsDirectoryProvider = FutureProvider<ui_person.PersonsDirectoryState>((ref) async {
  await ref.watch(coreDataBootstrapProvider.future);
  final personRepo = ref.watch(personRepositoryProvider);
  final persons = await personRepo.getAllPersons();
  final poas = await personRepo.getAllPoas();

  final records = <ui_person.PersonDirectoryRecord>[];
  for (final p in persons) {
    final rolesDb = await personRepo.getPersonRoles(p.id);
    final roles = rolesDb.map((r) {
      if (r.roleType >= 0 && r.roleType < ui_person.PersonDirectoryRole.values.length) {
        // map subset
      }
      switch (r.roleType) {
        case 1:
          return ui_person.PersonDirectoryRole.opponent;
        case 4:
          return ui_person.PersonDirectoryRole.teamMember;
        case 5:
          return ui_person.PersonDirectoryRole.contractParty;
        default:
          return ui_person.PersonDirectoryRole.client;
      }
    }).toList();
    if (roles.isEmpty) {
      roles.add(p.type == 1 ? ui_person.PersonDirectoryRole.legalEntity : ui_person.PersonDirectoryRole.client);
    }

    records.add(
      ui_person.PersonDirectoryRecord(
        id: '${p.id}',
        kind: p.type == 1 ? ui_person.PersonDirectoryKind.legal : ui_person.PersonDirectoryKind.natural,
        fullName: p.fullName,
        fatherName: p.fatherName ?? '',
        motherName: p.motherName ?? '',
        nationalId: p.nationalId ?? '',
        registryInfo: '${p.registryPlace ?? ''} ${p.registryNumber ?? ''}'.trim(),
        phone: p.phone1 ?? '',
        whatsapp: p.whatsapp ?? p.phone1 ?? '',
        email: p.email ?? '',
        address: p.permanentAddress ?? '',
        city: p.city ?? '',
        profession: p.profession ?? '',
        notes: p.notes ?? '',
        roles: roles,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      ),
    );
  }

  final agencies = poas
      .map(
        (a) => ui_person.AgencyRecord(
          id: '${a.id}',
          number: a.poaNumber ?? 'POA-${a.id}',
          type: a.poaType == 1 ? ui_person.AgencyType.special : ui_person.AgencyType.general,
          source: a.sourceType == 'notary' ? ui_person.AgencySource.notary : ui_person.AgencySource.barDelegate,
          branch: a.delegateBranch ?? '',
          principalPersonId: records.isNotEmpty ? records.first.id : '0',
          agentName: 'وكيل المكتب',
          issuedAt: a.poaDate ?? a.createdAt,
          expiresAt: a.status == 'archived' ? DateTime(2000) : a.expiryDate,
          scope: a.scopeText ?? '',
          documentId: a.filePath ?? '',
          notes: a.status,
        ),
      )
      .toList();

  return ui_person.PersonsDirectoryState(persons: records, agencies: agencies);
});

// =============================================================================
// Work orders
// =============================================================================

ui_wo.WorkOrderType _mapWoType(String raw) {
  switch (raw) {
    case 'document_photocopy':
      return ui_wo.WorkOrderType.documentPhotocopy;
    case 'fee_payment':
      return ui_wo.WorkOrderType.feePayment;
    case 'notary_review':
      return ui_wo.WorkOrderType.notaryReview;
    case 'execution_followup':
      return ui_wo.WorkOrderType.executionFollowup;
    case 'court_attendance':
      return ui_wo.WorkOrderType.courtAttendance;
    default:
      return ui_wo.WorkOrderType.other;
  }
}

ui_wo.WorkOrderPriority _mapWoPriority(String raw) {
  switch (raw) {
    case 'high':
      return ui_wo.WorkOrderPriority.high;
    case 'low':
      return ui_wo.WorkOrderPriority.low;
    default:
      return ui_wo.WorkOrderPriority.medium;
  }
}

ui_wo.WorkOrderStatus _mapWoStatus(String raw) {
  switch (raw) {
    case 'printed':
      return ui_wo.WorkOrderStatus.printed;
    case 'whatsapp_sent':
      return ui_wo.WorkOrderStatus.whatsappSent;
    case 'waiting_for_result':
      return ui_wo.WorkOrderStatus.waitingForResult;
    case 'result_entered':
      return ui_wo.WorkOrderStatus.resultEntered;
    case 'waiting_for_approval':
      return ui_wo.WorkOrderStatus.waitingForApproval;
    case 'approved':
      return ui_wo.WorkOrderStatus.approved;
    case 'returned_for_correction':
      return ui_wo.WorkOrderStatus.returnedForCorrection;
    case 'postponed':
      return ui_wo.WorkOrderStatus.postponed;
    case 'impossible':
      return ui_wo.WorkOrderStatus.impossible;
    case 'cancelled':
      return ui_wo.WorkOrderStatus.cancelled;
    default:
      return ui_wo.WorkOrderStatus.draft;
  }
}


String _mapWorkOrderEntityType(int raw) {
  switch (raw) {
    case 0:
      return 'case';
    case 1:
      return 'procedure';
    case 2:
      return 'company';
    case 3:
      return 'contract';
    case 4:
      return 'person';
    case 99:
      return 'work_order';
    default:
      return 'general';
  }
}

final uiWorkOrdersProvider = StreamProvider<List<ui_wo.WorkOrder>>((ref) async* {
  await ref.watch(coreDataBootstrapProvider.future);
  final repo = ref.watch(workOrderRepositoryProvider);
  await for (final rows in repo.watchAll()) {
    yield rows
      .map(
        (w) => ui_wo.WorkOrder(
          id: '${w.id}',
          internalNumber: w.internalNumber,
          linkedEntityType: _mapWorkOrderEntityType(w.linkedEntityType),
          linkedEntityId: '${w.linkedEntityId}',
          assignedToName: w.assignedToName,
          assignedToPhone: w.assignedToPhone ?? '',
          orderType: _mapWoType(w.orderType),
          priority: _mapWoPriority(w.priority),
          status: _mapWoStatus(w.status),
          dueDate: w.dueDate,
          instructions: w.instructions ?? '',
          createdAt: w.createdAt,
          createdBy: w.createdBy ?? '',
          printedAt: w.printedAt,
          whatsappSentAt: w.whatsappSentAt,
          resultText: w.resultText,
          resultDate: w.resultDate,
          nextDate: w.nextDate,
          approvedAt: w.approvedAt,
        ),
      )
      .toList();
  }
});
