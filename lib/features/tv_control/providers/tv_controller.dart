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

  /// Cambia la IP del SDK subyacente y verifica la conexión contra el TV microservicio
  Future<void> setTargetIp(String ip) async {
    // 1. Mostrar estado de carga y guardar IP
    state = state.copyWith(status: ConnectionStatus.loading, currentIp: ip);

    // 2. Modificar el cliente API (Singleton dentro del ProviderScope)
    ref.read(apiClientProvider).updateBaseUrl(ip);

    // 3. Chequear Health del microservicio
    final repo = ref.read(tvRepositoryProvider);
    final isHealthy = await repo.checkHealth();

    if (isHealthy) {
      // 4. Intentamos conectar el dispositivo vía ADB desde el microservicio
      await repo.connectDevice(); // Lo hacemos en background, si falla no importa, ADB puede estar ya pareado
      state = state.copyWith(status: ConnectionStatus.connected);
    } else {
      // 5. El TV no responde, revertir
      state = state.copyWith(status: ConnectionStatus.error);
    }
  }

  /// Limpia la IP guardada y regresa al estado en reposo
  void disconnect() {
    state = TvState.initial();
  }

  /// Oprime botón direccional/control si estamos conectados
  Future<void> pressButton(int code) async {
    if (state.status != ConnectionStatus.connected) return;
    await ref.read(tvRepositoryProvider).sendKeyEvent(code);
  }

  /// Control Media si estamos conectados
  Future<void> sendMediaControl(String controlCommand) async {
    if (state.status != ConnectionStatus.connected) return;
    await ref.read(tvRepositoryProvider).mediaControl(controlCommand);
  }

  /// Lanza una aplicación de AndroidTV instalada
  Future<void> launchApp(String packageName) async {
    if (state.status != ConnectionStatus.connected) return;
    await ref.read(tvRepositoryProvider).openApp(packageName);
  }

  /// Escribir texto remoto
  Future<void> inputText(String text) async {
    if (state.status != ConnectionStatus.connected || text.isEmpty) return;
    await ref.read(tvRepositoryProvider).sendText(text);
  }
}

/// Provider para que la UI escuche los cambios de IP o Status
final tvControllerProvider = NotifierProvider<TvController, TvState>(() {
  return TvController();
});
