# بناء نسخة التسليم Windows

## المتطلبات
- Flutter stable
- Windows 10/11 مع Visual Studio Desktop C++

## أوامر البناء
```bash
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build windows --release
```

## المخرجات
`build/windows/x64/runner/Release/`

انسخ مجلد Release كاملاً للزبون أو اضغطه ZIP.

## أول تشغيل عند الزبون
1. شغّل `lawyer_office.exe`
2. أكمل شاشة الإعداد
3. اترك «بيانات تجريبية» مغلقة للعمل الحقيقي
4. من الإعدادات أنشئ نسخة احتياطية فوراً بعد إدخال بيانات مهمة
