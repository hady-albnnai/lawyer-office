# 🪟 سجل CI لاختبار Windows - المرحلة 5

> التاريخ: 2026-07-10  
> الحالة: تم إضافة GitHub Actions Workflow لتشغيل اختبار Windows تلقائياً على `windows-latest`.

---

## Workflow

المسار:

```text
.github/workflows/stage5_windows_validation.yml
```

## خطوات الاختبار الآلية

1. Checkout repository.
2. Setup Flutter stable.
3. `flutter doctor -v`.
4. `flutter config --enable-windows-desktop`.
5. `flutter pub get`.
6. `dart run build_runner build --delete-conflicting-outputs`.
7. `flutter analyze`.
8. `flutter test`.
9. `flutter build windows --debug`.

---

## الحالة الدستورية

سيتم اعتبار اختبار Windows منجزاً فقط بعد نجاح هذا الـ Workflow على GitHub Actions أو تشغيل الاختبار يدوياً على Windows محلي.
