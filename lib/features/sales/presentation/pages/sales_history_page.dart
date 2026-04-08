import 'package:flutter/material.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../domain/entities/sale.dart';

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

  /// true = colapsada
  final Map<String, bool> _collapsedSections = {};

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

  void _clearSearch() {
    _searchController.clear();
  }

  void _toggleSection(String key) {
    setState(() {
      _collapsedSections[key] = !(_collapsedSections[key] ?? false);
    });
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)} MXN';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDate(DateTime date) {
    return '${_two(date.day)}/${_two(date.month)}/${date.year} ${_two(date.hour)}:${_two(date.minute)}';
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Efectivo';
      case 'transfer':
        return 'Transferencia';
      case 'point':
        return 'Tarjeta / Point';
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
      default:
        return Colors.grey;
    }
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
      payment,
      reference,
      productTerms,
      dateTerms,
    ].join(' ').toLowerCase();
  }

  bool _saleMatchesSearch(Sale sale, String query) {
    if (query.isEmpty) return true;
    return _buildSaleSearchIndex(sale).contains(query);
  }

  List<_SalesSection> _buildSections(List<Sale> sales) {
    final now = DateTime.now();
    final Map<String, _SalesSection> sections = {};

    for (final sale in sales) {
      final saleDate = sale.createdAt;
      final saleDay = DateTime(saleDate.year, saleDate.month, saleDate.day);
      final nowDay = DateTime(now.year, now.month, now.day);
      final diffDays = nowDay.difference(saleDay).inDays;

      late final String key;
      late final String title;

      if (diffDays < 31) {
        key = 'day-${saleDate.year}-${_two(saleDate.month)}-${_two(saleDate.day)}';
        title = _buildDayTitle(saleDate, now);
      } else if (diffDays < 366) {
        key = 'month-${saleDate.year}-${_two(saleDate.month)}';
        title = '${_monthName(saleDate.month)} ${saleDate.year}';
      } else {
        key = 'year-${saleDate.year}';
        title = '${saleDate.year}';
      }

      sections.putIfAbsent(
        key,
        () => _SalesSection(
          key: key,
          title: title,
          sales: [],
        ),
      );

      sections[key]!.sales.add(sale);
    }

    return sections.values.toList();
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
                children: const [
                  SizedBox(height: 180),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
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
                .toList();

            final sections = _buildSections(filteredSales);

            final totalFilteredAmount = filteredSales.fold<double>(
              0,
              (sum, sale) => sum + sale.total,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                const SizedBox(height: 16),
                if (sales.isEmpty)
                  _buildEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Aún no hay ventas guardadas.',
                    subtitle: 'Cuando confirmes ventas, aparecerán aquí.',
                  )
                else if (filteredSales.isEmpty)
                  _buildEmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'No se encontraron resultados.',
                    subtitle:
                        'Puedes buscar por fecha, folio, método de pago, referencia, nombre, clave o código.',
                  )
                else
                  ...sections.map((section) {
                    final sectionTotal = section.sales.fold<double>(
                      0,
                      (sum, sale) => sum + sale.total,
                    );

                    final isCollapsed = _searchQuery.isEmpty
                        ? (_collapsedSections[section.key] ?? false)
                        : false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionGroupHeader(
                            section: section,
                            total: sectionTotal,
                            isCollapsed: isCollapsed,
                          ),
                          if (!isCollapsed) ...[
                            const SizedBox(height: 12),
                            ...section.sales.map(
                              (sale) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildSaleCard(sale),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        ),
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
          hintText: 'Buscar por fecha, folio, producto, clave o método',
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
    required bool isCollapsed,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _toggleSection(section.key),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Row(
          children: [
            Icon(
              isCollapsed
                  ? Icons.keyboard_arrow_right
                  : Icons.keyboard_arrow_down,
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
            const SizedBox(width: 10),
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
                    'Venta #${sale.id}',
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

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)} MXN';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDate(DateTime date) {
    return '${_two(date.day)}/${_two(date.month)}/${date.year} ${_two(date.hour)}:${_two(date.minute)}';
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Efectivo';
      case 'transfer':
        return 'Transferencia';
      case 'point':
        return 'Tarjeta / Point';
      default:
        return method;
    }
  }

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
                  'Venta #${sale.id}',
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
                const SizedBox(height: 4),
                Text('Método de pago: ${_paymentMethodLabel(sale.paymentMethod)}'),
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
                  _SaleDetailThumbnail(imageUrl: item.imageUrl),
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

class _SalesSection {
  final String key;
  final String title;
  final List<Sale> sales;

  _SalesSection({
    required this.key,
    required this.title,
    required this.sales,
  });
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

  const _SaleDetailThumbnail({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
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