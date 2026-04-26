import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/empty_state.dart';

/// Placeholder provider until Convex queries are implemented
final _mockClientesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return [];
});

/// Search query provider
final clientesSearchProvider = StateProvider<String>((ref) => '');

class ClientesPage extends ConsumerWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(clientesSearchProvider);
    final clientesAsync = ref.watch(_mockClientesProvider);

    return Scaffold(
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
                  'Clientes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: ColmariaColors.textPrimary,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 300,
                  child: TextField(
                    onChanged: (value) =>
                        ref.read(clientesSearchProvider.notifier).state = value,
                    decoration: InputDecoration(
                      hintText: 'Buscar clientes...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Clients Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColmariaColors.divider),
                ),
                child: clientesAsync.when(
                  data: (clientes) {
                    // Filter by search
                    final filtered = searchQuery.isEmpty
                        ? clientes
                        : clientes.where((c) {
                            final query = searchQuery.toLowerCase();
                            return (c['nombre'] as String).toLowerCase().contains(query) ||
                                (c['telefono'] as String).contains(query);
                          }).toList();

                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Icons.people,
                        title: searchQuery.isEmpty
                            ? 'No hay clientes'
                            : 'No se encontraron clientes',
                        subtitle: searchQuery.isEmpty
                            ? 'Los clientes aparecerán aquí'
                            : 'Intenta con otro término',
                        action: searchQuery.isNotEmpty
                            ? TextButton(
                                onPressed: () => ref.read(clientesSearchProvider.notifier).state = '',
                                child: const Text('Limpiar búsqueda'),
                              )
                            : null,
                      );
                    }
                    return _buildClientsTable(context, filtered);
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
    );
  }

  Widget _buildClientsTable(
    BuildContext context,
    List<Map<String, dynamic>> clientes,
  ) {
    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
          ColmariaColors.background,
        ),
        columns: const [
          DataColumn(label: Text('Cliente')),
          DataColumn(label: Text('Teléfono')),
          DataColumn(label: Text('Pedidos'), numeric: true),
          DataColumn(label: Text('Total gastado'), numeric: true),
          DataColumn(label: Text('Último pedido')),
        ],
        rows: clientes.map((cliente) => DataRow(
          cells: [
            // Cliente
            DataCell(
              InkWell(
                onTap: () => context.go('/pedidos?cliente=${cliente['id']}'),
                child: Text(
                  cliente['nombre'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: ColmariaColors.primary,
                  ),
                ),
              ),
            ),
            // Teléfono
            DataCell(
              Text(
                cliente['telefono'] as String,
                style: TextStyle(
                  fontFamily: 'monospace',
                ),
              ),
            ),
            // Pedidos
            DataCell(
              Text('${cliente['total_orders']}'),
            ),
            // Total gastado
            DataCell(
              Text(
                '\$${(cliente['total_gastado'] as double).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Último pedido
            DataCell(
              Text(
                _formatDate(cliente['ultimo_pedido'] as DateTime),
                style: TextStyle(
                  color: ColmariaColors.textMuted,
                ),
              ),
            ),
          ],
        )).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }
}