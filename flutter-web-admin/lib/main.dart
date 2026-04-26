import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme.dart';
import 'app/router.dart';

void main() {
  runApp(
    ProviderScope(
      child: const ColmariaApp(),
    ),
  );
}

class ColmariaApp extends ConsumerWidget {
  const ColmariaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'COLMARIA Web Admin',
      theme: ColmariaTheme.theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}