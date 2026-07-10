import 'package:flutter_test/flutter_test.dart';
import 'package:lawyer_office/presentation/screens/finance/finance_models.dart';

void main() {
  test('FinanceNotifier calculates summary and accepts new movements', () {
    final notifier = FinanceNotifier();
    final initialSummary = notifier.state.summary;

    expect(initialSummary.agreementsTotal, greaterThan(0));
    expect(initialSummary.paymentsTotal, greaterThan(0));
    expect(initialSummary.expensesTotal, greaterThan(0));

    final agreement = FinanceAgreement(
      id: 'agreement_test',
      entityType: FinanceEntityType.caseFile,
      entityId: 'case_test',
      entityTitle: 'دعوى اختبار',
      partyId: 'person_test',
      partyName: 'موكل اختبار',
      agreementType: FeeAgreementType.fixed,
      totalAmount: 1000,
      agreementDate: DateTime(2026, 7, 10),
    );
    notifier.addAgreement(agreement);
    notifier.addPayment(
      FinancePayment(
        id: 'payment_test',
        agreementId: agreement.id,
        amount: 400,
        paymentDate: DateTime(2026, 7, 10),
      ),
    );
    notifier.addExpense(
      FinanceExpense(
        id: 'expense_test',
        entityType: FinanceEntityType.caseFile,
        entityId: 'case_test',
        entityTitle: 'دعوى اختبار',
        category: ExpenseCategory.courtFee,
        description: 'رسم اختبار',
        amount: 100,
        expenseDate: DateTime(2026, 7, 10),
      ),
    );

    expect(notifier.state.paidForAgreement(agreement.id), 400);
    expect(notifier.state.summary.agreementsTotal, initialSummary.agreementsTotal + 1000);
    expect(notifier.state.summary.paymentsTotal, initialSummary.paymentsTotal + 400);
    expect(notifier.state.summary.expensesTotal, initialSummary.expensesTotal + 100);
  });
}
