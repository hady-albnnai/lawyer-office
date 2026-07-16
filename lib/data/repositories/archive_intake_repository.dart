import 'package:drift/drift.dart';

import '../database/database.dart';

class ArchiveBatchRecord {
  final int id;
  final String name;
  final String sourceType;
  final String status;
  final String? sourcePath;
  final String? createdBy;
  final DateTime createdAt;
  final int totalFiles;
  final int processedFiles;
  final int failedFiles;
  final int duplicateFiles;
  final int unclassifiedFiles;
  final int approvedFiles;
  final String? notes;

  const ArchiveBatchRecord({
    required this.id,
    required this.name,
    required this.sourceType,
    required this.status,
    this.sourcePath,
    this.createdBy,
    required this.createdAt,
    required this.totalFiles,
    required this.processedFiles,
    required this.failedFiles,
    required this.duplicateFiles,
    required this.unclassifiedFiles,
    required this.approvedFiles,
    this.notes,
  });
}

class ArchiveIntakeRepository {
  final AppDatabase _db;
  ArchiveIntakeRepository(this._db);

  Future<void> ensureReady() => _db.ensureArchiveTables();

  Future<int> createBatch({
    required String name,
    required String sourceType,
    String? sourcePath,
    String? createdBy,
    String? notes,
  }) async {
    await ensureReady();
    await _db.customStatement('''
      INSERT INTO archive_batches(name, source_type, source_path, created_by_name_snapshot, notes)
      VALUES(?, ?, ?, ?, ?)
    ''', [name, sourceType, sourcePath, createdBy, notes]);
    final row = (await _db.customSelect('SELECT last_insert_rowid() AS id').get()).first;
    return row.data['id'] as int;
  }

  Future<void> updateBatchStatus(int id, String status) async {
    await ensureReady();
    await _db.customStatement(
      "UPDATE archive_batches SET status = ?, started_at = CASE WHEN ? = 'processing' THEN CURRENT_TIMESTAMP ELSE started_at END, completed_at = CASE WHEN ? LIKE 'completed%' THEN CURRENT_TIMESTAMP ELSE completed_at END WHERE id = ?",
      [status, status, status, id],
    );
  }

  Future<List<ArchiveBatchRecord>> getBatches() async {
    await ensureReady();
    final rows = await _db.customSelect('SELECT * FROM archive_batches ORDER BY created_at DESC').get();
    return rows.map((row) {
      final d = row.data;
      DateTime parseDate(Object? value) => DateTime.tryParse('${value ?? ''}') ?? DateTime.now();
      return ArchiveBatchRecord(
        id: d['id'] as int,
        name: d['name'] as String,
        sourceType: d['source_type'] as String,
        status: d['status'] as String,
        sourcePath: d['source_path'] as String?,
        createdBy: d['created_by_name_snapshot'] as String?,
        createdAt: parseDate(d['created_at']),
        totalFiles: d['total_files'] as int,
        processedFiles: d['processed_files'] as int,
        failedFiles: d['failed_files'] as int,
        duplicateFiles: d['duplicate_files'] as int,
        unclassifiedFiles: d['unclassified_files'] as int,
        approvedFiles: d['approved_files'] as int,
        notes: d['notes'] as String?,
      );
    }).toList();
  }

  Stream<List<ArchiveBatchRecord>> watchBatches() {
    return Stream.fromFuture(getBatches());
  }
}
