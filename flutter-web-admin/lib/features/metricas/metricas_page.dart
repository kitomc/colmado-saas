import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../app/theme.dart';
import '../../shared/widgets/kpi_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/utils/formatters.dart';

/// Opciones de rango de fechas para las métricas
enum RangoMetricas {
  siete('7 días'),
  treinta('30 días'),
  noventa('90 días');

  final String label;
  const RangoMetricas(this.label);
}

/// Placeholder provider until Convex queries are implemented
final _mockMetricasProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return {};
});

class MetricasPage extends ConsumerStatefulWidget {
  const MetricasPage({super.key});

  @override
  ConsumerState<MetricasPage> createState() => _MetricasPageState();
}

class _MetricasPageState extends ConsumerState<MetricasPage> {
  RangoMetricas _rangoSeleccionado = RangoMetricas.siete;

  @override
  Widget build(BuildContext context) {
    // TODO: Usar _rangoSeleccionado para filtrar cuando el provider real esté implementado
    final metricasAsync = ref.watch(_mockMetricasProvider);

    return Scaffold(
      backgroundColor: ColmariaColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Text(
                  'Métricas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: ColmariaColors.textPrimary,
                  ),
                ),
                const Spacer(),
                SegmentedButton<RangoMetricas>(
                  segments: RangoMetricas.values.map((r) {
                    return ButtonSegment(value: r, label: Text(r.label));
                  }).toList(),
                  selected: {_rangoSeleccionado},
                  onSelectionChanged: (selected) {
                    setState(() => _rangoSeleccionado = selected.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Contenido según estado ──
            metricasAsync.when(
              data: (data) => _buildContent(data),
              loading: () => _buildLoading(),
              error: (_, __) => _buildError(),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  CONTENIDO PRINCIPAL
  // ══════════════════════════════════════════════════

  Widget _buildContent(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return SizedBox(
        height: 400,
        child: EmptyState(
          icon: Icons.bar_chart,
          title: 'No hay datos para este período',
          subtitle:
              'Las métricas aparecerán cuando haya actividad en el colmado.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKpiRow(data),
        const SizedBox(height: 24),
        _buildVentasPorDia(data),
        const SizedBox(height: 24),
        _buildTopProductos(data),
        const SizedBox(height: 24),
        _buildRendimientoBot(data),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  //  FILA 1 — KPI Cards
  // ══════════════════════════════════════════════════

  Widget _buildKpiRow(Map<String, dynamic> data) {
    final ventasTotal = (data['ventasTotal'] as num?)?.toDouble() ?? 0;
    final totalOrdenes = (data['totalOrdenes'] as num?)?.toInt() ?? 0;
    final ticketPromedio = (data['ticketPromedio'] as num?)?.toDouble() ?? 0;
    final clientesUnicos = (data['clientesUnicos'] as num?)?.toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 48) / 4;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth.clamp(200, 300),
              child: KpiCard(
                title: 'Ventas totales',
                value: formatRD(ventasTotal),
                icon: Icons.trending_up,
                color: ColmariaColors.primary,
              ),
            ),
            SizedBox(
              width: cardWidth.clamp(200, 300),
              child: KpiCard(
                title: 'Total órdenes',
                value: totalOrdenes.toString(),
                icon: Icons.receipt_long,
                color: ColmariaColors.info,
              ),
            ),
            SizedBox(
              width: cardWidth.clamp(200, 300),
              child: KpiCard(
                title: 'Ticket promedio',
                value: formatRD(ticketPromedio),
                icon: Icons.payments,
                color: ColmariaColors.warning,
              ),
            ),
            SizedBox(
              width: cardWidth.clamp(200, 300),
              child: KpiCard(
                title: 'Clientes únicos',
                value: clientesUnicos?.toString() ?? '-',
                icon: Icons.people,
                color: ColmariaColors.chipGreenTx,
              ),
            ),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════
  //  FILA 2 — Ventas por día (LineChart)
  // ══════════════════════════════════════════════════

  Widget _buildVentasPorDia(Map<String, dynamic> data) {
    final ventasPorDia = data['ventasPorDia'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColmariaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ventas por día',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColmariaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          if (ventasPorDia.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(child: Text('No hay datos para este período')),
            )
          else
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: ColmariaColors.divider,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: _bottomInterval(ventasPorDia.length),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= ventasPorDia.length) {
                            return const SizedBox.shrink();
                          }
                          final item =
                              ventasPorDia[idx] as Map<String, dynamic>;
                          final fecha = item['fecha'] as String? ?? '';
                          // Mostrar solo día/mes
                          final parts = fecha.split('-');
                          final label = parts.length >= 3
                              ? '${parts[2]}/${parts[1]}'
                              : fecha;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: ColmariaColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatAxisRD(value),
                            style: TextStyle(
                              color: ColmariaColors.textMuted,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: ventasPorDia.asMap().entries.map((entry) {
                        final item = entry.value as Map<String, dynamic>;
                        final ventas =
                            (item['ventas'] as num?)?.toDouble() ?? 0;
                        return FlSpot(entry.key.toDouble(), ventas);
                      }).toList(),
                      isCurved: true,
                      color: ColmariaColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: ventasPorDia.length <= 31,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: ColmariaColors.primary,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: ColmariaColors.primary.withValues(alpha: 0.1),
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

  /// Espaciado entre labels del eje X: mostrar aprox 7 labels máximo
  double _bottomInterval(int totalDays) {
    if (totalDays <= 7) return 1;
    if (totalDays <= 14) return 2;
    if (totalDays <= 31) return 5;
    return 10;
  }

  /// Formato compacto para el eje Y: RD$ 1.2k, RD$ 15k, etc.
  String _formatAxisRD(double value) {
    if (value >= 1000000) {
      return 'RD\$ ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'RD\$ ${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'RD\$ ${value.toStringAsFixed(0)}';
  }

  // ══════════════════════════════════════════════════
  //  FILA 3 — Top 10 Productos (DataTable)
  // ══════════════════════════════════════════════════

  Widget _buildTopProductos(Map<String, dynamic> data) {
    final topProductos = data['topProductos'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColmariaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 10 productos más vendidos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColmariaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (topProductos.isEmpty)
            const SizedBox(
              height: 80,
              child: Center(child: Text('No hay datos')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 32,
                headingRowColor: WidgetStateProperty.all(
                  ColmariaColors.background,
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Producto',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(
                      'Unidades',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(
                      'Total RD\$',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                rows: topProductos.take(10).map((item) {
                  final p = item as Map<String, dynamic>;
                  final nombre = p['nombre'] as String? ?? '-';
                  final unidades = (p['unidades'] as num?)?.toInt() ?? 0;
                  final total = (p['total'] as num?)?.toDouble() ?? 0;
                  return DataRow(cells: [
                    DataCell(Text(nombre)),
                    DataCell(Text(unidades.toString())),
                    DataCell(Text(formatRD(total))),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  FILA 4 — Rendimiento del Bot
  // ══════════════════════════════════════════════════

  Widget _buildRendimientoBot(Map<String, dynamic> data) {
    final mensajesProcesados =
        (data['mensajesProcesados'] as num?)?.toInt() ?? 0;
    final ordenesGeneradas =
        (data['ordenesGeneradas'] as num?)?.toInt() ?? 0;
    final tasaConversion = mensajesProcesados > 0
        ? (ordenesGeneradas / mensajesProcesados) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColmariaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rendimiento del bot',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColmariaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildBotStat(
                icon: Icons.chat,
                label: 'Mensajes procesados',
                value: mensajesProcesados.toString(),
                color: ColmariaColors.info,
              ),
              const SizedBox(width: 24),
              _buildBotStat(
                icon: Icons.receipt,
                label: 'Órdenes generadas',
                value: ordenesGeneradas.toString(),
                color: ColmariaColors.primary,
              ),
              const SizedBox(width: 24),
              _buildBotStat(
                icon: Icons.trending_up,
                label: 'Tasa de conversión',
                value: '${tasaConversion.toStringAsFixed(1)}%',
                color: ColmariaColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ColmariaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: ColmariaColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  ESTADOS: Loading / Error
  // ══════════════════════════════════════════════════

  Widget _buildLoading() {
    return Column(
      children: [
        _buildLoadingRow(),
        const SizedBox(height: 24),
        _buildLoadingCard(height: 250),
        const SizedBox(height: 24),
        _buildLoadingCard(height: 200),
        const SizedBox(height: 24),
        _buildLoadingCard(height: 120),
      ],
    );
  }

  Widget _buildLoadingRow() {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 3 ? 16 : 0),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColmariaColors.divider),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColmariaColors.divider),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: 400,
      child: EmptyState(
        icon: Icons.error_outline,
        title: 'Error al cargar métricas',
        subtitle: 'Intenta de nuevo más tarde o verifica tu conexión.',
      ),
    );
  }
}
