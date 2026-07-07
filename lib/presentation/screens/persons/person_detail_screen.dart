import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/app_enums.dart';
import '../../../data/database/database.dart';
import '../../providers/app_providers.dart';

/// شاشة تفاصيل ملف الشخص أو الجهة الاعتبارية (PersonDetailScreen)
/// تعرض كافة القضايا، العقود، الشركات، والوكالات المرتبطة بهذا السجل في المكتب.
class PersonDetailScreen extends ConsumerStatefulWidget {
  final int personId;
  const PersonDetailScreen({super.key, required this.personId});

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personRepo = ref.watch(personRepositoryProvider);

    return FutureBuilder<PersonEntity?>(
      future: personRepo.getPersonById(widget.personId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final person = snapshot.data;
        if (person == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('الملف غير موجود')),
            body: const Center(child: Text('لم يتم العثور على بيانات هذا السجل في المكتب.')),
          );
        }

        final isLegal = person.type == PersonType.legal.index;

        return Scaffold(
          appBar: AppBar(
            title: Text('سجل: ${person.fullName}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'تعديل السجل',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تعديل بيانات السجل...')),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppConstants.accentGold,
              labelColor: AppConstants.accentGold,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'الملخص والبيانات'),
                Tab(text: 'الدعاوى القضائية'),
                Tab(text: 'العقود والاتفاقيات'),
                Tab(text: 'الشركات المرتبطة'),
                Tab(text: 'الخط الزمني للسجل'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(person, isLegal),
              _buildLinkedCasesTab(person.id),
              _buildLinkedContractsTab(person.id),
              _buildLinkedCompaniesTab(person.id),
              _buildTimelineTab(person.id),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab(PersonEntity person, bool isLegal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppConstants.primaryNavy,
                    child: Icon(
                      isLegal ? Icons.business : Icons.person,
                      size: 44,
                      color: AppConstants.accentGold,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.fullName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isLegal ? 'شخص اعتباري (جهة عامة / شركة / جمعية)' : 'شخص طبيعي • الجنسية: ${person.nationality}',
                          style: const TextStyle(fontSize: 15, color: AppConstants.textMuted, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: AppConstants.accentGold),
                            const SizedBox(width: 6),
                            Text(person.phone1 ?? 'الهاتف أساسي: غير مدخل'),
                            const SizedBox(width: 20),
                            const Icon(Icons.chat, size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(person.whatsapp ?? 'واتساب: غير مدخل'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text('البيانات التفصيلية في أرشيف المكتب:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy)),
          const SizedBox(height: 12),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (!isLegal) ...[
                    _buildDetailRow('اسم الأب:', person.fatherName ?? '---'),
                    _buildDetailRow('اسم الأم:', person.motherName ?? '---'),
                    _buildDetailRow('الرقم الوطني:', person.nationalId ?? '---'),
                    _buildDetailRow('محل ورقم القيد المدني:', '${person.registryPlace ?? ""} - رقم ${person.registryNumber ?? ""}'),
                    _buildDetailRow('المهنة / العمل:', person.profession ?? '---'),
                  ],
                  _buildDetailRow('العنوان الدائم:', person.permanentAddress ?? '---'),
                  _buildDetailRow('ملاحظات وسجل التعارف:', person.notes ?? 'لا توجد ملاحظات خاصة'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppConstants.textDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedCasesTab(int personId) {
    return const Center(child: Text('قائمة القضايا المرتبطة بهذا السجل (سيتم التوصيل بالمرحلة 5)'));
  }

  Widget _buildLinkedContractsTab(int personId) {
    return const Center(child: Text('قائمة العقود والاتفاقيات المرتبطة (سيتم التوصيل بالمرحلة 6)'));
  }

  Widget _buildLinkedCompaniesTab(int personId) {
    return const Center(child: Text('الشركات والحصص المرتبطة بهذا السجل (سيتم التوصيل بالمرحلة 6)'));
  }

  Widget _buildTimelineTab(int personId) {
    return const Center(child: Text('الخط الزمني الشامل لهذا الشخص في المكتب (سيتم التوصيل بالمرحلة 7)'));
  }
}
