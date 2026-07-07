import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'presentation/navigation/app_router.dart';

/// جذر التطبيق الرئيسي (LawyerOfficeApp)
class LawyerOfficeApp extends StatelessWidget {
  const LawyerOfficeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'مكتب المحامي • إدارة وأرشفة قانونية',
      debugShowCheckedModeBanner: false,
      
      // التوطين ودعم RTL الكامل للغة العربية السورية كافتراضية
      locale: const Locale('ar', 'SY'),
      supportedLocales: const [
        Locale('ar', 'SY'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ثيم المكتب الرسمي المخصص
      theme: AppTheme.lightTheme,

      // نظام الملاحة الموحد
      routerConfig: appRouter,
    );
  }
}
