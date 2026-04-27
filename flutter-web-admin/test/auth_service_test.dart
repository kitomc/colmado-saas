import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:colmaria_web_admin/shared/services/auth_service.dart';

void main() {
  const _deployUrl = 'https://different-hare-762.convex.cloud';
  const _fakeJwt = 'eyJ.eyJ.abc';
  const _fakeRefresh = 'refresh123';

  SharedPreferences? _prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  group('AuthService.saveTokens / getSavedJwt / clearTokens', () {
    test('saveTokens persiste jwt y refreshToken', () async {
      final auth = AuthService();
      await auth.saveTokens(_fakeJwt, _fakeRefresh);
      expect(await auth.getSavedJwt(), _fakeJwt);
      expect(await auth.getSavedRefresh(), _fakeRefresh);
    });

    test('clearTokens elimina todos los tokens', () async {
      final auth = AuthService();
      await auth.saveTokens(_fakeJwt, _fakeRefresh);
      await auth.clearTokens();
      expect(await auth.getSavedJwt(), isNull);
      expect(await auth.getSavedRefresh(), isNull);
    });
  });

  group('AuthService.signIn', () {
    test('signIn exitoso retorna jwt y refreshToken', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), '$_deployUrl/api/action');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['path'], 'auth:signIn');
        expect(body['args'][0]['params']['email'], 'test@c.com');
        expect(body['args'][0]['params']['flow'], 'signIn');
        return http.Response(
          jsonEncode({
            'value': {
              'tokens': {'token': _fakeJwt, 'refreshToken': _fakeRefresh}
            }
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final auth = AuthService(client: mockClient);
      final result = await auth.signIn('test@c.com', 'pass123');

      expect(result['jwt'], _fakeJwt);
      expect(result['refreshToken'], _fakeRefresh);
      // Verificar persistencia
      expect(await auth.getSavedJwt(), _fakeJwt);
    });

    test('signIn con credenciales invalidas lanza AuthException', () async {
      final mockClient = MockClient((_) async =>
          http.Response(jsonEncode({'errorMessage': 'InvalidCredentials'}), 400));

      final auth = AuthService(client: mockClient);
      expect(
        () => auth.signIn('bad@c.com', 'wrong'),
        throwsA(isA<AuthException>()),
      );
    });

    test('signIn con error de servidor lanza AuthException', () async {
      final mockClient = MockClient((_) async =>
          http.Response('Server Error', 500));

      final auth = AuthService(client: mockClient);
      expect(
        () => auth.signIn('test@c.com', 'pass'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService.signUp', () {
    test('signUp exitoso retorna jwt y refreshToken', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), '$_deployUrl/api/action');
        final body = jsonDecode(request.body);
        expect(body['args'][0]['params']['flow'], 'signUp');
        expect(body['args'][0]['params']['name'], 'Test User');
        return http.Response(
          jsonEncode({
            'value': {
              'tokens': {'token': _fakeJwt, 'refreshToken': _fakeRefresh}
            }
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final auth = AuthService(client: mockClient);
      final result = await auth.signUp('new@c.com', 'pass123', 'Test User');

      expect(result['jwt'], _fakeJwt);
      expect(result['refreshToken'], _fakeRefresh);
    });

    test('signUp con error de red lanza AuthException', () async {
      final mockClient = MockClient((_) async =>
          http.Response(jsonEncode({'errorMessage': 'NetworkError'}), 500));

      final auth = AuthService(client: mockClient);
      expect(
        () => auth.signUp('new@c.com', 'pass123', 'Test'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService.signOut', () {
    test('signOut borra tokens', () async {
      final auth = AuthService();
      await auth.saveTokens(_fakeJwt, _fakeRefresh);
      await auth.signOut();
      expect(await auth.getSavedJwt(), isNull);
      expect(await auth.getSavedRefresh(), isNull);
    });
  });

  group('AuthService.refreshJwt', () {
    test('refreshJwt retorna el jwt guardado', () async {
      final auth = AuthService();
      await auth.saveTokens(_fakeJwt, _fakeRefresh);
      final result = await auth.refreshJwt();
      expect(result, _fakeJwt);
    });

    test('refreshJwt retorna null si no hay jwt', () async {
      final auth = AuthService();
      final result = await auth.refreshJwt();
      expect(result, isNull);
    });
  });
}
