import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/widgets/empty_state.dart';

/// Placeholder provider until Convex queries are implemented
final _mockProductosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return [];
});

/// Provider for categorías (mock — Convex query pending)
final categoriasProvider = FutureProvider<List<String>>((ref) async {
  // TODO: Obtener categorías desde Convex
  return ['Bebidas', 'Snacks', 'Cigarrillos', 'Dulces', 'Varios'];
});

class ProductosPage extends ConsumerWidget {
  const ProductosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productosAsync = ref.watch(_mockProductosProvider);

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
                  'Productos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: ColmariaColors.textPrimary,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showFilterDialog(context, ref),
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filtrar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showProductoModal(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo producto'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Products Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColmariaColors.divider),
                ),
                child: productosAsync.when(
                  data: (productos) {
                    if (productos.isEmpty) {
                      return EmptyState(
                        icon: Icons.inventory_2,
                        title: 'No hay productos',
                        subtitle: 'Agrega tu primer producto',
                        action: ElevatedButton.icon(
                          onPressed: () => _showProductoModal(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Nuevo producto'),
                        ),
                      );
                    }
                    return _buildProductsTable(context, ref, productos);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductoModal(context, ref),
        backgroundColor: ColmariaColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductsTable(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> productos,
  ) {
    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
          ColmariaColors.background,
        ),
        columns: const [
          DataColumn(label: Text('Imagen')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Categoría')),
          DataColumn(label: Text('Precio'), numeric: true),
          DataColumn(label: Text('Disponible')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: productos.map((producto) => DataRow(
          cells: [
            // Imagen
            DataCell(
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColmariaColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: producto['imagen'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          producto['imagen'] as String,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.inventory_2,
                        color: ColmariaColors.textMuted,
                        size: 20,
                      ),
              ),
            ),
            // Nombre
            DataCell(
              Text(
                producto['nombre'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Categoría
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ColmariaColors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  producto['categoria'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: ColmariaColors.textMuted,
                  ),
                ),
              ),
            ),
            // Precio
            DataCell(
              Text(
                '\$${(producto['precio'] as double).toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Disponible
            DataCell(
              Switch(
                value: producto['disponible'] as bool,
                onChanged: (value) => _toggleDisponible(context, ref, producto['id'], value),
                activeColor: ColmariaColors.primary,
              ),
            ),
            // Acciones
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      size: 18,
                      color: ColmariaColors.textMuted,
                    ),
                    onPressed: () => _showProductoModal(context, ref, producto: producto),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: 18,
                      color: ColmariaColors.error,
                    ),
                    onPressed: () => _confirmDelete(context, ref, producto['id']),
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ),
          ],
        )).toList(),
      ),
    );
  }

  void _toggleDisponible(
    BuildContext context,
    WidgetRef ref,
    String productoId,
    bool disponible,
  ) async {
    // TODO: Call Convex mutation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          disponible
              ? 'Producto habilitado'
              : 'Producto deshabilitado',
        ),
      ),
    );
    // Refresh the list
    ref.invalidate(_mockProductosProvider);
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.read(categoriasProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar productos'),
        content: categoriasAsync.when(
          data: (categorias) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Categoría'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categorias.map((cat) => FilterChip(
                  label: Text(cat),
                  selected: false,
                  onSelected: (selected) {},
                )).toList(),
              ),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showProductoModal(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? producto,
  }) {
    final isEdit = producto != null;
    final nombreController = TextEditingController(text: producto?['nombre'] ?? '');
    final precioController = TextEditingController(
      text: producto?['precio']?.toString() ?? '',
    );
    String? selectedCategoria = producto?['categoria'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Editar producto' : 'Nuevo producto'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Nombre del producto',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: precioController,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    hintText: '0.00',
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ref.watch(categoriasProvider).when(
                  data: (categorias) => DropdownButtonFormField<String>(
                    value: selectedCategoria,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                    ),
                    items: categorias
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedCategoria = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Call Convex mutation
                Navigator.pop(context);
                ref.invalidate(_mockProductosProvider);
              },
              child: Text(isEdit ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String productoId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este producto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColmariaColors.error,
            ),
            onPressed: () {
              // TODO: Call Convex mutation
              Navigator.pop(context);
              ref.invalidate(_mockProductosProvider);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}