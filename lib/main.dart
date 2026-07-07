import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// نقطة انطلاق تطبيق إدارة وأرشفة مكتب المحاماة السوري (V6.2 Offline-First)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تشغيل التطبيق مغلفاً بمزود الحالة Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: LawyerOfficeApp(),
    ),
  );
}
