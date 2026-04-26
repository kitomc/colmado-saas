import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:convex_flutter/convex_flutter.dart';

import '../../app/theme.dart';
import '../../shared/widgets/boton_primario.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/convex_providers.dart';

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

  bool _isLoading = false;
  String? _errorMessage;

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

  // ───── Validación de contraseña (min 8 chars, al menos 1 número) ─────
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 8) return 'Debe tener al menos 8 caracteres';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Debe contener al menos 1 número';
    return null;
  }

  // ───── Validación de teléfono RD (809/829/849 + 7 dígitos) ─────
  String? _validatePhoneRD(String? value) {
    if (value == null || value.isEmpty) return 'El teléfono es requerido';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Debe tener 10 dígitos';
    if (!RegExp(r'^(809|829|849)').hasMatch(digits)) return 'Debe empezar con 809, 829 o 849';
    return null;
  }

  // ───── Ir al paso 2 ─────
  void _goToStep2() {
    if (!_formKeyStep1.currentState!.validate()) return;
    setState(() {
      _currentStep = 2;
      _errorMessage = null;
    });
  }

  // ───── Crear cuenta ─────
  Future<void> _handleRegister() async {
    if (!_formKeyStep2.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. SignUp via HTTP
      const baseUrl = 'https://different-hare-762.convex.cloud';
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/signin/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'flow': 'signUp',
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'name': _nameController.text.trim(),
        }),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        final code = data['code'] as String? ?? 'Unknown';
        String message;
        switch (code) {
          case 'AccountAlreadyExists':
            message = 'Ya existe una cuenta con este correo';
            break;
          default:
            message = 'Error al crear la cuenta';
        }
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
        return;
      }

      final data = jsonDecode(response.body);
      final tokens = data['tokens'];
      if (tokens == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Respuesta inválida del servidor';
        });
        return;
      }

      final jwt = tokens['token'] as String?;
      final refreshToken = tokens['refreshToken'] as String?;
      if (jwt == null || refreshToken == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Respuesta inválida del servidor';
        });
        return;
      }

      // 2. Guardar tokens localmente
      await ref.read(authServiceProvider).saveTokens(jwt, refreshToken);

      // 3. Set auth en ConvexClient
      await ConvexClient.instance.setAuth(token: jwt);

      // 4. Llamar mutation usuarios:registrar
      final client = ref.read(convexClientProvider);
      await client.mutation(
        name: 'usuarios:registrar',
        args: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'colmadoName': _colmadoNameController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
      );

      // 5. Inicializar estado de auth
      await ref.read(authProvider.notifier).initialize();

      // 6. Navegar a onboarding con datos del registro
      if (mounted) {
        context.go('/onboarding', extra: {
          'colmadoName': _colmadoNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'name': _nameController.text.trim(),
        });
      }
    } on http.ClientException {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sin conexión. Verifica tu internet';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error inesperado. Intenta de nuevo';
      });
    }
  }

  // ───── Build ─────
  @override
  Widget build(BuildContext context) {
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
                  child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───── Step Indicator ─────
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        children: [
          _stepDot(1, 'Datos'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 2 ? ColmariaColors.primary : ColmariaColors.divider,
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

  // ───── Build Step 1: Create account ─────
  Widget _buildStep1() {
    return Form(
      key: _formKeyStep1,
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
          // Error banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
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
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
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
    );
  }

  // ───── Build Step 2: Colmado details ─────
  Widget _buildStep2() {
    return Form(
      key: _formKeyStep2,
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
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
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
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          TextFormField(
            controller: _colmadoNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de tu colmado',
              prefixIcon: Icon(Icons.store_outlined),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'El nombre del colmado es requerido';
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
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleRegister,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _currentStep = 1;
                _errorMessage = null;
              }),
              child: Text(
                '← Volver',
                style: TextStyle(color: ColmariaColors.textMuted, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildRegisterFooter(),
        ],
      ),
    );
  }

  // ───── Footer compartido ─────
  Widget _buildRegisterFooter() {
    return Center(
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
    );
  }

  // ───── Feature items (left column) ─────
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
