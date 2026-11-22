import '../core/api_client.dart';
import '../modelos.dart';

class CatalogoService {
  CatalogoService(this._api);

  final ApiClient _api;

  Future<List<Servicio>> servicios() async {
    final r = await _api.get('/api/v1/catalogo/servicios');
    final lista = ((r.datos as List?) ?? const [])
        .map((e) => Servicio.fromJson(e as Map<String, dynamic>))
        .toList();
    lista.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }

  Future<List<Producto>> productos(String idServicio) async {
    final r = await _api.get('/api/v1/catalogo/servicios/${Uri.encodeComponent(idServicio)}/productos');
    final lista = ((r.datos as List?) ?? const [])
        .map((e) => Producto.fromJson(e as Map<String, dynamic>))
        .toList();
    // Primero lo que se puede comprar, luego por precio.
    lista.sort((a, b) {
      if (a.disponibleCompra != b.disponibleCompra) return a.disponibleCompra ? -1 : 1;
      return (a.montoFijo ?? a.montoMinimo ?? 0).compareTo(b.montoFijo ?? b.montoMinimo ?? 0);
    });
    return lista;
  }
}
