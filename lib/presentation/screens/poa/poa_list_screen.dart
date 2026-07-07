import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/app_enums.dart';
import '../../../data/database/database.dart';
import '../../providers/app_providers.dart';
import 'add_poa_dialog.dart';

/// شاشة إدارة الأرشيف العام للوكالات القضائية (PoaListScreen)
class PoaListScreen extends ConsumerWidget {
  const PoaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // جلب الوكالات من المزود
    final poasAsync = ref.watch(poaRepositoryProvider).watchAllPoas();

    return Scaffold(
      appBar: AppBar(
        title: const Text('أرشيف الوكالات القضائية والقانونية في المكتب'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentGold, foregroundColor: AppConstants.primaryNavy),
            icon: const Icon(Icons.add),
            label: const Text('إصدار وكالة جديدة'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddPoaDialog(),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<PowersOfAttorneyData>>(
        stream: poasAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل أرشيف الوكالات: ${snapshot.error}'));
          }
          final poas = snapshot.data ?? [];
          if (poas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_shared_outlined, size: 64, color: AppConstants.textMuted),
                  SizedBox(height: 16),
                  Text('أرشيف الوكالات فارغ حالياً', style: TextStyle(fontSize: 18, color: AppConstants.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: poas.length,
            itemBuilder: (context, index) {
              final poa = poas[index];
              final poaTypeEnum = PoaType.values[poa.poaType];

              return Card(
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppConstants.primaryNavy,
                    child: Icon(
                      poa.sourceType == 'delegate' ? Icons.account_balance : Icons.gavel,
                      color: AppConstants.accentGold,
                    ),
                  ),
                  title: Text(
                    '${poaTypeEnum.label} • رقم التوثيق: ${poa.poaNumber ?? "بدون رقم"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    'جهة التنظيم: ${poa.sourceType == "delegate" ? "مندوب فرع نقابة ${poa.delegateBranch ?? ""}" : "دائرة الكاتب بالعدل"} • التاريخ: ${poa.poaDate?.toString().substring(0, 10) ?? "غير محدد"}',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: poa.filePath != null ? AppConstants.statusSuccess.withOpacity(0.15) : AppConstants.statusDanger.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: poa.filePath != null ? AppConstants.statusSuccess : AppConstants.statusDanger),
                    ),
                    child: Text(
                      poa.filePath != null ? 'صورة مرفقة ✓' : 'صورة ناقصة ⚠️',
                      style: TextStyle(
                        color: poa.filePath != null ? AppConstants.statusSuccess : AppConstants.statusDanger,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('عرض تفاصيل الوكالة رقم: ${poa.poaNumber}')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
