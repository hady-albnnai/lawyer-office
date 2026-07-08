import 'dart:io';
import 'package:drift/drift.dart';
import '../../core/enums/app_enums.dart';
import '../database/database.dart';
import '../database/daos/finance_dao.dart';
import '../services/file_storage_service.dart';

/// مستودع إدارة المالية الموحدة (أتعاب الموكلين، سندات القبض، ومصاريف القضية/المعاملة)
class FinanceRepository {
  final FinanceDao _financeDao;
  final FileStorageService _storageService;

  FinanceRepository(this._financeDao, this._storageService);

  Stream<List<FeeAgreement>> watchAgreementsByEntity(EntityType entityType, int entityId) {
    return _financeDao.watchAgreementsByEntity(entityType.index, entityId);
  }

  /// إنشاء اتفاقية أتعاب جديدة لموكل مع إمكانية إرفاق صورة العقد
  Future<int> createAgreement({
    required FeeAgreementsCompanion agreement,
    File? contractFile,
    required String userRef,
  }) async {
    return await _financeDao.db.transaction(() async {
      final agreementId = await _financeDao.insertAgreement(agreement);

      if (contractFile != null) {
        final filePath = await _storageService.saveAttachment(
          sourceFile: contractFile,
          folderType: 'fee_agreements',
          entityId: agreementId,
        );
        await (_financeDao.update(_financeDao.db.feeAgreements)..where((t) => t.id.equals(agreementId))).write(
          FeeAgreementsCompanion(contractPath: Value(filePath)),
        );
      }

      return agreementId;
    });
  }

  Stream<List<FeePayment>> watchPaymentsByAgreement(int agreementId) {
    return _financeDao.watchPaymentsByAgreement(agreementId);
  }

  /// تسجيل سند قبض ودفعة جديدة من الموكل وتحديث الخط الزمني
  Future<int> addPayment({
    required FeePaymentsCompanion payment,
    File? receiptFile,
    required String userRef,
    required int entityType,
    required int entityId,
  }) async {
    return await _financeDao.db.transaction(() async {
      final paymentId = await _financeDao.insertPayment(payment);

      if (receiptFile != null) {
        final filePath = await _storageService.saveAttachment(
          sourceFile: receiptFile,
          folderType: 'fee_payments',
          entityId: paymentId,
        );
        await (_financeDao.update(_financeDao.db.feePayments)..where((t) => t.id.equals(paymentId))).write(
          FeePaymentsCompanion(receiptPath: Value(filePath)),
        );
      }

      await _financeDao.into(_financeDao.db.timelineEvents).insert(
        TimelineEventsCompanion.insert(
          entityType: entityType.index,
          entityId: entityId,
          eventType: 'payment_received',
          eventDate: Value(DateTime.now()),
          description: 'تم قبض دفعة أتعاب بمقدار: ${payment.amount.value} ${payment.method.value ?? ""}',
          userRef: Value(userRef),
        ),
      );

      return paymentId;
    });
  }

  Stream<List<Expense>> watchExpensesByEntity(EntityType entityType, int entityId) {
    return _financeDao.watchExpensesByEntity(entityType.index, entityId);
  }

  /// إدراج رسم قضائي أو مصروف إداري للملف
  Future<int> addExpense({
    required ExpensesCompanion expense,
    File? receiptFile,
    required String userRef,
  }) async {
    return await _financeDao.db.transaction(() async {
      final expenseId = await _financeDao.insertExpense(expense);

      if (receiptFile != null) {
        final filePath = await _storageService.saveAttachment(
          sourceFile: receiptFile,
          folderType: 'expenses',
          entityId: expenseId,
        );
        await (_financeDao.update(_financeDao.db.expenses)..where((t) => t.id.equals(expenseId))).write(
          ExpensesCompanion(receiptPath: Value(filePath)),
        );
      }

      await _financeDao.into(_financeDao.db.timelineEvents).insert(
        TimelineEventsCompanion.insert(
          entityType: expense.entityType.value,
          entityId: expense.entityId.value,
          eventType: 'expense_added',
          eventDate: Value(DateTime.now()),
          description: 'تم صرف مبلغ [${expense.amount.value}] عن: ${expense.expenseType.value}',
          userRef: Value(userRef),
        ),
      );

      return expenseId;
    });
  }
}
