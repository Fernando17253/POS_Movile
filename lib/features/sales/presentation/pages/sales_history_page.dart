import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../domain/entities/sale.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String _formatCurrency(double value) {
  return '\$${value.toStringAsFixed(2)} MXN';
}

String _formatDate(DateTime date) {
  return '${_two(date.day)}/${_two(date.month)}/${date.year} ${_two(date.hour)}:${_two(date.minute)}';
}

String _monthName(int month) {
  const months = [
    '',
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return months[month];
}

String _paymentMethodLabel(String method) {
  switch (method) {
    case 'cash':
      return 'Efectivo';
    case 'transfer':
      return 'Transferencia';
    case 'point':
      return 'Tarjeta / Point';
    case 'customer_ledger':
      return 'Libreta';
    default:
      return method;
  }
}

Color _paymentMethodColor(String method) {
  switch (method) {
    case 'cash':
      return Colors.green;
    case 'transfer':
      return Colors.blue;
    case 'point':
      return Colors.deepPurple;
    case 'customer_ledger':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

String _buildSaleFolio(Sale sale) {
  final date = sale.createdAt;
  final datePart = '${date.year}${_two(date.month)}${_two(date.day)}';
  final rawId = sale.id;
  final suffix = rawId.length > 6 ? rawId.substring(rawId.length - 6) : rawId;
  return 'VTA-$datePart-$suffix';
}

String _buildDayTitle(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;

  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  return '${date.day} de ${_monthName(date.month)} de ${date.year}';
}

String _buildSaleSearchIndex(Sale sale) {
  final date = sale.createdAt;
  final day = _two(date.day);
  final month = _two(date.month);
  final year = date.year.toString();
  final monthName = _monthName(date.month);
  final dayTitle = _buildDayTitle(date, DateTime.now()).toLowerCase();

  final productTerms = sale.items.expand((item) {
    return [
      item.productName,
      item.internalCode,
      item.barcode ?? '',
    ];
  }).join(' ');

  final payment = _paymentMethodLabel(sale.paymentMethod);
  final reference = sale.transferReference ?? '';
  final folio = _buildSaleFolio(sale);
  final customerName = sale.customerName ?? '';
  final ledgerTerms = sale.isCustomerLedger ? 'libreta adeudo cliente' : '';

  final dateTerms = [
    '$day/$month/$year',
    '${date.day}/${date.month}/$year',
    '$day-$month-$year',
    '${date.day}-${date.month}-$year',
    '$day de $monthName de $year',
    '${date.day} de $monthName de $year',
    '$monthName $year',
    monthName,
    year,
    dayTitle,
  ].join(' ');

  return [
    sale.id,
    folio,
    payment,
    reference,
    customerName,
    ledgerTerms,
    productTerms,
    dateTerms,
  ].join(' ').toLowerCase();
}

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  final SalesRepositoryImpl _salesRepository = SalesRepositoryImpl();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Sale>> _salesFuture;
  String _searchQuery = '';

  String? _expandedSectionKey;
  bool _didInteractWithSections = false;


  @override
  void initState() {
    super.initState();
    _salesFuture = _loadSales();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Sale>> _loadSales() async {
    final result = await _salesRepository.getSales();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (sales) => sales,
    );
  }

  Future<void> _refreshSales() async {
    setState(() {
      _salesFuture = _loadSales();
    });
    await _salesFuture;
  }

void _toggleSection(String key, String? effectiveExpandedKey) {
  setState(() {
    _didInteractWithSections = true;
    final current = _expandedSectionKey ?? effectiveExpandedKey;
    _expandedSectionKey = current == key ? null : key;
  });
}

  void _clearSearch() {
    _searchController.clear();
  }

  bool _saleMatchesSearch(Sale sale, String query) {
    if (query.isEmpty) return true;
    return _buildSaleSearchIndex(sale).contains(query);
  }

  List<_SalesSection> _buildSections(List<Sale> sales) {
    final now = DateTime.now();
    final Map<String, _SalesSection> sections = {};

    final sortedSales = [...sales]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final sale in sortedSales) {
      final saleDate = sale.createdAt;
      final saleDay = DateTime(saleDate.year, saleDate.month, saleDate.day);
      final nowDay = DateTime(now.year, now.month, now.day);
      final diffDays = nowDay.difference(saleDay).inDays;

      late final String key;
      late final String title;
      late final DateTime sortDate;
      late final bool isToday;

      if (diffDays < 31) {
        key = 'day-${saleDate.year}-${_two(saleDate.month)}-${_two(saleDate.day)}';
        title = _buildDayTitle(saleDate, now);
        sortDate = DateTime(saleDate.year, saleDate.month, saleDate.day);
        isToday = diffDays == 0;
      } else if (diffDays < 366) {
        key = 'month-${saleDate.year}-${_two(saleDate.month)}';
        title = '${_monthName(saleDate.month)} ${saleDate.year}';
        sortDate = DateTime(saleDate.year, saleDate.month, 1);
        isToday = false;
      } else {
        key = 'year-${saleDate.year}';
        title = '${saleDate.year}';
        sortDate = DateTime(saleDate.year, 1, 1);
        isToday = false;
      }

      sections.putIfAbsent(
        key,
        () => _SalesSection(
          key: key,
          title: title,
          sales: [],
          sortDate: sortDate,
          isToday: isToday,
        ),
      );

      sections[key]!.sales.add(sale);
    }

    final result = sections.values.toList()
      ..sort((a, b) => b.sortDate.compareTo(a.sortDate));

    for (final section in result) {
      section.sales.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }

  String? _effectiveExpandedKey(List<_SalesSection> sections) {
    if (sections.isEmpty) return null;

    if (_didInteractWithSections) {
      if (_expandedSectionKey == null) return null;

      final exists = sections.any((section) => section.key == _expandedSectionKey);
      return exists ? _expandedSectionKey : sections.first.key;
    }

    for (final section in sections) {
      if (section.isToday) return section.key;
    }

    return sections.first.key;
  }

  void _openSaleDetail(Sale sale) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SaleDetailPage(sale: sale),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de ventas'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSales,
        child: FutureBuilder<List<Sale>>(
          future: _salesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  const Icon(
                    Icons.error_outline,
                    size: 52,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo cargar el historial',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              );
            }

            final sales = snapshot.data ?? [];
            final filteredSales = sales
                .where((sale) => _saleMatchesSearch(sale, _searchQuery))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final sections = _buildSections(filteredSales);
            final expandedKey = _effectiveExpandedKey(sections);

            final totalFilteredAmount = filteredSales.fold<double>(
              0,
              (sum, sale) => sum + sale.total,
            );

            if (sales.isEmpty) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildTopArea(filteredSales, totalFilteredAmount)),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Aún no hay ventas guardadas.',
                      subtitle: 'Cuando confirmes ventas, aparecerán aquí.',
                    ),
                  ),
                ],
              );
            }

            if (filteredSales.isEmpty) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildTopArea(filteredSales, totalFilteredAmount)),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(
                      icon: Icons.search_off_outlined,
                      title: 'No se encontraron resultados.',
                      subtitle:
                          'Puedes buscar por fecha, folio, método de pago, referencia, nombre, clave o código.',
                    ),
                  ),
                ],
              );
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildTopArea(filteredSales, totalFilteredAmount),
                ),
...sections.expand((section) {
  final sectionTotal = section.sales.fold<double>(
    0,
    (sum, sale) => sum + sale.total,
  );

  final isExpanded = expandedKey == section.key;

  return <Widget>[
    if (isExpanded)
      SliverPersistentHeader(
        pinned: true,
        delegate: _SectionHeaderDelegate(
          height: 92,
          child: Container(
            color: const Color(0xFFF7F7F8),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _buildSectionGroupHeader(
              section: section,
              total: sectionTotal,
              isExpanded: true,
              onTap: () => _toggleSection(section.key, expandedKey),
            ),
          ),
        ),
      )
    else
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _buildSectionGroupHeader(
            section: section,
            total: sectionTotal,
            isExpanded: false,
            onTap: () => _toggleSection(section.key, expandedKey),
          ),
        ),
      ),
    SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          isExpanded ? 4 : 0,
          16,
          isExpanded ? 20 : 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );

            return ClipRect(
              child: FadeTransition(
                opacity: curved,
                child: SizeTransition(
                  sizeFactor: curved,
                  axisAlignment: -1.0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.15),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: isExpanded
              ? Column(
                  key: ValueKey('section-open-${section.key}'),
                  children: [
                    for (final sale in section.sales)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSaleCard(sale),
                      ),
                  ],
                )
              : const SizedBox(
                  key: ValueKey('section-closed'),
                ),
        ),
      ),
    ),
  ];
}),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopArea(List<Sale> filteredSales, double totalFilteredAmount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          _buildSearchCard(),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HistorySummaryCard(
                label: 'Ventas visibles',
                value: '${filteredSales.length}',
              ),
              _HistorySummaryCard(
                label: 'Monto visible',
                value: _formatCurrency(totalFilteredAmount),
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por fecha, folio, cliente, producto, clave o método',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close),
                  tooltip: 'Limpiar búsqueda',
                ),
        ),
      ),
    );
  }

Widget _buildSectionGroupHeader({
  required _SalesSection section,
  required double total,
  required bool isExpanded,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFFD7E3FF)
              : const Color(0xFFE5E5EA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isExpanded ? 0.05 : 0.03),
            blurRadius: isExpanded ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedRotation(
            turns: isExpanded ? 0.0 : -0.25,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: const Icon(Icons.keyboard_arrow_down),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              section.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${section.sales.length} venta${section.sales.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrency(total),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSaleCard(Sale sale) {
    final itemsCount = sale.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return InkWell(
      onTap: () => _openSaleDetail(sale),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5EA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _buildSaleFolio(sale),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _paymentMethodColor(sale.paymentMethod)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _paymentMethodLabel(sale.paymentMethod),
                    style: TextStyle(
                      color: _paymentMethodColor(sale.paymentMethod),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
Text(
  _formatDate(sale.createdAt),
  style: TextStyle(
    color: Colors.grey[600],
    fontSize: 13,
  ),
),
if (sale.customerName != null && sale.customerName!.trim().isNotEmpty) ...[
  const SizedBox(height: 8),
  Text(
    'Cliente: ${sale.customerName!}',
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: Colors.grey[800],
    ),
  ),
],
if (sale.isCustomerLedger) ...[
  const SizedBox(height: 6),
  Text(
    'Venta enviada a libreta',
    style: TextStyle(
      fontSize: 12,
      color: Colors.orange[800],
      fontWeight: FontWeight.w600,
    ),
  ),
],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HistoryInfoChip(
                  label: 'Artículos',
                  value: '$itemsCount',
                ),
                _HistoryInfoChip(
                  label: 'Total',
                  value: _formatCurrency(sale.total),
                  highlight: true,
                ),
              ],
            ),
            if (sale.transferReference != null &&
                sale.transferReference!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Referencia: ${sale.transferReference!}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    sale.items.take(2).map((e) => e.productName).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(
            icon,
            size: 56,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class SaleDetailPage extends StatelessWidget {
  final Sale sale;

  const SaleDetailPage({
    super.key,
    required this.sale,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = sale.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de venta'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E5EA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _buildSaleFolio(sale),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _HistoryInfoChip(
                      label: 'Artículos',
                      value: '$totalItems',
                    ),
                    _HistoryInfoChip(
                      label: 'Total',
                      value: _formatCurrency(sale.total),
                      highlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
Text('Fecha: ${_formatDate(sale.createdAt)}'),
if (sale.customerName != null && sale.customerName!.trim().isNotEmpty) ...[
  const SizedBox(height: 4),
  Text('Cliente: ${sale.customerName!}'),
],
const SizedBox(height: 4),
Text('Método de pago: ${_paymentMethodLabel(sale.paymentMethod)}'),
if (sale.isCustomerLedger) ...[
  const SizedBox(height: 4),
  const Text('Tipo: Venta enviada a libreta'),
],
                if (sale.amountReceived != null) ...[
                  const SizedBox(height: 4),
                  Text('Monto recibido: ${_formatCurrency(sale.amountReceived!)}'),
                ],
                if (sale.changeAmount != null) ...[
                  const SizedBox(height: 4),
                  Text('Cambio: ${_formatCurrency(sale.changeAmount!)}'),
                ],
                if (sale.transferReference != null &&
                    sale.transferReference!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Referencia: ${sale.transferReference!}'),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SaleTicketPreviewPage(sale: sale),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Ver ticket'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Productos',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...sale.items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E5EA)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SaleDetailThumbnail(
                    imageUrl: item.imageUrl,
                    localImagePath: item.localImagePath,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Clave: ${item.internalCode}'),
                        if (item.barcode != null &&
                            item.barcode!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('Código: ${item.barcode!}'),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _HistoryInfoChip(
                              label: 'Cantidad',
                              value: '${item.quantity}',
                            ),
                            _HistoryInfoChip(
                              label: 'Precio',
                              value: _formatCurrency(item.unitPrice),
                            ),
                            _HistoryInfoChip(
                              label: 'Subtotal',
                              value: _formatCurrency(item.total),
                              highlight: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SaleTicketPreviewPage extends StatelessWidget {
  final Sale sale;

  const SaleTicketPreviewPage({
    super.key,
    required this.sale,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = sale.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket'),
        centerTitle: true,
      ),
      body: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, shopState) {
          String shopName = 'Mi tienda';
          String address1 = '';
          String address2 = '';
          String phone = '';
          String footer = '';

          if (shopState is ShopLoaded) {
            shopName = shopState.shop.name;
            address1 = shopState.shop.addressLine1;
            address2 = shopState.shop.addressLine2;
            phone = shopState.shop.phoneNumber;
            footer = shopState.shop.footerText;
          }

          return Container(
            color: const Color(0xFFF3F4F6),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          shopName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (address1.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            address1,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                        if (address2.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            address2,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tel. $phone',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        _TicketRow(label: 'Folio', value: _buildSaleFolio(sale)),
                        const SizedBox(height: 4),
_TicketRow(label: 'Fecha', value: _formatDate(sale.createdAt)),
if (sale.customerName != null && sale.customerName!.trim().isNotEmpty) ...[
  const SizedBox(height: 4),
  _TicketRow(label: 'Cliente', value: sale.customerName!),
],
const SizedBox(height: 4),
_TicketRow(
  label: 'Pago',
  value: _paymentMethodLabel(sale.paymentMethod),
),
if (sale.isCustomerLedger) ...[
  const SizedBox(height: 4),
  const _TicketRow(
    label: 'Tipo',
    value: 'Venta enviada a libreta',
  ),
],
                        if (sale.amountReceived != null) ...[
                          const SizedBox(height: 4),
                          _TicketRow(
                            label: 'Recibido',
                            value: _formatCurrency(sale.amountReceived!),
                          ),
                        ],
                        if (sale.changeAmount != null) ...[
                          const SizedBox(height: 4),
                          _TicketRow(
                            label: 'Cambio',
                            value: _formatCurrency(sale.changeAmount!),
                          ),
                        ],
                        if (sale.transferReference != null &&
                            sale.transferReference!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _TicketRow(
                            label: 'Referencia',
                            value: sale.transferReference!,
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Productos',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...sale.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.quantity} x ${_formatCurrency(item.unitPrice)}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _formatCurrency(item.total),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        _TicketRow(
                          label: 'Artículos',
                          value: '$totalItems',
                        ),
                        const SizedBox(height: 6),
                        _TicketRow(
                          label: 'Subtotal',
                          value: _formatCurrency(sale.subtotal),
                        ),
                        const SizedBox(height: 6),
                        _TicketRow(
                          label: 'Descuento',
                          value: _formatCurrency(sale.discount),
                        ),
                        const SizedBox(height: 10),
                        _TicketRow(
                          label: 'TOTAL',
                          value: _formatCurrency(sale.total),
                          highlight: true,
                        ),
                        if (footer.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const Divider(),
                          const SizedBox(height: 12),
                          Text(
                            footer,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _TicketRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: highlight ? 16 : 13,
      fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
      color: highlight ? const Color(0xFF111827) : Colors.black87,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: style,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _SalesSection {
  final String key;
  final String title;
  final List<Sale> sales;
  final DateTime sortDate;
  final bool isToday;

  _SalesSection({
    required this.key,
    required this.title,
    required this.sales,
    required this.sortDate,
    required this.isToday,
  });
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _SectionHeaderDelegate({
    required this.height,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _HistorySummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _HistorySummaryCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = highlight ? const Color(0xFFE8F0FE) : Colors.white;
    final foreground =
        highlight ? const Color(0xFF1A73E8) : const Color(0xFF111827);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: foreground.withValues(alpha: 0.75),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _HistoryInfoChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        highlight ? const Color(0xFFE8F0FE) : Colors.grey.shade100;
    final foreground =
        highlight ? const Color(0xFF1A73E8) : Colors.grey.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: foreground.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleDetailThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String? localImagePath;

  const _SaleDetailThumbnail({
    required this.imageUrl,
    required this.localImagePath,
  });

  @override
  Widget build(BuildContext context) {
    if (localImagePath != null && localImagePath!.trim().isNotEmpty) {
      final file = File(localImagePath!);

      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: 58,
            height: 58,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.inventory_2_outlined,
          color: Colors.grey.shade400,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl!,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.grey.shade400,
            ),
          );
        },
      ),
    );
  }
}