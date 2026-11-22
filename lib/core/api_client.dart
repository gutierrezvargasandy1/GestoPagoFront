import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'almacen_token.dart';
import 'errores.dart';

class RespuestaApi {
  RespuestaApi(this.status, this.datos, this.encabezados);

  final int status;
  final dynamic datos;
  final Map<String, String> encabezados;
}

/// Único punto de salida HTTP hacia el backend. Agrega el token, traduce los
/// errores ProblemDetail y avisa cuando el servidor da la sesión por terminada.
class ApiClient {
  ApiClient({required this.tokens, http.Client? cliente, String? baseUrl})
      : _http = cliente ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.apiUrl;

  final AlmacenToken tokens;
  final http.Client _http;
  final String baseUrl;

  /// Se llama con el mensaje del servidor cuando una petición autenticada
  /// recibe 401 (sesión cerrada en otro dispositivo, vencida o inválida).
  void Function(String mensaje)? alTerminarSesion;

  Future<RespuestaApi> get(String ruta) => _enviar('GET', ruta);

  Future<RespuestaApi> post(
    String ruta, {
    Object? cuerpo,
    bool autenticado = true,
    Map<String, String> encabezados = const {},
    Duration? espera,
  }) =>
      _enviar('POST', ruta,
          cuerpo: cuerpo, autenticado: autenticado, extra: encabezados, espera: espera);

  Future<RespuestaApi> _enviar(
    String metodo,
    String ruta, {
    Object? cuerpo,
    bool autenticado = true,
    Map<String, String> extra = const {},
    Duration? espera,
  }) async {
    final uri = Uri.parse('$baseUrl$ruta');
    final encabezados = <String, String>{'Accept': 'application/json', ...extra};
    if (cuerpo != null) encabezados['Content-Type'] = 'application/json';
    final token = tokens.actual;
    if (autenticado && token != null) encabezados['Authorization'] = 'Bearer $token';

    http.Response respuesta;
    try {
      final peticion = metodo == 'GET'
          ? _http.get(uri, headers: encabezados)
          : _http.post(uri,
              headers: encabezados, body: cuerpo == null ? null : jsonEncode(cuerpo));
      respuesta = await peticion.timeout(espera ?? AppConfig.espera);
    } on TimeoutException {
      throw ComunicacionException('El servidor no respondió a tiempo.');
    } on Exception {
      throw ComunicacionException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }

    final texto = utf8.decode(respuesta.bodyBytes);
    dynamic datos;
    if (texto.isNotEmpty) {
      try {
        datos = jsonDecode(texto);
      } catch (_) {
        datos = null;
      }
    }
    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      return RespuestaApi(respuesta.statusCode, datos, respuesta.headers);
    }
    final error = _error(respuesta.statusCode, datos);
    if (autenticado && respuesta.statusCode == 401) {
      alTerminarSesion?.call(error.mensaje);
    }
    throw error;
  }

  ApiException _error(int status, dynamic datos) {
    if (datos is Map<String, dynamic>) {
      return ApiException(
        status: status,
        codigo: (datos['codigo'] ?? 'ERROR_$status').toString(),
        mensaje: (datos['detail'] ?? datos['title'] ?? 'Ocurrió un error.').toString(),
        transaccionId: (datos['transaccionId'] as num?)?.toInt(),
      );
    }
    return ApiException(
      status: status,
      codigo: 'ERROR_$status',
      mensaje: status >= 500
          ? 'El servidor tuvo un problema. Intenta más tarde.'
          : 'La solicitud no se pudo completar.',
    );
  }
}
