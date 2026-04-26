import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/boton_primario.dart';
import '../../shared/providers/auth_provider.dart';

// --------------------------------------------------------
// Pantalla pública: RegisterPage
// 2-column layout (40% green / 60% white)
// --------------------------------------------------------
class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _RegisterForm();
  }
}

class _RegisterForm extends ConsumerStatefulWidget {
  const _RegisterForm();

  @override
  ConsumerState<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<_RegisterForm> {
  int _currentStep = 1;

  // Step 1 controllers
  final _formKeyStep1 = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 2 controllers
  final _formKeyStep2 = GlobalKey<FormState>();
  final _colmadoNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _colmadoNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ───── Validaciones ──────────────────────────────────────────

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 8) return 'Debe tener al menos 8 caracteres';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Debe contener al menos 1 número';
    return null;
  }

  String? _validatePhoneRD(String? value) {
    if (value == null || value.isEmpty) return 'El teléfono es requerido';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Debe tener 10 dígitos';
    if (!RegExp(r'^(809|829|849)').hasMatch(digits)) return 'Debe empezar con 809, 829 o 849';
    return null;
  }

  // ───── Ir al paso 2 ───────────────────────────────────────

  void _goToStep2() {
    if (!_formKeyStep1.currentState!.validate()) return;
    setState(() {
      _currentStep = 2;
    });
  }

  // ───── Crear cuenta ────────────────────────────────────────

  Future<void> _handleRegister() async {
    if (!_formKeyStep2.currentState!.validate()) return;

    // Llamar signUp del authProvider (HTTP puro — sin convex_flutter WebSocket)
    await ref.read(authProvider.notifier).signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nombre: _nameController.text.trim(),
      nombreColmado: _colmadoNameController.text.trim(),
      telefono: _phoneController.text.trim(),
    );

    // El router reacciona automáticamente al cambio de AuthStatus
    // Si el registro fue exitoso → AuthStatus.authenticated → redirige al dashboard
    // Si falló → AuthStatus.unauthenticated con errorMessage → se muestra el error
  }

  // ───── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Escuchar el estado de auth para errores y loading
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final errorMessage = authState.errorMessage;

    return Scaffold(
      body: Row(
        children: [
          // ────── LEFT 40%: Branding ──────
          Expanded(
            flex: 40,
            child: Container(
              color: ColmariaColors.primaryDark,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store, color: Colors.white, size: 64),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'COLMARIA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tu colmado digital',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 48),
                    _buildFeatureItem(Icons.inventory_2, 'Gestiona tu catálogo'),
                    _buildFeatureItem(Icons.shopping_cart, 'Procesa pedidos'),
                    _buildFeatureItem(Icons.smart_toy, 'IA que vende por ti'),
                    _buildFeatureItem(Icons.print, 'Impresión automática'),
                  ],
                ),
              ),
            ),
          ),

          // ────── RIGHT 60%: Form ──────
          Expanded(
            flex: 60,
            child: Container(
              color: ColmariaColors.background,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(40),
                  child: _currentStep == 1
                      ? _buildStep1(errorMessage: errorMessage)
                      : _buildStep2(
                          isLoading: isLoading,
                          errorMessage: errorMessage,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───── Step Indicator ─────────────────────────────────────

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        children: [
          _stepDot(1, 'Datos'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 2
                  ? ColmariaColors.primary
                  : ColmariaColors.divider,
            ),
          ),
          _stepDot(2, 'Colmado'),
        ],
      ),
    );
  }

  Widget _stepDot(int step, String label) {
    final isActive = step <= _currentStep;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? ColmariaColors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? ColmariaColors.primary : ColmariaColors.textMuted,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : ColmariaColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? ColmariaColors.primary : ColmariaColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ───── Error Banner ──────────────────────────────────────

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ───── Step 1: Datos personales ─────────────────────────────

  Widget _buildStep1({String? errorMessage}) {
    return Form(
      key: _formKeyStep1,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepIndicator(),
            Text(
              'Crea tu cuenta COLMARIA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: ColmariaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa tus datos para registrarte',
              style: TextStyle(color: ColmariaColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            if (errorMessage != null) _buildErrorBanner(errorMessage),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'El nombre es requerido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'El correo es requerido';
                if (!value.contains('@') || !value.contains('.')) return 'Ingresa un correo válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _goToStep2(),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Confirma tu contraseña';
                if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                return null;
              },
            ),
            const SizedBox(height: 32),
            BotonPrimario(
              label: 'Continuar →',
              onPressed: _goToStep2,
            ),
            const SizedBox(height: 32),
            _buildRegisterFooter(),
          ],
        ),
      ),
    );
  }

  // ───── Step 2: Datos del colmado ────────────────────────────

  Widget _buildStep2({
    required bool isLoading,
    String? errorMessage,
  }) {
    return Form(
      key: _formKeyStep2,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepIndicator(),
            Text(
              'Tu colmado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: ColmariaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contanos sobre tu negocio',
              style: TextStyle(color: ColmariaColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            if (errorMessage != null) _buildErrorBanner(errorMessage),
            TextFormField(
              controller: _colmadoNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de tu colmado',
                prefixIcon: Icon(Icons.store_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'El nombre del colmado es requerido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono WhatsApp',
                hintText: '809 555 1234',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleRegister(),
              validator: _validatePhoneRD,
            ),
            const SizedBox(height: 32),
            BotonPrimario(
              label: 'Crear cuenta',
              isLoading: isLoading,
              onPressed: isLoading ? null : _handleRegister,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () => setState(() {
                          _currentStep = 1;
                        }),
                child: Text(
                  '← Volver',
                  style: TextStyle(
                    color: ColmariaColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildRegisterFooter(),
          ],
        ),
      ),
    );
  }

  // ───── Footer compartido ────────────────────────────────────

  Widget _buildRegisterFooter() {
    return Center(
      child: FittedBox(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Ya tenés cuenta? ',
              style: TextStyle(color: ColmariaColors.textMuted, fontSize: 14),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Iniciar sesión',
                style: TextStyle(
                  color: ColmariaColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───── Feature items (left column) ─────────────────────────

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
