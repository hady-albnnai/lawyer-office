import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../database/database.dart';
import '../services/file_storage_service.dart';

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



class ArchiveItemRecord {
  final int id;
  final int batchId;
  final String originalFileName;
  final String? sourcePath;
  final String? storedPath;
  final String? fileType;
  final int fileSize;
  final String? sha256;
  final String status;
  final String reviewStatus;
  final String? errorMessage;
  final String? suggestedDocumentType;
  final int? suggestedEntityType;
  final int? suggestedEntityId;
  final String? confirmedDocumentType;
  final int? confirmedEntityType;
  final int? confirmedEntityId;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final DateTime createdAt;

  const ArchiveItemRecord({
    required this.id,
    required this.batchId,
    required this.originalFileName,
    this.sourcePath,
    this.storedPath,
    this.fileType,
    required this.fileSize,
    this.sha256,
    required this.status,
    required this.reviewStatus,
    this.errorMessage,
    this.suggestedDocumentType,
    this.suggestedEntityType,
    this.suggestedEntityId,
    this.confirmedDocumentType,
    this.confirmedEntityType,
    this.confirmedEntityId,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    required this.createdAt,
  });
}

class ArchiveImportSummary {
  final int imported;
  final int duplicates;
  final int failed;

  const ArchiveImportSummary({
    required this.imported,
    required this.duplicates,
    required this.failed,
  });
}

class ArchiveIntakeRepository {
  final AppDatabase _db;
  final FileStorageService _storage;

  ArchiveIntakeRepository(this._db, this._storage);

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

  Future<ArchiveImportSummary> importFilesToBatch(int batchId, List<File> files) async {
    await ensureReady();
    await updateBatchStatus(batchId, 'processing');
    var imported = 0;
    var duplicates = 0;
    var failed = 0;

    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        final hash = sha256.convert(bytes).toString();
        final duplicateRows = await _db.customSelect(
          'SELECT id FROM archive_items WHERE sha256 = ? LIMIT 1',
          variables: [Variable.withString(hash)],
        ).get();
        final isDuplicate = duplicateRows.isNotEmpty;
        final duplicateOfId = isDuplicate ? duplicateRows.first.data['id'] as int? : null;
        String? storedPath;
        if (isDuplicate) {
          duplicates++;
        } else {
          storedPath = await _storage.saveAttachment(
            sourceFile: file,
            folderType: 'archive_intake',
            entityId: batchId,
          );
          imported++;
        }

        await _db.customStatement('''
          INSERT INTO archive_items(
            batch_id, original_file_name, source_path, stored_path, file_type, file_size, sha256,
            status, review_status, suggested_document_type, error_message
          ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          batchId,
          file.path.split(Platform.pathSeparator).last,
          file.path,
          storedPath,
          _extension(file.path),
          bytes.length,
          hash,
          isDuplicate ? 'duplicate' : 'imported',
          'needs_review',
          _suggestDocumentType(file.path),
          isDuplicate ? 'ملف مكرر محتمل${duplicateOfId == null ? '' : ' للعنصر #$duplicateOfId'}' : null,
        ]);
      } catch (e) {
        failed++;
        await _db.customStatement('''
          INSERT INTO archive_items(batch_id, original_file_name, source_path, status, review_status, error_message)
          VALUES(?, ?, ?, 'failed', 'needs_review', ?)
        ''', [
          batchId,
          file.path.split(Platform.pathSeparator).last,
          file.path,
          '$e',
        ]);
      }
    }

    await _db.customStatement('''
      UPDATE archive_batches
      SET total_files = total_files + ?,
          processed_files = processed_files + ?,
          failed_files = failed_files + ?,
          duplicate_files = duplicate_files + ?,
          unclassified_files = unclassified_files + ?,
          status = ?
      WHERE id = ?
    ''', [
      files.length,
      imported + duplicates + failed,
      failed,
      duplicates,
      imported + duplicates,
      failed > 0 ? 'completed_with_errors' : 'waiting_review',
      batchId,
    ]);

    return ArchiveImportSummary(imported: imported, duplicates: duplicates, failed: failed);
  }




  Future<List<ArchiveItemRecord>> getItemsByStatus(String status) async {
    await ensureReady();
    final rows = await _db.customSelect(
      'SELECT * FROM archive_items WHERE status = ? ORDER BY created_at DESC',
      variables: [Variable.withString(status)],
    ).get();
    return rows.map(_mapItem).toList();
  }

  Future<List<ArchiveItemRecord>> getItemsByReviewStatus(String reviewStatus) async {
    await ensureReady();
    final rows = await _db.customSelect(
      'SELECT * FROM archive_items WHERE review_status = ? ORDER BY created_at DESC',
      variables: [Variable.withString(reviewStatus)],
    ).get();
    return rows.map(_mapItem).toList();
  }

  ArchiveItemRecord _mapItem(QueryRow row) {
    final d = row.data;
    DateTime parseDate(Object? value) => DateTime.tryParse('${value ?? ''}') ?? DateTime.now();
    return ArchiveItemRecord(
      id: d['id'] as int,
      batchId: d['batch_id'] as int,
      originalFileName: d['original_file_name'] as String,
      sourcePath: d['source_path'] as String?,
      storedPath: d['stored_path'] as String?,
      fileType: d['file_type'] as String?,
      fileSize: (d['file_size'] as int?) ?? 0,
      sha256: d['sha256'] as String?,
      status: d['status'] as String,
      reviewStatus: d['review_status'] as String,
      errorMessage: d['error_message'] as String?,
      suggestedDocumentType: d['suggested_document_type'] as String?,
      suggestedEntityType: d['suggested_entity_type'] as int?,
      suggestedEntityId: d['suggested_entity_id'] as int?,
      confirmedDocumentType: d['confirmed_document_type'] as String?,
      confirmedEntityType: d['confirmed_entity_type'] as int?,
      confirmedEntityId: d['confirmed_entity_id'] as int?,
      reviewedBy: d['reviewed_by'] as String?,
      reviewedAt: d['reviewed_at'] == null ? null : parseDate(d['reviewed_at']),
      reviewNote: d['review_note'] as String?,
      createdAt: parseDate(d['created_at']),
    );
  }

  Future<List<ArchiveItemRecord>> getItemsForBatch(int batchId) async {
    await ensureReady();
    final rows = await _db.customSelect(
      'SELECT * FROM archive_items WHERE batch_id = ? ORDER BY created_at DESC',
      variables: [Variable.withInt(batchId)],
    ).get();
    return rows.map(_mapItem).toList();
  }


  Future<ArchiveItemRecord?> getItemById(int itemId) async {
    await ensureReady();
    final rows = await _db.customSelect(
      'SELECT * FROM archive_items WHERE id = ? LIMIT 1',
      variables: [Variable.withInt(itemId)],
    ).get();
    if (rows.isEmpty) return null;
    return _mapItem(rows.first);
  }

  Future<int> promoteItemToDocument({
    required int itemId,
    required String documentType,
    required int entityType,
    required int entityId,
    required String userRef,
    String? archiveNotes,
    int? physicalLocation,
  }) async {
    await ensureReady();
    final item = await getItemById(itemId);
    if (item == null) throw StateError('عنصر الأرشيف غير موجود');
    if (item.storedPath == null || item.storedPath!.isEmpty) {
      throw StateError('لا يمكن اعتماد عنصر بلا ملف محفوظ، غالباً لأنه مكرر أو فشل استيراده');
    }
    return _db.transaction(() async {
      final docId = await _db.into(_db.documents).insert(
            DocumentsCompanion.insert(
              docName: item.originalFileName,
              docType: Value(documentType),
              filePath: Value(item.storedPath),
              fileType: Value(item.fileType),
              summary: Value('مستند مستورد من مركز إدخال الأرشيف'),
              notes: Value([
                'ArchiveItem #$itemId / SHA256: ${item.sha256 ?? '-'}',
                if ((archiveNotes ?? '').trim().isNotEmpty) archiveNotes!.trim(),
              ].join('\n')),
              physicalLocation: Value(physicalLocation ?? 0),
            ),
          );
      await _db.into(_db.documentLinks).insert(
            DocumentLinksCompanion.insert(
              documentId: docId,
              entityType: entityType,
              entityId: entityId,
              linkType: const Value('archive_import'),
            ),
          );
      await updateItemReview(
        itemId: itemId,
        status: 'imported',
        reviewStatus: 'approved',
        documentType: documentType,
        entityType: entityType,
        entityId: entityId,
        reviewedBy: userRef,
        reviewNote: 'ربط واعتماد كمستند رقم $docId',
      );
      await refreshBatchCounters(item.batchId);
      await _db.into(_db.timelineEvents).insert(
            TimelineEventsCompanion.insert(
              entityType: entityType,
              entityId: entityId,
              eventType: 'archive_document_linked',
              eventDate: Value(DateTime.now()),
              description: 'تم ربط مستند من الأرشيف القديم: ${item.originalFileName}',
              userRef: Value(userRef),
            ),
          );
      return docId;
    });
  }

  Future<void> updateItemReview({
    required int itemId,
    required String status,
    required String reviewStatus,
    String? documentType,
    int? entityType,
    int? entityId,
    String? errorMessage,
    String? reviewedBy,
    String? reviewNote,
  }) async {
    await ensureReady();
    await _db.customStatement('''
      UPDATE archive_items
      SET status = ?,
          review_status = ?,
          confirmed_document_type = COALESCE(?, confirmed_document_type),
          confirmed_entity_type = COALESCE(?, confirmed_entity_type),
          confirmed_entity_id = COALESCE(?, confirmed_entity_id),
          error_message = ?,
          reviewed_by = COALESCE(?, reviewed_by),
          reviewed_at = CASE WHEN ? IS NOT NULL THEN CURRENT_TIMESTAMP ELSE reviewed_at END,
          review_note = COALESCE(?, review_note),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    ''', [status, reviewStatus, documentType, entityType, entityId, errorMessage, reviewedBy, reviewedBy, reviewNote, itemId]);
  }

  Future<void> refreshBatchCounters(int batchId) async {
    await ensureReady();
    await _db.customStatement('''
      UPDATE archive_batches SET
        total_files = (SELECT COUNT(*) FROM archive_items WHERE batch_id = ?),
        failed_files = (SELECT COUNT(*) FROM archive_items WHERE batch_id = ? AND status = 'failed'),
        duplicate_files = (SELECT COUNT(*) FROM archive_items WHERE batch_id = ? AND status = 'duplicate'),
        unclassified_files = (SELECT COUNT(*) FROM archive_items WHERE batch_id = ? AND review_status = 'needs_review'),
        approved_files = (SELECT COUNT(*) FROM archive_items WHERE batch_id = ? AND review_status = 'approved'),
        processed_files = (SELECT COUNT(*) FROM archive_items WHERE batch_id = ?),
        status = CASE
          WHEN (SELECT COUNT(*) FROM archive_items WHERE batch_id = ? AND review_status = 'needs_review') > 0 THEN 'waiting_review'
          WHEN (SELECT COUNT(*) FROM archive_items WHERE batch_id = ? AND status = 'failed') > 0 THEN 'completed_with_errors'
          ELSE 'completed'
        END,
        completed_at = CASE
          WHEN (SELECT COUNT(*) FROM archive_items WHERE batch_id = ? AND review_status = 'needs_review') = 0 THEN CURRENT_TIMESTAMP
          ELSE completed_at
        END
      WHERE id = ?
    ''', [batchId, batchId, batchId, batchId, batchId, batchId, batchId, batchId, batchId, batchId]);
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

  String _extension(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    return dot == -1 ? 'file' : name.substring(dot + 1).toLowerCase();
  }

  String _suggestDocumentType(String filePath) {
    final raw = filePath.toLowerCase();
    if (raw.contains('وكال') || raw.contains('poa') || raw.contains('power')) {
      return 'power_of_attorney';
    }
    if (raw.contains('جلس') || raw.contains('ضبط') || raw.contains('محضر') || raw.contains('session')) {
      return 'court_record';
    }
    if (raw.contains('حكم') || raw.contains('قرار') || raw.contains('decision') || raw.contains('judgment')) {
      return 'decision';
    }
    if (raw.contains('قبض') || raw.contains('ايصال') || raw.contains('إيصال') || raw.contains('receipt')) {
      return 'receipt';
    }
    if (raw.contains('عقد') || raw.contains('contract')) {
      return 'contract';
    }
    if (raw.contains('مذكرة') || raw.contains('لائحة') || raw.contains('memo')) {
      return 'memo';
    }
    return 'archive_document';
  }
}
