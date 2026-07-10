/// نماذج وحالة واجهة المرحلة 7: المالية الموحدة.
///
/// تم فصل نماذج الواجهة عن جداول Drift حتى تبقى الشاشة قابلة للاختبار
/// والتطوير المرحلي، مع قابلية الربط لاحقاً بمستودع FinanceRepository.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';

/// نوع الكيان المالي المرتبط بالحركة.
enum FinanceEntityType {
  caseFile,
  contract,
  company,
  adminProcedure,
  person;

  String get displayName => const [
        'دعوى',
        'عقد',
        'شركة',
        'إجراء إداري',
        'شخص / جهة',
      ][index];

  IconData get icon => const [
        Icons.gavel,
        Icons.description,
        Icons.business,
        Icons.assignment,
        Icons.person,
      ][index];
}

/// نوع اتفاق الأتعاب.
enum FeeAgreementType {
  fixed,
  percentage,
  perSession,
  free;

  String get displayName => const [
        'مقطوع',
        'نسبة',
        'حسب الجلسة',
        'مجاني',
      ][index];
}

/// طريقة الدفع.
enum FinancePaymentMethod {
  cash,
  bankTransfer,
  cheque,
  other;

  String get displayName => const [
        'نقداً',
        'تحويل بنكي',
        'شيك',
        'أخرى',
      ][index];
}

/// فئة المصروف.
enum ExpenseCategory {
  courtFee,
  stamps,
  expert,
  transport,
  photocopy,
  office,
  other;

  String get displayName => const [
        'رسم محكمة',
        'طوابع',
        'خبرة',
        'مواصلات',
        'تصوير',
        'مصاريف مكتبية',
        'أخرى',
      ][index];
}

/// اتفاق أتعاب مع موكل أو جهة.
class FinanceAgreement {
  final String id;
  final FinanceEntityType entityType;
  final String entityId;
  final String entityTitle;
  final String partyId;
  final String partyName;
  final FeeAgreementType agreementType;
  final double totalAmount;
  final String currency;
  final DateTime agreementDate;
  final String contractDocumentId;
  final String notes;

  const FinanceAgreement({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    required this.partyId,
    required this.partyName,
    required this.agreementType,
    required this.totalAmount,
    this.currency = 'ل.س',
    required this.agreementDate,
    this.contractDocumentId = '',
    this.notes = '',
  });

  bool get hasContractDocument => contractDocumentId.isNotEmpty;

  FinanceAgreement copyWith({
    String? partyName,
    FeeAgreementType? agreementType,
    double? totalAmount,
    String? currency,
    DateTime? agreementDate,
    String? contractDocumentId,
    String? notes,
  }) {
    return FinanceAgreement(
      id: id,
      entityType: entityType,
      entityId: entityId,
      entityTitle: entityTitle,
      partyId: partyId,
      partyName: partyName ?? this.partyName,
      agreementType: agreementType ?? this.agreementType,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      agreementDate: agreementDate ?? this.agreementDate,
      contractDocumentId: contractDocumentId ?? this.contractDocumentId,
      notes: notes ?? this.notes,
    );
  }
}

/// سند قبض أو دفعة أتعاب.
class FinancePayment {
  final String id;
  final String agreementId;
  final double amount;
  final String currency;
  final DateTime paymentDate;
  final FinancePaymentMethod method;
  final String receiptDocumentId;
  final String notes;

  const FinancePayment({
    required this.id,
    required this.agreementId,
    required this.amount,
    this.currency = 'ل.س',
    required this.paymentDate,
    this.method = FinancePaymentMethod.cash,
    this.receiptDocumentId = '',
    this.notes = '',
  });

  bool get hasReceipt => receiptDocumentId.isNotEmpty;
}

/// مصروف قضائي أو مكتبي.
class FinanceExpense {
  final String id;
  final FinanceEntityType entityType;
  final String entityId;
  final String entityTitle;
  final ExpenseCategory category;
  final String description;
  final double amount;
  final String currency;
  final DateTime expenseDate;
  final String paidBy;
  final String receiptDocumentId;
  final String notes;

  const FinanceExpense({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    required this.category,
    required this.description,
    required this.amount,
    this.currency = 'ل.س',
    required this.expenseDate,
    this.paidBy = 'مكتب المحامي',
    this.receiptDocumentId = '',
    this.notes = '',
  });

  bool get hasReceipt => receiptDocumentId.isNotEmpty;
}

/// تقرير مالي مختصر لكيان أو لكل المكتب.
class FinanceReportSummary {
  final double agreementsTotal;
  final double paymentsTotal;
  final double expensesTotal;

  const FinanceReportSummary({
    required this.agreementsTotal,
    required this.paymentsTotal,
    required this.expensesTotal,
  });

  double get remainingFees => agreementsTotal - paymentsTotal;

  double get netBalance => paymentsTotal - expensesTotal;
}

/// حالة شاشة المالية.
class FinanceState {
  final List<FinanceAgreement> agreements;
  final List<FinancePayment> payments;
  final List<FinanceExpense> expenses;
  final String searchQuery;
  final FinanceEntityType? entityFilter;

  const FinanceState({
    required this.agreements,
    required this.payments,
    required this.expenses,
    this.searchQuery = '',
    this.entityFilter,
  });

  List<FinanceAgreement> get filteredAgreements {
    final query = searchQuery.trim().toLowerCase();
    return agreements.where((agreement) {
      final filterOk = entityFilter == null || agreement.entityType == entityFilter;
      final queryOk = query.isEmpty ||
          agreement.entityTitle.toLowerCase().contains(query) ||
          agreement.partyName.toLowerCase().contains(query) ||
          agreement.entityId.toLowerCase().contains(query);
      return filterOk && queryOk;
    }).toList();
  }

  List<FinanceExpense> get filteredExpenses {
    final query = searchQuery.trim().toLowerCase();
    return expenses.where((expense) {
      final filterOk = entityFilter == null || expense.entityType == entityFilter;
      final queryOk = query.isEmpty ||
          expense.entityTitle.toLowerCase().contains(query) ||
          expense.description.toLowerCase().contains(query) ||
          expense.paidBy.toLowerCase().contains(query);
      return filterOk && queryOk;
    }).toList();
  }

  List<FinancePayment> paymentsForAgreement(String agreementId) {
    return payments.where((payment) => payment.agreementId == agreementId).toList();
  }

  double paidForAgreement(String agreementId) {
    return paymentsForAgreement(agreementId).fold(0, (sum, payment) => sum + payment.amount);
  }

  FinanceReportSummary get summary {
    return FinanceReportSummary(
      agreementsTotal: filteredAgreements.fold(0, (sum, agreement) => sum + agreement.totalAmount),
      paymentsTotal: filteredAgreements.fold(0, (sum, agreement) => sum + paidForAgreement(agreement.id)),
      expensesTotal: filteredExpenses.fold(0, (sum, expense) => sum + expense.amount),
    );
  }

  FinanceState copyWith({
    List<FinanceAgreement>? agreements,
    List<FinancePayment>? payments,
    List<FinanceExpense>? expenses,
    String? searchQuery,
    FinanceEntityType? entityFilter,
    bool clearEntityFilter = false,
  }) {
    return FinanceState(
      agreements: agreements ?? this.agreements,
      payments: payments ?? this.payments,
      expenses: expenses ?? this.expenses,
      searchQuery: searchQuery ?? this.searchQuery,
      entityFilter: clearEntityFilter ? null : entityFilter ?? this.entityFilter,
    );
  }
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  return FinanceNotifier();
});

class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier() : super(_seedState());

  static FinanceState _seedState() {
    final today = DateTime(2026, 7, 10);
    final agreements = [
      FinanceAgreement(
        id: 'agreement_1',
        entityType: FinanceEntityType.caseFile,
        entityId: '1',
        entityTitle: 'دعوى تعويض 2026/001',
        partyId: 'person_1',
        partyName: 'أحمد محمد الخطيب',
        agreementType: FeeAgreementType.fixed,
        totalAmount: 5000000,
        agreementDate: today.subtract(const Duration(days: 9)),
        contractDocumentId: 'doc_fee_1',
        notes: 'أتعاب مقطوعة على دفعتين.',
      ),
      FinanceAgreement(
        id: 'agreement_2',
        entityType: FinanceEntityType.caseFile,
        entityId: '3',
        entityTitle: 'دعوى تجارية 2026/003',
        partyId: 'person_3',
        partyName: 'شركة التطوير الحديث',
        agreementType: FeeAgreementType.fixed,
        totalAmount: 2500000,
        agreementDate: today.subtract(const Duration(days: 25)),
      ),
      FinanceAgreement(
        id: 'agreement_3',
        entityType: FinanceEntityType.contract,
        entityId: 'contract_1',
        entityTitle: 'عقد بيع عقار',
        partyId: 'person_1',
        partyName: 'أحمد محمد الخطيب',
        agreementType: FeeAgreementType.fixed,
        totalAmount: 800000,
        agreementDate: today.subtract(const Duration(days: 4)),
      ),
    ];

    final payments = [
      FinancePayment(
        id: 'payment_1',
        agreementId: 'agreement_1',
        amount: 1500000,
        paymentDate: today.subtract(const Duration(days: 8)),
        receiptDocumentId: 'receipt_1',
      ),
      FinancePayment(
        id: 'payment_2',
        agreementId: 'agreement_2',
        amount: 2500000,
        paymentDate: today.subtract(const Duration(days: 3)),
        method: FinancePaymentMethod.bankTransfer,
        receiptDocumentId: 'receipt_2',
      ),
      FinancePayment(
        id: 'payment_3',
        agreementId: 'agreement_3',
        amount: 300000,
        paymentDate: today.subtract(const Duration(days: 2)),
      ),
    ];

    final expenses = [
      FinanceExpense(
        id: 'expense_1',
        entityType: FinanceEntityType.caseFile,
        entityId: '1',
        entityTitle: 'دعوى تعويض 2026/001',
        category: ExpenseCategory.courtFee,
        description: 'رسم دعوى',
        amount: 100000,
        expenseDate: today.subtract(const Duration(days: 7)),
        receiptDocumentId: 'expense_doc_1',
      ),
      FinanceExpense(
        id: 'expense_2',
        entityType: FinanceEntityType.caseFile,
        entityId: '3',
        entityTitle: 'دعوى تجارية 2026/003',
        category: ExpenseCategory.transport,
        description: 'مصاريف معقب',
        amount: 25000,
        expenseDate: today.subtract(const Duration(days: 6)),
        paidBy: 'المعقب',
      ),
      FinanceExpense(
        id: 'expense_3',
        entityType: FinanceEntityType.contract,
        entityId: 'contract_1',
        entityTitle: 'عقد بيع عقار',
        category: ExpenseCategory.stamps,
        description: 'طوابع عقد',
        amount: 45000,
        expenseDate: today.subtract(const Duration(days: 2)),
      ),
    ];

    return FinanceState(agreements: agreements, payments: payments, expenses: expenses);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setEntityFilter(FinanceEntityType? entityType) {
    state = entityType == null ? state.copyWith(clearEntityFilter: true) : state.copyWith(entityFilter: entityType);
  }

  void addAgreement(FinanceAgreement agreement) {
    state = state.copyWith(agreements: [agreement, ...state.agreements]);
  }

  void addPayment(FinancePayment payment) {
    state = state.copyWith(payments: [payment, ...state.payments]);
  }

  void addExpense(FinanceExpense expense) {
    state = state.copyWith(expenses: [expense, ...state.expenses]);
  }
}
