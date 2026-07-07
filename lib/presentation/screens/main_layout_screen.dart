import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../providers/office_settings_provider.dart';

/// الشاشة الرئيسية وتخطيط الملاحة العام لتطبيقات إدارة مكتب المحاماة السوري (V6.2)
class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(officeSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: settingsAsync.when(
          data: (settings) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                settings.officeTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                settings.lawyerName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.accentGold),
              ),
            ],
          ),
          loading: () => const Text('مكتب المحامي', style: TextStyle(fontSize: 18)),
          error: (_, __) => const Text('مكتب المحامي • هادي فيصل البني'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, color: AppConstants.accentGold),
            tooltip: 'تنبيهات المواعيد والنواقص',
            onPressed: () {
              // سيتم ربط شاشة التنبيهات لاحقاً
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // شريط الملاحة الجانبي المخصص للشاشات العريضة (Windows / Tablet)
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: AppConstants.primaryNavy,
            selectedIconTheme: const IconThemeData(color: AppConstants.accentGold, size: 28),
            unselectedIconTheme: const IconThemeData(color: Colors.white70, size: 24),
            selectedLabelTextStyle: const TextStyle(
              color: AppConstants.accentGold,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: AppConstants.defaultPrintFont,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.normal,
              fontSize: 12,
              fontFamily: AppConstants.defaultPrintFont,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: Text('جديد ➕'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: Text('الأرشيف 📁'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: Text('الأعمال اليومية 📅'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('فريق المكتب 👥'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: Text('البحث 🔍'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('الإعدادات ⚙️'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFDEE2E6)),
          
          // محتوى التبويب النشط
          Expanded(
            child: _buildBodyContent(_selectedIndex, settingsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(int index, AsyncValue<OfficeSettingsModel> settingsAsync) {
    switch (index) {
      case 0:
        return _buildNewWorkDashboard(settingsAsync);
      case 1:
        return const Center(child: Text('تبويب الأرشيف العام 📁 (قيد البناء - المرحلة 4 و 6)'));
      case 2:
        return const Center(child: Text('تبويب الأعمال اليومية 📅 (قيد البناء - المرحلة 7)'));
      case 3:
        return const Center(child: Text('تبويب فريق المكتب والموكلين 👥 (قيد البناء - المرحلة 4)'));
      case 4:
        return const Center(child: Text('تبويب البحث المتقدم 🔍 (قيد البناء - المرحلة 7)'));
      case 5:
        return _buildSettingsPreview(settingsAsync);
      default:
        return const Center(child: Text('شاشة غير معرفة'));
    }
  }

  /// لوحة البدء السريع (تبويب جديد ➕)
  Widget _buildNewWorkDashboard(AsyncValue<OfficeSettingsModel> settingsAsync) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          settingsAsync.when(
            data: (settings) => Card(
              color: AppConstants.primaryNavy,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: AppConstants.accentGold,
                      child: Icon(Icons.balance, size: 36, color: AppConstants.primaryNavy),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.officeTitle,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'الأستاذ: ${settings.lawyerName}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.accentGold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            settings.officeAddress,
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppConstants.accentGold),
                      ),
                      child: const Text(
                        'النسخة 6.2 (Offline-First)',
                        style: TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('حدث خطأ في تحميل بيانات المكتب'),
          ),
          const SizedBox(height: 32),
          
          const Text(
            'البدء بعمل جديد في المكتب:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard(
                  title: 'دعوى قضائية',
                  subtitle: 'مدني، جزائي، شرعي، تجاري',
                  icon: Icons.gavel,
                  color: const Color(0xFF1B4F72),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سيتم فتح معالج إنشاء دعوى جديدة (المرحلة 5)')),
                    );
                  },
                ),
                _buildActionCard(
                  title: 'إجراء إداري',
                  subtitle: 'أحوال شخصية، عقاري، تجاري',
                  icon: Icons.assignment_outlined,
                  color: const Color(0xFF117A65),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سيتم فتح معالج الإجراءات الإدارية (المرحلة 6)')),
                    );
                  },
                ),
                _buildActionCard(
                  title: 'تأسيس شركة',
                  subtitle: 'أشخاص، أموال، محدودة',
                  icon: Icons.business_outlined,
                  color: const Color(0xFF9C640C),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سيتم فتح معالج تأسيس الشركات (المرحلة 6)')),
                    );
                  },
                ),
                _buildActionCard(
                  title: 'تنظيم عقد',
                  subtitle: 'بيع، إيجار، عمل مع ربط Word',
                  icon: Icons.description_outlined,
                  color: const Color(0xFF6C3483),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سيتم فتح معالج تنظيم العقود (المرحلة 6)')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// معاينة سريعة لإعدادات المكتب وتعديلها (تبويب الإعدادات ⚙️)
  Widget _buildSettingsPreview(AsyncValue<OfficeSettingsModel> settingsAsync) {
    return settingsAsync.when(
      data: (settings) {
        final titleController = TextEditingController(text: settings.officeTitle);
        final lawyerController = TextEditingController(text: settings.lawyerName);
        final addressController = TextEditingController(text: settings.officeAddress);
        final phoneController = TextEditingController(text: settings.officePhone);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.settings_applications, color: AppConstants.primaryNavy, size: 32),
                        SizedBox(width: 12),
                        Text(
                          'تعديل بيانات وإعدادات المكتب الأساسية:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'اسم التطبيق / المكتب',
                        hintText: 'مثال: مكتب المحامي',
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: lawyerController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المحامي الأستاذ',
                        hintText: 'مثال: هادي فيصل البني',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان المكتب',
                        hintText: 'مثال: سوريا - السويداء / دمشق',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف / الواتساب الرسمي',
                        hintText: 'مثال: 0999000000',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('حفظ الإعدادات وتحديث الواجهة الفوري'),
                        onPressed: () async {
                          await ref.read(officeSettingsProvider.notifier).updateSettings(
                            newTitle: titleController.text.trim(),
                            newLawyerName: lawyerController.text.trim(),
                            newAddress: addressController.text.trim(),
                            newPhone: phoneController.text.trim(),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم حفظ وتحديث بيانات المكتب بنجاح!'),
                                backgroundColor: AppConstants.statusSuccess,
                              ),
                            );
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
      error: (err, _) => Center(child: Text('خطأ في تحميل الإعدادات: $err')),
    );
  }
}
