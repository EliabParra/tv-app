import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../repositories/tv_repository.dart';

enum ConnectionStatus { idle, loading, connected, error }

class TvState {
  final String currentIp;
  final ConnectionStatus status;

  const TvState({
    required this.currentIp,
    required this.status,
  });

  factory TvState.initial() {
    return const TvState(
      currentIp: '',
      status: ConnectionStatus.idle,
    );
  }

  TvState copyWith({
    String? currentIp,
    ConnectionStatus? status,
  }) {
    return TvState(
      currentIp: currentIp ?? this.currentIp,
      status: status ?? this.status,
    );
  }
}

class TvController extends Notifier<TvState> {
  @override
  TvState build() {
    return TvState.initial();
  }

  /// Registra la IP del televisor Fire TV seleccionado y verifica la conexión
  Future<void> setTargetIp(String ip) async {
    state = state.copyWith(status: ConnectionStatus.loading, currentIp: ip);
    ref.read(apiClientProvider).setDeviceIp(ip);

    final repo = ref.read(tvRepositoryProvider);
    final isHealthy = await repo.checkHealth();

    if (isHealthy) {
      await repo.connectDevice();
      state = state.copyWith(status: ConnectionStatus.connected);
    } else {
      state = state.copyWith(status: ConnectionStatus.error);
    }
  }

  /// Limpia la IP guardada y regresa al estado en reposo
  void disconnect() {
    ref.read(apiClientProvider).setDeviceIp('');
    state = TvState.initial();
  }

  /// Botón de control remoto — fire-and-forget para máxima velocidad
  void pressButton(int code) {
    if (state.status != ConnectionStatus.connected) return;
    ref.read(tvRepositoryProvider).sendKeyEvent(code);
  }

  /// Control Media — fire-and-forget
  void sendMediaControl(String controlCommand) {
    if (state.status != ConnectionStatus.connected) return;
    ref.read(tvRepositoryProvider).mediaControl(controlCommand);
  }

  /// Lanza una aplicación de AndroidTV instalada
  void launchApp(String packageName) {
    if (state.status != ConnectionStatus.connected) return;
    ref.read(tvRepositoryProvider).openApp(packageName);
  }

  /// Escribe texto remoto en el campo enfocado del TV
  void inputText(String text) {
    if (state.status != ConnectionStatus.connected || text.isEmpty) return;
    ref.read(tvRepositoryProvider).sendText(text);
  }

  /// Control de encendido/apagado
  void powerControl(String action) {
    if (state.status != ConnectionStatus.connected) return;
    ref.read(tvRepositoryProvider).powerControl(action);
  }

  /// Captura de pantalla del TV. Retorna los bytes PNG o null.
  Future<Uint8List?> takeScreenshot() async {
    if (state.status != ConnectionStatus.connected) return null;
    return await ref.read(tvRepositoryProvider).takeScreenshot();
  }
}

/// Provider para que la UI escuche los cambios de IP o Status
final tvControllerProvider = NotifierProvider<TvController, TvState>(() {
  return TvController();
});
