/// شاشة قائمة الدعاوى
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'case_models.dart';
import 'document_viewer.dart';

class CasesScreen extends ConsumerWidget {
  const CasesScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(appBar: AppBar(title: const Text('الدعاوى'), actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => context.go('/search-reports'), tooltip: 'بحث'), IconButton(icon: const Icon(Icons.filter_alt), onPressed: () => showDialog(context: context, builder: (c) => const CasesFilterDialog()), tooltip: 'فلترة'), IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/new-work'), tooltip: 'دعوى جديدة')]), body: Column(children: [_buildQuickFilterBar(context, ref), Expanded(child: _buildCaseList(context, ref))]), floatingActionButton: FloatingActionButton(onPressed: () => context.go('/new-work'), tooltip: 'دعوى جديدة', child: const Icon(Icons.add)));
  }
  Widget _buildQuickFilterBar(BuildContext c, WidgetRef r) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.cardBackground, border: Border.all(color: AppColors.cardBorder, width: 0.5)), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_buildChip(c, r, 'الكل', null), _buildChip(c, r, 'عاملة', CaseStatus.scheduled), _buildChip(c, r, 'ناقصة', null, d: true), _buildChip(c, r, 'متأخرة', null, o: true), _buildChip(c, r, 'منتهية', CaseStatus.completed), _buildChip(c, r, 'بانتظار رقم أساس', null, p: true), _buildChip(c, r, 'جلسة قريب', null, s: true)])));
  Widget _buildChip(BuildContext c, WidgetRef r, String l, CaseStatus? s, {bool d=false, bool o=false, bool p=false, bool ss=false}) {
    final cases = r.watch(casesProvider);
    int count = 0;
    if(s != null) count = cases.where((x) => x.status == s).length;
    else if(d) count = cases.where((x) => x.openDeficienciesCount > 0).length;
    else if(o) count = cases.where((x) => x.nextSession?.sessionDate.isBefore(DateTime.now()) ?? false).length;
    else if(p) count = cases.where((x) => x.baseNumber == null || x.baseNumber!.isEmpty).length;
    else if(ss) count = cases.where((x) => x.nextSession != null).length;
    else count = cases.length;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: FilterChip(label: Text('$l${count > 0 ? " ($count)" : ""}', style: AppTextStyles.bodySmall), selected: false, onSelected: (x) {}, backgroundColor: AppColors.cardBackground, labelStyle: AppTextStyles.bodySmall.copyWith(color: count > 0 ? AppColors.primaryNavy : AppColors.textSecondary)));
  }
  Widget _buildCaseList(BuildContext c, WidgetRef r) {
    final cases = r.watch(casesProvider);
    if(cases.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.gavel, size: 64, color: AppColors.textSecondary), const SizedBox(height: 16), Text('لا يوجد دعاوى', style: AppTextStyles.bodyMedium), const SizedBox(height: 8), Text('اضغط + لإضافة دعوى', style: AppTextStyles.bodySmallSecondary)]));
    cases.sort((a,b) => (a.nextSession?.sessionDate ?? DateTime(9999)).compareTo(b.nextSession?.sessionDate ?? DateTime(9999)));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: cases.length, itemBuilder: (c, i) => CaseCard(caseItem: cases[i]));
  }
}

final casesProvider = Provider<List<Case>>((ref) => [
  Case(id: '1', caseNumber: '2026/001', title: 'دعوى تعويض', type: CaseType.civil, status: CaseStatus.scheduled, court: 'محكمة دمشق الأولى', baseNumber: '12345', baseYear: 2026, subject: 'تعويض عن ضرر', claim: '10,000,000 ل.س', creationDate: DateTime(2026,7,1), lastUpdated: DateTime(2026,7,9), clientIds: ['client_1'], opponentIds: ['opponent_1'], lawyerIds: ['lawyer_1'], poaIds: ['poa_1'], sessions: [CaseSession(id: 's1', sessionDate: DateTime(2026,7,15), sessionTime: const TimeOfDay(hour: 9, minute: 0), type: SessionType.ordinary, status: SessionStatus.scheduled, court: 'محكمة دمشق الأولى')], phases: [CasePhase(id: 'p1', type: CasePhaseType.initial, court: 'محكمة دمشق الأولى', baseNumber: '12345', baseYear: 2026, startDate: DateTime(2026,7,1))], deficiencies: [CaseDeficiency(id: 'd1', field: 'baseNumber', description: 'تأكيد رقم الأساس', createdAt: DateTime(2026,7,1), severity: 'high')], fees: [CaseFee(id: 'f1', clientId: 'client_1', amount: 5000000, agreementDate: DateTime(2026,7,1), status: 'unpaid')], expenses: [CaseExpense(id: 'e1', description: 'رسم دعوى', amount: 100000, expenseDate: DateTime(2026,7,2))], documentIds: ['doc_1', 'doc_2', 'doc_3']),
  Case(id: '2', caseNumber: '2026/002', title: 'دعوى استئناف', type: CaseType.commercial, status: CaseStatus.scheduled, court: 'محكمة الاستئناف', baseNumber: null, baseYear: null, subject: 'استئناف حكم', claim: 'إلغاء الحكم', creationDate: DateTime(2026,7,2), lastUpdated: DateTime(2026,7,8), clientIds: ['client_2'], opponentIds: ['opponent_2'], sessions: [CaseSession(id: 's2', sessionDate: DateTime(2026,7,10), sessionTime: const TimeOfDay(hour: 10, minute: 30), type: SessionType.ordinary, status: SessionStatus.scheduled, court: 'محكمة الاستئناف')], deficiencies: [CaseDeficiency(id: 'd2', field: 'baseNumber', description: 'حصول على رقم أساس', createdAt: DateTime(2026,7,2), severity: 'high'), CaseDeficiency(id: 'd3', field: 'poa', description: 'رفع الوكالة', createdAt: DateTime(2026,7,3), severity: 'high')], documentIds: ['doc_4', 'doc_5']),
  Case(id: '3', caseNumber: '2026/003', title: 'دعوى تجارية', type: CaseType.commercial, status: CaseStatus.completed, court: 'محكمة دمشق الأولى', baseNumber: '67890', baseYear: 2026, subject: 'منازعة تجارية', claim: '5,000,000 ل.س', creationDate: DateTime(2026,6,15), lastUpdated: DateTime(2026,7,5), clientIds: ['client_3'], opponentIds: ['opponent_3'], sessions: [CaseSession(id: 's3', sessionDate: DateTime(2026,7,5), sessionTime: const TimeOfDay(hour: 11, minute: 0), type: SessionType.judgment, status: SessionStatus.held, court: 'محكمة دمشق الأولى', decision: 'حكم لصالح الموكل', result: SessionResult(decision: 'حكم لصالح الموكل', clientAttended: true, opponentAttended: true, opponentLawyerAttended: true, expenses: 50000))], fees: [CaseFee(id: 'f2', clientId: 'client_3', amount: 2500000, agreementDate: DateTime(2026,6,15), paymentDate: DateTime(2026,7,5), status: 'paid')], expenses: [CaseExpense(id: 'e2', description: 'رسم دعوى', amount: 75000, expenseDate: DateTime(2026,6,16)), CaseExpense(id: 'e3', description: 'مصاريف معقب', amount: 25000, expenseDate: DateTime(2026,6,20))], documentIds: ['doc_6', 'doc_7', 'doc_8', 'doc_9', 'doc_10']),
]);

class CaseCard extends StatelessWidget {
  final Case caseItem;
  const CaseCard({super.key, required this.caseItem});
  @override Widget build(BuildContext context) {
    return Card(margin: const EdgeInsets.only(bottom: 12), child: InkWell(onTap: () => _showMsg(context, 'فتح دعوى: ${caseItem.caseNumber}'), borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Text(caseItem.caseNumber, style: AppTextStyles.headline6.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(4)), child: Text(caseItem.type.displayName, style: AppTextStyles.bodySmallSecondary)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: caseItem.status.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(caseItem.status.displayName, style: AppTextStyles.labelSmall.copyWith(color: caseItem.status.color)))]),
      const SizedBox(height: 8),
      Text(caseItem.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('الموضوع: ${caseItem.subject}', style: AppTextStyles.bodySmall),
      const SizedBox(height: 2),
      Text('الطلب: ${caseItem.claim}', style: AppTextStyles.bodySmallSecondary),
      const SizedBox(height: 4),
      Row(children: [Icon(Icons.balance, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text(caseItem.court, style: AppTextStyles.bodySmallSecondary), const SizedBox(width: 16), if(caseItem.baseNumber != null) ...[Icon(Icons.confirmation_number, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('رقم الأساس: ${caseItem.baseNumber}', style: AppTextStyles.bodySmallSecondary)] else ...[Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text('بانتظار رقم أساس', style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning)))]),
      const SizedBox(height: 4),
      if(caseItem.nextSession != null) ...[Row(children: [Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('الجلسة: ${caseItem.nextSession!.sessionDate.year}-${caseItem.nextSession!.sessionDate.month.toString().padLeft(2,"0")}-${caseItem.nextSession!.sessionDate.day.toString().padLeft(2,"0")} ${caseItem.nextSession!.sessionTime.hour}:${caseItem.nextSession!.sessionTime.minute.toString().padLeft(2,"0")}', style: AppTextStyles.bodySmall.copyWith(color: caseItem.nextSession!.sessionDate.isBefore(DateTime.now()) ? AppColors.error : AppColors.textPrimary, fontWeight: caseItem.nextSession!.sessionDate.isBefore(DateTime.now()) ? FontWeight.bold : FontWeight.normal))]), const SizedBox(height: 4)],
      if(caseItem.openDeficienciesCount > 0) ...[Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text('نواقص: ${caseItem.openDeficienciesCount}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))), const SizedBox(height: 4)],
      Row(children: [Icon(Icons.monetization_on, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('أتعاب: ${caseItem.totalFees.toStringAsFixed(0)} ل.س', style: AppTextStyles.bodySmallSecondary), const SizedBox(width: 16), Icon(Icons.money_off, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('مصاريف: ${caseItem.totalExpenses.toStringAsFixed(0)} ل.س', style: AppTextStyles.bodySmallSecondary), const SizedBox(width: 16), if(caseItem.balance > 0) ...[Icon(Icons.trending_up, color: AppColors.success, size: 16), const SizedBox(width: 4), Text('+${caseItem.balance.toStringAsFixed(0)} ل.س', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success))] else if(caseItem.balance < 0) ...[Icon(Icons.trending_down, color: AppColors.error, size: 16), const SizedBox(width: 4), Text('${caseItem.balance.toStringAsFixed(0)} ل.س', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))]]),
      const SizedBox(height: 4),
      Row(children: [Icon(Icons.attach_file, color: AppColors.textSecondary, size: 16), const SizedBox(width: 4), Text('مستندات: ${caseItem.documentIds.length}', style: AppTextStyles.bodySmallSecondary), const SizedBox(width: 8), if(caseItem.documentIds.isNotEmpty) TextButton(onPressed: () => _showDocsDialog(context, caseItem), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: Text('عرض المستندات', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryNavy)))]),
      const SizedBox(height: 8),
      Text('آخر تحديث: ${caseItem.lastUpdated?.year ?? caseItem.creationDate.year}-${(caseItem.lastUpdated?.month ?? caseItem.creationDate.month).toString().padLeft(2,"0")}-${(caseItem.lastUpdated?.day ?? caseItem.creationDate.day).toString().padLeft(2,"0")}', style: AppTextStyles.bodySmallSecondary),
    ])));
  }
  void _showMsg(BuildContext c, String msg) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.info));
  void _showDocsDialog(BuildContext c, Case ci) => showDialog(context: c, builder: (x) => CaseDocsDialog(caseItem: ci));
}

class CaseDocsDialog extends StatelessWidget {
  final Case caseItem;
  const CaseDocsDialog({super.key, required this.caseItem});
  @override Widget build(BuildContext context) {
    final docs = caseItem.documentIds.map((d) => DocumentItem(id: d, title: 'مستند $d', documentType: DocumentType.caseDocument, entityType: 'case', entityId: caseItem.id, entityTitle: caseItem.title, filePath: 'docs/cases/$d.pdf', fileName: '${caseItem.caseNumber}_$d.pdf', fileSize: 512*1024, fileType: FileType.pdf, uploadDate: DateTime.now(), uploadedBy: 'هادي البني', physicalLocation: 'ديوان المحكمة')).toList();
    return Dialog(insetPadding: const EdgeInsets.all(16), child: Container(constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.primaryNavy, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))), child: Row(children: [Icon(Icons.attach_file, color: Colors.white, size: 24), const SizedBox(width: 8), Text('مستندات الدعوى: ${caseItem.caseNumber}', style: AppTextStyles.headline6.copyWith(color: Colors.white))])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length, itemBuilder: (c, i) => ListTile(leading: Icon(docs[i].fileType.icon, color: AppColors.primaryNavy, size: 24), title: Text(docs[i].title, style: AppTextStyles.bodyMedium), subtitle: Text('${docs[i].fileType.displayName} - ${docs[i].formattedSize}', style: AppTextStyles.bodySmallSecondary), trailing: IconButton(icon: const Icon(Icons.open_in_new, size: 18), onPressed: () => openDocument(context, docs[i].id), tooltip: 'فتح'), onTap: () => openDocument(context, docs[i].id)))),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)), border: Border.all(color: AppColors.cardBorder, width: 0.5)), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))]))
    ])));
  }
}

class CasesFilterDialog extends StatefulWidget { const CasesFilterDialog({super.key}); @override State<CasesFilterDialog> createState() => _CasesFilterDialogState(); }
class _CasesFilterDialogState extends State<CasesFilterDialog> {
  CaseType? _type; CaseStatus? _status; bool _def=false, _session=false, _base=false;
  @override Widget build(BuildContext context) => Dialog(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text('فلترة الدعاوى', style: AppTextStyles.headline4.copyWith(color: AppColors.primaryNavy), textAlign: TextAlign.center),
    const SizedBox(height: 24),
    DropdownButtonFormField<CaseType?>(value: _type, items: [const DropdownMenuItem(value: null, child: Text('جميع الأنواع')), ...CaseType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))], onChanged: (v) => setState(() => _type = v), decoration: InputDecoration(labelText: 'نوع الدعوى', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
    const SizedBox(height: 16),
    DropdownButtonFormField<CaseStatus?>(value: _status, items: [const DropdownMenuItem(value: null, child: Text('جميع الحالات')), ...CaseStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))], onChanged: (v) => setState(() => _status = v), decoration: InputDecoration(labelText: 'حالة الدعوى', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
    const SizedBox(height: 16),
    Text('فلاتر إضافية:', style: AppTextStyles.labelLarge),
    const SizedBox(height: 8),
    CheckboxListTile(title: const Text('الدعاوى الناقصة'), value: _def, onChanged: (v) => setState(() => _def = v!), contentPadding: EdgeInsets.zero, dense: true),
    CheckboxListTile(title: const Text('الدعاوى بجلسة قريب'), value: _session, onChanged: (v) => setState(() => _session = v!), contentPadding: EdgeInsets.zero, dense: true),
    CheckboxListTile(title: const Text('بانتظار رقم أساس'), value: _base, onChanged: (v) => setState(() => _base = v!), contentPadding: EdgeInsets.zero, dense: true),
    const SizedBox(height: 24),
    Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')), const SizedBox(width: 12), ElevatedButton(onPressed: () { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تطبيق الفلاتر'), backgroundColor: AppColors.success)); }, child: const Text('تطبيق'))])
  ])));
}
