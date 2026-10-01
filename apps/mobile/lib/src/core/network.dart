import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_store.dart';
import 'logger.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5000',
);

final dioProvider = Provider<Dio>((ref) {
  AppLog.info('API base URL: $apiBaseUrl');
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(_DiagInterceptor());
  return dio;
});

/// Logs every request/response/error (debug builds) with secrets scrubbed.
class _DiagInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLog.info('--> ${options.method} ${options.baseUrl}${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLog.info('<-- ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final req = err.requestOptions;
    AppLog.error('xxx ${err.type.name} ${req.method} ${req.baseUrl}${req.path} '
        'status=${err.response?.statusCode} msg=${err.message} data=${err.response?.data}');
    if (kDebugMode) debugPrint('[DIAG] $err');
    handler.next(err);
  }
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);
  final Ref _ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _ref.read(authStoreProvider.notifier).accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _ref.read(authStoreProvider.notifier).refresh();
      if (refreshed) {
        final opts = err.requestOptions;
        final token = await _ref.read(authStoreProvider.notifier).accessToken;
        opts.headers['Authorization'] = 'Bearer $token';
        try {
          final res = await _ref.read(dioProvider).fetch(opts);
          return handler.resolve(res);
        } catch (_) {}
      }
    }
    handler.next(err);
  }
}
