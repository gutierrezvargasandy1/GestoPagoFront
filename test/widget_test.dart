import 'package:flutter_test/flutter_test.dart';
import 'package:gestopago_app/modelos.dart';
import 'package:gestopago_app/ui/widgets/comunes.dart';

void main() {
  test('Solo una compra CONFIRMADA cuenta como exitosa', () {
    ResultadoPago con(String estado) => ResultadoPago.fromJson({
          'transaccionId': 1,
          'estado': estado,
          'monto': '20.00',
          'comision': '0.00',
          'montoTotal': '20.00',
        });

    expect(con('CONFIRMADA').exitosa, isTrue);
    expect(con('REVERSADA').rechazada, isTrue);
    expect(con('EN_CONCILIACION').pendiente, isTrue);
    expect(con('REVISION_MANUAL').pendiente, isTrue);
  });

  test('Los montos llegan como texto y se leen sin perder centavos', () {
    final p = Producto.fromJson({
      'idServicio': '1',
      'idProducto': '10',
      'nombre': 'Telcel \$20',
      'modalidad': 'RECARGA',
      'tipoMonto': 'FIJO',
      'montoFijo': '20.00',
      'comision': '0.00',
      'longitudReferencia': 10,
      'disponibleCompra': true,
    });
    expect(p.montoFijo, 20.0);
    expect(p.esRecarga, isTrue);
    expect(p.disponibleCompra, isTrue);
  });

  test('Las categorias de GestoPago se agrupan para el catalogo', () {
    expect(CategoriaUi.de('TIPO_2'), CategoriaUi.recargas);
    expect(CategoriaUi.de('TIPO_15'), CategoriaUi.servicios);
    expect(CategoriaUi.de('TIPO_11'), CategoriaUi.entretenimiento);
    expect(CategoriaUi.de(null), CategoriaUi.otros);
  });

  test('Los numeros se enmascaran dejando los ultimos 4', () {
    expect(enmascarar('5555555551'), '•••• 5551');
  });
}
