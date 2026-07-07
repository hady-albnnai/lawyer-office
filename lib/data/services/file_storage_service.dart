import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';

/// محرك إدارة التخزين المحلي والمرفقات وقوالب Word (FileStorageService)
/// يحفظ المرفقات تحت بنية مجلدات منظمة ويعيد مسارات نسبية لتخزينها في SQLite.
class FileStorageService {
  /// الحصول على المجلد الجذري للتطبيق (مثال: AppData/LawOffice/files/)
  Future<Directory> getRootStorageDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final appDir = Directory(p.join(docsDir.path, AppConstants.appDataDirectoryName, AppConstants.filesDirectoryName));
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  /// حفظ ملف مرفق في المجلد المخصص للكيان (دعوى، عقد، شركة...) وإرجاع مساره النسبي
  Future<String> saveAttachment({
    required File sourceFile,
    required String folderType,
    required int entityId,
  }) async {
    final rootDir = await getRootStorageDir();
    final targetDir = Directory(p.join(rootDir.path, folderType, entityId.toString()));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // تسمية الملف مع طابع زمني لمنع تشابه الأسماء
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String cleanName = p.basename(sourceFile.path).replaceAll(' ', '_');
    final String fileName = '${timestamp}_$cleanName';
    final String fullDestPath = p.join(targetDir.path, fileName);

    await sourceFile.copy(fullDestPath);

    // إرجاع المسار النسبي فقط لتخزينه بقاعدة البيانات (مثال: cases/15/1719999_doc.pdf)
    return p.join(folderType, entityId.toString(), fileName);
  }

  /// تحويل المسار النسبي المحفوظ في قاعدة البيانات إلى مسار كامل على القرص الفعلي
  Future<File?> getFileFromRelativePath(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return null;
    final rootDir = await getRootStorageDir();
    final fullPath = p.join(rootDir.path, relativePath);
    final file = File(fullPath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// جلب المسار الكامل لنص نسبي
  Future<String> getAbsolutePath(String relativePath) async {
    final rootDir = await getRootStorageDir();
    return p.join(rootDir.path, relativePath);
  }

  /// حذف مرفق فيزيائياً من القرص الصلب
  Future<bool> deleteAttachment(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return false;
    try {
      final rootDir = await getRootStorageDir();
      final file = File(p.join(rootDir.path, relativePath));
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  /// حفظ قالب Word مخصص للنماذج والعقود
  Future<String> saveTemplate(File docxFile, String templateName) async {
    final rootDir = await getRootStorageDir();
    final targetDir = Directory(p.join(rootDir.path, AppConstants.templatesFolder));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$templateName.docx';
    final String fullPath = p.join(targetDir.path, fileName);
    await docxFile.copy(fullPath);

    return p.join(AppConstants.templatesFolder, fileName);
  }
}
