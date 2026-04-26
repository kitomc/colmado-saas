import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/convex_http_client.dart';

final convexClientProvider = Provider<ConvexHttpClient>((ref) {
  return ConvexHttpClient(
    deploymentUrl: 'https://different-hare-762.convex.cloud',
  );
});
