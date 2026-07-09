/// Models لنظام الدعاوى
import 'package:flutter/material.dart';

enum CaseStatus { scheduled, inProgress, completed, postponed, cancelled, pendingBaseNumber, pendingDocuments, pendingPayment
String get displayName => const ['مجدولة','قيد التنفيذ','منجزة','مؤجلة','ملغاة','بانتظار رقم أساس','بانتظار مستندات','بانتظار دفع'][index];
Color get color => const [Color(0xFF17A2B8), Color(0xFF17A2B8), Colors.green, Colors.orange, Colors.red, Colors.orange, Colors.orange, Colors.orange][index]; }

enum CaseType { civil, commercial, criminal, administrative, personalStatus, realEstate, labor, constitutional, other
String get displayName => const ['مدنية','تجارية','جزائية','إدارية','أحوال شخصية','عقارية','عمالية','دستورية','أخرى'][index]; }

enum CasePhaseType { initial, hearing, evidence, judgment, appeal, cassation, execution, settlement
String get displayName => const ['بداية','جلسات','إثبات','حكم','استئناف','نقض','تنفيذ','صلح'][index]; }

enum SessionType { ordinary, urgent, evidence, judgment, review, other
String get displayName => const ['عادية','مستعجلة','إثبات','حكم','مراجعة','أخرى'][index]; }

enum SessionStatus { scheduled, held, postponed, cancelled
String get displayName => const ['مجدولة','عقدت','مؤجلة','ملغاة'][index]; }

class SessionResult {
  final String decision, nextRequired, notes;
  final bool clientAttended, opponentAttended, opponentLawyerAttended;
  final DateTime? nextSessionDate;
  final double expenses;
  final List<String> attachments;
  SessionResult({this.decision='', this.clientAttended=true, this.opponentAttended=true, this.opponentLawyerAttended=true, this.nextSessionDate, this.nextRequired='', this.expenses=0, this.attachments=const [], this.notes=''});
}

class CasePhase {
  final String id, court, description;
  final CasePhaseType type;
  final String? baseNumber;
  final int? baseYear;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> documents;
  CasePhase({required this.id, required this.type, required this.court, this.baseNumber, this.baseYear, required this.startDate, this.endDate, this.description='', this.documents=const []});
}

class CaseSession {
  final String id, court, decision;
  final DateTime sessionDate;
  final TimeOfDay sessionTime;
  final SessionType type;
  final SessionStatus status;
  final SessionResult? result;
  final List<String> attendees, documents;
  CaseSession({required this.id, required this.sessionDate, required this.sessionTime, required this.type, this.status=SessionStatus.scheduled, required this.court, this.decision='', this.result, this.attendees=const [], this.documents=const []});
}

class CaseAction {
  final String id, title, description, assignedTo, status;
  final DateTime actionDate;
  final DateTime? dueDate;
  final List<String> documents;
  CaseAction({required this.id, required this.title, this.description='', required this.actionDate, this.dueDate, this.assignedTo='', this.status='pending', this.documents=const []});
}

class CaseDeficiency {
  final String id, field, description, severity;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final bool isResolved;
  CaseDeficiency({required this.id, required this.field, required this.description, required this.createdAt, this.resolvedAt, this.isResolved=false, this.severity='medium'});
}

class CaseTimelineEvent {
  final String id, eventType, description;
  final DateTime eventDate;
  final String? createdBy;
  final List<String>? documents;
  CaseTimelineEvent({required this.id, required this.eventDate, required this.eventType, required this.description, this.createdBy, this.documents});
}

class CaseFee {
  final String id, clientId, currency, status, paymentMethod, notes;
  final double amount;
  final DateTime agreementDate;
  final DateTime? paymentDate;
  CaseFee({required this.id, required this.clientId, required this.amount, this.currency='ل.س', required this.agreementDate, this.paymentDate, this.status='unpaid', this.paymentMethod='cash', this.notes=''});
}

class CaseExpense {
  final String id, description, paidBy, category;
  final double amount;
  final String currency;
  final DateTime expenseDate;
  final List<String> receipts;
  CaseExpense({required this.id, required this.description, required this.amount, this.currency='ل.س', required this.expenseDate, this.paidBy='', this.category='other', this.receipts=const []});
}

class Case {
  final String id, caseNumber, title, court, subject, claim, notes;
  final CaseType type;
  final CaseStatus status;
  final String? baseNumber;
  final int? baseYear;
  final DateTime creationDate;
  final DateTime? lastUpdated;
  final List<String> clientIds, opponentIds, lawyerIds, poaIds, documentIds;
  final List<CasePhase> phases;
  final List<CaseSession> sessions;
  final List<CaseAction> actions;
  final List<CaseDeficiency> deficiencies;
  final List<CaseTimelineEvent> timeline;
  final List<CaseFee> fees;
  final List<CaseExpense> expenses;
  Case({required this.id, required this.caseNumber, required this.title, required this.type, this.status=CaseStatus.scheduled, required this.court, this.baseNumber, this.baseYear, this.subject='', this.claim='', required this.creationDate, this.lastUpdated, this.clientIds=const [], this.opponentIds=const [], this.lawyerIds=const [], this.poaIds=const [], this.phases=const [], this.sessions=const [], this.actions=const [], this.deficiencies=const [], this.timeline=const [], this.fees=const [], this.expenses=const [], this.documentIds=const [], this.notes=''});
  CaseSession? get nextSession => sessions.where((s) => s.sessionDate.isAfter(DateTime.now())).toList()..sort((a,b) => a.sessionDate.compareTo(b.sessionDate)).firstOrNull;
  int get openDeficienciesCount => deficiencies.where((d) => !d.isResolved).length;
  double get totalFees => fees.fold(0, (s, f) => s + f.amount);
  double get totalExpenses => expenses.fold(0, (s, e) => s + e.amount);
  double get balance => totalFees - totalExpenses;
}

extension NullableListExtension<T> on List<T> {
  T? firstOrNull => isEmpty ? null : first;
}
