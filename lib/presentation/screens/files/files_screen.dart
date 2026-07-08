/// شاشة الملفات لتطبيق مكتب المحامي
/// Placeholder للمرحلة 1 - ستتم تطويرها في المرحلة 4
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملفات')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder, size: 64, color: AppColors.primaryNavy),
            const SizedBox(height: 16),
            Text('الملفات', style: AppTextStyles.headline3),
            const SizedBox(height: 8),
            Text('قيد التطوير - المرحلة 4', style: AppTextStyles.bodyMediumSecondary),
          ],
        ),
      ),
    );
  }
}
