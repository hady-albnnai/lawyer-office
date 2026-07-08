/// شاشة المستندات
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المستندات')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 64, color: AppColors.primaryNavy),
            const SizedBox(height: 16),
            Text('المستندات', style: AppTextStyles.headline3),
            const SizedBox(height: 8),
            Text('قيد التطوير - المرحلة 4', style: AppTextStyles.bodyMediumSecondary),
          ],
        ),
      ),
    );
  }
}
