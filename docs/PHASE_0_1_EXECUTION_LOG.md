# سجل تنفيذ تصحيحي — المرحلة 0 + بداية المرحلة 1

التاريخ: 2026-07-21

## الهدف

تصحيح المسار بعد أن ظهرت تعديلات Sprint خارج خارطة إعادة الهيكلة، ثم بدء تنفيذ قلب الخطة المتفق عليها بأقل مخاطرة ممكنة.

## ما تم تصحيحه

- التراجع عن تعديلات Sprint الأخيرة التي كسرت مسار الأجندة/نتائج العمل ومعالج إنشاء الدعوى، لأنها لم تكن مطابقة لترتيب الخطة وأدخلت أخطاء نوعية واضحة.
- حذف `IMPLEMENTATION_SPRINT_PLAN.md` لأنه كان خطة موازية خارج خارطة التنفيذ النهائية المعتمدة.
- تنظيف فهارس Drift المكررة في `schema.dart`:
  - `idx_case_parties_case`
  - `idx_case_phases_case`
  - `idx_case_sessions_case`
  - `idx_tasks_date`

## ما تم تنفيذه من قلب المرحلة 1

أضيفت بنية ملف المكتب الموحد بشكل آمن لا يحتاج إلى `build_runner` في هذه البيئة:

- جداول SQL-managed:
  - `office_file_sequences`
  - `office_files`
- دالة فتح الجداول:
  - `AppDatabase.ensureOfficeFileTables()`
- استدعاء الجداول عند فتح قاعدة البيانات في `beforeOpen`.
- Enums مركزية:
  - `OfficeFileType`
  - `OfficeFileSource`
  - `OfficeFileStatus`
- مستودع جديد:
  - `lib/data/repositories/office_file_repository.dart`
- Provider جديد:
  - `officeFileRepositoryProvider`

## قرار تقني مهم

الخطة الأصلية تقترح Drift-managed tables، لكن بيئة المساعد لا تحتوي Flutter/Dart ولا يمكن تشغيل `build_runner`. لتجنب كسر البناء بملفات generated غير محدثة، تم إنشاء الجداول كـ SQL-managed مؤقتاً، مثل جداول الصلاحيات والأرشيف الموجودة مسبقاً.

يمكن لاحقاً نقلها إلى Drift-managed schema عندما يشغل المستخدم `build_runner` على Windows ويصبح لدينا مجال لتحديث `database.g.dart` بأمان.

## ما لم يتم بعد

- لم يتم بعد ربط إنشاء الدعوى/الإجراء/العقد/الشركة/الوكالة بـ `OfficeFile`.
- لم يتم بعد تحويل شاشة الملفات لتقرأ من `office_files` كمصدر أساسي.
- لم يتم بعد تنفيذ الإغلاق الإداري.
- لم يتم بعد تنفيذ مركز اليوم/الغد الجديد.

## التحقق المطلوب من المستخدم

على Windows:

```bash
flutter pub get
flutter analyze
flutter run -d windows
```

إذا ظهر خطأ، يرسل فوراً ليتم إصلاحه قبل متابعة المرحلة التالية.
