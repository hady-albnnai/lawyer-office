import 'package:drift/drift.dart';

/// 1. دورة الحياة الموحدة لكل عنصر تشغيلي في التطبيق (القاعدة الذهبية V6.2)
enum LifecycleStatus {
  scheduled,   // 0: مجدولة
  inProgress,  // 1: قيد التنفيذ
  completed,   // 2: تمت / أُنجزت
  postponed,   // 3: مؤجلة
  cancelled;   // 4: ملغاة

  String get label {
    switch (this) {
      case LifecycleStatus.scheduled:
        return 'مجدولة';
      case LifecycleStatus.inProgress:
        return 'قيد التنفيذ';
      case LifecycleStatus.completed:
        return 'تمت';
      case LifecycleStatus.postponed:
        return 'مؤجلة';
      case LifecycleStatus.cancelled:
        return 'ملغاة';
    }
  }
}

/// 2. أنواع الأشخاص في النظام القضائي السوري
enum PersonType {
  natural, // 0: شخص طبيعي
  legal;   // 1: شخص اعتباري (شركة / مؤسسة / جمعية / جهة عامة)

  String get label {
    switch (this) {
      case PersonType.natural:
        return 'شخص طبيعي';
      case PersonType.legal:
        return 'شخص اعتباري (جهة / شركة)';
    }
  }
}

/// 3. أدوار الأشخاص والجهات في ملفات المكتب
enum PersonRoleType {
  client,        // 0: موكل
  opponent,      // 1: خصم
  partner,       // 2: شريك في شركة
  director,      // 3: مدير أو مفوض بالتوقيع
  teamMember,    // 4: عضو في فريق المكتب
  contractParty; // 5: طرف في عقد

  String get label {
    switch (this) {
      case PersonRoleType.client:
        return 'موكل';
      case PersonRoleType.opponent:
        return 'خصم';
      case PersonRoleType.partner:
        return 'شريك';
      case PersonRoleType.director:
        return 'مدير / مفوض';
      case PersonRoleType.teamMember:
        return 'فريق المكتب';
      case PersonRoleType.contractParty:
        return 'طرف عقدي';
    }
  }
}

/// 4. الصفة الوظيفية لأعضاء فريق مكتب المحاماة
enum TeamPosition {
  seniorLawyer, // 0: محامي أستاذ
  trainee,      // 1: محامي متمرن
  procurer,     // 2: معقب معاملات
  officeStaff;  // 3: موظفة مكتب (بدون صلاحيات مالية)

  String get label {
    switch (this) {
      case TeamPosition.seniorLawyer:
        return 'محامي أستاذ';
      case TeamPosition.trainee:
        return 'محامي متمرن';
      case TeamPosition.procurer:
        return 'معقب معاملات';
      case TeamPosition.officeStaff:
        return 'موظفة مكتب';
    }
  }
}

/// 5. أنواع الوكالات القضائية والقانونية
enum PoaType {
  general,       // 0: عامة
  special,       // 1: خاصة
  specialSharia; // 2: خاصة شرعية

  String get label {
    switch (this) {
      case PoaType.general:
        return 'وكالة عامة';
      case PoaType.special:
        return 'وكالة خاصة';
      case PoaType.specialSharia:
        return 'وكالة خاصة شرعية';
    }
  }
}

/// 6. أنواع الكيانات في قاعدة البيانات الموحدة (للماليات، المستندات، النواقص، والخط الزمني)
enum EntityType {
  caseEntity,     // 0: دعوى قضائية
  contract,       // 1: عقد
  company,        // 2: شركة
  adminProcedure, // 3: إجراء إداري
  person,         // 4: شخص (موكل / خصم / فريق)
  powerOfAttorney;// 5: وكالة

  String get label {
    switch (this) {
      case EntityType.caseEntity:
        return 'دعوى';
      case EntityType.contract:
        return 'عقد';
      case EntityType.company:
        return 'شركة';
      case EntityType.adminProcedure:
        return 'إجراء إداري';
      case EntityType.person:
        return 'سجل شخص';
      case EntityType.powerOfAttorney:
        return 'وكالة';
    }
  }
}

/// 7. درجة أولوية المهام اليومية وجداول الأعمال
enum TaskPriority {
  low,    // 0: منخفضة
  normal, // 1: عادية
  high,   // 2: هامة
  urgent; // 3: عاجلة وقصوى

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'منخفضة';
      case TaskPriority.normal:
        return 'عادية';
      case TaskPriority.high:
        return 'هامة';
      case TaskPriority.urgent:
        return 'عاجلة جداً';
    }
  }
}

/// 8. خطورة وأهمية النقص القضائي أو الإداري في الملف
enum DeficiencySeverity {
  required, // 0: إلزامي (مثل موعد الجلسة القادمة أو سند التوكيل)
  warning;  // 1: تنبيه (مثل رقم الأساس بانتظار التسجيل)

  String get label {
    switch (this) {
      case DeficiencySeverity.required:
        return 'نقص إلزامي';
      case DeficiencySeverity.warning:
        return 'تنبيه استكمال';
    }
  }
}

/// 9. حالة المستند أو المبرز القانوني
enum DocumentStatus {
  original,  // 0: أصل
  copy,      // 1: صورة ضوئية
  certified, // 2: صورة مصدقة أصولاً
  draft,     // 3: مسودة
  finalDoc;  // 4: نهائي / مبرم

  String get label {
    switch (this) {
      case DocumentStatus.original:
        return 'أصل';
      case DocumentStatus.copy:
        return 'صورة ضوئية';
      case DocumentStatus.certified:
        return 'صورة مصدقة';
      case DocumentStatus.draft:
        return 'مسودة';
      case DocumentStatus.finalDoc:
        return 'نهائي';
    }
  }
}

/// 10. الموقع الفيزيائي لأصل المستند أو الوكالة
enum PhysicalLocation {
  office,      // 0: في خزنة المكتب
  client,      // 1: طرف الموكل
  court,       // 2: مبرز في إضبارة المحكمة
  digitalOnly; // 3: نسخة رقمية فقط

  String get label {
    switch (this) {
      case PhysicalLocation.office:
        return 'في خزنة المكتب';
      case PhysicalLocation.client:
        return 'مع الموكل';
      case PhysicalLocation.court:
        return 'في إضبارة المحكمة';
      case PhysicalLocation.digitalOnly:
        return 'نسخة رقمية فقط';
    }
  }
}


/// 11. أنواع ملفات المكتب الموحدة في النسخة الجديدة.
enum OfficeFileType {
  caseFile('case', 'دعوى'),
  procedure('procedure', 'إجراء'),
  contract('contract', 'عقد'),
  company('company', 'شركة'),
  agency('agency', 'وكالة');

  final String dbValue;
  final String label;
  const OfficeFileType(this.dbValue, this.label);

  static OfficeFileType fromDb(String value) {
    return OfficeFileType.values.firstWhere(
      (item) => item.dbValue == value,
      orElse: () => OfficeFileType.caseFile,
    );
  }
}

/// 12. مصدر ملف المكتب: عمل جديد أو أرشيف قديم أو إدخال إداري تصحيحي.
enum OfficeFileSource {
  newWork('new_work', 'عمل جديد'),
  oldArchive('old_archive', 'أرشيف قديم'),
  manualAdmin('manual_admin', 'إداري/تصحيحي');

  final String dbValue;
  final String label;
  const OfficeFileSource(this.dbValue, this.label);

  static OfficeFileSource fromDb(String value) {
    return OfficeFileSource.values.firstWhere(
      (item) => item.dbValue == value,
      orElse: () => OfficeFileSource.newWork,
    );
  }
}

/// 13. حالة ملف المكتب الموحدة.
enum OfficeFileStatus {
  active('active', 'جاري'),
  closed('closed', 'منتهي');

  final String dbValue;
  final String label;
  const OfficeFileStatus(this.dbValue, this.label);

  static OfficeFileStatus fromDb(String value) {
    return OfficeFileStatus.values.firstWhere(
      (item) => item.dbValue == value,
      orElse: () => OfficeFileStatus.active,
    );
  }
}

// =============================================================================
// محولات بيانات Drift (Type Converters) لتخزين التعدادات بسلاسة وأمان في SQLite
// =============================================================================

class LifecycleStatusConverter extends EnumIndexConverter<LifecycleStatus> {
  const LifecycleStatusConverter() : super(LifecycleStatus.values);
}

class PersonTypeConverter extends EnumIndexConverter<PersonType> {
  const PersonTypeConverter() : super(PersonType.values);
}

class PersonRoleTypeConverter extends EnumIndexConverter<PersonRoleType> {
  const PersonRoleTypeConverter() : super(PersonRoleType.values);
}

class TeamPositionConverter extends EnumIndexConverter<TeamPosition> {
  const TeamPositionConverter() : super(TeamPosition.values);
}

class PoaTypeConverter extends EnumIndexConverter<PoaType> {
  const PoaTypeConverter() : super(PoaType.values);
}

class EntityTypeConverter extends EnumIndexConverter<EntityType> {
  const EntityTypeConverter() : super(EntityType.values);
}

class TaskPriorityConverter extends EnumIndexConverter<TaskPriority> {
  const TaskPriorityConverter() : super(TaskPriority.values);
}

class DeficiencySeverityConverter extends EnumIndexConverter<DeficiencySeverity> {
  const DeficiencySeverityConverter() : super(DeficiencySeverity.values);
}

class DocumentStatusConverter extends EnumIndexConverter<DocumentStatus> {
  const DocumentStatusConverter() : super(DocumentStatus.values);
}

class PhysicalLocationConverter extends EnumIndexConverter<PhysicalLocation> {
  const PhysicalLocationConverter() : super(PhysicalLocation.values);
}
