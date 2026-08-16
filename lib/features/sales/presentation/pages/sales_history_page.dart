import 'package:flutter/material.dart';

import '../../domain/entities/sale.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../../customers/data/repositories/customer_repository_impl.dart';
import '../../../customers/domain/entities/customer_debt_cycle.dart';
import '../../../customers/domain/entities/customer_ledger_entry.dart';

import '../widgets/history_widgets.dart';
import 'history_details.dart';

String _two(int n) => n.toString().padLeft(2, '0');
String _formatCurrency(double value) => '\$${value.toStringAsFixed(2)} MXN';
String _formatDate(DateTime date) => '${_two(date.day)}/${_two(date.month)}/${date.year} ${_two(date.hour)}:${_two(date.minute)}';
String _monthName(int month) => const ['', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][month];
Color _paymentMethodColor(String method) => {'cash': Colors.green, 'transfer': Colors.blue, 'point': Colors.deepPurple, 'customer_ledger': Colors.orange}[method] ?? Colors.grey;
String _buildSaleFolio(Sale sale) => 'VTA-${sale.createdAt.year}${_two(sale.createdAt.month)}${_two(sale.createdAt.day)}-${sale.id.length > 6 ? sale.id.substring(sale.id.length - 6) : sale.id}';
String _buildDayTitle(DateTime date, DateTime now) {
  final diff = DateTime(now.year, now.month, now.day).difference(DateTime(date.year, date.month, date.day)).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  return '${date.day} de ${_monthName(date.month)} de ${date.year}';
}

class _HistoryRecord {
  final String id;
  final DateTime createdAt;
  final Sale? sale;
  final CustomerDebtCycle? debtCycle;
  final List<CustomerLedgerEntry> debtCycleEntries;

  const _HistoryRecord({required this.id, required this.createdAt, this.sale, this.debtCycle, this.debtCycleEntries = const []});

  bool get isNormalSale => sale != null;
  double get totalAmount => sale?.total ?? debtCycle?.totalCharged ?? 0;
  String get searchIndex => isNormalSale ? sale!.id.toLowerCase() : debtCycle!.id.toLowerCase();
}

class _SalesSection {
  final String key;
  final String title;
  final List<_HistoryRecord> records;
  final DateTime sortDate;
  final bool isToday;

  _SalesSection({required this.key, required this.title, required this.records, required this.sortDate, required this.isToday});
}

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  final SalesRepositoryImpl _salesRepository = SalesRepositoryImpl();
  final CustomerRepositoryImpl _customerRepository = CustomerRepositoryImpl();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<_HistoryRecord>> _historyFuture;
  String _searchQuery = '';
  
  // Variables para controlar la apertura/cierre
  String? _expandedSectionKey;
  bool _didInteractWithSections = false;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text.toLowerCase().trim()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<_HistoryRecord>> _loadHistory() async {
    final salesResult = await _salesRepository.getSales();
    final allSales = salesResult.fold<List<Sale>>((failure) => throw Exception(failure.message), (sales) => sales);
    final normalSales = allSales.where((sale) => !sale.isCustomerLedger).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final closedCyclesResult = await _customerRepository.getAllClosedDebtCycles();
    final closedCycles = closedCyclesResult.fold<List<CustomerDebtCycle>>((failure) => throw Exception(failure.message), (cycles) => cycles.where((cycle) => cycle.isClosed).toList());

    final records = <_HistoryRecord>[...normalSales.map((sale) => _HistoryRecord(id: 'sale-${sale.id}', createdAt: sale.createdAt, sale: sale))];

    for (final cycle in closedCycles) {
      final entriesResult = await _customerRepository.getDebtCycleEntries(cycle.id);
      final entries = entriesResult.fold<List<CustomerLedgerEntry>>((failure) => throw Exception(failure.message), (entries) => entries..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
      records.add(_HistoryRecord(id: 'cycle-${cycle.id}', createdAt: cycle.closedAt ?? cycle.openedAt, debtCycle: cycle, debtCycleEntries: entries));
    }
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  List<_SalesSection> _buildSections(List<_HistoryRecord> records) {
    final now = DateTime.now();
    final Map<String, _SalesSection> sections = {};

    for (final record in records) {
      final itemDate = record.createdAt;
      final diffDays = DateTime(now.year, now.month, now.day).difference(DateTime(itemDate.year, itemDate.month, itemDate.day)).inDays;
      String key, title; DateTime sortDate; bool isToday;

      if (diffDays < 31) {
        key = 'day-${itemDate.year}-${_two(itemDate.month)}-${_two(itemDate.day)}'; title = _buildDayTitle(itemDate, now); sortDate = DateTime(itemDate.year, itemDate.month, itemDate.day); isToday = diffDays == 0;
      } else if (diffDays < 366) {
        key = 'month-${itemDate.year}-${_two(itemDate.month)}'; title = '${_monthName(itemDate.month)} ${itemDate.year}'; sortDate = DateTime(itemDate.year, itemDate.month, 1); isToday = false;
      } else {
        key = 'year-${itemDate.year}'; title = '${itemDate.year}'; sortDate = DateTime(itemDate.year, 1, 1); isToday = false;
      }

      sections.putIfAbsent(key, () => _SalesSection(key: key, title: title, records: [], sortDate: sortDate, isToday: isToday));
      sections[key]!.records.add(record);
    }
    return sections.values.toList()..sort((a, b) => b.sortDate.compareTo(a.sortDate));
  }

  void _openHistoryDetail(_HistoryRecord record) {
    if (record.isNormalSale) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SaleDetailPage(sale: record.sale!)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => DebtCycleHistoryDetailPage(cycle: record.debtCycle!, entries: record.debtCycleEntries)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial General')),
      body: RefreshIndicator(
        onRefresh: () async { setState(() => _historyFuture = _loadHistory()); await _historyFuture; },
        child: FutureBuilder<List<_HistoryRecord>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: Theme.of(context).textTheme.titleMedium));

            final records = snapshot.data ?? [];
            final filteredRecords = _searchQuery.isEmpty ? records : records.where((r) => r.searchIndex.contains(_searchQuery)).toList();
            final sections = _buildSections(filteredRecords);
            final totalFilteredAmount = filteredRecords.fold<double>(0, (sum, record) => sum + record.totalAmount);

            // FIX DE APERTURA Y CIERRE: Lógica para saber cuál está abierto.
            String? currentExpandedKey;
            if (!_didInteractWithSections && sections.isNotEmpty) {
              currentExpandedKey = sections.first.key; // Al entrar, el primero está abierto por defecto
            } else {
              currentExpandedKey = _expandedSectionKey; // Después de tocar, respeta la elección (incluso si es null para cerrar todos)
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Buscar venta...',
                            prefixIcon: const Icon(Icons.search, size: 28),
                            suffixIcon: _searchQuery.isEmpty ? null : IconButton(icon: const Icon(Icons.close), onPressed: _searchController.clear),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: HistorySummaryCard(label: 'Registros', value: '${filteredRecords.length}')),
                            const SizedBox(width: 12),
                            Expanded(child: HistorySummaryCard(label: 'Monto Visible', value: _formatCurrency(totalFilteredAmount), highlight: true)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                ...sections.map((section) {
                  final sectionTotal = section.records.fold<double>(0, (sum, r) => sum + r.totalAmount);
                  final isExpanded = currentExpandedKey == section.key;

                  return SliverToBoxAdapter(
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _didInteractWithSections = true;
                              // Si tocamos el que está expandido, lo cerramos (pasa a ser null). Si tocamos otro, lo abrimos.
                              _expandedSectionKey = isExpanded ? null : section.key;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            color: isExpanded ? Colors.grey.shade100 : Colors.white,
                            child: Row(
                              children: [
                                AnimatedRotation(
                                  turns: isExpanded ? 0.0 : -0.25,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(Icons.keyboard_arrow_down, size: 32),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(section.title, style: Theme.of(context).textTheme.titleLarge)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${section.records.length} registros', style: Theme.of(context).textTheme.bodyMedium),
                                    Text(_formatCurrency(sectionTotal), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Animación suave de apertura/cierre
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          firstChild: Column(
                            children: section.records.map((record) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: record.isNormalSale
                                  ? HistoryNormalSaleCard(sale: record.sale!, onTap: () => _openHistoryDetail(record))
                                  : HistoryDebtCycleCard(cycle: record.debtCycle!, entries: record.debtCycleEntries, onTap: () => _openHistoryDetail(record)),
                            )).toList(),
                          ),
                          secondChild: const SizedBox(width: double.infinity, height: 0),
                        ),
                      ],
                    ),
                  );
                }),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }
}