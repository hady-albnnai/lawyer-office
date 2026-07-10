/// شاشة المالية الموحدة - المرحلة 7.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../documents/document_viewer.dart';
import 'finance_models.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);

    return Theme(
      data: AppTheme.lightTheme,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('المالية الموحدة'),
            actions: [
              IconButton(
                tooltip: 'إضافة اتفاق أتعاب',
                icon: const Icon(Icons.note_add),
                onPressed: () => showDialog<void>(context: context, builder: (context) => const AddAgreementDialog()),
              ),
              IconButton(
                tooltip: 'إضافة دفعة',
                icon: const Icon(Icons.payments),
                onPressed: () => showDialog<void>(context: context, builder: (context) => const AddPaymentDialog()),
              ),
              IconButton(
                tooltip: 'إضافة مصروف',
                icon: const Icon(Icons.receipt_long),
                onPressed: () => showDialog<void>(context: context, builder: (context) => const AddExpenseDialog()),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.secondaryGold,
              labelColor: AppColors.secondaryGold,
              unselectedLabelColor: AppColors.textOnLight.withOpacity(0.75),
              labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'لوحة مالية'),
                Tab(text: 'اتفاقيات الأتعاب'),
                Tab(text: 'سندات القبض'),
                Tab(text: 'المصاريف'),
                Tab(text: 'الأرصدة'),
                Tab(text: 'التقارير'),
              ],
            ),
          ),
          body: Column(
            children: [
              _filtersBar(state),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _dashboardTab(state),
                    _agreementsTab(state),
                    _paymentsTab(state),
                    _expensesTab(state),
                    _balancesTab(state),
                    _reportsTab(state),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filtersBar(FinanceState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'بحث باسم الموكل، الملف، رقم الكيان...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => ref.read(financeProvider.notifier).setSearchQuery(value),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<FinanceEntityType?>(
            value: state.entityFilter,
            items: [
              const DropdownMenuItem<FinanceEntityType?>(value: null, child: Text('كل الملفات')),
              ...FinanceEntityType.values.map(
                (type) => DropdownMenuItem<FinanceEntityType?>(value: type, child: Text(type.displayName)),
              ),
            ],
            onChanged: (value) => ref.read(financeProvider.notifier).setEntityFilter(value),
          ),
        ],
      ),
    );
  }

  Widget _dashboardTab(FinanceState state) {
    final summary = state.summary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metricCard('إجمالي الأتعاب', _formatCurrency(summary.agreementsTotal), Icons.assignment_turned_in, AppColors.primaryNavy),
              _metricCard('المقبوض', _formatCurrency(summary.paymentsTotal), Icons.payments, AppColors.success),
              _metricCard('المتبقي', _formatCurrency(summary.remainingFees), Icons.pending_actions, AppColors.warning),
              _metricCard('المصاريف', _formatCurrency(summary.expensesTotal), Icons.receipt, AppColors.error),
              _metricCard('الصافي', _formatCurrency(summary.netBalance), Icons.account_balance_wallet, summary.netBalance >= 0 ? AppColors.success : AppColors.error),
            ],
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'تنبيهات مالية',
            icon: Icons.notifications_active,
            children: [
              _alertLine(Icons.warning_amber, 'اتفاقيات غير مسددة بالكامل: ${_unpaidAgreements(state).length}', AppColors.warning),
              _alertLine(Icons.receipt_long, 'مصاريف دون إيصال: ${state.filteredExpenses.where((expense) => !expense.hasReceipt).length}', AppColors.error),
              _alertLine(Icons.description, 'اتفاقيات دون عقد أتعاب مرفق: ${state.filteredAgreements.where((agreement) => !agreement.hasContractDocument).length}', AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _agreementsTab(FinanceState state) {
    final agreements = [...state.filteredAgreements]..sort((a, b) => b.agreementDate.compareTo(a.agreementDate));
    if (agreements.isEmpty) {
      return _emptyState(Icons.assignment, 'لا توجد اتفاقيات أتعاب', 'أضف اتفاق أتعاب جديد من الشريط العلوي.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agreements.length,
      itemBuilder: (context, index) => _agreementCard(state, agreements[index]),
    );
  }

  Widget _paymentsTab(FinanceState state) {
    final payments = [...state.payments]..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    if (payments.isEmpty) {
      return _emptyState(Icons.payments, 'لا توجد سندات قبض', 'سجل دفعة جديدة من الشريط العلوي.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) => _paymentCard(state, payments[index]),
    );
  }

  Widget _expensesTab(FinanceState state) {
    final expenses = [...state.filteredExpenses]..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    if (expenses.isEmpty) {
      return _emptyState(Icons.receipt_long, 'لا توجد مصاريف', 'أضف مصروفاً جديداً من الشريط العلوي.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      itemBuilder: (context, index) => _expenseCard(expenses[index]),
    );
  }

  Widget _balancesTab(FinanceState state) {
    final agreements = state.filteredAgreements;
    if (agreements.isEmpty) {
      return _emptyState(Icons.account_balance_wallet, 'لا توجد أرصدة', 'لا توجد اتفاقيات ضمن الفلتر الحالي.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agreements.length,
      itemBuilder: (context, index) {
        final agreement = agreements[index];
        final paid = state.paidForAgreement(agreement.id);
        final remaining = agreement.totalAmount - paid;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: remaining <= 0 ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
              child: Icon(remaining <= 0 ? Icons.verified : Icons.pending_actions, color: remaining <= 0 ? AppColors.success : AppColors.warning),
            ),
            title: Text(agreement.entityTitle, style: AppTextStyles.labelLarge),
            subtitle: Text('${agreement.partyName} • المقبوض: ${_formatCurrency(paid)}', style: AppTextStyles.bodySmallSecondary),
            trailing: Text(_formatCurrency(remaining), style: AppTextStyles.numberText.copyWith(color: remaining <= 0 ? AppColors.success : AppColors.warning)),
          ),
        );
      },
    );
  }

  Widget _reportsTab(FinanceState state) {
    final summary = state.summary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _sectionCard(
        title: 'تقرير مالي مختصر',
        icon: Icons.summarize,
        children: [
          _reportRow('إجمالي اتفاقيات الأتعاب', _formatCurrency(summary.agreementsTotal)),
          _reportRow('إجمالي المقبوضات', _formatCurrency(summary.paymentsTotal)),
          _reportRow('إجمالي المتبقي على الموكلين', _formatCurrency(summary.remainingFees)),
          _reportRow('إجمالي المصروفات', _formatCurrency(summary.expensesTotal)),
          _reportRow('صافي صندوق الملفات', _formatCurrency(summary.netBalance)),
          const SizedBox(height: 16),
          Text('هذا التقرير قابل للتوسيع لاحقاً إلى PDF/Excel ضمن مرحلة التقارير والطباعة.', style: AppTextStyles.bodySmallSecondary),
        ],
      ),
    );
  }

  Widget _agreementCard(FinanceState state, FinanceAgreement agreement) {
    final paid = state.paidForAgreement(agreement.id);
    final remaining = agreement.totalAmount - paid;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(agreement.entityType.icon, color: AppColors.primaryNavy),
                const SizedBox(width: 8),
                Expanded(child: Text(agreement.entityTitle, style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy))),
                _badge(agreement.agreementType.displayName, AppColors.info),
              ],
            ),
            const SizedBox(height: 8),
            _detailLine(Icons.person, 'الموكل: ${agreement.partyName}'),
            _detailLine(Icons.calendar_today, 'تاريخ الاتفاق: ${_formatDate(agreement.agreementDate)}'),
            _detailLine(Icons.assignment, 'الإجمالي: ${_formatCurrency(agreement.totalAmount)} • المقبوض: ${_formatCurrency(paid)} • المتبقي: ${_formatCurrency(remaining)}'),
            if (agreement.notes.isNotEmpty) _detailLine(Icons.note, agreement.notes),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.description),
                  label: const Text('عقد الأتعاب'),
                  onPressed: agreement.hasContractDocument ? () => openDocument(context, agreement.contractDocumentId) : null,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة دفعة'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AddPaymentDialog(defaultAgreementId: agreement.id),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentCard(FinanceState state, FinancePayment payment) {
    final agreement = state.agreements.where((item) => item.id == payment.agreementId).firstOrNull;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: AppColors.success.withOpacity(0.12), child: Icon(Icons.payments, color: AppColors.success)),
        title: Text(_formatCurrency(payment.amount), style: AppTextStyles.labelLarge.copyWith(color: AppColors.success)),
        subtitle: Text('${agreement?.partyName ?? 'غير محدد'} • ${payment.method.displayName} • ${_formatDate(payment.paymentDate)}', style: AppTextStyles.bodySmallSecondary),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: payment.hasReceipt ? () => openDocument(context, payment.receiptDocumentId) : null,
          tooltip: 'فتح سند القبض',
        ),
      ),
    );
  }

  Widget _expenseCard(FinanceExpense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: AppColors.error.withOpacity(0.12), child: Icon(Icons.receipt_long, color: AppColors.error)),
        title: Text(expense.description, style: AppTextStyles.labelLarge),
        subtitle: Text('${expense.entityTitle} • ${expense.category.displayName} • ${_formatDate(expense.expenseDate)}', style: AppTextStyles.bodySmallSecondary),
        trailing: Text(_formatCurrency(expense.amount), style: AppTextStyles.numberText.copyWith(color: AppColors.error)),
        onTap: expense.hasReceipt ? () => openDocument(context, expense.receiptDocumentId) : null,
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(title, style: AppTextStyles.bodySmallSecondary),
              const SizedBox(height: 4),
              Text(value, style: AppTextStyles.headline5.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryNavy),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.headline5.copyWith(color: AppColors.primaryNavy)),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _alertLine(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _detailLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: AppTextStyles.bodySmallSecondary)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(value, style: AppTextStyles.numberText.copyWith(color: AppColors.primaryNavy)),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.headline5),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.bodySmallSecondary, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  List<FinanceAgreement> _unpaidAgreements(FinanceState state) {
    return state.filteredAgreements.where((agreement) => state.paidForAgreement(agreement.id) < agreement.totalAmount).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} ل.س';
  }
}

class AddAgreementDialog extends ConsumerStatefulWidget {
  const AddAgreementDialog({super.key});

  @override
  ConsumerState<AddAgreementDialog> createState() => _AddAgreementDialogState();
}

class _AddAgreementDialogState extends ConsumerState<AddAgreementDialog> {
  final TextEditingController _entityTitleController = TextEditingController();
  final TextEditingController _partyController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  FinanceEntityType _entityType = FinanceEntityType.caseFile;
  FeeAgreementType _agreementType = FeeAgreementType.fixed;

  @override
  void dispose() {
    _entityTitleController.dispose();
    _partyController.dispose();
    _amountController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FinanceDialogFrame(
      title: 'إضافة اتفاق أتعاب',
      children: [
        TextField(controller: _entityTitleController, decoration: const InputDecoration(labelText: 'عنوان الملف / الكيان')),
        const SizedBox(height: 12),
        TextField(controller: _partyController, decoration: const InputDecoration(labelText: 'اسم الموكل')),
        const SizedBox(height: 12),
        TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'المبلغ الإجمالي'), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        DropdownButtonFormField<FinanceEntityType>(
          value: _entityType,
          decoration: const InputDecoration(labelText: 'نوع الكيان'),
          items: FinanceEntityType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(),
          onChanged: (value) => setState(() => _entityType = value ?? _entityType),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<FeeAgreementType>(
          value: _agreementType,
          decoration: const InputDecoration(labelText: 'نوع الاتفاق'),
          items: FeeAgreementType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(),
          onChanged: (value) => setState(() => _agreementType = value ?? _agreementType),
        ),
        const SizedBox(height: 12),
        TextField(controller: _documentController, decoration: const InputDecoration(labelText: 'معرف عقد الأتعاب المرفق')),
      ],
      onSave: _save,
    );
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (_entityTitleController.text.trim().isEmpty || _partyController.text.trim().isEmpty || amount <= 0) {
      _error('عنوان الملف واسم الموكل والمبلغ إلزامية');
      return;
    }
    final now = DateTime.now();
    ref.read(financeProvider.notifier).addAgreement(
          FinanceAgreement(
            id: 'agreement_${now.microsecondsSinceEpoch}',
            entityType: _entityType,
            entityId: 'manual_${now.microsecondsSinceEpoch}',
            entityTitle: _entityTitleController.text.trim(),
            partyId: 'manual_party',
            partyName: _partyController.text.trim(),
            agreementType: _agreementType,
            totalAmount: amount,
            agreementDate: now,
            contractDocumentId: _documentController.text.trim(),
          ),
        );
    Navigator.of(context).pop();
  }

  void _error(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: AppColors.error));
  }
}

class AddPaymentDialog extends ConsumerStatefulWidget {
  final String? defaultAgreementId;

  const AddPaymentDialog({super.key, this.defaultAgreementId});

  @override
  ConsumerState<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<AddPaymentDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _receiptController = TextEditingController();
  FinancePaymentMethod _method = FinancePaymentMethod.cash;
  String? _agreementId;

  @override
  void initState() {
    super.initState();
    _agreementId = widget.defaultAgreementId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agreements = ref.watch(financeProvider).agreements;
    _agreementId ??= agreements.isNotEmpty ? agreements.first.id : null;
    return _FinanceDialogFrame(
      title: 'إضافة سند قبض',
      children: [
        DropdownButtonFormField<String>(
          value: _agreementId,
          decoration: const InputDecoration(labelText: 'اتفاق الأتعاب'),
          items: agreements.map((agreement) => DropdownMenuItem(value: agreement.id, child: Text('${agreement.partyName} - ${agreement.entityTitle}'))).toList(),
          onChanged: (value) => setState(() => _agreementId = value),
        ),
        const SizedBox(height: 12),
        TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'المبلغ المقبوض'), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        DropdownButtonFormField<FinancePaymentMethod>(
          value: _method,
          decoration: const InputDecoration(labelText: 'طريقة الدفع'),
          items: FinancePaymentMethod.values.map((method) => DropdownMenuItem(value: method, child: Text(method.displayName))).toList(),
          onChanged: (value) => setState(() => _method = value ?? _method),
        ),
        const SizedBox(height: 12),
        TextField(controller: _receiptController, decoration: const InputDecoration(labelText: 'معرف سند القبض')),
      ],
      onSave: _save,
    );
  }

  void _save() {
    final agreementId = _agreementId;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (agreementId == null || amount <= 0) {
      _error('الاتفاق والمبلغ إلزاميان');
      return;
    }
    final now = DateTime.now();
    ref.read(financeProvider.notifier).addPayment(
          FinancePayment(
            id: 'payment_${now.microsecondsSinceEpoch}',
            agreementId: agreementId,
            amount: amount,
            paymentDate: now,
            method: _method,
            receiptDocumentId: _receiptController.text.trim(),
          ),
        );
    Navigator.of(context).pop();
  }

  void _error(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: AppColors.error));
  }
}

class AddExpenseDialog extends ConsumerStatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final TextEditingController _entityTitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _receiptController = TextEditingController();
  FinanceEntityType _entityType = FinanceEntityType.caseFile;
  ExpenseCategory _category = ExpenseCategory.courtFee;

  @override
  void dispose() {
    _entityTitleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FinanceDialogFrame(
      title: 'إضافة مصروف',
      children: [
        TextField(controller: _entityTitleController, decoration: const InputDecoration(labelText: 'عنوان الملف / الكيان')),
        const SizedBox(height: 12),
        TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'وصف المصروف')),
        const SizedBox(height: 12),
        TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'المبلغ'), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        DropdownButtonFormField<FinanceEntityType>(
          value: _entityType,
          decoration: const InputDecoration(labelText: 'نوع الكيان'),
          items: FinanceEntityType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(),
          onChanged: (value) => setState(() => _entityType = value ?? _entityType),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ExpenseCategory>(
          value: _category,
          decoration: const InputDecoration(labelText: 'فئة المصروف'),
          items: ExpenseCategory.values.map((category) => DropdownMenuItem(value: category, child: Text(category.displayName))).toList(),
          onChanged: (value) => setState(() => _category = value ?? _category),
        ),
        const SizedBox(height: 12),
        TextField(controller: _receiptController, decoration: const InputDecoration(labelText: 'معرف الإيصال')),
      ],
      onSave: _save,
    );
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (_entityTitleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty || amount <= 0) {
      _error('عنوان الملف والوصف والمبلغ إلزامية');
      return;
    }
    final now = DateTime.now();
    ref.read(financeProvider.notifier).addExpense(
          FinanceExpense(
            id: 'expense_${now.microsecondsSinceEpoch}',
            entityType: _entityType,
            entityId: 'manual_${now.microsecondsSinceEpoch}',
            entityTitle: _entityTitleController.text.trim(),
            category: _category,
            description: _descriptionController.text.trim(),
            amount: amount,
            expenseDate: now,
            receiptDocumentId: _receiptController.text.trim(),
          ),
        );
    Navigator.of(context).pop();
  }

  void _error(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: AppColors.error));
  }
}

class _FinanceDialogFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;

  const _FinanceDialogFrame({
    required this.title,
    required this.children,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 560,
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        ElevatedButton(onPressed: onSave, child: const Text('حفظ')),
      ],
    );
  }
}

extension _FirstOrNullFinance<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
