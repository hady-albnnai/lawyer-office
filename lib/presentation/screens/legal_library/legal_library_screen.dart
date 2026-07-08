/// شاشة المكتبة القانونية
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LegalLibraryScreen extends StatelessWidget {
  const LegalLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المكتبة القانونية')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books, size: 64, color: AppColors.primaryNavy),
            const SizedBox(height: 16),
            Text('المكتبة القانونية السورية', style: AppTextStyles.headline3),
            const SizedBox(height: 8),
            Text('قيد التطوير - المرحلة 8', style: AppTextStyles.bodyMediumSecondary),
          ],
        ),
      ),
    );
  }
}
