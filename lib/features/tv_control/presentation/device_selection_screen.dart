import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tv_controller.dart';
import 'remote_screen.dart';

class DeviceSelectionScreen extends ConsumerStatefulWidget {
  const DeviceSelectionScreen({super.key});

  @override
  ConsumerState<DeviceSelectionScreen> createState() => _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends ConsumerState<DeviceSelectionScreen> {
  final TextEditingController _ipController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _onConnect() async {
    if (_formKey.currentState!.validate()) {
      // Ocultar teclado
      FocusScope.of(context).unfocus();
      
      final ip = _ipController.text.trim();
      await ref.read(tvControllerProvider.notifier).setTargetIp(ip);
      
      // Chequear el status resultante
      final status = ref.read(tvControllerProvider).status;
      if (!mounted) return;

      if (status == ConnectionStatus.connected) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RemoteScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al conectar. Verifica la IP, la Red Local o el TV.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escucha el estado para animaciones de carga
    final status = ref.watch(tvControllerProvider).status;
    final isLoading = status == ConnectionStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.tv, size: 80, color: Colors.blueAccent),
                   const SizedBox(height: 20),
                   const Text(
                     'TV Remote Corporativo',
                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 10),
                   const Text(
                     'Ingresa la IP del televisor Fire TV',
                     style: TextStyle(fontSize: 14, color: Colors.white70),
                   ),
                   const SizedBox(height: 40),
                   TextFormField(
                     controller: _ipController,
                     keyboardType: TextInputType.numberWithOptions(decimal: true),
                     style: const TextStyle(color: Colors.white),
                     decoration: InputDecoration(
                       labelText: 'IP del Fire TV (ej. 192.168.X.X)',
                       hintText: '192.168.1.55',
                       hintStyle: const TextStyle(color: Colors.white30),
                       labelStyle: const TextStyle(color: Colors.white70),
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                       filled: true,
                       fillColor: Colors.white10,
                       prefixIcon: const Icon(Icons.tv, color: Colors.white54),
                     ),
                     validator: (value) {
                       if (value == null || value.trim().isEmpty) {
                         return 'La IP no puede estar vacía';
                       }
                       // Regex básica de IPv4
                       final ipRegex = RegExp(r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$');
                       if (!ipRegex.hasMatch(value.trim())) {
                         return 'Ingresa una IP válida';
                       }
                       return null;
                     },
                     onFieldSubmitted: (_) => _onConnect(),
                   ),
                   const SizedBox(height: 30),
                   SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: ElevatedButton(
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.blueAccent,
                         foregroundColor: Colors.white,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(12),
                         ),
                       ),
                       onPressed: isLoading ? null : _onConnect,
                       child: isLoading
                           ? const SizedBox(
                               width: 24,
                               height: 24,
                               child: CircularProgressIndicator(
                                 color: Colors.white,
                                 strokeWidth: 2,
                               ),
                             )
                           : const Text(
                               'CONECTAR',
                               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                             ),
                     ),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
