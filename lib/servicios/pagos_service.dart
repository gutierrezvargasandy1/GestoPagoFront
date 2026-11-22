import '../config.dart';
import '../core/api_client.dart';
import '../modelos.dart';

class PagosService {
  PagosService(this._api);

  final ApiClient _api;

  /// [clave] es la Idempotency-Key: se genera una por intención de compra y se
  /// reutiliza al reintentar, así el backend nunca cobra dos veces.
  Future<ResultadoPago> comprar({
    required String numeroCuenta,
    required Producto producto,
    required String referencia,
    required double monto,
    required String clave,
  }) async {
    final r = await _api.post(
      '/api/v1/pagos',
      encabezados: {'Idempotency-Key': clave},
      espera: AppConfig.esperaCompra,
      cuerpo: {
        'numeroCuenta': numeroCuenta,
        'idServicio': producto.idServicio,
        'idProducto': producto.idProducto,
        'referencia': referencia,
        'monto': monto,
      },
    );
    return ResultadoPago.fromJson(r.datos as Map<String, dynamic>);
  }

  Future<ResultadoPago> consultar(int transaccionId) async {
    final r = await _api.get('/api/v1/pagos/$transaccionId');
    return ResultadoPago.fromJson(r.datos as Map<String, dynamic>);
  }

  Future<List<Compra>> historial() async {
    final r = await _api.get('/api/v1/pagos/historial');
    return ((r.datos as List?) ?? const [])
        .map((e) => Compra.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
