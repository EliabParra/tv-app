import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class TvRepository {
  final ApiClient _apiClient;

  TvRepository(this._apiClient);

  /// Verifica si el microservicio está accesible (endpoint raíz /health)
  Future<bool> checkHealth() async {
    try {
      final response = await _apiClient.dio.get('/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Inicia conexión ADB con el TV a través del microservicio
  Future<bool> connectDevice() async {
    try {
      final response = await _apiClient.dio.post('/tv/connect');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Envía un keyevent genérico 
  Future<bool> sendKeyEvent(int code) async {
    try {
      final response = await _apiClient.dio.post('/tv/keyevent/$code');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Envía un comando para abrir una App en específico por nombre de paquete
  Future<bool> openApp(String packageName) async {
    try {
      final response = await _apiClient.dio.post('/tv/app/$packageName');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Envía texto inyectado
  Future<bool> sendText(String text) async {
    try {
      final response = await _apiClient.dio.post(
        '/tv/text',
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
      final response = await _apiClient.dio.post('/tv/media/$control');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Control de encendido/apagado
  Future<bool> powerControl(String action) async {
    try {
      final response = await _apiClient.dio.post('/tv/power/$action');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Captura de pantalla del Fire TV. Devuelve los bytes PNG o null si falla.
  Future<Uint8List?> takeScreenshot() async {
    try {
      final response = await _apiClient.dio.get(
        '/tv/screenshot',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data as List<int>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Proveedor de Riverpod del repositorio inyectando el apiClient
final tvRepositoryProvider = Provider<TvRepository>((ref) {
  return TvRepository(ref.watch(apiClientProvider));
});
