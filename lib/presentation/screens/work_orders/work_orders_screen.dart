/// شاشة أوامر العمل
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class WorkOrdersScreen extends StatelessWidget {
  const WorkOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أوامر العمل')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment, size: 64, color: AppColors.primaryNavy),
            const SizedBox(height: 16),
            Text('أوامر العمل للمعقب', style: AppTextStyles.headline3),
            const SizedBox(height: 8),
            Text('قيد التطوير - المرحلة 3', style: AppTextStyles.bodyMediumSecondary),
          ],
        ),
      ),
    );
  }
}
