/// شاشة عمل جديد لتطبيق مكتب المحامي
/// 
/// هذه شاشة Placeholder للمرحلة 1
/// ستتم تطويرها في المرحلة 2
/// 
/// آخر تحديث: 2026-07-09

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class NewWorkScreen extends StatelessWidget {
  const NewWorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عمل جديد'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 64,
              color: AppColors.primaryNavy,
            ),
            const SizedBox(height: 16),
            Text(
              'عمل جديد',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: 8),
            Text(
              'قيد التطوير - المرحلة 2',
              style: AppTextStyles.bodyMediumSecondary,
            ),
            const SizedBox(height: 32),
            Text(
              'هذه الشاشة ستسمح ب:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            ..._buildFeatureList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeatureList() {
    return [
      _buildFeatureItem('بدء عمل جديد'),
      _buildFeatureItem('أرشفة عمل سابق'),
      _buildFeatureItem('إنشاء دعوى قضائية'),
      _buildFeatureItem('إنشاء عقد'),
      _buildFeatureItem('تأسيس شركة'),
      _buildFeatureItem('إجراء إداري'),
      _buildFeatureItem('تنظيم وكالة'),
      _buildFeatureItem('إضافة شخص أو جهة'),
      _buildFeatureItem('إضافة مستند مستقل'),
      _buildFeatureItem('إنشاء أمر عمل للمعقب'),
      _buildFeatureItem('إنشاء مهمة يدوية'),
    ];
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
