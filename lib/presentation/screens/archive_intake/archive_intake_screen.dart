import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/permission_catalog.dart';
import '../../providers/auth_providers.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

final _archiveIntakeRefreshProvider = StateProvider<int>((ref) => 0);

/// مركز إدخال الأرشيف القديم.
///
/// هذه شاشة تأسيسية آمنة للمرحلة القادمة من إعادة الهيكلة. لا تحفظ بيانات بعد،
/// لكنها تثبت بنية المسارات والأقسام المتفق عليها قبل بناء جداول الدفعات.
class ArchiveIntakeScreen extends ConsumerWidget {
  const ArchiveIntakeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionServiceProvider);
    ref.watch(_archiveIntakeRefreshProvider);
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

  Widget _batchesList(WidgetRef ref) {
    final repo = ref.watch(archiveIntakeRepositoryProvider);
    return FutureBuilder(
      future: repo.getBatches(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final batches = snapshot.data!;
        if (batches.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text('لا توجد دفعات إدخال بعد. ابدأ بإنشاء دفعة من المسارات أعلاه.', style: AppTextStyles.bodyMediumSecondary),
            ),
          );
        }
        return Column(
          children: batches.map((b) {
            final canImport = ref.watch(permissionServiceProvider).can(PermissionKeys.archiveIntakeImportFiles);
            return Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.primaryNavy.withOpacity(0.12), child: Icon(_sourceIcon(b.sourceType), color: AppColors.primaryNavy)),
                title: Text(b.name, style: AppTextStyles.labelLarge),
                subtitle: Text('${_sourceLabel(b.sourceType)} • ${_statusLabel(b.status)} • ${b.createdAt.toString().substring(0, 16)}'),
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _mini('ملفات', b.totalFiles),
                    _mini('غير مصنف', b.unclassifiedFiles),
                    _mini('مكرر', b.duplicateFiles),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('فتح'),
                      onPressed: () => _showBatchDetails(context, ref, b.id, b.name),
                    ),
                    if (canImport)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: const Text('إضافة ملفات'),
                        onPressed: () => _importFiles(context, ref, b.id),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _mini(String label, int value) => Chip(label: Text('$label: $value'));

  IconData _sourceIcon(String source) {
    switch (source) {
      case 'paper': return Icons.document_scanner;
      case 'electronic': return Icons.folder_copy;
      case 'excel': return Icons.table_chart;
      case 'mixed': return Icons.all_inbox;
      default: return Icons.archive;
    }
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'paper': return 'أرشيف ورقي';
      case 'electronic': return 'أرشيف إلكتروني';
      case 'excel': return 'Excel / CSV';
      case 'mixed': return 'أرشيف مختلط';
      default: return source;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'new': return 'جديدة';
      case 'processing': return 'قيد المعالجة';
      case 'waiting_review': return 'بانتظار المراجعة';
      case 'completed': return 'مكتملة';
      case 'completed_with_errors': return 'مكتملة مع أخطاء';
      case 'cancelled': return 'ملغاة';
      default: return status;
    }
  }

  Future<void> _showCreateBatch(BuildContext context, WidgetRef ref, String sourceType) async {
    final name = TextEditingController(text: '${_sourceLabel(sourceType)} - ${DateTime.now().toString().substring(0, 10)}');
    final notes = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إنشاء دفعة ${_sourceLabel(sourceType)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الدفعة *')),
            const SizedBox(height: 12),
            TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إنشاء')),
        ],
      ),
    ) ?? false;
    if (!ok || name.text.trim().isEmpty) return;
    final user = ref.read(authControllerProvider).user;
    final id = await ref.read(archiveIntakeRepositoryProvider).createBatch(
      name: name.text.trim(),
      sourceType: sourceType,
      createdBy: user?.fullName,
      notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
    );
    await ref.read(auditServiceProvider).log(
      action: 'create',
      category: 'archive',
      entityType: 'archive_batch',
      entityId: '$id',
      entityTitle: name.text.trim(),
      description: 'إنشاء دفعة إدخال أرشيف',
      after: {'sourceType': sourceType},
      severity: 'info',
    );
    ref.read(_archiveIntakeRefreshProvider.notifier).state++;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء دفعة الأرشيف: ${name.text.trim()}'), backgroundColor: AppColors.success));
    }
  }

  Future<void> _importFiles(BuildContext context, WidgetRef ref, int batchId) async {
    if (!ref.read(permissionServiceProvider).can(PermissionKeys.archiveIntakeImportFiles)) {
      await ref.read(auditServiceProvider).log(action: 'access_denied', category: 'archive', entityType: 'archive_batch', entityId: '$batchId', description: 'محاولة استيراد ملفات أرشيف دون صلاحية', severity: 'warning');
      return;
    }
    final result = await fp.FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    final files = result.paths.whereType<String>().map(File.new).toList();
    if (files.isEmpty) return;
    final summary = await ref.read(archiveIntakeRepositoryProvider).importFilesToBatch(batchId, files);
    await ref.read(auditServiceProvider).log(
      action: 'import_files',
      category: 'archive',
      entityType: 'archive_batch',
      entityId: '$batchId',
      description: 'استيراد ملفات إلى دفعة أرشيف',
      after: {'files': files.length, 'imported': summary.imported, 'duplicates': summary.duplicates, 'failed': summary.failed},
      severity: 'info',
    );
    ref.read(_archiveIntakeRefreshProvider.notifier).state++;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت المعالجة: ${summary.imported} جديد، ${summary.duplicates} مكرر، ${summary.failed} فشل'),
          backgroundColor: summary.failed > 0 ? AppColors.warning : AppColors.success,
        ),
      );
    }
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
                'يمكنك الآن إنشاء دفعات وإضافة ملفات إليها. الربط والتصنيف والاعتماد النهائي ستُستكمل في المراحل التالية وفق الخطة.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
