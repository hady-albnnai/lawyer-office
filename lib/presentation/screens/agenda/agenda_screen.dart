/// شاشة الأجندة لتطبيق مكتب المحامي
/// 
/// هذه شاشة Placeholder للمرحلة 1
/// ستتم تطويرها في المرحلة 2
/// 
/// آخر تحديث: 2026-07-09

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأجندة'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: AppColors.primaryNavy,
            ),
            const SizedBox(height: 16),
            Text(
              'الأجندة',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: 8),
            Text(
              'قيد التطوير - المرحلة 2',
              style: AppTextStyles.bodyMediumSecondary,
            ),
            const SizedBox(height: 32),
            Text(
              'هذه الشاشة ستعرض:',
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
      _buildFeatureItem('جدول المحكمة'),
      _buildFeatureItem('المراجعات الإدارية'),
      _buildFeatureItem('المتأخرات'),
      _buildFeatureItem('منجز اليوم'),
      _buildFeatureItem('مصاريف اليوم'),
      _buildFeatureItem('تحضير الغد'),
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
