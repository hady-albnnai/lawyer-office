import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/permission_catalog.dart';
import '../../providers/auth_providers.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// مركز إدخال الأرشيف القديم.
///
/// هذه شاشة تأسيسية آمنة للمرحلة القادمة من إعادة الهيكلة. لا تحفظ بيانات بعد،
/// لكنها تثبت بنية المسارات والأقسام المتفق عليها قبل بناء جداول الدفعات.
class ArchiveIntakeScreen extends ConsumerWidget {
  const ArchiveIntakeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionServiceProvider);
    return Theme(
      data: AppTheme.lightTheme,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('مركز إدخال الأرشيف القديم'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _introCard(),
                const SizedBox(height: 16),
                _sectionTitle('ابدأ دفعة إدخال'),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 900;
                    final cards = [
                      _actionCard(
                        icon: Icons.document_scanner,
                        title: 'أرشيف ورقي',
                        subtitle: 'ملفات ممسوحة ضوئياً PDF أو صور، مع بيانات الأصل الورقي.',
                        enabled: permissions.can(PermissionKeys.archiveIntakeCreate),
                        onTap: () => _showCreateBatch(context, ref, 'paper'),
                      ),
                      _actionCard(
                        icon: Icons.folder_copy,
                        title: 'أرشيف إلكتروني',
                        subtitle: 'استيراد مجلدات وملفات موجودة على الجهاز أو الفلاش.',
                        enabled: permissions.can(PermissionKeys.archiveIntakeImportFiles),
                        onTap: () => _showCreateBatch(context, ref, 'electronic'),
                      ),
                      _actionCard(
                        icon: Icons.table_chart,
                        title: 'Excel / CSV',
                        subtitle: 'استيراد الأشخاص والدعاوى والوكالات والمستندات من قوالب منظمة.',
                        enabled: permissions.can(PermissionKeys.archiveIntakeImportExcel),
                        onTap: () => _showCreateBatch(context, ref, 'excel'),
                      ),
                      _actionCard(
                        icon: Icons.all_inbox,
                        title: 'أرشيف مختلط',
                        subtitle: 'دفعة تجمع ورقي وإلكتروني وجداول قديمة في مسار مراجعة واحد.',
                        enabled: permissions.can(PermissionKeys.archiveIntakeCreate),
                        onTap: () => _showCreateBatch(context, ref, 'mixed'),
                      ),
                    ];
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: wide ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: wide ? 1.25 : 1.15,
                      children: cards,
                    );
                  },
                ),
                const SizedBox(height: 24),
                _sectionTitle('مراجعة الأرشيف'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _statusTile('دفعات الإدخال', 'متابعة دفعات الاستيراد وحالاتها.', Icons.inventory_2, AppColors.primaryNavy),
                    _statusTile('صندوق غير مصنف', 'ملفات تحتاج ربطاً أو تصنيفاً.', Icons.inbox, AppColors.warning),
                    _statusTile('ملفات جارية تحتاج استكمال', 'دعاوى وإجراءات مستوردة ناقصة بيانات تشغيلية.', Icons.pending_actions, AppColors.error),
                    _statusTile('المكررات', 'ملفات كشفها النظام كنسخ مكررة.', Icons.copy_all, AppColors.info),
                    _statusTile('تقارير الجودة', 'نتائج الاستيراد والأخطاء والعينات المطلوبة للمراجعة.', Icons.fact_check, AppColors.success),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle('دفعات الإدخال الحالية'),
                const SizedBox(height: 12),
                _batchesList(ref),
                const SizedBox(height: 24),
                _notice(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _introCard() {
    return Card(
      color: AppColors.primaryNavy,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.archive, color: AppColors.secondaryGold, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إدخال الأرشيف القديم بدون فوضى', style: AppTextStyles.headline5.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text(
                    'كل ملف مستورد يجب أن يصبح إما ملفاً جارياً يغذي مكتب العمل، أو ملفاً منتهياً للأرشفة والبحث، أو عنصراً يحتاج مراجعة.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
      );

  Widget _actionCard({required IconData icon, required String title, required String subtitle, required bool enabled, VoidCallback? onTap}) {
    return Card(
      elevation: enabled ? 2 : 0,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: (enabled ? AppColors.primaryNavy : AppColors.textSecondary).withOpacity(0.12),
                child: Icon(icon, color: enabled ? AppColors.primaryNavy : AppColors.textSecondary),
              ),
              const Spacer(),
              Text(title, style: AppTextStyles.headline6.copyWith(color: enabled ? AppColors.primaryNavy : AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text(subtitle, style: AppTextStyles.bodySmallSecondary, maxLines: 3, overflow: TextOverflow.ellipsis),
              if (!enabled) ...[
                const SizedBox(height: 6),
                Text('لا تملك الصلاحية', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusTile(String title, String subtitle, IconData icon, Color color) {
    return SizedBox(
      width: 300,
      child: Card(
        child: ListTile(
          leading: CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color)),
          title: Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryNavy)),
          subtitle: Text(subtitle, style: AppTextStyles.bodySmallSecondary),
        ),
      ),
    );
  }

  Widget _notice() {
    return Card(
      color: AppColors.warning.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.warning),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'هذه الشاشة تثبت هيكل مركز الأرشيف. معالجة الملفات الفعلية والدفعات وقواعد الكشف عن التكرار ستُنفذ في المراحل التالية وفق الخطة.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
