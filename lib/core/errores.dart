/// Error que respondió el backend (ProblemDetail con un `codigo` estable).
class ApiException implements Exception {
  ApiException({
    required this.status,
    required this.codigo,
    required this.mensaje,
    this.transaccionId,
  });

  final int status;
  final String codigo;
  final String mensaje;
  final int? transaccionId;

  @override
  String toString() => mensaje;
}

/// No hubo respuesta (sin red, servidor caído o tiempo agotado).
/// En una compra NO significa que no se cobró: hay que consultar.
class ComunicacionException implements Exception {
  ComunicacionException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
