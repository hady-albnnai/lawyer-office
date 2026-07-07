import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/database/database.dart';
import '../../providers/app_providers.dart';
import 'create_case_wizard.dart';
import 'case_detail_screen.dart';

/// شاشة إدارة وقائمة ملفات الدعاوى القضائية في المكتب (CasesListScreen)
class CasesListScreen extends ConsumerStatefulWidget {
  const CasesListScreen({super.key});

  @override
  ConsumerState<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends ConsumerState<CasesListScreen> {
  String _searchQuery = '';
  String _selectedCategoryFilter = 'الكل';

  final List<String> _categories = ['الكل', 'مدني', 'جزائي', 'شرعي', 'تجاري', 'إداري'];

  @override
  Widget build(BuildContext context) {
    final casesAsync = ref.watch(allCasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('أرشيف وملفات الدعاوى القضائية في المكتب'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGold, foregroundColor: AppConstants.primaryNavy),
            icon: const Icon(Icons.add_business),
            label: const Text('فتح ملف دعوى جديدة'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CreateCaseWizard()),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث والفلترة
          Container(
            padding: const EdgeInsets.all(16),
            color: AppConstants.surfaceWhite,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'بحث برقم الملف الداخلي (2026/001)، رقم الأساس، أو الموضوع...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedCategoryFilter,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text('تصنيف: $c'))).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryFilter = val!),
                ),
              ],
            ),
          ),

          // قائمة ملفات الدعاوى
          Expanded(
            child: casesAsync.when(
              data: (cases) {
                final filtered = cases.where((c) {
                  final matchesCat = _selectedCategoryFilter == 'الكل' || c.caseType == _selectedCategoryFilter;
                  final matchesSearch = c.internalNumber.toLowerCase().contains(_searchQuery) ||
                      (c.baseNumber?.toLowerCase().contains(_searchQuery) ?? false) ||
                      (c.subject?.toLowerCase().contains(_searchQuery) ?? false);
                  return matchesCat && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off_outlined, size: 64, color: AppConstants.textMuted),
                        SizedBox(height: 16),
                        Text('لا توجد ملفات دعاوى مطابقة للبحث الحالي', style: TextStyle(fontSize: 18, color: AppConstants.textMuted)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    final isClosed = c.status == 'closed';
                    final isUrgent = c.isUrgent;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isUrgent ? AppConstants.statusDanger : AppConstants.primaryNavy.withOpacity(0.2),
                          width: isUrgent ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: isClosed ? Colors.grey : AppConstants.primaryNavy,
                          child: Text(
                            c.internalNumber.split('/').last,
                            style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'ملف رقم [${c.internalNumber}] • ${c.caseType} (${c.subType ?? "بداية"})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppConstants.primaryNavy),
                            ),
                            const SizedBox(width: 12),
                            if (isUrgent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppConstants.statusDanger, borderRadius: BorderRadius.circular(4)),
                                child: const Text('مستعجل ⚠️', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text('الموضوع: ${c.subject ?? "غير محدد"} • رقم الأساس: ${c.baseNumber ?? "بانتظار التسجيل"}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_month, size: 16, color: AppConstants.accentGold),
                                const SizedBox(width: 4),
                                Text(
                                  c.nextSessionDate != null
                                      ? 'الجلسة القادمة: ${c.nextSessionDate!.toString().substring(0, 10)}'
                                      : 'الموعد القادم: بانتظار التحديد ⚠️',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: c.nextSessionDate != null ? AppConstants.primaryNavy : AppConstants.statusDanger,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: AppConstants.primaryNavy),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => CaseDetailScreen(caseId: c.id)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('خطأ في تحميل ملفات الدعاوى: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
