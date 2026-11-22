import 'package:flutter/foundation.dart';

import '../core/almacen_token.dart';
import '../modelos.dart';
import '../servicios/auth_service.dart';

enum EstadoSesion { cargando, anonima, autenticada }

/// Estado de la sesión en la app. La autoridad es el servidor: si responde
/// que la sesión terminó (otro dispositivo, inactividad o cierre), la app
/// vuelve al inicio de sesión con el motivo.
class SesionController extends ChangeNotifier {
  SesionController(this._auth, this._tokens);

  final AuthService _auth;
  final AlmacenToken _tokens;

  EstadoSesion estado = EstadoSesion.cargando;
  Perfil? perfil;
  String? aviso;

  /// Lo usa main.dart para cerrar las pantallas abiertas al entrar o salir.
  VoidCallback? alCambiarSesion;

  Future<void> iniciar() async {
    final token = await _tokens.cargar();
    if (token == null) {
      _cambiar(EstadoSesion.anonima);
      return;
    }
    try {
      perfil = await _auth.perfil();
      _cambiar(EstadoSesion.autenticada);
    } catch (_) {
      await _tokens.borrar();
      _cambiar(EstadoSesion.anonima);
    }
  }

  Future<void> completarLogin(SesionNueva nueva) async {
    await _tokens.guardar(nueva.accessToken);
    try {
      perfil = await _auth.perfil();
    } catch (_) {
      await _tokens.borrar();
      rethrow;
    }
    aviso = null;
    _cambiar(EstadoSesion.autenticada);
  }

  Future<void> recargarPerfil() async {
    try {
      perfil = await _auth.perfil();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cerrarSesion() async {
    try {
      await _auth.cerrarSesion();
    } catch (_) {
      // Aunque el servidor no responda, la sesión local se borra.
    }
    await _tokens.borrar();
    perfil = null;
    aviso = 'Cerraste sesión correctamente.';
    _cambiar(EstadoSesion.anonima);
  }

  /// Llamado por ApiClient ante un 401 en una petición autenticada.
  void sesionTerminada(String mensaje) {
    if (estado == EstadoSesion.anonima) return;
    _tokens.borrar();
    perfil = null;
    aviso = mensaje;
    _cambiar(EstadoSesion.anonima);
  }

  void _cambiar(EstadoSesion nuevo) {
    estado = nuevo;
    notifyListeners();
    alCambiarSesion?.call();
  }
}
