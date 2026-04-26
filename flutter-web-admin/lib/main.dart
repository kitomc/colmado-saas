import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:convex_flutter/convex_flutter.dart';

import 'app/theme.dart';
import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Convex Client
  await ConvexClient.initialize(
    const ConvexConfig(
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

class ColmariaApp extends ConsumerWidget {
  const ColmariaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El router usa el authProvider automáticamente
    // No necesitamos inicializar auth aquí - el router lo hace en /splash
    return MaterialApp.router(
      title: 'COLMARIA Web Admin',
      theme: ColmariaTheme.theme,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
