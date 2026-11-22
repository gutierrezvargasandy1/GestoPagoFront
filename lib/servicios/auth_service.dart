import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/api_client.dart';
import '../modelos.dart';

/// Autenticación compartida con la app móvil: mismos endpoints y credenciales.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  /// La misma base de código corre en web y en móvil; el servidor lo necesita
  /// para avisar en qué plataforma está abierta la otra sesión.
  String get plataforma => kIsWeb ? 'WEB' : 'MOVIL';

  Future<String> registrar({
    required String usuario,
    required String password,
    required String nombre,
  }) async {
    final r = await _api.post('/api/v1/auth/registro',
        autenticado: false,
        cuerpo: {'usuario': usuario, 'password': password, 'nombre': nombre});
    return (r.datos as Map<String, dynamic>)['numeroCuenta'].toString();
  }

  /// Paso 1: usuario y contraseña. Devuelve el desafío para el segundo factor.
  Future<PrimerPaso> iniciar(String usuario, String password) async {
    final r = await _api.post('/api/v1/auth/token',
        autenticado: false, cuerpo: {'usuario': usuario, 'password': password});
    return PrimerPaso.fromJson(r.datos as Map<String, dynamic>);
  }

  /// Paso 2: código de 6 dígitos. [forzar] cierra la sesión de la otra plataforma.
  Future<SesionNueva> verificar(String desafio, String codigo, {bool forzar = false}) async {
    final r = await _api.post('/api/v1/auth/2fa', autenticado: false, cuerpo: {
      'desafio': desafio,
      'codigo': codigo,
      'plataforma': plataforma,
      'forzar': forzar,
    });
    return SesionNueva.fromJson(r.datos as Map<String, dynamic>);
  }

  Future<Perfil> perfil() async {
    final r = await _api.get('/api/v1/perfil');
    return Perfil.fromJson(r.datos as Map<String, dynamic>);
  }

  Future<void> cerrarSesion() => _api.post('/api/v1/auth/logout');
}
