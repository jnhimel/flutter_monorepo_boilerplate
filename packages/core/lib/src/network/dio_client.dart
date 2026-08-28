import 'package:dio/dio.dart';

import '../logging/app_logger.dart';
import '../security/security_config.dart';
import 'app_exception.dart';

/// Single configured [Dio] instance for the whole app. Register one instance
/// via DI rather than constructing `Dio()` ad hoc in repositories.
class DioClient {
  DioClient({
    required String baseUrl,
    required AppLogger logger,
    SecurityConfig securityConfig = const SecurityConfig(),
  }) : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          logger.debug('--> ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          logger.debug(
            '<-- ${response.statusCode} ${response.requestOptions.uri}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          logger.error('<-- ERROR ${error.requestOptions.uri}', error);
          handler.next(error);
        },
      ),
    );

    if (securityConfig.sslPinningEnabled) {
      dio.interceptors.add(_pinningInterceptor);
    }
  }

  final Dio dio;

  /// Hook point for certificate/public-key pinning. Only attached when
  /// [SecurityConfig.sslPinningEnabled] is true.
  ///
  /// ponytail: no-op stub, not a working pinning implementation. To turn
  /// this on for real: validate `options.extra['certificate']` (or use
  /// `HttpClientAdapter.onHttpClientCreate` for a proper cert check) against
  /// a bundled certificate/public key, then throw a [DioException] on
  /// mismatch. See dio's `IOHttpClientAdapter.createHttpClient` docs.
  static final _pinningInterceptor = InterceptorsWrapper(
    onRequest: (options, handler) => handler.next(options),
  );

  /// Runs [request] and maps any [DioException] to our [AppException]
  /// hierarchy.
  Future<T> guard<T>(Future<T> Function(Dio dio) request) async {
    try {
      return await request(dio);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
