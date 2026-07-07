import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../cases/case_detail_screen.dart';
import '../contracts/contract_detail_screen.dart';
import '../companies/company_detail_screen.dart';
import '../admin_procedures/procedure_detail_screen.dart';

/// شاشة البحث المتقدم الفوري والشامل في كل ملفات وأرشيف المكتب (AdvancedSearchScreen V6.2)
class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'الكل'; // الكل، دعاوى، عقود، شركات، إجراءات

  final List<String> _filters = ['الكل', 'دعاوى قضائية', 'عقود ونماذج', 'تأسيس شركات', 'إجراءات إدارية'];

  @override
  Widget build(BuildContext context) {
    final casesAsync = ref.watch(allCasesProvider);
    final contractsAsync = ref.watch(allContractsProvider);
    final companiesAsync = ref.watch(allCompaniesProvider);
    final proceduresAsync = ref.watch(allProceduresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('البحث الشامل والفوري في أرشيف مكتب المحاماة')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppConstants.surfaceWhite,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث برقم الملف الداخلي، رقم الأساس، اسم العميل، موضوع القضية، أو العنوان...',
                    prefixIcon: const Icon(Icons.search, size: 28, color: AppConstants.primaryNavy),
                    suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = '')) : null,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('تخصيص نطاق البحث:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Wrap(
                      spacing: 8,
                      children: _filters.map((f) => ChoiceChip(
                        label: Text(f),
                        selected: _selectedFilter == f,
                        onSelected: (_) => setState(() => _selectedFilter = f),
                      )).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _searchQuery.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.manage_search, size: 80, color: AppConstants.textMuted),
                        SizedBox(height: 16),
                        Text('ابدأ بكتابة كلمة البحث للوصول الفوري إلى أي إضبارة في المكتب', style: TextStyle(fontSize: 18, color: AppConstants.textMuted)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_selectedFilter == 'الكل' || _selectedFilter == 'دعاوى قضائية')
                        ..._buildCasesResults(casesAsync),
                      if (_selectedFilter == 'الكل' || _selectedFilter == 'عقود ونماذج')
                        ..._buildContractsResults(contractsAsync),
                      if (_selectedFilter == 'الكل' || _selectedFilter == 'تأسيس شركات')
                        ..._buildCompaniesResults(companiesAsync),
                      if (_selectedFilter == 'الكل' || _selectedFilter == 'إجراءات إدارية')
                        ..._buildProceduresResults(proceduresAsync),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCasesResults(AsyncValue casesAsync) {
    return casesAsync.maybeWhen(
      data: (cases) {
        final filtered = cases.where((c) =>
            c.internalNumber.toLowerCase().contains(_searchQuery) ||
            (c.baseNumber?.toLowerCase().contains(_searchQuery) ?? false) ||
            (c.subject?.toLowerCase().contains(_searchQuery) ?? false) ||
            c.caseType.toLowerCase().contains(_searchQuery)).toList();
        
        return filtered.map<Widget>((c) => Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: AppConstants.primaryNavy, child: Icon(Icons.gavel, color: AppConstants.accentGold)),
            title: Text('دعوى قضائية [${c.internalNumber}] • ${c.caseType}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('الموضوع: ${c.subject ?? "---"} • رقم الأساس: ${c.baseNumber ?? "---"}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: c.id))),
          ),
        )).toList();
      },
      orElse: () => [],
    );
  }

  List<Widget> _buildContractsResults(AsyncValue contractsAsync) {
    return contractsAsync.maybeWhen(
      data: (contracts) {
        final filtered = contracts.where((c) =>
            c.title.toLowerCase().contains(_searchQuery) ||
            c.internalNumber.toLowerCase().contains(_searchQuery) ||
            c.contractType.toLowerCase().contains(_searchQuery)).toList();
        
        return filtered.map<Widget>((c) => Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF6C3483), child: Icon(Icons.description, color: Colors.white)),
            title: Text('عقد [${c.internalNumber}] • ${c.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('النوع: ${c.contractType} • القيمة: ${c.financialValue} ${c.currency}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContractDetailScreen(contractId: c.id))),
          ),
        )).toList();
      },
      orElse: () => [],
    );
  }

  List<Widget> _buildCompaniesResults(AsyncValue companiesAsync) {
    return companiesAsync.maybeWhen(
      data: (companies) {
        final filtered = companies.where((c) =>
            c.name.toLowerCase().contains(_searchQuery) ||
            c.internalNumber.toLowerCase().contains(_searchQuery) ||
            (c.registrationNumber?.toLowerCase().contains(_searchQuery) ?? false)).toList();
        
        return filtered.map<Widget>((c) => Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF9C640C), child: Icon(Icons.business, color: Colors.white)),
            title: Text('شركة [${c.name}] • رقم الملف: ${c.internalNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('الشكل: ${c.companyType} • السجل: ${c.registrationNumber ?? "بانتظار الصدور"}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompanyDetailScreen(companyId: c.id))),
          ),
        )).toList();
      },
      orElse: () => [],
    );
  }

  List<Widget> _buildProceduresResults(AsyncValue proceduresAsync) {
    return proceduresAsync.maybeWhen(
      data: (procedures) {
        final filtered = procedures.where((p) =>
            p.title.toLowerCase().contains(_searchQuery) ||
            p.internalNumber.toLowerCase().contains(_searchQuery) ||
            (p.transactionNumber?.toLowerCase().contains(_searchQuery) ?? false)).toList();
        
        return filtered.map<Widget>((p) => Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF117A65), child: Icon(Icons.assignment, color: Colors.white)),
            title: Text('معاملة [${p.title}] • رقم الملف: ${p.internalNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('التصنيف: ${p.procedureType} • الدائرة: ${p.department ?? "---"}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProcedureDetailScreen(procedureId: p.id))),
          ),
        )).toList();
      },
      orElse: () => [],
    );
  }
}
