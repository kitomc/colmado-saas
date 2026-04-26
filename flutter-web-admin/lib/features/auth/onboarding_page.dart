import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/boton_primario.dart';
import '../../shared/widgets/boton_secundario.dart';
import '../../shared/providers/convex_providers.dart';

// --------------------------------------------------------
// OnboardingPage — wizard de 4 pasos post-registro
// --------------------------------------------------------
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _currentStep = 1;
  final int _totalSteps = 4;

  // ───── Step 1: Perfil del negocio ─────
  final _formKeyStep1 = GlobalKey<FormState>();
  final _colmadoNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // ───── Step 2: Productos ─────
  final List<_ProductRow> _products = [];
  String? _selectedCategory;
  static const List<String> _categories = [
    'Bebidas',
    'Comida',
    'Snacks',
    'Lácteos',
    'Limpieza',
    'Cigarrillos',
    'Otros',
  ];

  // ───── Step 3: WhatsApp ─────
  bool _whatsappConnected = false;
  bool _whatsappLoading = false;
  String? _qrBase64;
  Timer? _qrPollTimer;
  String? _whatsappError;

  // ───── Estado de instancia Evolution ─────
  String? _instanceName;

  // ───── Step 4: Flags ─────
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();

    // Cargar datos pre-filled desde GoRouter extra
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map<String, String>) {
        _colmadoNameController.text = extra['colmadoName'] ?? '';
        _phoneController.text = extra['phone'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _colmadoNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    for (final p in _products) {
      p.nameController.dispose();
      p.priceController.dispose();
    }
    _qrPollTimer?.cancel();
    super.dispose();
  }

  // ───── Navigate step ─────
  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    }
  }

  // ───── Step 1: Continuar ─────
  void _handleStep1Continue() {
    if (!_formKeyStep1.currentState!.validate()) return;
    _nextStep();
  }

  // ───── Step 2: Product helpers ─────
  void _addProductRow() {
    setState(() {
      _products.add(_ProductRow(
        nameController: TextEditingController(),
        priceController: TextEditingController(),
      ));
    });
  }

  void _removeProductRow(int index) {
    setState(() {
      _products[index].nameController.dispose();
      _products[index].priceController.dispose();
      _products.removeAt(index);
    });
  }

  // ───── Step 2: Guardar productos ─────
  Future<void> _handleSaveProducts() async {
    setState(() => _isCompleting = true);

    try {
      final productsData = _products
          .where((p) =>
              p.nameController.text.trim().isNotEmpty &&
              p.priceController.text.trim().isNotEmpty)
          .map((p) => {
                'name': p.nameController.text.trim(),
                'price': double.tryParse(p.priceController.text.trim()) ?? 0,
                'category': _selectedCategory,
              })
          .toList();

      if (productsData.isNotEmpty) {
        final client = ref.read(convexClientProvider);
        // TODO: Obtener colmadoId real desde query o auth flow
        const colmadoId = 'col_placeholder';
        for (final p in productsData) {
          await client.mutation('productos:crearProducto', {
            'colmadoId': colmadoId,
            'nombre': p['name'] as String,
            'precio': p['price'] as double,
            'categoria': p['category'] as String? ?? 'Otros',
          });
        }
      }

      if (mounted) _nextStep();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar productos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  void _handleSkipProducts() {
    _nextStep();
  }

  // ───── Step 3: WhatsApp ─────
  Future<void> _handleConnectWhatsApp() async {
    setState(() {
      _whatsappLoading = true;
      _whatsappError = null;
      _qrBase64 = null;
    });

    try {
      final client = ref.read(convexClientProvider);
      // TODO: Obtener colmadoId real desde query o auth flow
      const colmadoId = 'col_placeholder';
      // Generar instanceName único a partir del colmadoId
      final instanceName = 'colmado_${colmadoId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      _instanceName = instanceName;

      final result = await client.action('evolution:crearInstancia', {
        'colmadoId': colmadoId,
        'instanceName': instanceName,
      });

      final decoded = jsonDecode(result) as Map<String, dynamic>;

      if (decoded['qr'] != null) {
        setState(() {
          _qrBase64 = decoded['qr'] as String;
          _whatsappLoading = false;
        });

        // Iniciar polling cada 5s para verificar estado
        _startQrPolling();
      } else if (decoded['error'] != null) {
        setState(() {
          _whatsappError = decoded['error'] as String;
          _whatsappLoading = false;
        });
      } else {
        // Puede que ya esté conectado
        setState(() {
          _whatsappConnected = true;
          _whatsappLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _whatsappError = 'Error al conectar WhatsApp';
        _whatsappLoading = false;
      });
    }
  }

  void _startQrPolling() {
    _qrPollTimer?.cancel();
    _qrPollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) {
        _qrPollTimer?.cancel();
        return;
      }

      try {
        if (_instanceName == null) return;
        final client = ref.read(convexClientProvider);
        final result = await client.action('evolution:verificarEstado', {
          'instanceName': _instanceName!,
        });
        final decoded = result as Map<String, dynamic>;

        if (decoded['status'] == 'connected' || decoded['connected'] == true) {
          _qrPollTimer?.cancel();
          if (mounted) {
            setState(() => _whatsappConnected = true);
          }
        } else if (decoded['qr'] != null && decoded['qr'] != _qrBase64) {
          if (mounted) {
            setState(() => _qrBase64 = decoded['qr'] as String);
          }
        }
      } catch (_) {
        // Ignorar errores de polling, reintentar en el próximo ciclo
      }
    });
  }

  void _handleWhatsAppContinue() {
    _qrPollTimer?.cancel();
    _nextStep();
  }

  void _handleWhatsAppSkip() {
    _qrPollTimer?.cancel();
    _nextStep();
  }

  // ───── Step 4: Completar ─────
  Future<void> _handleFinish() async {
    setState(() => _isCompleting = true);

    try {
      final client = ref.read(convexClientProvider);
      // TODO: Obtener colmadoId real desde query o auth flow
      const colmadoId = 'col_placeholder';

      // Marcar onboarding como completado
      await client.mutation('colmados:marcarOnboardingCompleto', {
        'colmadoId': colmadoId,
      });

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al finalizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColmariaColors.background,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              children: [
                // ── Progress bar ──
                _buildProgressBar(),
                const SizedBox(height: 40),

                // ── Step content ──
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildCurrentStep(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───── Progress Bar ─────
  Widget _buildProgressBar() {
    return Column(
      children: [
        // Step circles row
        Row(
          children: List.generate(_totalSteps, (i) {
            final step = i + 1;
            final isActive = step <= _currentStep;
            return Expanded(
              child: Row(
                children: [
                  // Circle
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF16AA3A) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? const Color(0xFF16AA3A) : ColmariaColors.divider,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isActive
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(
                              '$step',
                              style: TextStyle(
                                color: ColmariaColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  // Line (not after last)
                  if (i < _totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: step < _currentStep
                            ? const Color(0xFF16AA3A)
                            : ColmariaColors.divider,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Labels row
        Row(
          children: [
            _stepLabel('Perfil', 1),
            const Spacer(),
            _stepLabel('Productos', 2),
            const Spacer(),
            _stepLabel('WhatsApp', 3),
            const Spacer(),
            _stepLabel('Listo', 4),
          ],
        ),
      ],
    );
  }

  Widget _stepLabel(String label, int step) {
    final isActive = step <= _currentStep;
    return Text(
      label,
      style: TextStyle(
        color: isActive ? const Color(0xFF16AA3A) : ColmariaColors.textMuted,
        fontSize: 12,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  // ───── Route to current step ─────
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return _buildStep1();
    }
  }

  // ═══════════════════════════════════════════════════════
  // STEP 1 — Perfil del negocio
  // ═══════════════════════════════════════════════════════
  Widget _buildStep1() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Perfil del negocio',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: ColmariaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contanos sobre tu colmado',
            style: TextStyle(color: ColmariaColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 32),
          // Logo placeholder
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ColmariaColors.divider, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 32, color: ColmariaColors.textMuted),
                  const SizedBox(height: 4),
                  Text(
                    'Logo',
                    style: TextStyle(
                        color: ColmariaColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Nombre (pre-filled)
          TextFormField(
            controller: _colmadoNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del colmado',
              prefixIcon: Icon(Icons.store_outlined),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre del colmado es requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Teléfono (pre-filled)
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono WhatsApp',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El teléfono es requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Dirección (optional)
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Dirección del colmado (opcional)',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 32),
          BotonPrimario(
            label: 'Continuar →',
            onPressed: _handleStep1Continue,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // STEP 2 — Agrega tus primeros productos
  // ═══════════════════════════════════════════════════════
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Agregá tus primeros productos',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: ColmariaColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cargá algunos productos para empezar a vender',
          style: TextStyle(color: ColmariaColors.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // Categorías como FilterChip
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final selected = _selectedCategory == cat;
            return FilterChip(
              label: Text(cat),
              selected: selected,
              onSelected: (isSelected) {
                setState(() => _selectedCategory = isSelected ? cat : null);
              },
              selectedColor: const Color(0xFF16AA3A).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF16AA3A),
              labelStyle: TextStyle(
                color: selected ? const Color(0xFF16AA3A) : ColmariaColors.textMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              side: BorderSide(
                color: selected ? const Color(0xFF16AA3A) : ColmariaColors.divider,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Lista dinámica de productos
        if (_products.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColmariaColors.divider),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 40, color: ColmariaColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'Todavía no tenés productos',
                    style: TextStyle(
                        color: ColmariaColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Agregalos ahora o saltá este paso',
                    style: TextStyle(
                        color: ColmariaColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_products.length, (i) {
            final product = _products[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Nombre
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: product.nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Precio
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: product.priceController,
                      decoration: InputDecoration(
                        labelText: 'Precio',
                        prefixText: '\$ ',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Delete
                  IconButton(
                    onPressed: () => _removeProductRow(i),
                    icon: Icon(Icons.remove_circle_outline,
                        color: ColmariaColors.error, size: 22),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 16),

        // Botón agregar producto
        BotonSecundario(
          label: '+ Agregar producto',
          onPressed: _addProductRow,
          icon: Icons.add,
        ),
        const SizedBox(height: 24),

        // Guardar y continuar
        BotonPrimario(
          label: 'Guardar y continuar →',
          isLoading: _isCompleting,
          onPressed: _isCompleting ? null : _handleSaveProducts,
        ),
        const SizedBox(height: 12),

        // Saltar
        Center(
          child: TextButton(
            onPressed: _handleSkipProducts,
            child: Text(
              'Saltar por ahora →',
              style: TextStyle(
                  color: ColmariaColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // STEP 3 — Conectá tu WhatsApp
  // ═══════════════════════════════════════════════════════
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Conectá tu WhatsApp',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: ColmariaColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Conectá tu WhatsApp para recibir pedidos automáticamente',
          style: TextStyle(color: ColmariaColors.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 32),

        // WhatsApp connection area
        if (_whatsappConnected)
          // Connected banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF16AA3A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF16AA3A), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'WhatsApp conectado',
                    style: TextStyle(
                      color: const Color(0xFF16AA3A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (_whatsappLoading)
          // Loading state
          Center(
            child: Column(
              children: [
                const CircularProgressIndicator(color: Color(0xFF16AA3A)),
                const SizedBox(height: 16),
                Text(
                  'Generando código QR...',
                  style: TextStyle(
                      color: ColmariaColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          )
        else if (_qrBase64 != null)
          // QR code
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColmariaColors.divider),
                  ),
                  child: Image.memory(
                    base64Decode(_qrBase64!),
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Escaneá el código con tu WhatsApp',
                  style: TextStyle(
                      color: ColmariaColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          )
        else if (_whatsappError != null)
          // Error state
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF4444)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _whatsappError!,
                    style:
                        const TextStyle(color: Color(0xFFEF4444), fontSize: 14),
                  ),
                ),
              ],
            ),
          )
        else
          // Initial state (no QR, no loading)
          Center(
            child: Column(
              children: [
                Icon(Icons.chat,
                    size: 80, color: const Color(0xFF25D366)),
                const SizedBox(height: 16),
                Text(
                  'Vinculá tu número de WhatsApp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ColmariaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tus clientes podrán hacer pedidos\npor WhatsApp automáticamente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: ColmariaColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          ),

        const SizedBox(height: 32),

        // Connect button (only show when not connected and not loading)
        if (!_whatsappConnected && !_whatsappLoading && _qrBase64 == null)
          BotonPrimario(
            label: 'Conectar WhatsApp',
            onPressed: _handleConnectWhatsApp,
            icon: Icons.qr_code_scanner,
          ),

        // Retry button if error
        if (_whatsappError != null && !_whatsappLoading)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: BotonSecundario(
              label: 'Reintentar',
              onPressed: _handleConnectWhatsApp,
            ),
          ),

        // Continue always enabled
        const SizedBox(height: 24),
        BotonPrimario(
          label: 'Continuar →',
          onPressed: _handleWhatsAppContinue,
        ),

        // Skip
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _handleWhatsAppSkip,
            child: Text(
              'Saltar por ahora →',
              style: TextStyle(
                  color: ColmariaColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // STEP 4 — ¡Todo listo!
  // ═══════════════════════════════════════════════════════
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        // Green checkmark
        const Icon(Icons.check_circle, color: Color(0xFF16AA3A), size: 80),
        const SizedBox(height: 24),
        Text(
          'Tu colmado está configurado',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: ColmariaColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Checklist
        _buildChecklistItem(
            Icons.check, 'Perfil del negocio completo', true),
        _buildChecklistItem(
            Icons.check, 'Productos cargados', _products.isNotEmpty),
        _buildChecklistItem(
            Icons.check, 'WhatsApp conectado', _whatsappConnected),
        _buildChecklistItem(
            Icons.check, 'Listo para recibir pedidos', true),

        const SizedBox(height: 48),

        BotonPrimario(
          label: 'Ir al Dashboard →',
          isLoading: _isCompleting,
          onPressed: _isCompleting ? null : _handleFinish,
        ),
      ],
    );
  }

  Widget _buildChecklistItem(IconData icon, String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: completed ? const Color(0xFF16AA3A) : ColmariaColors.divider,
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed ? Icons.check : Icons.remove,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: ColmariaColors.textPrimary,
              fontWeight: completed ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper model para producto dinámico
class _ProductRow {
  final TextEditingController nameController;
  final TextEditingController priceController;

  _ProductRow({
    required this.nameController,
    required this.priceController,
  });
}
