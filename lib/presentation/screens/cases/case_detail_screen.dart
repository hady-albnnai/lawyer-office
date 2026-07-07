import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/app_enums.dart';
import '../../../data/database/database.dart';
import '../../providers/app_providers.dart';

/// شاشة ملف الدعوى الموحد مع تبويباته التسعة وشريط الحالة الدائم (CaseDetailScreen V6.2)
class CaseDetailScreen extends ConsumerStatefulWidget {
  final int caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caseRepo = ref.watch(caseRepositoryProvider);

    return FutureBuilder<Case?>(
      future: caseRepo.getCaseById(widget.caseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final c = snapshot.data;
        if (c == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('الملف غير موجود')),
            body: const Center(child: Text('لم يتم العثور على ملف هذه الدعوى في قاعدة البيانات.')),
          );
        }

        // مراقبة النواقص لهذا الملف لعرض شارة التنبيه في شريط الحالة
        final defsAsync = ref.watch(openDeficienciesProvider((type: EntityType.caseEntity, id: c.id)));
        final hasDeficiencies = defsAsync.maybeWhen(
          data: (defs) => defs.isNotEmpty,
          orElse: () => false,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('ملف دعوى رقم: [${c.internalNumber}] • ${c.caseType}'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppConstants.accentGold,
              labelColor: AppConstants.accentGold,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                const Tab(text: '1️⃣ الملخص'),
                const Tab(text: '2️⃣ الأطراف والوكالات'),
                const Tab(text: '3️⃣ المراحل القضائية'),
                const Tab(text: '4️⃣ الجلسات والإجراءات'),
                const Tab(text: '5️⃣ المستندات'),
                const Tab(text: '6️⃣ المالية'),
                Tab(
                  child: Row(
                    children: [
                      const Text('7️⃣ النواقص '),
                      if (hasDeficiencies)
                        const Icon(Icons.error, color: AppConstants.statusDanger, size: 16),
                    ],
                  ),
                ),
                const Tab(text: '8️⃣ الخط الزمني'),
                const Tab(text: '9️⃣ الإنهاء'),
              ],
            ),
          ),
          body: Column(
            children: [
              // شريط الحالة الدائم أعلى الملف دائمًا
              _buildStatusBar(c, hasDeficiencies),
              
              // محتوى التبويبات التسعة
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(c),
                    _buildPartiesTab(c.id),
                    _buildPhasesTab(c),
                    _buildSessionsTab(c),
                    _buildDocumentsTab(c.id),
                    _buildFinancesTab(c.id),
                    _buildDeficienciesTab(c.id),
                    _buildTimelineTab(c.id),
                    _buildTerminationTab(c),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// شريط الحالة العلوي الثابت في ملف الدعوى
  Widget _buildStatusBar(Case c, bool hasDeficiencies) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: hasDeficiencies ? AppConstants.statusDanger.withOpacity(0.1) : AppConstants.primaryNavy.withOpacity(0.08),
        border: Border(bottom: BorderSide(color: hasDeficiencies ? AppConstants.statusDanger : AppConstants.primaryNavy.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          _statusItem(Icons.folder, 'الرقم الداخلي:', c.internalNumber, AppConstants.primaryNavy),
          _statusItem(Icons.category, 'النوع:', '${c.caseType} (${c.subType ?? ""})', AppConstants.primaryNavy),
          _statusItem(Icons.numbers, 'الأساس:', c.baseNumber ?? 'بانتظار التسجيل', c.baseNumber == null ? AppConstants.statusDanger : AppConstants.textDark),
          _statusItem(
            Icons.event,
            'الجلسة القادمة:',
            c.nextSessionDate?.toString().substring(0, 10) ?? 'غير محددة ⚠️',
            c.nextSessionDate == null ? AppConstants.statusDanger : AppConstants.statusSuccess,
          ),
          const Spacer(),
          if (hasDeficiencies)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppConstants.statusDanger, borderRadius: BorderRadius.circular(12)),
              child: const Text('الملف ناقص ثبوتيات / مواعيد ⚠️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppConstants.statusSuccess, borderRadius: BorderRadius.circular(12)),
              child: const Text('الملف مكتمل ✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _statusItem(IconData icon, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppConstants.accentGold),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppConstants.textMuted)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1️⃣ تبويب الملخص (Summary Tab)
  // ---------------------------------------------------------------------------
  Widget _buildSummaryTab(Case c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الإجراءات السريعة للملف:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy)),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: const Text('إضافة جلسة مرافعة جديدة'),
                onPressed: () => _openAddSessionDialog(c),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('إرفاق مستند أو مذكرة'),
                onPressed: () => _tabController.animateTo(4),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.upgrade),
                label: const Text('نقل للمرحلة القضائية التالية'),
                onPressed: () => _openTransferPhaseDialog(c),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('موضوع الدعوى والطلبات الختامية:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  Text('الموضوع: ${c.subject ?? "غير مدخل"}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Text('التفاصيل: ${c.subjectDetails ?? "لا توجد تفاصيل إضافية"}', style: const TextStyle(color: AppConstants.textMuted, height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2️⃣ تبويب الأطراف والوكالات (Parties Tab)
  // ---------------------------------------------------------------------------
  Widget _buildPartiesTab(int caseId) {
    final partiesStream = ref.watch(caseRepositoryProvider).watchCaseParties(caseId);

    return StreamBuilder<List<CaseParty>>(
      stream: partiesStream,
      builder: (context, snapshot) {
        final parties = snapshot.data ?? [];
        final clients = parties.where((p) => p.isClient).toList();
        final opponents = parties.where((p) => !p.isClient).toList();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('موکلو المكتب في هذه القضية:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy)),
            const SizedBox(height: 8),
            ...clients.map((p) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppConstants.primaryNavy, child: Icon(Icons.person, color: AppConstants.accentGold)),
                    title: Text('طرف موكل رقم [ID: ${p.personId}] • الصفة: ${p.partyRole}'),
                    subtitle: Text(p.isPrimary ? 'الموكل الرئيسي في الملف' : 'موكل تابع / إضافي'),
                    trailing: const Icon(Icons.verified, color: AppConstants.statusSuccess),
                  ),
                )),
            const SizedBox(height: 24),
            const Text('الخصوم وأطراف الدعوى الآخرون:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.statusDanger)),
            const SizedBox(height: 8),
            ...opponents.map((p) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppConstants.statusDanger, child: Icon(Icons.person_off, color: Colors.white)),
                    title: Text('طرف خصم رقم [ID: ${p.personId}] • الصفة: ${p.partyRole}'),
                    subtitle: Text(p.isPrimary ? 'الخصم الرئيسي في الدعوى' : 'خصم إضافي / مدخل'),
                  ),
                )),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3️⃣ تبويب المراحل القضائية (Phases Tab) - مع زر النقل التلقائي
  // ---------------------------------------------------------------------------
  Widget _buildPhasesTab(Case c) {
    final phasesStream = ref.watch(caseRepositoryProvider).watchCasePhases(c.id);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppConstants.surfaceWhite,
          child: Row(
            children: [
              const Expanded(
                child: Text('التسلسل الهرمي للمراحل القضائية (صلح ← بداية ← استئناف ← نقض):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryNavy),
                icon: const Icon(Icons.upgrade),
                label: const Text('نقل للمرحلة التالية (مع القرارات والمبرزات)'),
                onPressed: () => _openTransferPhaseDialog(c),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<CasePhase>>(
            stream: phasesStream,
            builder: (context, snapshot) {
              final phases = snapshot.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: phases.length,
                itemBuilder: (context, index) {
                  final phase = phases[index];
                  return Card(
                    elevation: phase.isTransferred ? 1 : 3,
                    color: phase.isTransferred ? Colors.grey.withOpacity(0.08) : AppConstants.surfaceWhite,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: phase.isTransferred ? Colors.grey : AppConstants.accentGold,
                                child: Text('${phase.phaseOrder}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryNavy)),
                              ),
                              const SizedBox(width: 12),
                              Text('مرحلة: [${phase.phaseType}] • سنة ${phase.year ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const Spacer(),
                              if (phase.isTransferred)
                                const Chip(label: Text('منتقلة للمرحلة الأعلى ↗️'), backgroundColor: Colors.black12)
                              else
                                const Chip(label: Text('المرحلة النشطة حالياً ⭐'), backgroundColor: AppConstants.accentGold),
                            ],
                          ),
                          const Divider(height: 24),
                          Text('رقم الأساس: ${phase.baseNumber ?? "غير مدخل"} • تاريخ البدء: ${phase.startDate?.toString().substring(0, 10) ?? ""}'),
                          const SizedBox(height: 8),
                          Text('ملخص القرار الصادر في المرحلة: ${phase.decisionText ?? "لم يصدر حكم بعد"}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4️⃣ تبويب الجلسات والإجراءات (Sessions Tab)
  // ---------------------------------------------------------------------------
  Widget _buildSessionsTab(Case c) {
    final sessionsStream = ref.watch(caseRepositoryProvider).watchCaseSessions(c.id);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppConstants.surfaceWhite,
          child: Row(
            children: [
              const Expanded(child: Text('سجل جلسات المحاكمة والمرافعة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('تسجيل جلسة جديدة'),
                onPressed: () => _openAddSessionDialog(c),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<CaseSession>>(
            stream: sessionsStream,
            builder: (context, snapshot) {
              final sessions = snapshot.data ?? [];
              if (sessions.isEmpty) return const Center(child: Text('لا توجد جلسات مسجلة بعد'));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  final statusEnum = LifecycleStatus.values[s.status];

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.event, color: AppConstants.primaryNavy),
                              const SizedBox(width: 8),
                              Text('جلسة بتاريخ: ${s.sessionDate.toString().substring(0, 10)} (${s.sessionType ?? "مرافعة"})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              Chip(label: Text(statusEnum.label), backgroundColor: statusEnum == LifecycleStatus.completed ? AppConstants.statusSuccess.withOpacity(0.2) : AppConstants.statusWarning.withOpacity(0.2)),
                            ],
                          ),
                          const Divider(height: 16),
                          Text('قرار المحكمة في الجلسة: ${s.decision ?? "بانتظار القرار"}'),
                          const SizedBox(height: 8),
                          Text('المطلوب للموعد القادم: ${s.nextAction ?? "غير محدد"} • التاريخ التالي: ${s.nextSessionDate?.toString().substring(0, 10) ?? "بدون"}', style: const TextStyle(color: AppConstants.primaryNavy, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5️⃣ تبويب المستندات (Documents Tab)
  // ---------------------------------------------------------------------------
  Widget _buildDocumentsTab(int caseId) {
    return const Center(child: Text('المستندات المبرزة في إضبارة هذه القضية (أصلي / صورة / في خزنة المكتب)'));
  }

  // ---------------------------------------------------------------------------
  // 6️⃣ تبويب المالية (Finances Tab)
  // ---------------------------------------------------------------------------
  Widget _buildFinancesTab(int caseId) {
    return const Center(child: Text('حسابات أتعاب الموكلين ومصاريف الرسوم والطوابع لهذه القضية'));
  }

  // ---------------------------------------------------------------------------
  // 7️⃣ تبويب النواقص (Deficiencies Tab)
  // ---------------------------------------------------------------------------
  Widget _buildDeficienciesTab(int caseId) {
    final defsStream = ref.watch(taskRepositoryProvider).watchOpenDeficiencies(entityType: EntityType.caseEntity, entityId: caseId);

    return StreamBuilder<List<Deficiency>>(
      stream: defsStream,
      builder: (context, snapshot) {
        final defs = snapshot.data ?? [];
        if (defs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, size: 64, color: AppConstants.statusSuccess),
                SizedBox(height: 16),
                Text('الملف مكتمل بنسبة 100% ولا توجد أي نواقص مفتوحة ✓', style: TextStyle(fontSize: 18, color: AppConstants.statusSuccess, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: defs.length,
          itemBuilder: (context, index) {
            final d = defs[index];
            return Card(
              color: AppConstants.statusDanger.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppConstants.statusDanger)),
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: AppConstants.statusDanger, size: 36),
                title: Text('نقص مرصود: [${d.fieldName}]', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.statusDanger)),
                subtitle: Text(d.description),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.statusSuccess),
                  child: const Text('استكمال وإغلاق النقص'),
                  onPressed: () async {
                    await ref.read(taskRepositoryProvider).resolveDeficiency(d.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إغلاق النقص!'), backgroundColor: AppConstants.statusSuccess));
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 8️⃣ تبويب الخط الزمني (Timeline Tab)
  // ---------------------------------------------------------------------------
  Widget _buildTimelineTab(int caseId) {
    final timelineStream = ref.watch(taskRepositoryProvider).watchTimelineEvents(EntityType.caseEntity, caseId);

    return StreamBuilder<List<TimelineEvent>>(
      stream: timelineStream,
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        if (events.isEmpty) return const Center(child: Text('لا توجد أحداث في الخط الزمني بعد'));

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final e = events[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: AppConstants.primaryNavy, child: Icon(Icons.history, color: AppConstants.accentGold)),
                title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('النوع: ${e.eventType} • التاريخ: ${e.eventDate.toString().substring(0, 16)} • بواسطة: ${e.userRef ?? "المكتب"}'),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 9️⃣ تبويب الإنهاء (Termination Tab)
  // ---------------------------------------------------------------------------
  Widget _buildTerminationTab(Case c) {
    if (c.status == 'closed') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: AppConstants.statusDanger),
            const SizedBox(height: 16),
            const Text('هذه الدعوى منتهية ومغلقة في أرشيف المكتب', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.statusDanger)),
            const SizedBox(height: 12),
            Text(c.notes ?? '', style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    final reasonController = TextEditingController(text: 'حكم قضائي قطعي نهائي');
    final numController = TextEditingController();
    final summaryController = TextEditingController();
    File? decisionFile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Card(
        color: AppConstants.statusDanger.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppConstants.statusDanger)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.gavel, color: AppConstants.statusDanger, size: 32),
                  SizedBox(width: 12),
                  Text('إنهاء الدعوى وإغلاق الملف في أرشيف المكتب:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.statusDanger)),
                ],
              ),
              const Divider(height: 32),
              TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'سبب الإنهاء * (حكم نهائي / صلح / اعتزال توكيل)')),
              const SizedBox(height: 16),
              TextField(controller: numController, decoration: const InputDecoration(labelText: 'رقم قرار الحكم النهائي *')),
              const SizedBox(height: 16),
              TextField(controller: summaryController, maxLines: 4, decoration: const InputDecoration(labelText: 'ملخص ومنطوق الحكم الصادر *')),
              const SizedBox(height: 24),
              const Text('تطبيقاً لصرامة الدستور (V6.2): إرفاق صورة قرار الحكم إلزامي لإنهاء الملف!', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.statusDanger)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.statusDanger),
                  icon: const Icon(Icons.archive),
                  label: const Text('اعتماد الحكم النهائي وإغلاق القضية'),
                  onPressed: () async {
                    if (summaryController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ملخص الحكم إلزامي!'), backgroundColor: AppConstants.statusDanger));
                      return;
                    }
                    await ref.read(caseRepositoryProvider).terminateCase(
                      caseId: c.id,
                      terminationReason: reasonController.text.trim(),
                      decisionNumber: numController.text.trim(),
                      summary: summaryController.text.trim(),
                      decisionFile: decisionFile,
                      userRef: AppConstants.defaultLawyerName,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إغلاق القضية بنجاح!'), backgroundColor: AppConstants.statusSuccess));
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // دوال الإجراءات المنبثقة (Dialogs)
  // ---------------------------------------------------------------------------
  void _openAddSessionDialog(Case c) {
    final nextActionController = TextEditingController(text: 'مرافعة / سماع شهود');
    final decisionController = TextEditingController(text: 'تأجيل للجلسة القادمة');
    DateTime sessionDate = DateTime.now();
    DateTime? nextDate = DateTime.now().add(const Duration(days: 14));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل جلسة قضائية جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: decisionController, decoration: const InputDecoration(labelText: 'قرار المحكمة في هذه الجلسة')),
            const SizedBox(height: 12),
            TextField(controller: nextActionController, decoration: const InputDecoration(labelText: 'المطلوب للجلسة القادمة')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            child: const Text('حفظ وترحيل الموعد القادم'),
            onPressed: () async {
              await ref.read(caseRepositoryProvider).addSession(
                session: CaseSessionsCompanion.insert(
                  caseId: c.id,
                  sessionDate: sessionDate,
                  decision: drift.Value(decisionController.text.trim()),
                  nextAction: drift.Value(nextActionController.text.trim()),
                  nextSessionDate: drift.Value(nextDate),
                ),
                caseTitle: '[${c.internalNumber}] - ${c.subject ?? ""}',
                userRef: AppConstants.defaultLawyerName,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الجلسة وترحيل المهمة اليومية بنجاح!'), backgroundColor: AppConstants.statusSuccess));
              }
            },
          ),
        ],
      ),
    );
  }

  void _openTransferPhaseDialog(Case c) {
    String newPhaseType = 'استئناف';
    final baseController = TextEditingController();
    final yearController = TextEditingController(text: DateTime.now().year.toString());
    int? newCourtId = c.courtId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نقل القضية للمرحلة القضائية الأعلى ↗️'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('القاعدة الذهبية (V6.2): سينتقل نص القرار السابق وكل المبرزات تلقائياً للمحكمة الجديدة.', style: TextStyle(color: AppConstants.accentGoldDark, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: newPhaseType,
              decoration: const InputDecoration(labelText: 'المرحلة الجديدة *'),
              items: ['استئناف', 'نقض', 'إعادة محاكمة'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => newPhaseType = val!,
            ),
            const SizedBox(height: 12),
            TextField(controller: baseController, decoration: const InputDecoration(labelText: 'رقم الأساس الجديد في محكمة الاستئناف/النقض')),
            const SizedBox(height: 12),
            TextField(controller: yearController, decoration: const InputDecoration(labelText: 'سنة الأساس')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            child: const Text('اعتماد ونقل القضية الآن'),
            onPressed: () async {
              await ref.read(caseRepositoryProvider).transferToNextPhase(
                caseId: c.id,
                newPhaseType: newPhaseType,
                newCourtId: newCourtId ?? 1,
                newBaseNumber: baseController.text.trim(),
                newYear: int.tryParse(yearController.text.trim()),
                userRef: AppConstants.defaultLawyerName,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نقل القضية ومبرزاتها للمرحلة الجديدة بنجاح!'), backgroundColor: AppConstants.statusSuccess));
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }
}
