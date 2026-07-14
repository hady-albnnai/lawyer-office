import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'person_detail_screen.dart';
import 'person_models.dart';

/// شاشة إدارة الأشخاص والجهات للمرحلة 6.
class PersonsListScreen extends ConsumerStatefulWidget {
  const PersonsListScreen({super.key});

  @override
  ConsumerState<PersonsListScreen> createState() => _PersonsListScreenState();
}

class _PersonsListScreenState extends ConsumerState<PersonsListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<PersonDirectoryRole?> _tabs = const [
    null,
    PersonDirectoryRole.client,
    PersonDirectoryRole.opponent,
    PersonDirectoryRole.opponentLawyer,
    PersonDirectoryRole.notary,
    PersonDirectoryRole.barDelegate,
    PersonDirectoryRole.teamMember,
    PersonDirectoryRole.legalEntity,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(personsDirectoryProvider.notifier).setRoleFilter(_tabs[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {    _cityController.dispose();
    _phoneController.dispose();
    _nameController.dispose();

    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personsDirectoryProvider);

    return Theme(
      data: AppTheme.lightTheme,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
        children: [
          _buildToolbar(state),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((role) => _PersonsTab(role: role)).toList(),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildToolbar(PersonsDirectoryState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'بحث بالاسم، الهوية، الهاتف، المدينة...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => ref.read(personsDirectoryProvider.notifier).setSearchQuery(value),
            ),
          ),
          const SizedBox(width: 12),
          _counterCard('السجلات', state.persons.length, Icons.people, AppColors.primaryNavy),
          const SizedBox(width: 12),
          _counterCard('الوكالات', state.agencies.length, Icons.verified_user, AppColors.secondaryGold),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة سجل'),
            onPressed: () => _openAddPersonDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: AppColors.primaryNavy,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppColors.secondaryGold,
        labelColor: AppColors.secondaryGold,
        unselectedLabelColor: AppColors.textOnLight.withOpacity(0.75),
        labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppTextStyles.labelMedium,
        tabs: const [
          Tab(text: 'الكل'),
          Tab(text: 'الموكلون'),
          Tab(text: 'الخصوم'),
          Tab(text: 'محامو الخصوم'),
          Tab(text: 'كتاب العدل'),
          Tab(text: 'مندوبو النقابة'),
          Tab(text: 'فريق المكتب'),
          Tab(text: 'الشركات والجهات'),
        ],
      ),
    );
  }

  Widget _counterCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text('$title: ', style: AppTextStyles.labelSmall),
          Text('$count', style: AppTextStyles.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }

  void _openAddPersonDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const QuickAddPersonDialog(),
    );
  }
}

class _PersonsTab extends ConsumerWidget {
  final PersonDirectoryRole? role;

  const _PersonsTab({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(personsDirectoryProvider);
    final persons = state.filteredPersons.where((person) => role == null || person.hasRole(role!)).toList();

    if (persons.isEmpty) {
      return _emptyState(
        icon: Icons.person_search,
        title: 'لا توجد سجلات مطابقة',
        subtitle: 'غيّر البحث أو أضف سجلاً جديداً من الزر العلوي.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: persons.length,
      itemBuilder: (context, index) => PersonDirectoryCard(person: persons[index]),
    );
  }

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.headline5),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.bodySmallSecondary),
        ],
      ),
    );
  }
}

class PersonDirectoryCard extends StatelessWidget {
  final PersonDirectoryRecord person;

  const PersonDirectoryCard({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PersonDetailScreen(personId: person.id)),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: person.kind == PersonDirectoryKind.legal
                    ? AppColors.primaryNavy.withOpacity(0.12)
                    : AppColors.secondaryGold.withOpacity(0.18),
                child: Icon(person.kind.icon, color: person.kind == PersonDirectoryKind.legal ? AppColors.primaryNavy : AppColors.secondaryGold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(person.fullName, style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy))),
                        _kindBadge(person.kind.displayName),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: person.roles.map((role) => _roleBadge(role)).toList(),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _iconText(Icons.phone, person.phone.isEmpty ? 'لا يوجد هاتف' : person.phone),
                        _iconText(Icons.location_on, person.city.isEmpty ? 'غير محدد' : person.city),
                        _iconText(Icons.verified_user, 'وكالات: ${person.agencyIds.length}'),
                        _iconText(Icons.gavel, 'دعاوى: ${person.caseIds.length}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('آخر تحديث: ${_formatDate(person.updatedAt)}', style: AppTextStyles.bodySmallSecondary),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kindBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }

  Widget _roleBadge(PersonDirectoryRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: role.color.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
      child: Text(role.displayName, style: AppTextStyles.labelSmall.copyWith(color: role.color)),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.bodySmallSecondary),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class QuickAddPersonDialog extends ConsumerStatefulWidget {
  const QuickAddPersonDialog({super.key});

  @override
  ConsumerState<QuickAddPersonDialog> createState() => _QuickAddPersonDialogState();
}

class _QuickAddPersonDialogState extends ConsumerState<QuickAddPersonDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController(text: 'دمشق');
  PersonDirectoryKind _kind = PersonDirectoryKind.natural;
  PersonDirectoryRole _role = PersonDirectoryRole.client;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة سجل سريع'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل / اسم الجهة')),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'الهاتف')),
            const SizedBox(height: 12),
            TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'المدينة')),
            const SizedBox(height: 12),
            DropdownButtonFormField<PersonDirectoryKind>(
              value: _kind,
              decoration: const InputDecoration(labelText: 'نوع السجل'),
              items: PersonDirectoryKind.values.map((kind) => DropdownMenuItem(value: kind, child: Text(kind.displayName))).toList(),
              onChanged: (value) => setState(() => _kind = value ?? _kind),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PersonDirectoryRole>(
              value: _role,
              decoration: const InputDecoration(labelText: 'الدور'),
              items: PersonDirectoryRole.values.map((role) => DropdownMenuItem(value: role, child: Text(role.displayName))).toList(),
              onChanged: (value) => setState(() => _role = value ?? _role),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('الاسم إلزامي'), backgroundColor: AppColors.error));
      return;
    }

    final now = DateTime.now();
    ref.read(personsDirectoryProvider.notifier).addPerson(
          PersonDirectoryRecord(
            id: 'person_${now.microsecondsSinceEpoch}',
            kind: _kind,
            fullName: name,
            phone: _phoneController.text.trim(),
            city: _cityController.text.trim(),
            roles: [_role],
            createdAt: now,
            updatedAt: now,
            timeline: [
              DirectoryTimelineEvent(
                id: 'created_${now.microsecondsSinceEpoch}',
                title: 'إضافة سجل',
                description: 'تمت إضافة السجل من شاشة الأشخاص والجهات.',
                type: 'created',
                date: now,
              ),
            ],
          ),
        );
    Navigator.of(context).pop();
  }
}
