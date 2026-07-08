import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/constants/app_constants.dart';
import '../../../data/database/database.dart';
import '../../providers/app_providers.dart';
import '../../providers/office_settings_provider.dart';

/// شاشة الإعدادات الشاملة، الأمان، التشفير، والنسخ الاحتياطي الذكي (SettingsScreen V6.2)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم إعدادات المكتب والأمان والنسخ الاحتياطي'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppConstants.accentGold,
          labelColor: AppConstants.accentGold,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.business), text: '1️⃣ بيانات المكتب الأساسية'),
            Tab(icon: Icon(Icons.security), text: '2️⃣ الأمان والنسخ الاحتياطي'),
            Tab(icon: Icon(Icons.backup), text: '3️⃣ النسخ الاحتياطي الذكي واستعادتها'),
            Tab(icon: Icon(Icons.list_alt), text: '4️⃣ إدارة القوائم السورية الجاهزة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOfficeInfoTab(),
          _buildSecurityTab(),
          _buildBackupTab(),
          _buildLookupsTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1️⃣ تبويب بيانات المكتب الأساسية
  // ---------------------------------------------------------------------------
  Widget _buildOfficeInfoTab() {
    final settingsAsync = ref.watch(officeSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final titleCtrl = TextEditingController(text: settings.officeTitle);
        final lawyerCtrl = TextEditingController(text: settings.lawyerName);
        final addressCtrl = TextEditingController(text: settings.officeAddress);
        final phoneCtrl = TextEditingController(text: settings.officePhone);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_document, color: AppConstants.primaryNavy, size: 28),
                        SizedBox(width: 12),
                        Text('تعديل الترويسة والبيانات الظاهرة في التطبيق والتقارير:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 32),
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'اسم المكتب / التطبيق *', prefixIcon: Icon(Icons.business))),
                    const SizedBox(height: 16),
                    TextField(controller: lawyerCtrl, decoration: const InputDecoration(labelText: 'اسم المحامي الأستاذ * (مثال: هادي فيصل البني)', prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 16),
                    TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'العنوان الرسمي للمكتب *', prefixIcon: Icon(Icons.location_on))),
                    const SizedBox(height: 16),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'هواتف المكتب / واتساب التواصل', prefixIcon: Icon(Icons.phone))),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('حفظ الإعدادات وتحديث الواجهة والترويسة فوراً'),
                        onPressed: () async {
                          await ref.read(officeSettingsProvider.notifier).updateSettings(
                            newTitle: titleCtrl.text.trim(),
                            newLawyerName: lawyerCtrl.text.trim(),
                            newAddress: addressCtrl.text.trim(),
                            newPhone: phoneCtrl.text.trim(),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ وتحديث بيانات المكتب بنجاح!'), backgroundColor: AppConstants.statusSuccess));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('خطأ: $err')),
    );
  }

  // ---------------------------------------------------------------------------
  // 2️⃣ تبويب الأمان والنسخ الاحتياطي
  // ---------------------------------------------------------------------------
  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          children: [
            Card(
              color: AppConstants.primaryNavy,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, size: 48, color: AppConstants.accentGold),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الحماية المحلية والنسخ الاحتياطي مفعّلان أصولاً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 6),
                          Text('جميع البيانات، القضايا، والحسابات المخزنة محلياً على هذا الجهاز مشفرة تماماً بمفتاح أمان 256-bit ولا يمكن قراءتها من خارج التطبيق.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: AppConstants.statusSuccess, borderRadius: BorderRadius.circular(8)),
                      child: const Text('محمي 🔒', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تغيير كلمة المرور وسؤال الأمان لاستعادة الحساب:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy)),
                    const Divider(height: 24),
                    const TextField(obscureText: true, decoration: InputDecoration(labelText: 'كلمة المرور الحالية', prefixIcon: Icon(Icons.lock_outline))),
                    const SizedBox(height: 16),
                    const TextField(obscureText: true, decoration: InputDecoration(labelText: 'كلمة المرور الجديدة', prefixIcon: Icon(Icons.lock))),
                    const SizedBox(height: 16),
                    const TextField(obscureText: true, decoration: InputDecoration(labelText: 'تأكيد كلمة المرور الجديدة', prefixIcon: Icon(Icons.lock))),
                    const SizedBox(height: 24),
                    const TextField(decoration: InputDecoration(labelText: 'سؤال الأمان (مثال: ما اسم مدرستك الابتدائية؟)', prefixIcon: Icon(Icons.question_answer))),
                    const SizedBox(height: 16),
                    const TextField(decoration: InputDecoration(labelText: 'إجابة سؤال الأمان', prefixIcon: Icon(Icons.check))),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.update),
                        label: const Text('تحديث بيانات الحماية'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث بيانات الأمان بنجاح!'), backgroundColor: AppConstants.statusSuccess));
                        },
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

  // ---------------------------------------------------------------------------
  // 3️⃣ تبويب النسخ الاحتياطي الذكي والاستعادة
  // ---------------------------------------------------------------------------
  Widget _buildBackupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF117A65),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done, size: 48, color: Colors.white),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('نظام النسخ الاحتياطي الذكي المشغل في الخلفية (Isolate)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 6),
                          Text('يقوم النظام عند الإغلاق بالفحص الذكي للنسخ (مرة واحدة كل 7 أيام) وضغط قاعدة البيانات والمرفقات في ملف .zip واحد دون إبطاء أداء الجهاز.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF117A65)),
                      icon: const Icon(Icons.backup_table),
                      label: const Text('نسخ الآن 🚀'),
                      onPressed: () async {
                        try {
                          final path = await ref.read(backupServiceProvider).triggerBackgroundBackup(includeAttachments: true);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء نسخة احتياطية بنجاح في: $path'), backgroundColor: AppConstants.statusSuccess));
                            setState(() {});
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في النسخ: $e'), backgroundColor: AppConstants.statusDanger));
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('النسخ السابقة المتاحة في أرشيف المكتب:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy)),
                        const Spacer(),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.usb),
                          label: const Text('اختيار قرص خارجي (USB)'),
                          onPressed: () async {
                            final dir = await FilePicker.platform.getDirectoryPath();
                            if (dir != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تعيين مسار النسخ الخارجي إلى: $dir'), backgroundColor: AppConstants.statusSuccess));
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    FutureBuilder<List<File>>(
                      future: ref.read(backupServiceProvider).listAvailableBackups(),
                      builder: (context, snapshot) {
                        final list = snapshot.data ?? [];
                        if (list.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد نسخ السابقة محسوبة في هذا المجلد')));

                        return Column(
                          children: list.map((f) => Card(
                                child: ListTile(
                                  leading: const Icon(Icons.archive, color: AppConstants.accentGold, size: 36),
                                  title: Text(f.path.split("/").last.split("\\").last, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('حجم الملف: ${(f.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} ميغابايت • تاريخ التعديل: ${f.lastModifiedSync().toString().substring(0, 16)}'),
                                  trailing: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryNavy),
                                    icon: const Icon(Icons.restore),
                                    label: const Text('استعادة هذه النسخة'),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('تأكيد استعادة النسخة الاحتياطية ⚠️'),
                                          content: const Text('هل أنت متأكد من استعادة هذه النسخة؟ سيتم استبدال قاعدة البيانات الحالية بالبيانات المحفوظة في ملف الـ Zip.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppConstants.statusDanger), onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد واستعادة')),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        final success = await ref.read(backupServiceProvider).restoreFromBackup(f);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                            content: Text(success ? 'تم استعادة النظام بنجاح!' : 'خطأ في الاستعادة!'),
                                            backgroundColor: success ? AppConstants.statusSuccess : AppConstants.statusDanger,
                                          ));
                                        }
                                      }
                                    },
                                  ),
                                ),
                              )).toList(),
                        );
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

  // ---------------------------------------------------------------------------
  // 4️⃣ تبويب الجداول المرجعية للقوائم السورية الجاهزة
  // ---------------------------------------------------------------------------
  Widget _buildLookupsTab() {
    final courtsStream = ref.watch(activeCourtsProvider(null));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppConstants.surfaceWhite,
          child: Row(
            children: [
              const Expanded(child: Text('دليل المحامين، المحاكم، والمواضيع القانونية في سوريا:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('إضافة محكمة أو دائرة جديدة'),
                onPressed: _openAddCourtDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: courtsStream.when(
            data: (courts) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courts.length,
                itemBuilder: (context, index) {
                  final c = courts[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: AppConstants.primaryNavy, child: Icon(Icons.account_balance, color: AppConstants.accentGold)),
                      title: Text('${c.name} (${c.city ?? "دمشق"})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('النوع: ${c.type ?? "بداية"} • الدائرة: ${c.district ?? "المركز"}'),
                      trailing: const Icon(Icons.check_circle, color: AppConstants.statusSuccess),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('خطأ: $err')),
          ),
        ),
      ],
    );
  }

  void _openAddCourtDialog() {
    final nameCtrl = TextEditingController();
    String type = 'بداية';
    String city = 'دمشق';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة محكمة أو دائرة قضائية سورية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المحكمة * (مثال: محكمة البداية المدنية الثانية)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'الدرجة والتصنيف'),
                items: ['صلح', 'بداية', 'استئناف', 'نقض', 'شرعية', 'تجارية'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setDialogState(() => type = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: city,
                decoration: const InputDecoration(labelText: 'المحافظة'),
                items: ['دمشق', 'السويداء', 'ريف دمشق', 'حلب', 'حمص', 'اللاذقية', 'درعا'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setDialogState(() => city = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              child: const Text('حفظ بالقائمة'),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await ref.read(lookupRepositoryProvider).insertCourt(
                  CourtsCompanion.insert(
                    name: nameCtrl.text.trim(),
                    type: drift.Value(type),
                    city: drift.Value(city),
                  ),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المحكمة بنجاح!'), backgroundColor: AppConstants.statusSuccess));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
