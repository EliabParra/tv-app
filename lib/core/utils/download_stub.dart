import 'dart:typed_data';

/// Descarga un archivo en la plataforma web usando dart:html.
void downloadFileWeb(Uint8List bytes, String filename) {
  // Importación dinámica de dart:html solo en web.
  // ignore: avoid_web_libraries_in_flutter
  // Esta función solo es llamada cuando kIsWeb == true.
  throw UnsupportedError('downloadFileWeb no soportado en esta plataforma');
}
