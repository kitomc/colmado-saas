import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/boton_primario.dart';
import '../../shared/widgets/boton_secundario.dart';

class LoginPage extends ConsumerStatefulWidget {
  final Function(bool)? onAuthStateChanged;

  const LoginPage({super.key, this.onAuthStateChanged});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 800));

    // Credenciales válidas
    final validUsers = [
      {'email': 'admin@colmado.com', 'password': 'colmado123'},
      {'email': 'test@colmado.com', 'password': 'test123'},
    ];

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final isValid = validUsers.any(
      (u) => u['email'] == email && u['password'] == password
    );

    if (isValid) {
      if (mounted) {
        widget.onAuthStateChanged?.call(true);
        context.go('/dashboard');
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = 'Credenciales incorrectas. Verifica tu email y contraseña.';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left side - 40%
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
                    Text(
                      'COLMARIA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
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
          // Right side - 60%
          Expanded(
            flex: 60,
            child: Container(
              color: ColmariaColors.background,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: ColmariaColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingresa tus credenciales para continuar',
                          style: TextStyle(color: ColmariaColors.textMuted, fontSize: 14),
                        ),
                        const SizedBox(height: 40),
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
                                  child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'tu@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'El email es requerido';
                            if (!value.contains('@')) return 'Ingresa un email válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            hintText: '••••••••',
                            prefixIcon: Icon(Icons.lock_outlined),
                          ),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'La contraseña es requerida';
                            if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: ColmariaColors.primary, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        BotonPrimario(
                          label: 'Iniciar sesión',
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _handleLogin,
                        ),
                        const SizedBox(height: 32),
                        // Demo credentials button
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF16AA3A).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Color(0xFF16AA3A), size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Modo demo — Acceso rápido',
                                      style: TextStyle(
                                        color: Color(0xFF16AA3A),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              BotonSecundario(
                                label: 'Usar credenciales de prueba',
                                icon: Icons.play_arrow,
                                onPressed: () {
                                  _emailController.text = 'admin@colmado.com';
                                  _passwordController.text = 'colmado123';
                                  _handleLogin();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Text('COLMARIA © 2026', style: TextStyle(color: ColmariaColors.textMuted, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
