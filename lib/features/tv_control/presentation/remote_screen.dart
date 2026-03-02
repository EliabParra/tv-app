import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tv_controller.dart';
import 'device_selection_screen.dart';
import '../../../core/utils/download_stub.dart'
    if (dart.library.html) '../../../core/utils/download_web.dart';

class RemoteScreen extends ConsumerWidget {
  const RemoteScreen({super.key});

  /// Todos los botones usan keyevent directo — fire-and-forget
  void _key(WidgetRef ref, int keycode) {
    HapticFeedback.lightImpact();
    ref.read(tvControllerProvider.notifier).pressButton(keycode);
  }

  void _launchApp(WidgetRef ref, String packageName) {
    HapticFeedback.mediumImpact();
    ref.read(tvControllerProvider.notifier).launchApp(packageName);
  }

  void _showScreenshot(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
    );

    final bytes = await ref.read(tvControllerProvider.notifier).takeScreenshot();
    
    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (bytes != null) {
      _displayScreenshotDialog(context, bytes);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al capturar pantalla'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _displayScreenshotDialog(BuildContext context, Uint8List bytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: const Color(0xFF2D2D2D),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text('Screenshot', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.blueAccent),
                    tooltip: 'Descargar',
                    onPressed: () {
                      final filename = 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
                      if (kIsWeb) {
                        downloadFileWeb(bytes, filename);
                      }
                    },
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(tvControllerProvider).status;
    final ip = ref.watch(tvControllerProvider).currentIp;

    if (status == ConnectionStatus.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DeviceSelectionScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Remote', style: TextStyle(color: Colors.white, fontSize: 18)),
            Text(
              status == ConnectionStatus.connected ? 'Conectado: $ip' : 'Desconectado',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.screenshot_monitor, color: Colors.white70),
            tooltip: 'Captura de pantalla',
            onPressed: () => _showScreenshot(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white70),
            tooltip: 'Cambiar TV',
            onPressed: () {
              ref.read(tvControllerProvider.notifier).disconnect();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const DeviceSelectionScreen()),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              // Texto remoto
              _TextInputField(),
              const SizedBox(height: 24),
              
              // D-PAD Central
              _DPadWidget(onKey: (code) => _key(ref, code)),
              const SizedBox(height: 24),
              
              // Navegación (Back, Home, Menu)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _BaseBtn(icono: Icons.arrow_back, label: 'Back', onPressed: () => _key(ref, 4)),
                   _BaseBtn(icono: Icons.home_filled, label: 'Home', onPressed: () => _key(ref, 3)),
                   _BaseBtn(icono: Icons.menu, label: 'Menú', onPressed: () => _key(ref, 82)),
                ],
              ),
              const SizedBox(height: 16),

              // Media: Volumen + Play/Pause (todos por keyevent directo)
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                   _BaseBtn(icono: Icons.volume_down, label: 'Vol-', onPressed: () => _key(ref, 25)),
                   _BaseBtn(icono: Icons.play_arrow, label: 'Play/Pause', onPressed: () => _key(ref, 85)),
                   _BaseBtn(icono: Icons.volume_up, label: 'Vol+', onPressed: () => _key(ref, 24)),
                 ],
              ),
              const SizedBox(height: 16),

              // Mute + Skip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BaseBtn(icono: Icons.volume_off, label: 'Mute', onPressed: () => _key(ref, 164)),
                  _BaseBtn(icono: Icons.skip_previous, label: 'Prev', onPressed: () => _key(ref, 88)),
                  _BaseBtn(icono: Icons.skip_next, label: 'Next', onPressed: () => _key(ref, 87)),
                ],
              ),
              const SizedBox(height: 16),

              // Power
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BaseBtn(icono: Icons.power_settings_new, label: 'Power', onPressed: () => _key(ref, 26)),
                ],
              ),
              const SizedBox(height: 30),
              
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Lanzamiento Rápido', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),

              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: [
                  _DeepLinkChip('Netflix', Colors.red, () => _launchApp(ref, 'com.netflix.ninja')),
                  _DeepLinkChip('YouTube', Colors.white, () => _launchApp(ref, 'com.amazon.firetv.youtube')),
                  _DeepLinkChip('Prime Video', Colors.blue, () => _launchApp(ref, 'com.amazon.avod')),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextInputField extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Enviar texto al TV...',
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        prefixIcon: const Icon(Icons.keyboard, color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
      onSubmitted: (value) {
        if (value.trim().isNotEmpty) {
           HapticFeedback.lightImpact();
           ref.read(tvControllerProvider.notifier).inputText(value.trim());
        }
      },
    );
  }
}

class _DPadWidget extends StatelessWidget {
  final Function(int) onKey;

  const _DPadWidget({required this.onKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Align(alignment: Alignment.topCenter, child: _DirBtn(Icons.arrow_drop_up, () => onKey(19))),
          Align(alignment: Alignment.bottomCenter, child: _DirBtn(Icons.arrow_drop_down, () => onKey(20))),
          Align(alignment: Alignment.centerLeft, child: _DirBtn(Icons.arrow_left, () => onKey(21))),
          Align(alignment: Alignment.centerRight, child: _DirBtn(Icons.arrow_right, () => onKey(22))),
          Align(
            alignment: Alignment.center,
            child: Material(
              color: const Color(0xFF383838),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onKey(23),
                child: const SizedBox(
                  width: 90,
                  height: 90,
                  child: Center(
                    child: Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirBtn extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;

  const _DirBtn(this.icono, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Icon(icono, color: Colors.white70, size: 40),
        ),
      ),
    );
  }
}

class _BaseBtn extends StatelessWidget {
  final IconData icono;
  final String label;
  final VoidCallback onPressed;

  const _BaseBtn({required this.icono, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icono, size: 28, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF2A2A2A),
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _DeepLinkChip extends StatelessWidget {
  final String label;
  final Color chipColor;
  final VoidCallback onTap;

  const _DeepLinkChip(this.label, this.chipColor, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: const Color(0xFF2A2A2A),
      side: BorderSide(color: chipColor.withOpacity(0.5)),
      label: Text(label, style: TextStyle(color: chipColor, fontWeight: FontWeight.bold)),
      onPressed: onTap,
    );
  }
}
