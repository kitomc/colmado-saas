import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../app/theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/estado_chip.dart';

/// Helper to get current tab value
String tabValueFromIndex(int index) {
  switch (index) {
    case 0:
      return 'lista_para_imprimir';
    case 1:
      return 'imprimiendo';
    case 2:
      return 'impresa';
    case 3:
      return 'todos';
    default:
      return 'todos';
  }
}

/// Helper to get tab label
String tabLabelFromIndex(int index) {
  switch (index) {
    case 0:
      return 'En cola';
    case 1:
      return 'Imprimiendo';
    case 2:
      return 'Impresos';
    case 3:
      return 'Todos';
    default:
      return 'Todos';
  }
}

/// Provider for orders filtered by tab
final ordersProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tab) async {
  // TODO: Connect to Convex query with filter
  final allOrders = [
    {
      'id': 'ord_001',
      'cliente_nombre': 'Juan Pérez',
      'cliente_telefono': '8091234567',
      'items': [
        {'nombre': 'Cerveza Presidente', 'cantidad': 6, 'precio': 80},
      ],
      'total': 480.00,
      'estado': 'lista_para_imprimir',
      'created_at': DateTime.now().subtract(Duration(minutes: 5)),
    },
    {
      'id': 'ord_002',
      'cliente_nombre': 'María García',
      'cliente_telefono': '8299876543',
      'items': [
        {'nombre': 'Bavaria', 'cantidad': 12, 'precio': 75},
        {'nombre': 'Papas Hit', 'cantidad': 2, 'precio': 35},
      ],
      'total': 970.00,
      'estado': 'confirmada',
      'created_at': DateTime.now().subtract(Duration(minutes: 15)),
    },
    {
      'id': 'ord_003',
      'cliente_nombre': 'Carlos López',
      'cliente_telefono': '8495551234',
      'items': [
        {'nombre': 'Quilmes', 'cantidad': 6, 'precio': 85},
        {'nombre': 'Galletas Gamesa', 'cantidad': 3, 'precio': 25},
      ],
      'total': 585.00,
      'estado': 'imprimiendo',
      'created_at': DateTime.now().subtract(Duration(minutes: 25)),
    },
    {
      'id': 'ord_004',
      'cliente_nombre': 'Ana Martínez',
      'cliente_telefono': '8094445678',
      'items': [
        {'nombre': 'Cerveza Presidente', 'cantidad': 24, 'precio': 80},
      ],
      'total': 1920.00,
      'estado': 'impresa',
      'created_at': DateTime.now().subtract(Duration(minutes: 45)),
    },
    {
      'id': 'ord_005',
      'cliente_nombre': 'Luis Rodríguez',
      'cliente_telefono': '8297778888',
      'items': [
        {'nombre': 'Bavaria', 'cantidad': 6, 'precio': 75},
      ],
      'total': 450.00,
      'estado': 'cancelada',
      'created_at': DateTime.now().subtract(Duration(hours: 1)),
    },
  ];

  if (tab == 'todos') return allOrders;
  
  return allOrders.where((order) => order['estado'] == tab).toList();
});

/// Provider for current tab index
final pedidosTabProvider = StateProvider<int>((ref) => 0);

class PedidosPage extends ConsumerWidget {
  const PedidosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(pedidosTabProvider);
    final tabValue = tabValueFromIndex(currentTab);
    final ordersAsync = ref.watch(ordersProvider(tabValue));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: ColmariaColors.background,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Pedidos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: ColmariaColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => ref.invalidate(ordersProvider(tabValue)),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColmariaColors.divider),
                ),
                child: TabBar(
                  controller: DefaultTabController.of(context),
                  onTap: (index) => ref.read(pedidosTabProvider.notifier).state = index,
                  labelColor: ColmariaColors.primary,
                  unselectedLabelColor: ColmariaColors.textMuted,
                  indicatorColor: ColmariaColors.primary,
                  tabs: [
                    Tab(text: tabLabelFromIndex(0)),
                    Tab(text: tabLabelFromIndex(1)),
                    Tab(text: tabLabelFromIndex(2)),
                    Tab(text: tabLabelFromIndex(3)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Orders List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColmariaColors.divider),
                  ),
                  child: ordersAsync.when(
                    data: (orders) {
                      if (orders.isEmpty) {
                        return EmptyState(
                          icon: Icons.receipt_long,
                          title: 'No hay pedidos',
                          subtitle: tabValueFromIndex(currentTab) == 'todos'
                              ? 'Los pedidos aparecerán aquí'
                              : 'No hay pedidos en este estado',
                        );
                      }
                      return _buildOrdersList(context, orders);
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (_, __) => EmptyState(
                      icon: Icons.error_outline,
                      title: 'Error al cargar',
                      subtitle: 'Intenta de nuevo más tarde',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, List<Map<String, dynamic>> orders) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderItem(context, order);
      },
    );
  }

  Widget _buildOrderItem(BuildContext context, Map<String, dynamic> order) {
    final estado = order['estado'] as String;
    final items = order['items'] as List<Map<String, dynamic>>;
    final createdAt = order['created_at'] as DateTime;

    return InkWell(
      onTap: () => _showOrdenModal(context, order),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Order info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        order['id'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ColmariaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      EstadoChip(estado: estado),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order['cliente_nombre'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order['cliente_telefono'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: ColmariaColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Items preview
                  Text(
                    items
                        .map((item) => '${item['cantidad']}x ${item['nombre']}')
                        .join(', '),
                    style: TextStyle(
                      fontSize: 12,
                      color: ColmariaColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Total and time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${(order['total'] as double).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColmariaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: ColmariaColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrdenModal(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Pedido ${order['id']}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  EstadoChip(estado: order['estado'] as String),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Cliente',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ColmariaColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(order['cliente_nombre'] as String),
              Text(
                order['cliente_telefono'] as String,
                style: TextStyle(color: ColmariaColors.textMuted),
              ),
              const SizedBox(height: 16),
              Text(
                'Items',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ColmariaColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...(order['items'] as List<Map<String, dynamic>>).map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: ColmariaColors.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${item['cantidad']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item['nombre'] as String)),
                    Text(
                      '\$${((item['cantidad'] as int) * (item['precio'] as int)).toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  Text(
                    'Total: ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$${(order['total'] as double).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColmariaColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Acciones based on estado
              _buildAcciones(context, order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcciones(BuildContext context, Map<String, dynamic> order) {
    final estado = order['estado'] as String;

    switch (estado) {
      case 'lista_para_imprimir':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Call mutation - cancel
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColmariaColors.error,
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Call mutation - imprimir
                  Navigator.pop(context);
                },
                child: const Text('Imprimir'),
              ),
            ),
          ],
        );
      case 'imprimiendo':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Call mutation - re-imprimir
                  Navigator.pop(context);
                },
                child: const Text('Re-imprimir'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Call mutation - marcar impresa
                  Navigator.pop(context);
                },
                child: const Text('Marcar impresa'),
              ),
            ),
          ],
        );
      default:
        return SizedBox.shrink();
    }
  }
}