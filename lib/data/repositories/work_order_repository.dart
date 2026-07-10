import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/daos/work_order_dao.dart';

class WorkOrderRepository {
  final WorkOrderDao _dao;
  WorkOrderRepository(this._dao);

  Stream<List<WorkOrder>> watchAll() => _dao.watchAll();
  Future<List<WorkOrder>> getAll() => _dao.getAll();

  Future<int> create({
    required String internalNumber,
    required String assignedToName,
    String? assignedToPhone,
    required String orderType,
    required String priority,
    required String status,
    required DateTime dueDate,
    String? instructions,
    String? createdBy,
    int linkedEntityType = 0,
    int linkedEntityId = 0,
  }) {
    return _dao.insertOrder(
      WorkOrdersCompanion.insert(
        internalNumber: internalNumber,
        assignedToName: assignedToName,
        assignedToPhone: Value(assignedToPhone),
        orderType: orderType,
        priority: Value(priority),
        status: Value(status),
        dueDate: dueDate,
        instructions: Value(instructions),
        createdBy: Value(createdBy),
        linkedEntityType: Value(linkedEntityType),
        linkedEntityId: Value(linkedEntityId),
      ),
    );
  }

  Future<void> seedDemoIfEmpty() async {
    final existing = await _dao.getAll();
    if (existing.isNotEmpty) return;
    final now = DateTime.now();
    final samples = [
      ('WO-2026-001', 'أحمد محمد', '0912345678', 'court_attendance', 'high', 'draft', now, 'حضور جلسة الدعوى 2026/001'),
      ('WO-2026-002', 'محمد أحمد', '0987654321', 'document_photocopy', 'medium', 'printed', now.add(const Duration(days: 1)), 'تصوير ضبط المحكمة'),
      ('WO-2026-003', 'أحمد محمد', '0912345678', 'fee_payment', 'high', 'waiting_for_result', now.subtract(const Duration(days: 1)), 'دفع رسم الدعوى'),
      ('WO-2026-004', 'محمد أحمد', '0987654321', 'notary_review', 'low', 'result_entered', now.add(const Duration(days: 2)), 'مراجعة كاتب عدل'),
      ('WO-2026-005', 'أحمد محمد', '0912345678', 'execution_followup', 'medium', 'waiting_for_approval', now.add(const Duration(days: 3)), 'متابعة تنفيذ'),
    ];
    for (final s in samples) {
      await create(
        internalNumber: s.$1,
        assignedToName: s.$2,
        assignedToPhone: s.$3,
        orderType: s.$4,
        priority: s.$5,
        status: s.$6,
        dueDate: s.$7,
        instructions: s.$8,
        createdBy: 'هادي البني',
        linkedEntityType: 0,
        linkedEntityId: 1,
      );
    }
  }
}
