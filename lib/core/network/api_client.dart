import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../error/exceptions.dart';

class ApiClient {
  final Dio dio;

  /// IP del dispositivo Fire TV actualmente seleccionado.
  /// Se actualiza cada vez que el usuario elige un televisor en la UI.
  String _deviceIp = '';

  ApiClient() : dio = Dio() {
    // La URL base del microservicio es fija (la PC donde corre el backend).
    final serviceUrl = dotenv.env['MICROSERVICE_URL'] ?? '';
    dio.options.baseUrl = serviceUrl;
    dio.options.connectTimeout = const Duration(seconds: 3);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 3);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Header de autenticación
          final apiKey = dotenv.env['API_KEY'];
          if (apiKey != null && apiKey.isNotEmpty) {
            options.headers['x-api-key'] = apiKey;
          }
          // Header de dispositivo: IP dinámica del Fire TV seleccionado
          if (_deviceIp.isNotEmpty) {
            options.headers['x-device-ip'] = _deviceIp;
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

  /// Actualiza la IP del televisor destino.
  /// Esta IP se enviará en el header [x-device-ip] en cada petición al microservicio.
  void setDeviceIp(String ip) {
    _deviceIp = ip;
  }
}

/// Proveedor global de Riverpod para inyectar esta instancia.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
