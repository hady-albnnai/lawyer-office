import 'package:drift/drift.dart';
import '../database.dart';
import '../schema.dart';

part 'finance_dao.g.dart';

/// كائن الوصول لبيانات المالية الموحدة (اتفاقيات الأتعاب، الدفعات، والمصاريف - FinanceDao)
@DriftAccessor(tables: [
  FeeAgreements,
  FeePayments,
  Expenses,
  Persons,
])
class FinanceDao extends DatabaseAccessor<AppDatabase> with _$FinanceDaoMixin {
  FinanceDao(super.db);

  // ---------------------------------------------------------------------------
  // إدارة اتفاقيات الأتعاب (FeeAgreements)
  // ---------------------------------------------------------------------------

  /// مراقبة اتفاقيات الأتعاب الخاصة بكيان محدد (مثلاً: كافة اتفاقيات موكلي دعوى معينة)
  Stream<List<FeeAgreement>> watchAgreementsByEntity(int entityType, int entityId) {
    return (select(feeAgreements)
          ..where((t) => t.entityType.equals(entityType) & t.entityId.equals(entityId)))
        .watch();
  }

  /// إدخال اتفاقية أتعاب جديدة لموكل في دعوى أو شركة أو عقد
  Future<int> insertAgreement(FeeAgreementsCompanion companion) {
    return into(feeAgreements).insert(companion);
  }

  /// تحديث بيانات اتفاقية أتعاب
  Future<bool> updateAgreement(FeeAgreementsCompanion companion) {
    return update(feeAgreements).replace(companion);
  }

  // ---------------------------------------------------------------------------
  // إدارة سندات القبض والدفعات (FeePayments)
  // ---------------------------------------------------------------------------

  /// مراقبة الدفعات المسددة بموجب اتفاقية أتعاب معينة
  Stream<List<FeePayment>> watchPaymentsByAgreement(int agreementId) {
    return (select(feePayments)
          ..where((t) => t.agreementId.equals(agreementId))
          ..orderBy([(t) => OrderingTerm(expression: t.paymentDate, mode: OrderingMode.desc)]))
        .watch();
  }

  /// تسجيل دفعة مالية مستلمة (سند قبض)
  Future<int> insertPayment(FeePaymentsCompanion companion) {
    return into(feePayments).insert(companion);
  }

  // ---------------------------------------------------------------------------
  // إدارة مصاريف ورسوم الملفات (Expenses)
  // ---------------------------------------------------------------------------

  /// مراقبة مصاريف ملف معين (دعوى، شركة، أو معاملة إدارية)
  Stream<List<Expens>> watchExpensesByEntity(int entityType, int entityId) {
    return (select(expenses)
          ..where((t) => t.entityType.equals(entityType) & t.entityId.equals(entityId))
          ..orderBy([(t) => OrderingTerm(expression: t.expenseDate, mode: OrderingMode.desc)]))
        .watch();
  }

  /// إدراج مصروف أو رسم قضائي/إداري جديد
  Future<int> insertExpense(ExpensesCompanion companion) {
    return into(expenses).insert(companion);
  }
}
