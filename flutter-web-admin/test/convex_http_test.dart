import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:colmaria_web_admin/shared/services/auth_service.dart';

void main() {
  const _deployUrl = 'https://different-hare-762.convex.cloud';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService -> Convex HTTP communication', () {
    test('signIn POST a /api/action con auth:signIn', () async {
      final requests = <http.Request>[];
      final mock = MockClient((r) {
        requests.add(r);
        return Future.value(http.Response(
          jsonEncode({'value': {'tokens': {'token': 'j', 'refreshToken': 'r'}}}),
          200,
        ));
      });
      final auth = AuthService(client: mock);
      await auth.signIn('a@b.com', 'p');
      expect(requests.length, 1);
      expect(requests[0].url.toString(), '$_deployUrl/api/action');
    });

    test('signIn body incluye provider, email, password, flow:signIn', () async {
      http.Request? cap;
      final mock = MockClient((r) {
        cap = r;
        return Future.value(http.Response(
          jsonEncode({'value': {'tokens': {'token': 'j', 'refreshToken': 'r'}}}),
          200,
        ));
      });
      final auth = AuthService(client: mock);
      await auth.signIn('u@t.com', 'Secret1');
      final b = jsonDecode(cap!.body);
      expect(b['path'], 'auth:signIn');
      expect(b['args'][0]['params']['flow'], 'signIn');
      expect(b['args'][0]['params']['email'], 'u@t.com');
      expect(b['args'][0]['params']['password'], 'Secret1');
    });

    test('signUp body incluye flow:signUp y name', () async {
      http.Request? cap;
      final mock = MockClient((r) {
        cap = r;
        return Future.value(http.Response(
          jsonEncode({'value': {'tokens': {'token': 'j', 'refreshToken': 'r'}}}),
          200,
        ));
      });
      final auth = AuthService(client: mock);
      await auth.signUp('n@t.com', 'Pass1', 'Nuevo');
      final b = jsonDecode(cap!.body);
      expect(b['args'][0]['params']['flow'], 'signUp');
      expect(b['args'][0]['params']['name'], 'Nuevo');
    });

    test('signUp exitoso persiste tokens', () async {
      final mock = MockClient((_) => Future.value(http.Response(
        jsonEncode({'value': {'tokens': {'token': 'jwt_test', 'refreshToken': 'rt'}}}),
        200,
      )));
      final auth = AuthService(client: mock);
      await auth.signUp('x@y.com', 'Pass1', 'U');
      expect(await auth.getSavedJwt(), 'jwt_test');
      expect(await auth.getSavedRefresh(), 'rt');
    });

    test('signOut borra tokens', () async {
      final auth = AuthService();
      await auth.saveTokens('j', 'r');
      await auth.signOut();
      expect(await auth.getSavedJwt(), isNull);
    });

    test('signIn con 400 lanza AuthException', () async {
      final mock = MockClient((_) => Future.value(http.Response('err', 400)));
      final auth = AuthService(client: mock);
      expect(() => auth.signIn('a@b.com', 'p'), throwsA(isA<AuthException>()));
    });

    test('signIn con 500 lanza AuthException', () async {
      final mock = MockClient((_) => Future.value(http.Response('fail', 500)));
      final auth = AuthService(client: mock);
      expect(() => auth.signIn('a@b.com', 'p'), throwsA(isA<AuthException>()));
    });
  });
}
