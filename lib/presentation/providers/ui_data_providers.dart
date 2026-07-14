import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final List<ui_case.Case> result = await Future.wait<ui_case.Case>(cases.map((c) async {
      return ui_case.Case(
        id: '${c.id}',
        caseNumber: c.internalNumber,
        title: c.subject ?? c.internalNumber,
        type: _mapCaseType(c.caseType),
        status: _mapCaseStatus(c.status),
        court: 'محكمة',
        subject: c.subject ?? '',
        claim: c.subjectDetails ?? '',
        notes: c.notes ?? '',
        creationDate: c.createdAt,
        lastUpdated: c.updatedAt,
        baseNumber: c.baseNumber,
        baseYear: c.year,
        sessions: [],
        phases: [],
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
    return ui_doc.DocumentItem(
      id: '${d.id}',
      title: d.docName,
      documentType: _mapDocType(d.docType),
      entityType: entityType == 1 ? 'contract' : 'case',
      entityId: '$entityId',
      entityTitle: entityType == 1 ? 'عقد #$entityId' : 'دعوى #$entityId',
      filePath: d.filePath ?? '',
      fileName: d.filePath?.split('/').last ?? '${d.docName}.pdf',
      fileSize: 0,
      fileType: _mapFileType(d.fileType),
      uploadDate: d.dateAdded,
      uploadedBy: 'المكتب',
      physicalLocation: d.physicalLocation == 0 ? 'مكتب المحامي' : 'خارج المكتب',
      isMissingOriginal: d.status != 0,
      notes: d.notes ?? '',
    );
  }).toList();
});

// =============================================================================
// Files archive (unified)
// =============================================================================

final uiFilesProvider = FutureProvider<List<ui_files.FileItem>>((ref) async {
  final cases = await ref.watch(uiCasesProvider.future);
  final docs = await ref.watch(uiDocumentsProvider.future);
  return cases.map((c) {
    final relatedDocs = docs.where((d) => d.entityId == c.id).toList();
    final next = c.nextSession?.sessionDate ?? c.sessions.where((s) => s.sessionDate.isAfter(DateTime.now())).map((s) => s.sessionDate).fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
    final hasBase = (c.baseNumber ?? '').isNotEmpty;
    final deficient = c.openDeficienciesCount > 0 || !hasBase;
    final overdue = next != null && next.isBefore(DateTime.now());
    return ui_files.FileItem(
      id: c.id,
      fileNumber: c.caseNumber,
      title: c.title,
      type: ui_files.FileType.caseFile,
      court: c.court,
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
    );
  }).toList();
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
          expiresAt: a.expiryDate,
          scope: a.scopeText ?? '',
          documentId: a.filePath ?? '',
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

final uiWorkOrdersProvider = StreamProvider<List<ui_wo.WorkOrder>>((ref) async* {
  await ref.watch(coreDataBootstrapProvider.future);
  final repo = ref.watch(workOrderRepositoryProvider);
  await for (final rows in repo.watchAll()) {
    yield rows
      .map(
        (w) => ui_wo.WorkOrder(
          id: '${w.id}',
          internalNumber: w.internalNumber,
          linkedEntityType: w.linkedEntityType == 0 ? 'case' : 'procedure',
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
});
