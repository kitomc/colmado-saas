import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../app/theme.dart';
import '../../shared/widgets/kpi_card.dart';

/// Provider for weekly metrics
final metricasSemanalesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // TODO: Connect to Convex query
  return {
    'ventas_semana': 45200.00,
    'pedidos_semana': 89,
    'nuevos_clientes': 12,
    'ticket_promedio': 508.00,
  };
});

/// Provider for daily breakdown
final metricasDiariasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // TODO: Connect to Convex query
  return [
    {'dia': 'Lun', 'ventas': 6200, 'pedidos': 12},
    {'dia': 'Mar', 'ventas': 5800, 'pedidos': 10},
    {'dia': 'Mié', 'ventas': 7100, 'pedidos': 14},
    {'dia': 'Jue', 'ventas': 6500, 'pedidos': 11},
    {'dia': 'Vie', 'ventas': 8200, 'pedidos': 16},
    {'dia': 'Sáb', 'ventas': 9400, 'pedidos': 18},
    {'dia': 'Dom', 'ventas': 2000, 'pedidos': 8},
  ];
});

/// Provider for top products
final topProductosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // TODO: Connect to Convex query
  return [
    {'nombre': 'Cerveza Presidente', 'cantidad': 145, 'ingresos': 11600},
    {'nombre': 'Bavaria', 'cantidad': 98, 'ingresos': 7350},
    {'nombre': 'Quilmes', 'cantidad': 76, 'ingresos': 6460},
    {'nombre': 'Papas Hit', 'cantidad': 234, 'ingresos': 8190},
    {'nombre': 'Galletas Gamesa', 'cantidad': 189, 'ingresos': 4725},
  ];
});

class MetricasPage extends ConsumerWidget {
  const MetricasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semanalesAsync = ref.watch(metricasSemanalesProvider);
    final diariasAsync = ref.watch(metricasDiariasProvider);
    final topAsync = ref.watch(topProductosProvider);

    return Scaffold(
      backgroundColor: ColmariaColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métricas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: ColmariaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Weekly KPIs
            semanalesAsync.when(
              data: (data) => _buildWeeklyKPIs(data),
              loading: () => _buildLoadingRow(),
              error: (_, __) => _buildWeeklyKPIs({}),
            ),
            const SizedBox(height: 24),
            
            // Charts Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily Chart - 60%
                Expanded(
                  flex: 60,
                  child: _buildDailyChart(diariasAsync),
                ),
                const SizedBox(width: 24),
                // Top Products - 40%
                Expanded(
                  flex: 40,
                  child: _buildTopProducts(topAsync),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyKPIs(Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: KpiCard(
            title: 'Ventas semana',
            value: '\$${(data['ventas_semana'] as double? ?? 0).toStringAsFixed(0)}',
            icon: Icons.trending_up,
            color: ColmariaColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: KpiCard(
            title: 'Pedidos semana',
            value: '${data['pedidos_semana'] ?? 0}',
            icon: Icons.receipt_long,
            color: ColmariaColors.info,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: KpiCard(
            title: 'Nuevos clientes',
            value: '${data['nuevos_clientes'] ?? 0}',
            icon: Icons.person_add,
            color: ColmariaColors.chipGreenTx,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: KpiCard(
            title: 'Ticket promedio',
            value: '\$${(data['ticket_promedio'] as double? ?? 0).toStringAsFixed(0)}',
            icon: Icons.payments,
            color: ColmariaColors.warning,
          ),
        ),
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
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDailyChart(AsyncValue<List<Map<String, dynamic>>> dataAsync) {
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
          dataAsync.when(
            data: (data) => SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.map((d) => d['ventas'] as int).reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                          return Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: ColmariaColors.textMuted,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${(value / 1000).toStringAsFixed(0)}k',
                            style: TextStyle(
                              color: ColmariaColors.textMuted,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2000,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: (entry.value['ventas'] as int).toDouble(),
                          color: ColmariaColors.primary,
                          width: 24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(
              height: 200,
              child: Center(child: Text('Error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(AsyncValue<List<Map<String, dynamic>>> dataAsync) {
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
            'Productos más vendidos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColmariaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          dataAsync.when(
            data: (data) => Column(
              children: data.asMap().entries.map((entry) {
                final producto = entry.value;
                final maxCant = data.map((p) => p['cantidad'] as int).reduce((a, b) => a > b ? a : b);
                final percent = (producto['cantidad'] as int) / maxCant;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            producto['nombre'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${producto['cantidad']}u',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ColmariaColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percent,
                        backgroundColor: ColmariaColors.background,
                        valueColor: AlwaysStoppedAnimation(ColmariaColors.primary),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error'),
          ),
        ],
      ),
    );
  }
}