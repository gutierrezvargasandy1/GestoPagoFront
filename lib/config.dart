/// Configuración de la app. La URL del backend se puede cambiar al compilar:
/// flutter run -d chrome --dart-define=API_URL=http://localhost:8080
class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://gestopago-pp6y.onrender.com',
  );

  /// Render (plan gratuito) tarda hasta ~50 s en despertar.
  static const Duration espera = Duration(seconds: 60);

  /// Mayor que la espera del backend hacia GestoPago (70 s): así no cortamos
  /// una compra que todavía va a tener respuesta.
  static const Duration esperaCompra = Duration(seconds: 100);
}
