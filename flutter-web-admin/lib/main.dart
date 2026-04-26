import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/theme.dart';
import 'app/router.dart';
import 'services/convex_http_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
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
    return MaterialApp.router(
      title: 'COLMARIA Web Admin',
      theme: ColmariaTheme.theme,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
