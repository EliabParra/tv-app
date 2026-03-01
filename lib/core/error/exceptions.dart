class ServerException implements Exception {
  final String message;
  const ServerException({this.message = 'Error interno del servidor o timeout'});
  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException({this.message = 'No autorizado. Verifique su API Key.'});
  @override
  String toString() => message;
}
