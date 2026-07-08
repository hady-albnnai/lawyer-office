/// شاشة الأشخاص والجهات
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class PersonsScreen extends StatelessWidget {
  const PersonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأشخاص والجهات')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, size: 64, color: AppColors.primaryNavy),
            const SizedBox(height: 16),
            Text('الأشخاص والجهات', style: AppTextStyles.headline3),
            const SizedBox(height: 8),
            Text('قيد التطوير - المرحلة 6', style: AppTextStyles.bodyMediumSecondary),
          ],
        ),
      ),
    );
  }
}
