import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../error/exceptions.dart';

class ApiClient {
  final Dio dio;

  ApiClient() : dio = Dio() {
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 5);
    dio.options.sendTimeout = const Duration(seconds: 5);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final apiKey = dotenv.env['API_KEY'];
          if (apiKey != null && apiKey.isNotEmpty) {
             options.headers['x-api-key'] = apiKey;
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            throw const UnauthorizedException();
          } else if (e.response?.statusCode == 500 ||
                     e.type == DioExceptionType.connectionTimeout ||
                     e.type == DioExceptionType.receiveTimeout) {
            throw const ServerException();
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Actualiza dinámicamente el BaseURL de Dio apuntando a la IP proporcionada.
  void updateBaseUrl(String ip) {
    dio.options.baseUrl = 'http://$ip:8000/tv';
  }
}

/// Proveedor global de Riverpod para inyectar esta instancia.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
