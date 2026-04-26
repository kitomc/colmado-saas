import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:convex_flutter/convex_flutter.dart';
import 'package:go_router/go_router.dart';

import 'app/theme.dart';
import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ConvexClient.initialize(
    ConvexConfig(
      deploymentUrl: 'https://different-hare-762.convex.cloud',
      clientId: 'colmaria-web-admin',
    ),
  );

  runApp(
    const ProviderScope(
      child: ColmariaApp(),
    ),
  );
}

class ColmariaApp extends ConsumerStatefulWidget {
  const ColmariaApp({super.key});

  @override
  ConsumerState<ColmariaApp> createState() => _ColmariaAppState();
}

class _ColmariaAppState extends ConsumerState<ColmariaApp> {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(_isAuthenticated, _updateAuthState);
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Login local simulado - siempre empieza sin auth
    // En producción, esto verificaría el token real
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isAuthenticated = false; // Always start at login for demo
        _isLoading = false;
      });
    }
  }

  void _updateAuthState(bool isAuth) {
    setState(() {
      _isAuthenticated = isAuth;
    });
    // Rebuild router with new auth state
    _router = createRouter(isAuth, _updateAuthState);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        title: 'COLMARIA Web Admin',
        theme: ColmariaTheme.theme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'COLMARIA Web Admin',
      theme: ColmariaTheme.theme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}