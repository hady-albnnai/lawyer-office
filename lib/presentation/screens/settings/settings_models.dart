/// نماذج وحالة المرحلة 10: الإعدادات والأمان والنسخ الاحتياطي.
///
/// طبقة واجهة seed قابلة للاختبار فوق SharedPreferences/CryptoUtils،
/// مع سجل نشاط ونسخ احتياطي ومهلة قفل وقوائم مرجعية.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/crypto_utils.dart';
import '../../theme/app_colors.dart';

/// عنصر سجل نشاط.
class ActivityLogEntry {
  final String id;
  final String action;
  final String tableName;
  final String details;
  final String userRef;
  final DateTime timestamp;

  const ActivityLogEntry({
    required this.id,
    required this.action,
    required this.tableName,
    required this.details,
    required this.userRef,
    required this.timestamp,
  });
}

/// سجل نسخة احتياطية.
class BackupRecord {
  final String id;
  final String path;
  final String type;
  final double sizeMb;
  final bool includesAttachments;
  final DateTime createdAt;
  final String status;

  const BackupRecord({
    required this.id,
    required this.path,
    required this.type,
    required this.sizeMb,
    required this.includesAttachments,
    required this.createdAt,
    this.status = 'success',
  });
}

/// محكمة مرجعية (قائمة سورية).
class SettingsCourtItem {
  final String id;
  final String name;
  final String type;
  final String city;
  final bool isActive;

  const SettingsCourtItem({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    this.isActive = true,
  });
}

/// إعدادات الأمان المحلية.
class SecuritySettings {
  final String passwordHash;
  final String securityQuestion;
  final String answerHash;
  final int lockTimeoutMinutes;
  final bool isConfigured;

  const SecuritySettings({
    required this.passwordHash,
    required this.securityQuestion,
    required this.answerHash,
    this.lockTimeoutMinutes = 10,
    this.isConfigured = false,
  });

  SecuritySettings copyWith({
    String? passwordHash,
    String? securityQuestion,
    String? answerHash,
    int? lockTimeoutMinutes,
    bool? isConfigured,
  }) {
    return SecuritySettings(
      passwordHash: passwordHash ?? this.passwordHash,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      answerHash: answerHash ?? this.answerHash,
      lockTimeoutMinutes: lockTimeoutMinutes ?? this.lockTimeoutMinutes,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
}

/// تفضيلات المكتب الإضافية.
class OfficePreferences {
  final String officeTitle;
  final String lawyerName;
  final String officeAddress;
  final String officePhone;
  final String officeEmail;
  final String logoPath;
  final String signaturePath;
  final String uiFont;
  final String printFont;
  final String backupFolderPath;
  final String externalBackupPath;
  final int workOrderDefaultPriority; // 0 low 1 med 2 high
  final bool libraryAutoFavoritePrinciples;
  final DateTime? lastBackupAt;

  const OfficePreferences({
    required this.officeTitle,
    required this.lawyerName,
    required this.officeAddress,
    required this.officePhone,
    this.officeEmail = '',
    this.logoPath = '',
    this.signaturePath = '',
    this.uiFont = 'Cairo',
    this.printFont = 'Amiri',
    this.backupFolderPath = '',
    this.externalBackupPath = '',
    this.workOrderDefaultPriority = 1,
    this.libraryAutoFavoritePrinciples = true,
    this.lastBackupAt,
  });

  OfficePreferences copyWith({
    String? officeTitle,
    String? lawyerName,
    String? officeAddress,
    String? officePhone,
    String? officeEmail,
    String? logoPath,
    String? signaturePath,
    String? uiFont,
    String? printFont,
    String? backupFolderPath,
    String? externalBackupPath,
    int? workOrderDefaultPriority,
    bool? libraryAutoFavoritePrinciples,
    DateTime? lastBackupAt,
    bool clearLastBackup = false,
  }) {
    return OfficePreferences(
      officeTitle: officeTitle ?? this.officeTitle,
      lawyerName: lawyerName ?? this.lawyerName,
      officeAddress: officeAddress ?? this.officeAddress,
      officePhone: officePhone ?? this.officePhone,
      officeEmail: officeEmail ?? this.officeEmail,
      logoPath: logoPath ?? this.logoPath,
      signaturePath: signaturePath ?? this.signaturePath,
      uiFont: uiFont ?? this.uiFont,
      printFont: printFont ?? this.printFont,
      backupFolderPath: backupFolderPath ?? this.backupFolderPath,
      externalBackupPath: externalBackupPath ?? this.externalBackupPath,
      workOrderDefaultPriority: workOrderDefaultPriority ?? this.workOrderDefaultPriority,
      libraryAutoFavoritePrinciples:
          libraryAutoFavoritePrinciples ?? this.libraryAutoFavoritePrinciples,
      lastBackupAt: clearLastBackup ? null : lastBackupAt ?? this.lastBackupAt,
    );
  }
}

/// حالة شاشة الإعدادات.
class SettingsHubState {
  final OfficePreferences preferences;
  final SecuritySettings security;
  final List<ActivityLogEntry> activityLog;
  final List<BackupRecord> backups;
  final List<SettingsCourtItem> courts;
  final String activityFilter;
  final bool isBusy;
  final String? lastMessage;

  const SettingsHubState({
    required this.preferences,
    required this.security,
    required this.activityLog,
    required this.backups,
    required this.courts,
    this.activityFilter = '',
    this.isBusy = false,
    this.lastMessage,
  });

  List<ActivityLogEntry> get filteredActivity {
    final q = activityFilter.trim().toLowerCase();
    if (q.isEmpty) return activityLog;
    return activityLog
        .where(
          (e) =>
              e.action.toLowerCase().contains(q) ||
              e.details.toLowerCase().contains(q) ||
              e.tableName.toLowerCase().contains(q) ||
              e.userRef.toLowerCase().contains(q),
        )
        .toList();
  }

  bool get needsWeeklyBackup {
    final last = preferences.lastBackupAt;
    if (last == null) return true;
    return DateTime.now().difference(last).inDays >= 7;
  }

  SettingsHubState copyWith({
    OfficePreferences? preferences,
    SecuritySettings? security,
    List<ActivityLogEntry>? activityLog,
    List<BackupRecord>? backups,
    List<SettingsCourtItem>? courts,
    String? activityFilter,
    bool? isBusy,
    String? lastMessage,
    bool clearMessage = false,
  }) {
    return SettingsHubState(
      preferences: preferences ?? this.preferences,
      security: security ?? this.security,
      activityLog: activityLog ?? this.activityLog,
      backups: backups ?? this.backups,
      courts: courts ?? this.courts,
      activityFilter: activityFilter ?? this.activityFilter,
      isBusy: isBusy ?? this.isBusy,
      lastMessage: clearMessage ? null : lastMessage ?? this.lastMessage,
    );
  }
}

final settingsHubProvider =
    StateNotifierProvider<SettingsHubNotifier, SettingsHubState>((ref) {
  return SettingsHubNotifier();
});

class SettingsHubNotifier extends StateNotifier<SettingsHubState> {
  SettingsHubNotifier() : super(_seedState()) {
    _hydrateFromPrefs();
  }

  static const _kEmail = 'office_email';
  static const _kLogo = 'office_logo_path';
  static const _kSignature = 'office_signature_path';
  static const _kUiFont = 'ui_font';
  static const _kPrintFont = 'print_font';
  static const _kBackupFolder = 'backup_folder_path';
  static const _kExternalBackup = 'external_backup_path';
  static const _kWoPriority = 'wo_default_priority';
  static const _kLibFav = 'library_auto_favorite_principles';
  static const _kLastBackup = 'last_backup_at';
  static const _kPwdHash = 'security_password_hash';
  static const _kQuestion = 'security_question';
  static const _kAnswerHash = 'security_answer_hash';
  static const _kLockTimeout = 'lock_timeout_minutes';

  static SettingsHubState _seedState() {
    final now = DateTime(2026, 7, 10);
    return SettingsHubState(
      preferences: OfficePreferences(
        officeTitle: AppConstants.defaultOfficeTitle,
        lawyerName: AppConstants.defaultLawyerName,
        officeAddress: AppConstants.defaultAddress,
        officePhone: AppConstants.defaultPhone,
        officeEmail: 'office@example.sy',
        uiFont: 'Cairo',
        printFont: 'Amiri',
        workOrderDefaultPriority: 1,
        libraryAutoFavoritePrinciples: true,
        lastBackupAt: now.subtract(const Duration(days: 3)),
      ),
      security: SecuritySettings(
        passwordHash: CryptoUtils.hashPassword('Office@2026'),
        securityQuestion: 'ما اسم مدرستك الابتدائية؟',
        answerHash: CryptoUtils.hashPassword('المجد'),
        lockTimeoutMinutes: 10,
        isConfigured: true,
      ),
      activityLog: [
        ActivityLogEntry(
          id: 'act_1',
          action: 'login',
          tableName: 'security',
          details: 'تسجيل دخول ناجح للمحامي الأستاذ',
          userRef: AppConstants.defaultLawyerName,
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
        ActivityLogEntry(
          id: 'act_2',
          action: 'update',
          tableName: 'app_settings',
          details: 'تحديث بيانات الترويسة',
          userRef: AppConstants.defaultLawyerName,
          timestamp: now.subtract(const Duration(hours: 5)),
        ),
        ActivityLogEntry(
          id: 'act_3',
          action: 'export',
          tableName: 'backups',
          details: 'إنشاء نسخة احتياطية يدوية',
          userRef: AppConstants.defaultLawyerName,
          timestamp: now.subtract(const Duration(days: 3)),
        ),
      ],
      backups: [
        BackupRecord(
          id: 'bk_1',
          path: 'LawOffice_Backups/SyrLawOffice_Backup_2026-07-07.zip',
          type: 'manual',
          sizeMb: 12.4,
          includesAttachments: true,
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        BackupRecord(
          id: 'bk_2',
          path: 'LawOffice_Backups/SyrLawOffice_Backup_2026-06-30.zip',
          type: 'auto',
          sizeMb: 11.8,
          includesAttachments: true,
          createdAt: now.subtract(const Duration(days: 10)),
        ),
      ],
      courts: const [
        SettingsCourtItem(
          id: 'c1',
          name: 'محكمة البداية المدنية الأولى بدمشق',
          type: 'بداية',
          city: 'دمشق',
        ),
        SettingsCourtItem(
          id: 'c2',
          name: 'محكمة الاستئناف المدنية بدمشق',
          type: 'استئناف',
          city: 'دمشق',
        ),
        SettingsCourtItem(
          id: 'c3',
          name: 'محكمة النقض السورية - الغرفة المدنية',
          type: 'نقض',
          city: 'دمشق',
        ),
        SettingsCourtItem(
          id: 'c4',
          name: 'محكمة البداية المدنية بالسويداء',
          type: 'بداية',
          city: 'السويداء',
        ),
        SettingsCourtItem(
          id: 'c5',
          name: 'المحكمة الشرعية بالسويداء',
          type: 'شرعية',
          city: 'السويداء',
        ),
      ],
    );
  }

  Future<void> _hydrateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final p = state.preferences;
      final s = state.security;
      final lastBackupRaw = prefs.getString(_kLastBackup);
      state = state.copyWith(
        preferences: p.copyWith(
          officeTitle: prefs.getString(AppConstants.keyOfficeTitle) ?? p.officeTitle,
          lawyerName: prefs.getString(AppConstants.keyLawyerName) ?? p.lawyerName,
          officeAddress: prefs.getString(AppConstants.keyOfficeAddress) ?? p.officeAddress,
          officePhone: prefs.getString(AppConstants.keyOfficePhone) ?? p.officePhone,
          officeEmail: prefs.getString(_kEmail) ?? p.officeEmail,
          logoPath: prefs.getString(_kLogo) ?? p.logoPath,
          signaturePath: prefs.getString(_kSignature) ?? p.signaturePath,
          uiFont: prefs.getString(_kUiFont) ?? p.uiFont,
          printFont: prefs.getString(_kPrintFont) ?? p.printFont,
          backupFolderPath: prefs.getString(_kBackupFolder) ?? p.backupFolderPath,
          externalBackupPath: prefs.getString(_kExternalBackup) ?? p.externalBackupPath,
          workOrderDefaultPriority: prefs.getInt(_kWoPriority) ?? p.workOrderDefaultPriority,
          libraryAutoFavoritePrinciples: prefs.getBool(_kLibFav) ?? p.libraryAutoFavoritePrinciples,
          lastBackupAt: lastBackupRaw != null ? DateTime.tryParse(lastBackupRaw) : p.lastBackupAt,
        ),
        security: s.copyWith(
          passwordHash: prefs.getString(_kPwdHash) ?? s.passwordHash,
          securityQuestion: prefs.getString(_kQuestion) ?? s.securityQuestion,
          answerHash: prefs.getString(_kAnswerHash) ?? s.answerHash,
          lockTimeoutMinutes: prefs.getInt(_kLockTimeout) ?? s.lockTimeoutMinutes,
          isConfigured: (prefs.getString(_kPwdHash) ?? s.passwordHash).isNotEmpty,
        ),
      );
    } catch (_) {
      // تبقى القيم الافتراضية عند فشل prefs (اختبارات/بيئة بلا منصة).
    }
  }

  void setActivityFilter(String query) {
    state = state.copyWith(activityFilter: query);
  }

  void _log(String action, String table, String details) {
    final entry = ActivityLogEntry(
      id: 'act_${DateTime.now().microsecondsSinceEpoch}',
      action: action,
      tableName: table,
      details: details,
      userRef: state.preferences.lawyerName,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(activityLog: [entry, ...state.activityLog]);
  }

  Future<void> saveOfficePreferences(OfficePreferences next) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyOfficeTitle, next.officeTitle);
      await prefs.setString(AppConstants.keyLawyerName, next.lawyerName);
      await prefs.setString(AppConstants.keyOfficeAddress, next.officeAddress);
      await prefs.setString(AppConstants.keyOfficePhone, next.officePhone);
      await prefs.setString(_kEmail, next.officeEmail);
      await prefs.setString(_kLogo, next.logoPath);
      await prefs.setString(_kSignature, next.signaturePath);
      await prefs.setString(_kUiFont, next.uiFont);
      await prefs.setString(_kPrintFont, next.printFont);
      await prefs.setString(_kBackupFolder, next.backupFolderPath);
      await prefs.setString(_kExternalBackup, next.externalBackupPath);
      await prefs.setInt(_kWoPriority, next.workOrderDefaultPriority);
      await prefs.setBool(_kLibFav, next.libraryAutoFavoritePrinciples);
      if (next.lastBackupAt != null) {
        await prefs.setString(_kLastBackup, next.lastBackupAt!.toIso8601String());
      }
    } catch (_) {}

    state = state.copyWith(
      preferences: next,
      lastMessage: 'تم حفظ إعدادات المكتب',
    );
    _log('update', 'app_settings', 'تحديث بيانات المكتب والترويسة والتفضيلات');
  }

  /// تحديث كلمة المرور وسؤال الأمان بعد التحقق من الحالية.
  String? updateSecurity({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    required String securityQuestion,
    required String securityAnswer,
    int? lockTimeoutMinutes,
  }) {
    if (!CryptoUtils.verifyPassword(currentPassword, state.security.passwordHash)) {
      return 'كلمة المرور الحالية غير صحيحة';
    }
    if (newPassword.length < 6) {
      return 'كلمة المرور الجديدة يجب ألا تقل عن 6 أحرف';
    }
    if (newPassword != confirmPassword) {
      return 'تأكيد كلمة المرور غير مطابق';
    }
    if (securityQuestion.trim().isEmpty || securityAnswer.trim().isEmpty) {
      return 'سؤال الأمان وإجابته إلزاميان';
    }

    final next = state.security.copyWith(
      passwordHash: CryptoUtils.hashPassword(newPassword),
      securityQuestion: securityQuestion.trim(),
      answerHash: CryptoUtils.hashPassword(securityAnswer.trim()),
      lockTimeoutMinutes: lockTimeoutMinutes ?? state.security.lockTimeoutMinutes,
      isConfigured: true,
    );

    // حفظ prefs بأفضل جهد — لا يفشل المسار المنطقي إن تعذّر SharedPreferences.
    // ignore: unawaited_futures
    _safePrefsWrite((prefs) async {
      await prefs.setString(_kPwdHash, next.passwordHash);
      await prefs.setString(_kQuestion, next.securityQuestion);
      await prefs.setString(_kAnswerHash, next.answerHash);
      await prefs.setInt(_kLockTimeout, next.lockTimeoutMinutes);
    });

    state = state.copyWith(security: next, lastMessage: 'تم تحديث بيانات الأمان');
    _log('update', 'security', 'تغيير كلمة المرور/سؤال الأمان/مهلة القفل');
    return null;
  }

  Future<void> _safePrefsWrite(Future<void> Function(SharedPreferences prefs) writer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await writer(prefs);
    } catch (_) {
      // بيئة اختبار أو منصة بلا prefs.
    }
  }

  bool verifySecurityAnswer(String answer) {
    return CryptoUtils.verifyPassword(answer.trim(), state.security.answerHash);
  }

  /// محاكاة إنشاء نسخة احتياطية ناجحة (offline seed + سجل).
  Future<BackupRecord> createBackup({
    bool includeAttachments = true,
    String type = 'manual',
    String? customPath,
  }) async {
    state = state.copyWith(isBusy: true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final now = DateTime.now();
    final stamp = now.toIso8601String().replaceAll(':', '-').substring(0, 19);
    final folder = customPath?.isNotEmpty == true
        ? customPath!
        : (state.preferences.externalBackupPath.isNotEmpty
            ? state.preferences.externalBackupPath
            : 'LawOffice_Backups');
    final record = BackupRecord(
      id: 'bk_${now.microsecondsSinceEpoch}',
      path: '$folder/SyrLawOffice_Backup_$stamp.zip',
      type: type,
      sizeMb: includeAttachments ? 12.6 : 3.2,
      includesAttachments: includeAttachments,
      createdAt: now,
    );
    final prefs = state.preferences.copyWith(lastBackupAt: now);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kLastBackup, now.toIso8601String());
    } catch (_) {}

    state = state.copyWith(
      isBusy: false,
      backups: [record, ...state.backups],
      preferences: prefs,
      lastMessage: 'تم إنشاء نسخة احتياطية: ${record.path}',
    );
    _log('export', 'backups', 'نسخ احتياطي ($type) — ${record.path}');
    return record;
  }

  /// محاكاة استعادة نسخة.
  Future<bool> restoreBackup(String backupId) async {
    final exists = state.backups.any((b) => b.id == backupId);
    if (!exists) return false;
    _log('import', 'backups', 'استعادة النسخة $backupId');
    state = state.copyWith(lastMessage: 'تمت استعادة النسخة بنجاح');
    return true;
  }

  void setExternalBackupPath(String path) {
    final next = state.preferences.copyWith(externalBackupPath: path);
    state = state.copyWith(preferences: next, lastMessage: 'تم تعيين مسار النسخ الخارجي');
    // ignore: unawaited_futures
    _safePrefsWrite((p) => p.setString(_kExternalBackup, path));
    _log('update', 'backups', 'تعيين مسار خارجي: $path');
  }

  void addCourt(SettingsCourtItem court) {
    state = state.copyWith(courts: [court, ...state.courts], lastMessage: 'تمت إضافة محكمة');
    _log('insert', 'courts', 'إضافة محكمة: ${court.name}');
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}

Color priorityColor(int priority) {
  switch (priority) {
    case 2:
      return AppColors.error;
    case 0:
      return AppColors.success;
    default:
      return AppColors.warning;
  }
}

String priorityLabel(int priority) {
  switch (priority) {
    case 2:
      return 'عالية';
    case 0:
      return 'منخفضة';
    default:
      return 'متوسطة';
  }
}
