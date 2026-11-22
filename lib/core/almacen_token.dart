import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el token de acceso cifrado (Keystore/Keychain en móvil, WebCrypto en
/// web). Nunca se guarda la contraseña ni el código de doble factor.
class AlmacenToken {
  static const _clave = 'gp_token_acceso';
  final FlutterSecureStorage _almacen = const FlutterSecureStorage();
  String? _actual;

  String? get actual => _actual;

  Future<String?> cargar() async {
    try {
      _actual = await _almacen.read(key: _clave);
    } catch (_) {
      _actual = null;
    }
    return _actual;
  }

  Future<void> guardar(String token) async {
    _actual = token;
    try {
      await _almacen.write(key: _clave, value: token);
    } catch (_) {
      // Si el navegador no permite almacenamiento, la sesión vive solo en memoria.
    }
  }

  Future<void> borrar() async {
    _actual = null;
    try {
      await _almacen.delete(key: _clave);
    } catch (_) {}
  }
}
