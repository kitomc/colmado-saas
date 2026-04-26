import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:convex_flutter/convex_flutter.dart';
import 'auth_provider.dart';

// Provider del ConvexClient singleton (ya inicializado en main.dart)
final convexClientProvider = Provider<ConvexClient>((ref) {
  return ConvexClient.instance;
});

// Provider del usuario + colmado actual
// NOTA: auth ya se maneja globalmente via ConvexClient.instance.setAuth()
// desde auth_provider.dart, asi que no pasamos authToken
final usuarioActualProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final jwt = ref.watch(authProvider).jwt;
  if (jwt == null) return null;
  final client = ref.read(convexClientProvider);
  try {
    final result = await client.query("usuarios:getMe", <String, dynamic>{});
    if (result.isEmpty) return null;
    return jsonDecode(result) as Map<String, dynamic>;
  } catch (e) {
    return null;
  }
});

// Provider de productos del colmado (reactivo via StreamController bridge)
// subscribe() en v3 retorna Future<SubscriptionHandle>, no un Stream
final productosProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final controller = StreamController<List<Map<String, dynamic>>>();
  final colmadoId = ref.watch(authProvider).colmadoId;

  if (colmadoId == null) {
    controller.close();
    return controller.stream;
  }

  Future.microtask(() async {
    final client = ref.read(convexClientProvider);
    try {
      await client.subscribe(
        name: "productos:listByColmado",
        args: <String, dynamic>{"colmado_id": colmadoId},
        onUpdate: (data) {
          final list = jsonDecode(data);
          if (list is List) {
            controller.add(list.cast<Map<String, dynamic>>());
          }
        },
        onError: (error, details) {
          controller.addError(error);
        },
      );
    } catch (e) {
      controller.addError(e);
    }
  });

  ref.onDispose(() => controller.close());
  return controller.stream;
});

// Provider de pedidos por estado (reactivo via family)
final pedidosProvider = StreamProvider.family<List<Map<String, dynamic>>, String>(
  (ref, estado) {
    final controller = StreamController<List<Map<String, dynamic>>>();
    final colmadoId = ref.watch(authProvider).colmadoId;

    if (colmadoId == null) {
      controller.close();
      return controller.stream;
    }

    Future.microtask(() async {
      final client = ref.read(convexClientProvider);
      try {
        await client.subscribe(
          name: "ordenes:listByEstado",
          args: <String, dynamic>{"colmado_id": colmadoId, "estado": estado},
          onUpdate: (data) {
            final list = jsonDecode(data);
            if (list is List) {
              controller.add(list.cast<Map<String, dynamic>>());
            }
          },
          onError: (error, details) => controller.addError(error),
        );
      } catch (e) {
        controller.addError(e);
      }
    });
    ref.onDispose(() => controller.close());
    return controller.stream;
  },
);

// Provider de clientes del colmado (reactivo)
final clientesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final controller = StreamController<List<Map<String, dynamic>>>();
  final colmadoId = ref.watch(authProvider).colmadoId;

  if (colmadoId == null) {
    controller.close();
    return controller.stream;
  }

  Future.microtask(() async {
    final client = ref.read(convexClientProvider);
    try {
      await client.subscribe(
        name: "clientes:listByColmado",
        args: <String, dynamic>{"colmado_id": colmadoId},
        onUpdate: (data) {
          final list = jsonDecode(data);
          if (list is List) {
            controller.add(list.cast<Map<String, dynamic>>());
          }
        },
        onError: (error, details) => controller.addError(error),
      );
    } catch (e) {
      controller.addError(e);
    }
  });
  ref.onDispose(() => controller.close());
  return controller.stream;
});

// Provider de metricas por rango de fechas
class DateRange {
  final DateTime start;
  final DateTime end;
  const DateRange({required this.start, required this.end});
}

final metricasProvider = FutureProvider.family<Map<String, dynamic>, DateRange>(
  (ref, range) async {
    final colmadoId = ref.watch(authProvider).colmadoId;
    if (colmadoId == null) return <String, dynamic>{};

    final client = ref.read(convexClientProvider);
    try {
      final result = await client.query("ordenes:getMetricas", <String, dynamic>{
        "colmado_id": colmadoId,
        "desde": range.start.millisecondsSinceEpoch,
        "hasta": range.end.millisecondsSinceEpoch,
      });
      if (result.isEmpty) return <String, dynamic>{};
      return jsonDecode(result) as Map<String, dynamic>;
    } catch (e) {
      return <String, dynamic>{};
    }
  },
);
