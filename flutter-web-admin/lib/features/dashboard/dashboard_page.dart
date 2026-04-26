import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/kpi_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/estado_chip.dart';

/// Provider for dashboard metrics
final dashboardMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // TODO: Connect to Convex queries
  // This will fetch from Convex
  return {
    'pedidos_hoy': 12,
    'ventas_hoy': 8590.50,
    'clientes_activos': 45,
    'mensajes_hoy': 8,
  };
});

/// Provider for recent orders
final recentOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // TODO: Connect to Convex query
  return [
    {
      'id': 'ord_001',
      'cliente_nombre': 'Juan Pérez',
      'total': 1450.00,
      'estado': 'lista_para_imprimir',
      'created_at': DateTime.now().subtract(Duration(minutes: 5)),
    },
    {
      'id': 'ord_002',
      'cliente_nombre': 'María García',
      'total': 2340.00,
      'estado': 'confirmada',
      'created_at': DateTime.now().subtract(Duration(minutes: 15)),
    },
    {
      'id': 'ord_003',
      'cliente_nombre': 'Carlos López',
      'total': 890.00,
      'estado': 'impresa',
      'created_at': DateTime.now().subtract(Duration(minutes: 30)),
    },
  ];
});

/// Provider for last 7 days sales
final last7DaysSalesProvider = FutureProvider<List<FlSpot>>((ref) async {
  // TODO: Connect to Convex query
  return [
    const FlSpot(0, 4200),
    const FlSpot(1, 3800),
    const FlSpot(2, 5100),
    const FlSpot(3, 4800),
    const FlSpot(4, 6200),
    const FlSpot(5, 5900),
    const FlSpot(6, 6500),
  ];
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final ordersAsync = ref.watch(recentOrdersProvider);

    return Scaffold(
      backgroundColor: ColmariaColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards
            metricsAsync.when(
              data: (metrics) => _buildKpiCards(context, metrics),
              loading: () => _buildKpiLoading(),
              error: (_, __) => _buildKpiCards(context, {
                'pedidos_hoy': 0,
                'ventas_hoy': 0.0,
                'clientes_activos': 0,
                'mensajes_hoy': 0,
              }),
            ),
            const SizedBox(height: 24),
            
            // Chart and Recent Orders Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sales Chart - 60%
                Expanded(
                  flex: 60,
                  child: _buildSalesChart(),
                ),
                const SizedBox(width: 24),
                // Recent Orders - 40%
                Expanded(
                  flex: 40,
                  child: _buildRecentOrders(context, ref, ordersAsync),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // System Status
            _buildSystemStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCards(BuildContext context, Map<String, dynamic> metrics) {
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
                title: 'Pedidos hoy',
                value: '${metrics['pedidos_hoy']}',
                icon: Icons.receipt_long,
                color: ColmariaColors.primary,
                onTap: () => context.go('/pedidos'),
              ),
            ),
            SizedBox(
              width: cardWidth.clamp(200, 300),
              child: KpiCard(
                title: 'Ventas hoy',
                value: '\$${(metrics['ventas_hoy'] as double).toStringAsFixed(0)}',
                icon: Icons.attach_money,
                color: ColmariaColors.chipGreenTx,
              ),
            ),
            SizedBox(
              width: cardWidth.clamp(200, 300),
              child: KpiCard(
                title: 'Clientes activos',
                value: '${metrics['clientes_activos']}',
                icon: Icons.people,
                color: ColmariaColors.info,
                onTap: () => context.go('/clientes'),
              ),
            ),
            SizedBox(
              width: cardWidth.clamp(200, 300),
              child: KpiCard(
                title: 'Mensajes hoy',
                value: '${metrics['mensajes_hoy']}',
                icon: Icons.chat,
                color: ColmariaColors.warning,
                onTap: () => context.go('/whatsapp'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiLoading() {
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

  Widget _buildSalesChart() {
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
            'Ventas últimos 7 días',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColmariaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2000,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: ColmariaColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
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
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 4200),
                      FlSpot(1, 3800),
                      FlSpot(2, 5100),
                      FlSpot(3, 4800),
                      FlSpot(4, 6200),
                      FlSpot(5, 5900),
                      FlSpot(6, 6500),
                    ],
                    isCurved: true,
                    color: ColmariaColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
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

  Widget _buildRecentOrders(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Map<String, dynamic>>> ordersAsync,
  ) {
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
          Row(
            children: [
              Text(
                'Pedidos recientes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColmariaColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/pedidos'),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ordersAsync.when(
            data: (orders) => Column(
              children: orders.map((order) => _buildOrderItem(order)).toList(),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => EmptyState(
              icon: Icons.error_outline,
              title: 'Error al cargar',
              subtitle: 'Intenta de nuevo más tarde',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ColmariaColors.divider),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['cliente_nombre'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: ColmariaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order['id'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: ColmariaColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${(order['total'] as double).toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ColmariaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              EstadoChip(estado: order['estado'] as String),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColmariaColors.divider),
      ),
      child: Row(
        children: [
          Text(
            'Estado del sistema',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColmariaColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ColmariaColors.chipGreenBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ColmariaColors.chipGreenTx,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Operativo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ColmariaColors.chipGreenTx,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}