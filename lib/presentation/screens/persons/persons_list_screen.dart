import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/app_enums.dart';
import '../../../data/database/database.dart';
import '../../providers/app_providers.dart';
import 'add_person_dialog.dart';

/// شاشة إدارة الأفراد والجهات الاعتبارية وفريق المكتب (PersonsListScreen)
class PersonsListScreen extends ConsumerStatefulWidget {
  const PersonsListScreen({super.key});

  @override
  ConsumerState<PersonsListScreen> createState() => _PersonsListScreenState();
}

class _PersonsListScreenState extends ConsumerState<PersonsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط الأدوات العلوي والبحث
        Container(
          padding: const EdgeInsets.all(16),
          color: AppConstants.surfaceWhite,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'بحث بالاسم، الهوية، أو رقم الهاتف...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('إضافة سجل شخص أو جهة'),
                onPressed: () => _openAddDialog(),
              ),
            ],
          ),
        ),
        
        // شريط التبويبات الفئوي
        Container(
          color: AppConstants.primaryNavy,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppConstants.accentGold,
            labelColor: AppConstants.accentGold,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: 'الكل (عام)'),
              Tab(text: 'الموكلون'),
              Tab(text: 'الخصوم'),
              Tab(text: 'محامو الأخصام'),
              Tab(text: 'كتاب العدل والمندوبون'),
              Tab(text: 'فريق المكتب'),
            ],
          ),
        ),

        // قائمة السجلات حسب التبويب المختار
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPersonsList(null),
              _buildPersonsList(PersonRoleType.client),
              _buildPersonsList(PersonRoleType.opponent),
              _buildOpponentLawyersList(),
              _buildNotariesList(),
              _buildTeamList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonsList(PersonRoleType? filterRole) {
    final personsAsync = ref.watch(allPersonsProvider(null));

    return personsAsync.when(
      data: (persons) {
        final filtered = persons.where((p) {
          final matchesSearch = p.fullName.toLowerCase().contains(_searchQuery) ||
              (p.nationalId?.contains(_searchQuery) ?? false) ||
              (p.phone1?.contains(_searchQuery) ?? false);
          return matchesSearch;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('لا توجد سجلات مطابقة للبحث الحالي'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final person = filtered[index];
            final isLegal = person.type == PersonType.legal.index;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLegal ? AppConstants.primaryNavy : AppConstants.accentGold,
                  child: Icon(
                    isLegal ? Icons.business : Icons.person,
                    color: isLegal ? AppConstants.accentGold : AppConstants.primaryNavy,
                  ),
                ),
                title: Text(
                  person.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  '${isLegal ? "شخص اعتباري (جهة/شركة)" : "شخص طبيعي"} • الهاتف: ${person.phone1 ?? "غير مدخل"}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('عرض ملف الشخص: ${person.fullName}')),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('خطأ في جلب البيانات: $err')),
    );
  }

  Widget _buildOpponentLawyersList() {
    return const Center(child: Text('دليل محامي الأخصام (قائمة الأستاذة الزملاء)'));
  }

  Widget _buildNotariesList() {
    return const Center(child: Text('دليل كتاب العدل ومندوبي فروع النقابة الـ 14'));
  }

  Widget _buildTeamList() {
    return const Center(child: Text('فريق المكتب (المحامي الأستاذ، المتمرن، معقب المعاملات، وموظفة المكتب)'));
  }

  void _openAddDialog() {
    PersonRoleType? defaultRole;
    if (_tabController.index == 1) defaultRole = PersonRoleType.client;
    if (_tabController.index == 2) defaultRole = PersonRoleType.opponent;

    showDialog(
      context: context,
      builder: (context) => AddPersonDialog(defaultRole: defaultRole),
    );
  }
}
