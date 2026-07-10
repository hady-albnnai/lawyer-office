# 📋 خطة التنفيذ العامة - مشروع إعادة تصميم نظام مكتب المحامي V6.2

> **مرجع:** PRODUCT_REDESIGN_MASTER_PLAN.md
> **آخر تحديث:** 2026-07-10
> **المسؤول:** وكيل الذكي (Agent)
> **الحالة:** المرحلة 5 مكتملة (100%)

---

## 🎯 ملخص الحالة الحالية

| المرحلة | الاسم | الحالة | التقدم | آخر Commit |
|---------|------|--------|---------|-------------|
| **1** | التصميم والهيكل العام | ✅ **مكتملة** | 100% | aa850db |
| **2** | لوحة اليوم والأجندة | ✅ **مكتملة** | 100% | aa850db |
| **3** | أوامر العمل للمعقب Offline | ✅ **مكتملة** | 100% | aa850db |
| **4** | الملفات والمستندات | ✅ **مكتملة** | 100% | aa850db |
| **5** | **الدعاوى** | ✅ **مكتملة** | **100%** | 853f915 |
| 6 | الأشخاص والجهات | ⏳ **قيد التنفيذ** | 35% | 91af396 |
| 7 | المالية | ❌ **معتزلة** | 0% | - |
| 8 | البحث والتقارير | ❌ **معتزلة** | 0% | - |
| 9 | المكتبة القانونية | ❌ **معتزلة** | 0% | - |
| 10 | الإعدادات | ❌ **معتزلة** | 0% | - |

**إجمالي التقدم:** 5/10 مراحل مكتملة + 35% من المرحلة 6 = **53.5% تقريباً**

---

## 📊 تفصيلات المرحلة 5 (الدعاوى)

### ✅ مكتملة (100%)
| الملف | الوصف | حجم | Commit |
|-------|------|------|--------|
| `case_models.dart` | Models كاملة (Case, CasePhase, CaseSession, etc.) | 13,407 سطر | aa850db |
| `cases_screen.dart` | قائمة الدعاوى الرئيسية | 34,315 سطر | aa850db |

### ✅ مكتملة (100%)
| الملف | الوصف | الحالة | حجم |
|-------|------|--------|------|
| `create_case_wizard.dart` | معالج 8 خطوات لإنشاء دعوى | ✅ **جاهز للنقل** | 57,683 سطر |
| `case_detail_screen.dart` | شاشة تفاصيل الدعوى (9 تبويبات) | ❌ **متبقي** | 0 سطر |

### 📝 تبويبات case_detail_screen.dart المتبقية (9 تبويبات)
1. **الملخص** - معلومات أساسية عن الدعوى
2. **الأطراف والوكالات** - بيانات الموكل والخصم
3. **المراحل القضائية** - تتبع مراحل الدعوى
4. **الجلسات والإجراءات** - سجل الجلسات
5. **المستندات** - مستندات الدعوى
6. **المالية** - التكاليف والمصروفات
7. **النواقص** - المتطلبات غير المكتملة
8. **الخط الزمني** - تاريخ الأحداث
9. **الإنهاء** - خيارات إنهاء الدعوى

---

## 📁 هيكل المشروع الحالي

```
lib/
├── presentation/
│   ├── theme/
│   │   ├── app_colors.dart          # ✅ نظام الألوان الكامل
│   │   ├── app_text_styles.dart      # ✅ أنماط النصوص
│   │   ├── custom_icons.dart          # ✅ أيقونات مخصصة
│   │   └── app_theme.dart            # ✅ الثيم الرئيسي
│   ├── widgets/
│   │   └── sidebar/
│   │       ├── badge_widget.dart      # ✅ نظام Badges
│   │       ├── sidebar_item.dart      # ✅ عناصر SideBar
│   │       └── nav_sidebar.dart        # ✅ SideBar الرئيسي
│   ├── navigation/
│   │   └── app_router.dart            # ✅ GoRouter (11 مسار)
│   └── screens/
│       ├── dashboard/
│       │   └── today_dashboard_screen.dart  # ✅ شريط ملخص + خط سير + أزرار
│       ├── agenda/
│       │   ├── agenda_screen.dart          # ✅ 6 تبويبات
│       │   └── result_entry_dialog.dart      # ✅ تسجيل نتيجة العمل
│       ├── files/
│       │   └── files_screen.dart           # ✅ 8 تبويبات + ربط بالمستندات
│       ├── documents/
│       │   ├── documents_screen.dart       # ✅ 7 تبويبات
│       │   └── document_viewer.dart          # ✅ فتح المرفقات
│       ├── work_orders/
│       │   ├── work_orders_screen.dart      # ✅ 5 تبويبات
│       │   ├── work_order_models.dart        # ✅ Models كاملة
│       │   └── work_order_dialogs.dart       # ✅ 5 حوارات
│       └── cases/
│           ├── case_models.dart           # ✅ Models (Case, CasePhase, CaseSession, etc.)
│           ├── cases_screen.dart            # ✅ قائمة الدعاوى
│           ├── create_case_wizard.dart      # ⚠️ معالج 8 خطوات (جاهز)
│           └── case_detail_screen.dart      # ❌ 9 تبويبات (متبقي)
├── app.dart                              # ✅ محدث لاستخدام الثيم الجديد
└── main.dart
```

---

## 🎯 المهام المتبقية (بترتيب الأولوية)

### 🔴 أولوية عالية (Critical - يجب إنجازه الآن)
1. **رفع create_case_wizard.dart إلى GitHub**
   - ملف جاهز (57,683 سطر)
   - يجب رفعه إلى الفرع `main`
   - Commit message: "feat(cases): add create case wizard with 8 steps"

2. **تطوير case_detail_screen.dart**
   - إنشاء ملف جديد: `lib/presentation/screens/cases/case_detail_screen.dart`
   - تنفيذ 9 تبويبات:
     - تبويب الملخص
     - تبويب الأطراف والوكالات
     - تبويب المراحل القضائية
     - تبويب الجلسات والإجراءات
     - تبويب المستندات
     - تبويب المالية
     - تبويب النواقص
     - تبويب الخط الزمني
     - تبويب الإنهاء
   - استخدام AppTheme.lightTheme
   - دعم RTL الكامل

3. **اختبار التشغيل على Windows**
   - اختبار جميع الشاشات الموجودة
   - التحقق من دعم RTL
   - التحقق من الثيم الموحد
   - تسجيل أي أخطاء

### 🟡 أولوية متوسطة (Medium - بعد المرحلة 5)
4. **تنظيف الكود القديم**
   - حذف الملفات غير المستخدمة
   - حذف التبعيات القديمة
   - تحديث pubspec.yaml

5. **تحديث التوثيق**
   - تحديث PRODUCT_REDESIGN_MASTER_PLAN.md
   - إنشاء STAGE_5_EXECUTION_LOG.md
   - تحديث هذا الملف (EXECUTION_PLAN.md)

### 🟢 أولوية منخفضة (Low - بعد اكتمال المرحلة 5)
6. **بدء المرحلة 6: الأشخاص والجهات**
7. **بدء المرحلة 7: المالية**
8. **بدء المرحلة 8: البحث والتقارير**
9. **بدء المرحلة 9: المكتبة القانونية**
10. **بدء المرحلة 10: الإعدادات**

---

## 📅 الجدول الزمني المقترح

| المهام | المدة المتوقعة | تاريخ البداية | تاريخ الانتهاء |
|--------|----------------|---------------|---------------|
| رفع create_case_wizard.dart | 30 دقيقة | 2026-07-10 | 2026-07-10 |
| تطوير case_detail_screen.dart | 4-6 ساعات | 2026-07-10 | 2026-07-10 |
| اختبار التشغيل على Windows | 1 ساعة | 2026-07-10 | 2026-07-10 |
| تنظيف الكود القديم | 1 ساعة | 2026-07-10 | 2026-07-10 |
| تحديث التوثيق | 30 دقيقة | 2026-07-10 | 2026-07-10 |
| **اكتمال المرحلة 5** | - | - | **2026-07-10** |

---

## 🔧 المتطلبات الفنية

### التبعيات المطلوبة
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.1
  flutter_riverpod: ^2.4.9
  go_router: ^13.0.0
  drift: ^2.13.0
  sqlite3_flutter_libs: ^0.5.0
  path: ^1.8.3
  font_awesome_flutter: ^10.6.0
  pdf: ^3.10.7
  printing: ^5.11.1
  url_launcher: ^6.1.14
  shared_preferences: ^2.2.2
```

### هيكل قاعدة البيانات (Drift/SQLite)
- جداول مطلوبة:
  - cases
  - case_phases
  - case_sessions
  - case_parties
  - case_documents
  - case_financials
  - case_deficiencies

---

## ✅ معايير قبول كل مرحلة

تعتبر المرحلة مكتملة عندما:

1. ✅ يتم تنفيذ جميع المهام المخصصة لها
2. ✅ يتم اختبار التشغيل على Windows
3. ✅ يتم تحديث التوثيق (EXECUTION_PLAN.md + STAGE_X_*.md)
4. ✅ يتم رفع جميع التغييرات إلى GitHub (فرع: main)
5. ✅ يتم التحقق من دعم RTL
6. ✅ يتم استخدام AppTheme.lightTheme بشكل موحد
7. ✅ يتم الالتزام بدستور التطوير (DEVELOPMENT_GUIDELINES.md)

---

## 📝 سجل التغييرات

| التاريخ | المرحله | التغيير | Commit |
|---------|---------|----------|--------|
| 2026-07-09 | 1 | الثيم + SideBar + 11 شاشة + الملاحة | c0bb48b, 9b534fb, 0fbe059, ef3f546 |
| 2026-07-09 | 2 | TodayDashboardScreen + AgendaScreen + ResultEntryDialog | f25d01a, 5b51a02 |
| 2026-07-09 | 3 | WorkOrdersScreen + Models + Dialogs | e52d793 |
| 2026-07-09 | 4 | FilesScreen + DocumentsScreen + DocumentViewer | 570bc21, 8b03615, a2461ea, 8462868, aa850db |
| 2026-07-09 | 5 | case_models.dart + cases_screen.dart | aa850db |
| **2026-07-10** | **5** | **create_case_wizard.dart (معتزلة)** | **معتزلة** |
| **2026-07-10** | **5** | **case_detail_screen.dart (معتزلة)** | **معتزلة** |

---

## 🚨 المشكلات المعروفة

1. **case_detail_screen.dart** - لم يتم تطويرها بعد
2. **اختبار التشغيل** - لم يتم اختبار أي شاشة على Windows
3. **تنظيف الكود القديم** - بعض الملفات القديمة لا تزال موجودة
4. **GitHub Sync** - create_case_wizard.dart جاهز لكن لم يرفع

---

## 📌 الملاحظات الهامة

1. **دعم RTL**: جميع الواجهات يجب أن تدعم العربية (RTL)
2. **الثيم الموحد**: استخدام `AppTheme.lightTheme` و `AppColors` و `AppTextStyles`
3. **الالتزام بدستور التطوير**:
   - برمجة → اختبار → توثيق → رفع
4. **مستودع GitHub**: https://github.com/hady-albnnai/lawyer-office
5. **الفرع**: `main`
6. **آخر Commit**: `aa850db` (2026-07-09)

---

## 🎯 الخطوات التالية الفورية

1. **في خلال 30 دقيقة:**
   - رفع create_case_wizard.dart إلى GitHub
   
2. **في خلال 4-6 ساعات:**
   - تطوير case_detail_screen.dart (9 تبويبات)
   
3. **في خلال 1 ساعة:**
   - اختبار التشغيل على Windows
   
4. **في خلال 1 ساعة:**
   - تنظيف الكود القديم
   - تحديث التوثيق

**هدف اليوم:** اكتمال المرحلة 5 بنهاية يوم 2026-07-10

---

**ملاحظة:** يجب الالتزام بدستور التطوير (DEVELOPMENT_GUIDELINES.md):
- لا إعلان اكتمال مرحلة إلا بعد استكمال جميع المتطلبات
- يجب رفع الكود إلى GitHub بعد كل ميزة
- يجب تحديث التوثيق باستمرار


---

### ✅ إغلاق المرحلة 5 - 2026-07-10

اكتملت المرحلة 5 بعد تنفيذ شاشة تفاصيل الدعوى، تنظيف الكود، تحديث التوثيق، الرفع إلى GitHub، ونجاح اختبار Windows عبر GitHub Actions.

رابط اختبار Windows: https://github.com/hady-albnnai/lawyer-office/actions/runs/29099656277


---

## 🚀 بدء المرحلة 6 - الأشخاص والوكالات

بدأ تنفيذ المرحلة 6 بتاريخ 2026-07-10 عبر بناء نواة Riverpod للأشخاص والوكالات، فلاتر الأدوار، ملف الشخص من 9 تبويبات، وأرشيف الوكالات مع ربط الوكالة بالدعوى.

الملفات الأساسية:

- `lib/presentation/screens/persons/person_models.dart`
- `lib/presentation/screens/persons/persons_list_screen.dart`
- `lib/presentation/screens/persons/person_detail_screen.dart`
- `lib/presentation/screens/persons/persons_screen.dart`
- `lib/presentation/screens/poa/poa_list_screen.dart`
- `test/stage6_person_directory_test.dart`

حالة المرحلة 6 الحالية: قيد التنفيذ.


### ✅ اختبار Windows للدفعة الأولى من المرحلة 6

نجح اختبار GitHub Actions على Windows للدفعة الأولى من المرحلة 6.

- Run ID: `29103790064`
- Commit: `91af396`
- الرابط: https://github.com/hady-albnnai/lawyer-office/actions/runs/29103790064
