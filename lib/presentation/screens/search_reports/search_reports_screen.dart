/// شاشة البحث والتقارير
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SearchReportsScreen extends StatelessWidget {
  const SearchReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البحث والتقارير')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: AppColors.primaryNavy),
            const SizedBox(height: 16),
            Text('البحث والتقارير', style: AppTextStyles.headline3),
            const SizedBox(height: 8),
            Text('قيد التطوير - المرحلة 7', style: AppTextStyles.bodyMediumSecondary),
          ],
        ),
      ),
    );
  }
}
