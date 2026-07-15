/// شاشة الإعدادات والأمان والنسخ - المرحلة 10.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/permission_catalog.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../providers/ui_data_providers.dart';
import '../../providers/auth_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'settings_models.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    // tabs.dispose();
    // super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsHubProvider);

    return Theme(
      data: AppTheme.lightTheme,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('الإعدادات والأمان والنسخ الاحتياطي'),
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              indicatorColor: AppColors.secondaryGold,
              labelColor: AppColors.secondaryGold,
              unselectedLabelColor: AppColors.textOnLight.withOpacity(0.75),
              labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'بيانات المكتب'),
                Tab(text: 'الأمان'),
                Tab(text: 'النسخ الاحتياطي'),
                Tab(text: 'القوائم المرجعية'),
                Tab(text: 'المستخدمون والصلاحيات'),
                Tab(text: 'سجل المسؤولية'),
                Tab(text: 'سجل النشاط'),
              ],
            ),
          ),
          body: Column(
            children: [
              if (state.lastMessage != null)
                MaterialBanner(
                  content: Text(state.lastMessage!),
                  actions: [
                    TextButton(
                      onPressed: () => ref.read(settingsHubProvider.notifier).clearMessage(),
                      child: const Text('إخفاء'),
                    ),
                  ],
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _OfficeTab(),
                    _SecurityTab(),
                    _BackupTab(),
                    _LookupsTab(),
                    _UsersRolesTab(),
                    _AuditTab(),
                    _ActivityTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfficeTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_OfficeTab> createState() => _OfficeTabState();
}

class _OfficeTabState extends ConsumerState<_OfficeTab> {
  late final TextEditingController _title;
  late final TextEditingController _lawyer;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _logo;
  late final TextEditingController _signature;
  late String _uiFont;
  late String _printFont;
  late int _woPriority;
  late bool _libFav;

  @override
  void initState() {
    super.initState();
    final p = ref.read(settingsHubProvider).preferences;
    _title = TextEditingController(text: p.officeTitle);
    _lawyer = TextEditingController(text: p.lawyerName);
    _address = TextEditingController(text: p.officeAddress);
    _phone = TextEditingController(text: p.officePhone);
    _email = TextEditingController(text: p.officeEmail);
    _logo = TextEditingController(text: p.logoPath);
    _signature = TextEditingController(text: p.signaturePath);
    _uiFont = p.uiFont;
    _printFont = p.printFont;
    _woPriority = p.workOrderDefaultPriority;
    _libFav = p.libraryAutoFavoritePrinciples;
  }

  @override
  void dispose() {
    // title.dispose();
    // lawyer.dispose();
    // address.dispose();
    // phone.dispose();
    // email.dispose();
    // logo.dispose();
    // signature.dispose();
    // super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('بيانات المكتب والترويسة', style: AppTextStyles.headline5.copyWith(color: AppColors.primaryNavy)),
                const SizedBox(height: 8),
                Text('تظهر في الشاشات وتقارير PDF.', style: AppTextStyles.bodySmallSecondary),
                const Divider(height: 28),
                TextField(controller: _title, decoration: const InputDecoration(labelText: 'اسم المكتب *', prefixIcon: Icon(Icons.business))),
                const SizedBox(height: 12),
                TextField(controller: _lawyer, decoration: const InputDecoration(labelText: 'اسم المحامي الأستاذ *', prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 12),
                TextField(controller: _address, decoration: const InputDecoration(labelText: 'العنوان', prefixIcon: Icon(Icons.location_on))),
                const SizedBox(height: 12),
                TextField(controller: _phone, decoration: const InputDecoration(labelText: 'الهاتف / واتساب', prefixIcon: Icon(Icons.phone))),
                const SizedBox(height: 12),
                TextField(controller: _email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email))),
                const SizedBox(height: 12),
                TextField(controller: _logo, decoration: const InputDecoration(labelText: 'مسار الشعار (محلي)', prefixIcon: Icon(Icons.image))),
                const SizedBox(height: 12),
                TextField(controller: _signature, decoration: const InputDecoration(labelText: 'مسار التوقيع (محلي)', prefixIcon: Icon(Icons.draw))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _uiFont,
                        decoration: const InputDecoration(labelText: 'خط الواجهة'),
                        items: const [
                          DropdownMenuItem(value: 'Cairo', child: Text('Cairo')),
                          DropdownMenuItem(value: 'Amiri', child: Text('Amiri')),
                        ],
                        onChanged: (v) => setState(() => _uiFont = v ?? _uiFont),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _printFont,
                        decoration: const InputDecoration(labelText: 'خط الطباعة القانونية'),
                        items: const [
                          DropdownMenuItem(value: 'Amiri', child: Text('Amiri')),
                          DropdownMenuItem(value: 'Cairo', child: Text('Cairo')),
                        ],
                        onChanged: (v) => setState(() => _printFont = v ?? _printFont),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _woPriority,
                  decoration: const InputDecoration(labelText: 'أولوية أمر العمل الافتراضية'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('منخفضة')),
                    DropdownMenuItem(value: 1, child: Text('متوسطة')),
                    DropdownMenuItem(value: 2, child: Text('عالية')),
                  ],
                  onChanged: (v) => setState(() => _woPriority = v ?? _woPriority),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تعيين المبادئ القانونية تلقائياً كمفضلة في المكتبة'),
                  value: _libFav,
                  onChanged: (v) => setState(() => _libFav = v),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ إعدادات المكتب'),
                  onPressed: () async {
                    if (_title.text.trim().isEmpty || _lawyer.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('اسم المكتب واسم المحامي إلزاميان'), backgroundColor: AppColors.error),
                      );
                      return;
                    }
                    final current = ref.read(settingsHubProvider).preferences;
                    await ref.read(settingsHubProvider.notifier).saveOfficePreferences(
                          current.copyWith(
                            officeTitle: _title.text.trim(),
                            lawyerName: _lawyer.text.trim(),
                            officeAddress: _address.text.trim(),
                            officePhone: _phone.text.trim(),
                            officeEmail: _email.text.trim(),
                            logoPath: _logo.text.trim(),
                            signaturePath: _signature.text.trim(),
                            uiFont: _uiFont,
                            printFont: _printFont,
                            workOrderDefaultPriority: _woPriority,
                            libraryAutoFavoritePrinciples: _libFav,
                          ),
                        );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends ConsumerState<_SecurityTab> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _question = TextEditingController();
  final _answer = TextEditingController();
  int _timeout = 10;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsHubProvider).security;
    _question.text = s.securityQuestion;
    _timeout = s.lockTimeoutMinutes;
  }

  @override
  void dispose() {
    // current.dispose();
    // next.dispose();
    // confirm.dispose();
    // question.dispose();
    // answer.dispose();
    // super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final security = ref.watch(settingsHubProvider).security;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            Card(
              color: AppColors.primaryNavy,
              child: ListTile(
                leading: const Icon(Icons.verified_user, color: AppColors.secondaryGold, size: 40),
                title: Text(
                  security.isConfigured ? 'الحماية المحلية مفعّلة' : 'الحماية غير مهيأة',
                  style: AppTextStyles.headline6.copyWith(color: Colors.white),
                ),
                subtitle: Text(
                  'تشفير محلي لكلمة المرور (SHA-256) • مهلة القفل: ${security.lockTimeoutMinutes} دقيقة',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(8)),
                  child: const Text('محمي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('تغيير كلمة المرور وسؤال الأمان', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy)),
                    const SizedBox(height: 12),
                    TextField(controller: _current, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الحالية', prefixIcon: Icon(Icons.lock_outline))),
                    const SizedBox(height: 12),
                    TextField(controller: _next, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', prefixIcon: Icon(Icons.lock))),
                    const SizedBox(height: 12),
                    TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور', prefixIcon: Icon(Icons.lock))),
                    const SizedBox(height: 12),
                    TextField(controller: _question, decoration: const InputDecoration(labelText: 'سؤال الأمان', prefixIcon: Icon(Icons.question_answer))),
                    const SizedBox(height: 12),
                    TextField(controller: _answer, decoration: const InputDecoration(labelText: 'إجابة سؤال الأمان', prefixIcon: Icon(Icons.check))),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _timeout,
                      decoration: const InputDecoration(labelText: 'مهلة القفل التلقائي (دقيقة)'),
                      items: const [5, 10, 15, 30, 60]
                          .map((m) => DropdownMenuItem(value: m, child: Text('$m دقيقة')))
                          .toList(),
                      onChanged: (v) => setState(() => _timeout = v ?? _timeout),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.security),
                      label: const Text('تحديث بيانات الحماية'),
                      onPressed: () async {
                        final err = await ref.read(settingsHubProvider.notifier).updateSecurity(
                              currentPassword: _current.text,
                              newPassword: _next.text,
                              confirmPassword: _confirm.text,
                              securityQuestion: _question.text,
                              securityAnswer: _answer.text,
                              lockTimeoutMinutes: _timeout,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(err ?? 'تم تحديث بيانات الأمان بنجاح'),
                            backgroundColor: err == null ? AppColors.success : AppColors.error,
                          ),
                        );
                        if (err == null) {
                          _current.clear();
                          _next.clear();
                          _confirm.clear();
                          _answer.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsHubProvider);
    final notifier = ref.read(settingsHubProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF117A65),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done, size: 48, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'النسخ الاحتياطي الذكي (Offline)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.needsWeeklyBackup
                                ? 'تنبيه: مر أسبوع أو أكثر — يُفضّل إنشاء نسخة الآن.'
                                : 'آخر نسخة: ${state.preferences.lastBackupAt?.toString().substring(0, 16) ?? '—'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF117A65)),
                      onPressed: state.isBusy
                          ? null
                          : () async {
                              final rec = await notifier.createBackup(includeAttachments: true);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تم إنشاء: ${rec.path}'), backgroundColor: AppColors.success),
                                );
                              }
                            },
                      icon: const Icon(Icons.backup),
                      label: Text(state.isBusy ? 'جارٍ...' : 'نسخ الآن'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.error.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cleaning_services, color: AppColors.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'بدء مكتب حقيقي بقاعدة نظيفة',
                            style: AppTextStyles.headline6.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يمسح الدعاوى والأشخاص والعقود والشركات والمستندات والمالية وأوامر العمل والبيانات التجريبية، مع الإبقاء على بيانات المكتب وكلمة المرور والقوائم المرجعية السورية.',
                      style: AppTextStyles.bodySmallSecondary,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('مسح البيانات التجريبية وبدء مكتب نظيف'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                        onPressed: state.isBusy ? null : () => _confirmCleanStart(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('النسخ السابقة', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy)),
                        const Spacer(),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.folder_open),
                          label: const Text('مسار خارجي'),
                          onPressed: () async {
                            final controller = TextEditingController(text: state.preferences.externalBackupPath);
                            final path = await showDialog<String>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('مسار النسخ الخارجي / USB'),
                                content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'D:/Backups أو /media/usb')),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('حفظ')),
                                ],
                              ),
                            );
                            if (path != null && path.isNotEmpty) {
                              notifier.setExternalBackupPath(path);
                            }
                          },
                        ),
                      ],
                    ),
                    if (state.preferences.externalBackupPath.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('المسار الخارجي: ${state.preferences.externalBackupPath}', style: AppTextStyles.bodySmallSecondary),
                      ),
                    const Divider(height: 24),
                    if (state.backups.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('لا توجد نسخ سابقة')),
                      )
                    else
                      ...state.backups.map(
                        (b) => Card(
                          child: ListTile(
                            leading: Icon(Icons.archive, color: AppColors.secondaryGold),
                            title: Text(b.path.split('/').last, style: AppTextStyles.labelLarge),
                            subtitle: Text(
                              '${b.type} • ${b.sizeMb.toStringAsFixed(1)} MB • ${b.createdAt.toString().substring(0, 16)}${b.includesAttachments ? ' • مع مرفقات' : ''}',
                              style: AppTextStyles.bodySmallSecondary,
                            ),
                            trailing: ElevatedButton.icon(
                              icon: const Icon(Icons.restore, size: 16),
                              label: const Text('استعادة'),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('تأكيد الاستعادة'),
                                        content: const Text('سيتم اعتماد هذه النسخة كمرجع استعادة. هل تريد المتابعة؟'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('استعادة'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (!ok) return;
                                final success = await notifier.restoreBackup(b.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'تمت الاستعادة' : 'فشلت الاستعادة'),
                                      backgroundColor: success ? AppColors.success : AppColors.error,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCleanStart(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تأكيد مسح البيانات التجريبية'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('سيتم مسح كل بيانات التشغيل الحالية وفتح المكتب كأنه جديد. لا يؤثر ذلك على بيانات المكتب وكلمة المرور والقوائم المرجعية.'),
                const SizedBox(height: 12),
                const Text('للتأكيد اكتب: مسح'),
                const SizedBox(height: 8),
                TextField(controller: controller, autofocus: true),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(ctx, controller.text.trim() == 'مسح'),
                child: const Text('مسح وبدء مكتب نظيف'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('demo_seed_enabled', false);
    ref.read(allowDemoSeedProvider.notifier).state = false;
    await ref.read(databaseProvider).clearOperationalData();

    ref.invalidate(coreDataBootstrapProvider);
    ref.invalidate(uiWorkOrdersProvider);
    ref.invalidate(uiPersonsDirectoryProvider);
    ref.invalidate(allCasesProvider);
    ref.invalidate(allPersonsProvider);
    ref.invalidate(allCompaniesProvider);
    ref.invalidate(allContractsProvider);
    ref.invalidate(allProceduresProvider);
    ref.invalidate(tasksByDateProvider);
    ref.invalidate(openDeficienciesProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم مسح البيانات التجريبية. أصبح المكتب جاهزاً لإدخال الملفات الحقيقية.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _LookupsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courts = ref.watch(settingsHubProvider).courts;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.cardBackground,
          child: Row(
            children: [
              Expanded(
                child: Text('القوائم المرجعية السورية — المحاكم', style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('إضافة محكمة'),
                onPressed: () => _addCourt(context, ref),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courts.length,
            itemBuilder: (context, index) {
              final c = courts[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryNavy,
                    child: Icon(Icons.account_balance, color: AppColors.secondaryGold),
                  ),
                  title: Text(c.name, style: AppTextStyles.labelLarge),
                  subtitle: Text('${c.type} • ${c.city}', style: AppTextStyles.bodySmallSecondary),
                  trailing: Icon(Icons.check_circle, color: c.isActive ? AppColors.success : AppColors.textSecondary),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _addCourt(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    String type = 'بداية';
    String city = 'السويداء';
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('إضافة محكمة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم المحكمة *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                items: ['صلح', 'بداية', 'استئناف', 'نقض', 'شرعية', 'تجارية']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setDialog(() => type = v ?? type),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: city,
                decoration: const InputDecoration(labelText: 'المحافظة'),
                items: ['دمشق', 'السويداء', 'ريف دمشق', 'حلب', 'حمص', 'اللاذقية', 'درعا']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialog(() => city = v ?? city),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                ref.read(settingsHubProvider.notifier).addCourt(
                      SettingsCourtItem(
                        id: 'court_${DateTime.now().microsecondsSinceEpoch}',
                        name: name.text.trim(),
                        type: type,
                        city: city,
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsHubProvider);
    final logs = state.filteredActivity;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'بحث في سجل النشاط...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => ref.read(settingsHubProvider.notifier).setActivityFilter(v),
          ),
        ),
        Expanded(
          child: logs.isEmpty
              ? Center(child: Text('لا أحداث', style: AppTextStyles.bodyMediumSecondary))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final e = logs[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                          child: Icon(_iconFor(e.action), color: AppColors.primaryNavy),
                        ),
                        title: Text('${e.action} • ${e.tableName}', style: AppTextStyles.labelLarge),
                        subtitle: Text(
                          '${e.details}\n${e.userRef} • ${e.timestamp.toString().substring(0, 16)}',
                          style: AppTextStyles.bodySmallSecondary,
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _iconFor(String action) {
    switch (action) {
      case 'login':
        return Icons.login;
      case 'export':
        return Icons.backup;
      case 'import':
        return Icons.restore;
      case 'insert':
        return Icons.add_circle_outline;
      default:
        return Icons.edit;
    }
  }
}

class _UsersRolesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(authRepositoryProvider);
    final current = ref.watch(authControllerProvider).user;
    return FutureBuilder<List<Object>>(
      future: Future.wait<Object>([repo.getUsers(), repo.getRoles()]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data![0] as List;
        final roles = snapshot.data![1] as List;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('المستخدمون والصلاحيات', style: AppTextStyles.headline5.copyWith(color: AppColors.primaryNavy))),
                  ElevatedButton.icon(onPressed: () => _showRoleDialog(context, ref), icon: const Icon(Icons.security), label: const Text('دور جديد')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(onPressed: () => _showUserDialog(context, ref, roles), icon: const Icon(Icons.person_add), label: const Text('مستخدم جديد')),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(title: Text('المستخدمون', style: AppTextStyles.headline6)),
                    ...users.map((dynamic u) => ListTile(
                          leading: Icon(u.isOwner ? Icons.workspace_premium : Icons.person, color: u.isActive ? AppColors.primaryNavy : AppColors.textSecondary),
                          title: Text(u.fullName),
                          subtitle: Text('${u.username} • ${u.roleName} • ${u.isActive ? 'فعال' : 'معطل'}'),
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              if (u.isOwner) const Chip(label: Text('Owner')),
                              IconButton(
                                tooltip: 'تعديل المستخدم',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showUserDialog(context, ref, roles, user: u),
                              ),
                              IconButton(
                                tooltip: 'تغيير كلمة المرور',
                                icon: const Icon(Icons.password),
                                onPressed: () => _showPasswordDialog(context, ref, user: u),
                              ),
                              if (!u.isOwner)
                                Switch(value: u.isActive, onChanged: (v) async { await repo.setUserActive(u.id, v, actor: current); }),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(title: Text('الأدوار', style: AppTextStyles.headline6)),
                    ...roles.map((dynamic r) => ListTile(
                          leading: Icon(r.isSystemRole ? Icons.admin_panel_settings : Icons.badge, color: AppConstants.accentGold),
                          title: Text(r.name),
                          subtitle: Text('مستخدمون: ${r.userCount} • صلاحيات: ${r.permissionCount}${r.description.isNotEmpty ? ' • ${r.description}' : ''}'),
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              TextButton.icon(onPressed: () => _showRoleDialog(context, ref, role: r), icon: const Icon(Icons.edit), label: const Text('تعديل')),
                              TextButton.icon(onPressed: () => _showCopyRoleDialog(context, ref, role: r), icon: const Icon(Icons.copy), label: const Text('نسخ')),
                              if (!r.isSystemRole)
                                Switch(value: r.isActive, onChanged: (v) async {
                                  try { await ref.read(authRepositoryProvider).setRoleActive(r.id, v, actor: ref.read(authControllerProvider).user); }
                                  catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.error)); }
                                }),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUserDialog(BuildContext context, WidgetRef ref, List roles, {dynamic user}) {
    final name = TextEditingController(text: user?.fullName ?? '');
    final username = TextEditingController(text: user?.username ?? '');
    final phone = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    int? roleId = user?.roleId ?? (roles.isNotEmpty ? roles.first.id as int : null);
    final isEdit = user != null;
    showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
      title: Text(isEdit ? 'تعديل مستخدم' : 'إضافة مستخدم'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم الكامل *')),
        const SizedBox(height: 8),
        TextField(controller: username, decoration: const InputDecoration(labelText: 'اسم الدخول *')),
        if (!isEdit) ...[
          const SizedBox(height: 8),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور المؤقتة *')),
        ],
        const SizedBox(height: 8),
        TextField(controller: phone, decoration: const InputDecoration(labelText: 'الهاتف')),
        const SizedBox(height: 8),
        TextField(controller: email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(value: roleId, decoration: const InputDecoration(labelText: 'الدور'), items: roles.map<DropdownMenuItem<int>>((dynamic r) => DropdownMenuItem<int>(value: r.id as int, child: Text(r.name))).toList(), onChanged: (v) => setDialog(() => roleId = v)),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), ElevatedButton(onPressed: () async {
        if (name.text.trim().isEmpty || username.text.trim().isEmpty || roleId == null) return;
        final repo = ref.read(authRepositoryProvider);
        final actor = ref.read(authControllerProvider).user;
        if (isEdit) {
          await repo.updateUser(id: user.id, fullName: name.text.trim(), username: username.text.trim(), roleId: roleId!, phone: phone.text.trim(), email: email.text.trim(), actor: actor);
        } else {
          if (password.text.length < 6) return;
          await repo.createUser(fullName: name.text.trim(), username: username.text.trim(), password: password.text, roleId: roleId!, phone: phone.text.trim(), email: email.text.trim(), actor: actor);
        }
        if (ctx.mounted) Navigator.pop(ctx);
      }, child: const Text('حفظ'))],
    )));
  }

  void _showPasswordDialog(BuildContext context, WidgetRef ref, {required dynamic user}) {
    final password = TextEditingController();
    final confirm = TextEditingController();
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: Text('تغيير كلمة مرور ${user.fullName}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة *')),
        const SizedBox(height: 8),
        TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور *')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (password.text.length < 6 || password.text != confirm.text) return;
          await ref.read(authRepositoryProvider).changeUserPassword(id: user.id, newPassword: password.text, actor: ref.read(authControllerProvider).user);
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('حفظ')),
      ],
    ));
  }

  void _showCopyRoleDialog(BuildContext context, WidgetRef ref, {required dynamic role}) {
    final name = TextEditingController(text: '${role.name} - نسخة');
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('نسخ دور'),
      content: TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الدور الجديد *')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (name.text.trim().isEmpty) return;
          await ref.read(authRepositoryProvider).duplicateRole(role.id, newName: name.text.trim(), actor: ref.read(authControllerProvider).user);
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('نسخ')),
      ],
    ));
  }

  void _showRoleDialog(BuildContext context, WidgetRef ref, {dynamic role}) {
    final name = TextEditingController(text: role?.name ?? '');
    final description = TextEditingController(text: role?.description ?? '');
    final selected = <String>{};
    if (role != null) selected.addAll((role.permissions as Set<String>));
    showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
      title: Text(role == null ? 'إنشاء دور' : 'تعديل دور'),
      content: SizedBox(width: 720, height: 560, child: Column(children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الدور *')),
        const SizedBox(height: 8),
        TextField(controller: description, decoration: const InputDecoration(labelText: 'وصف اختياري')),
        if (role != null && role.userCount > 0) ...[
          const SizedBox(height: 8),
          MaterialBanner(
            content: Text('هذا الدور مستخدم من ${role.userCount} مستخدم/مستخدمين. أي تعديل سيطبق عليهم جميعاً.'),
            actions: const [SizedBox.shrink()],
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: PermissionCatalog.groups.map((g) {
              final groupPermissions = PermissionCatalog.byGroup(g.key);
              final allSelected = groupPermissions.every((p) => selected.contains(p.key));
              final anySelected = groupPermissions.any((p) => selected.contains(p.key));
              return ExpansionTile(
                title: Text(g.label, style: AppTextStyles.labelLarge),
                children: [
                  CheckboxListTile(
                    value: allSelected ? true : (anySelected ? null : false),
                    tristate: true,
                    title: const Text('تحديد كل صلاحيات هذا القسم'),
                    subtitle: Text('عدد الصلاحيات: ${groupPermissions.length}'),
                    secondary: const Icon(Icons.select_all),
                    onChanged: (v) => setDialog(() {
                      if (v == true || !allSelected) {
                        selected.addAll(groupPermissions.map((p) => p.key));
                      } else {
                        selected.removeAll(groupPermissions.map((p) => p.key));
                      }
                    }),
                  ),
                  const Divider(height: 1),
                  ...groupPermissions.map((p) => CheckboxListTile(
                    value: selected.contains(p.key),
                    title: Text(p.label),
                    subtitle: Text(p.description),
                    secondary: p.sensitive ? Icon(Icons.warning_amber, color: AppColors.warning) : null,
                    onChanged: (v) => setDialog(() { if (v == true) selected.add(p.key); else selected.remove(p.key); }),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), ElevatedButton(onPressed: () async {
        if (name.text.trim().isEmpty) return;
        final repo = ref.read(authRepositoryProvider);
        final actor = ref.read(authControllerProvider).user;
        if (role == null) { await repo.createRole(name: name.text.trim(), description: description.text.trim(), permissions: selected, actor: actor); }
        else { await repo.updateRole(id: role.id, name: name.text.trim(), description: description.text.trim(), permissions: selected, actor: actor); }
        if (ctx.mounted) Navigator.pop(ctx);
      }, child: const Text('حفظ'))],
    )));
  }
}

class _AuditTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends ConsumerState<_AuditTab> {
  final _query = TextEditingController();
  String _severity = 'all';
  String _category = 'all';
  String _action = 'all';
  String _user = 'all';
  String _dateRange = 'all';

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(authRepositoryProvider);
    return FutureBuilder<List<Object>>(
      future: Future.wait<Object>([repo.getSessions(), repo.getAuditEvents()]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final sessions = snapshot.data![0] as List;
        final allEvents = snapshot.data![1] as List;
        var events = allEvents;
        final q = _query.text.trim().toLowerCase();
        final now = DateTime.now();
        events = events.where((dynamic e) {
          final okSeverity = _severity == 'all' || e.severity == _severity;
          final okCategory = _category == 'all' || e.category == _category;
          final okAction = _action == 'all' || e.action == _action;
          final okUser = _user == 'all' || e.username == _user;
          bool okDate = true;
          if (_dateRange == 'today') {
            okDate = e.createdAt.year == now.year && e.createdAt.month == now.month && e.createdAt.day == now.day;
          } else if (_dateRange == '7d') {
            okDate = e.createdAt.isAfter(now.subtract(const Duration(days: 7)));
          } else if (_dateRange == '30d') {
            okDate = e.createdAt.isAfter(now.subtract(const Duration(days: 30)));
          }
          final haystack = '${e.fullName} ${e.username} ${e.roleName} ${e.action} ${e.category} ${e.entityTitle} ${e.description}'.toLowerCase();
          final okQuery = q.isEmpty || haystack.contains(q);
          return okSeverity && okCategory && okAction && okUser && okDate && okQuery;
        }).toList();
        final categories = <String>{'all', ...allEvents.map((dynamic e) => e.category as String)}.toList();
        final actions = <String>{'all', ...allEvents.map((dynamic e) => e.action as String)}.toList();
        final users = <String>{'all', ...allEvents.map((dynamic e) => e.username as String)}.toList();
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(tabs: [Tab(text: 'سجل المسؤولية'), Tab(text: 'جلسات الدخول')]),
              Expanded(child: TabBarView(children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _query,
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'بحث في سجل المسؤولية'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: DropdownButtonFormField<String>(value: _severity, decoration: const InputDecoration(labelText: 'الأهمية'), items: const [
                            DropdownMenuItem(value: 'all', child: Text('الكل')),
                            DropdownMenuItem(value: 'info', child: Text('معلومة')),
                            DropdownMenuItem(value: 'warning', child: Text('تحذير')),
                            DropdownMenuItem(value: 'critical', child: Text('حرج')),
                          ], onChanged: (v) => setState(() => _severity = v ?? 'all'))),
                          const SizedBox(width: 8),
                          Expanded(child: DropdownButtonFormField<String>(value: categories.contains(_category) ? _category : 'all', decoration: const InputDecoration(labelText: 'القسم'), items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c == 'all' ? 'الكل' : c))).toList(), onChanged: (v) => setState(() => _category = v ?? 'all'))),
                          const SizedBox(width: 8),
                          Expanded(child: DropdownButtonFormField<String>(value: actions.contains(_action) ? _action : 'all', decoration: const InputDecoration(labelText: 'العملية'), items: actions.map((a) => DropdownMenuItem(value: a, child: Text(a == 'all' ? 'الكل' : a))).toList(), onChanged: (v) => setState(() => _action = v ?? 'all'))),
                          const SizedBox(width: 8),
                          Expanded(child: DropdownButtonFormField<String>(value: users.contains(_user) ? _user : 'all', decoration: const InputDecoration(labelText: 'المستخدم'), items: users.map((u) => DropdownMenuItem(value: u, child: Text(u == 'all' ? 'الكل' : u))).toList(), onChanged: (v) => setState(() => _user = v ?? 'all'))),
                          const SizedBox(width: 8),
                          Expanded(child: DropdownButtonFormField<String>(value: _dateRange, decoration: const InputDecoration(labelText: 'الفترة'), items: const [
                            DropdownMenuItem(value: 'all', child: Text('كل الفترات')),
                            DropdownMenuItem(value: 'today', child: Text('اليوم')),
                            DropdownMenuItem(value: '7d', child: Text('آخر 7 أيام')),
                            DropdownMenuItem(value: '30d', child: Text('آخر 30 يوم')),
                          ], onChanged: (v) => setState(() => _dateRange = v ?? 'all'))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: events.length,
                        itemBuilder: (_, i) {
                          final dynamic e = events[i];
                          return Card(child: ListTile(
                            leading: Icon(e.severity == 'critical' ? Icons.error : e.severity == 'warning' ? Icons.warning : Icons.info_outline, color: e.severity == 'critical' ? AppColors.error : e.severity == 'warning' ? AppColors.warning : AppColors.info),
                            title: Text('${e.fullName} • ${e.action} • ${e.category}'),
                            subtitle: Text('${e.description}\n${e.entityTitle} • ${e.createdAt.toString().substring(0, 16)}'),
                            isThreeLine: true,
                            onTap: () => _showAuditDetails(context, e),
                          ));
                        },
                      ),
                    ),
                  ],
                ),
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (_, i) {
                    final dynamic s = sessions[i];
                    return Card(child: ListTile(
                      leading: Icon(s.status == 'failed' ? Icons.lock : Icons.login, color: s.status == 'failed' ? AppColors.error : AppColors.success),
                      title: Text('${s.fullName.isEmpty ? s.username : s.fullName} • ${s.status}'),
                      subtitle: Text('${s.roleName}\nدخول: ${s.loginAt.toString().substring(0, 16)}${s.logoutAt == null ? '' : ' • خروج: ${s.logoutAt.toString().substring(0, 16)}'}${s.failedReason == null ? '' : ' • ${s.failedReason}'}'),
                      isThreeLine: true,
                    ));
                  },
                ),
              ])),
            ],
          ),
        );
      },
    );
  }

  void _showAuditDetails(BuildContext context, dynamic e) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تفاصيل العملية'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('المستخدم: ${e.fullName} (${e.username})'),
                Text('الدور: ${e.roleName}'),
                Text('الوقت: ${e.createdAt}'),
                Text('القسم: ${e.category}'),
                Text('العملية: ${e.action}'),
                Text('السجل: ${e.entityTitle}'),
                const Divider(),
                Text(e.description),
                if (e.beforeJson != null) ...[
                  const SizedBox(height: 12),
                  Text('قبل التعديل', style: AppTextStyles.labelLarge),
                  SelectableText(e.beforeJson!),
                ],
                if (e.afterJson != null) ...[
                  const SizedBox(height: 12),
                  Text('بعد التعديل', style: AppTextStyles.labelLarge),
                  SelectableText(e.afterJson!),
                ],
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }
}
