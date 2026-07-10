# حالة طبقة البيانات الحقيقية (Drift / SQLite)

> التاريخ: 2026-07-10  
> الهدف: إزالة الاعتماد على بيانات وهمية في الذاكرة وجعل التطبيق يخزّن ويسترجع من SQLite.

## ما كانت "الملاحظة المعمارية"؟

في مراحل 5–10 بُنيت واجهات سريعة بنماذج `seed` في الذاكرة لتسريع UX والاختبارات.  
**لم تكن أمراً من صاحب المشروع**، بل وصفاً لفجوة تقنية: الواجهة تعمل، لكن بعض الشاشات لم تكن مربوطة بعد بجداول Drift.

## ماذا يعني "جاهز 100%" هنا؟

1. الشاشات الرئيسية تعمل بدون Placeholder.
2. **العمليات المالية / المكتبة / الإعدادات-الأمان-النسخ** تُكتب وتُقرأ من SQLite عبر Repositories.
3. عند أول تشغيل تُبذر بيانات تجريبية **داخل قاعدة البيانات** (مرة واحدة إن كانت الجداول فارغة).
4. الاختبارات تغطي المنطق + طبقة البيانات (in-memory Drift).

## ما تم ربطه فعلياً

| المجال | DAO | Repository | الواجهة |
|---|---|---|---|
| المالية | `FinanceDao` (كل الاتفاقات/الدفعات/المصاريف) | `FinanceRepository` + seedDemoIfEmpty | `FinanceNotifier` → repository |
| المكتبة القانونية | `LegalLibraryDao` + جداول جديدة | `LegalLibraryRepository` + seed | `LegalLibraryNotifier` → repository |
| الإعدادات/الأمان/النسخ/السجل/المحاكم | `SettingsDao` | `SettingsRepository` + `BackupService` | `SettingsHubNotifier` → repository |

## ترقية قاعدة البيانات

- `schemaVersion = 2`
- جداول جديدة: `legal_library_items`, `legal_library_links`

## اختبارات طبقة البيانات

`test/stage11_data_layer_test.dart` — Finance / LegalLibrary / Settings على `NativeDatabase.memory()`.

## ما يبقى لتحسين 100% تشغيلي (ليس مانعاً للتخزين)

- ربط باقي الشاشات القديمة (دعاوى/ملفات/أوامر عمل seed UI) بالكامل بنفس النمط.
- تشغيل يدوي على Windows للتأكد من مسارات الملفات والنسخ Zip.
