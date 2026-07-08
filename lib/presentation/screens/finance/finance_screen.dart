/// شاشة المالية
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المالية')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.attach_money, size: 64, color: AppColors.primaryNavy),
            const SizedBox(height: 16),
            Text('المالية', style: AppTextStyles.headline3),
            const SizedBox(height: 8),
            Text('قيد التطوير - المرحلة 9', style: AppTextStyles.bodyMediumSecondary),
          ],
        ),
      ),
    );
  }
}
