import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class TvRepository {
  final ApiClient _apiClient;

  TvRepository(this._apiClient);

  /// Verifica si el televisor bajo la IP configurada está accesible
  Future<bool> checkHealth() async {
    try {
      final response = await _apiClient.dio.get('/health');
      // Esperamos respuesta exitosa para confirmar que el backend está vivo
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Inicia conexión ADB con el TV a través del microservicio
  Future<bool> connectDevice() async {
    try {
      final response = await _apiClient.dio.post('/connect');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Envía un keyevent genérico 
  Future<bool> sendKeyEvent(int code) async {
    try {
      final response = await _apiClient.dio.post('/keyevent/$code');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Envía un comando para abrir una App en específico por nombre de paquete
  Future<bool> openApp(String packageName) async {
    try {
      final response = await _apiClient.dio.post('/app/$packageName');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Envía texto inyectado
  Future<bool> sendText(String text) async {
    try {
      final response = await _apiClient.dio.post(
        '/text',
        data: {'text': text},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Control de medios genérico (Play, Pause, etc.)
  Future<bool> mediaControl(String control) async {
    try {
      final response = await _apiClient.dio.post('/media/$control');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// Proveedor de Riverpod del repositorio inyectando el apiClient
final tvRepositoryProvider = Provider<TvRepository>((ref) {
  return TvRepository(ref.watch(apiClientProvider));
});
