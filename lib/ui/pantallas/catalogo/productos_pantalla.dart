import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../modelos.dart';
import '../../../servicios/catalogo_service.dart';
import '../../widgets/chip_saldo.dart';
import '../../widgets/comunes.dart';
import 'producto_pantalla.dart';

String precioDe(Producto p) {
  if (p.montoFijoEstablecido) return dinero(p.montoFijo!);
  if (p.montoMinimo != null && p.montoMaximo != null) {
    return '${dinero(p.montoMinimo!)} a ${dinero(p.montoMaximo!)}';
  }
  return 'Monto variable';
}

class ProductosPantalla extends StatefulWidget {
  const ProductosPantalla({super.key, required this.servicio});

  final Servicio servicio;

  @override
  State<ProductosPantalla> createState() => _ProductosPantallaState();
}

class _ProductosPantallaState extends State<ProductosPantalla> {
  late Future<List<Producto>> _productos;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => _productos = context.read<CatalogoService>().productos(widget.servicio.idServicio);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final servicio = widget.servicio;
    return Scaffold(
      appBar: AppBar(title: Text(servicio.nombre), actions: const [ChipSaldo()]),
      body: FutureBuilder<List<Producto>>(
        future: _productos,
        builder: (context, estado) {
          if (estado.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (estado.hasError) {
            return EstadoVacio(
              icono: Icons.cloud_off_outlined,
              titulo: 'No pudimos cargar los productos',
              mensaje: estado.error.toString(),
              accion: FilledButton(onPressed: () => setState(_cargar), child: const Text('Reintentar')),
            );
          }
          final productos = estado.data!;
          return Centrado(
            anchoMaximo: 820,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                AvatarServicio(nombre: servicio.nombre, categoria: servicio.categoria, tamano: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(servicio.nombre, style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${CategoriaUi.de(servicio.categoria).etiqueta} · ${productos.length} productos',
                        style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),
              if (productos.isEmpty)
                const EstadoVacio(icono: Icons.inventory_2_outlined, titulo: 'Este servicio no tiene productos activos'),
              for (final p in productos)
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: tema.colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(spacing: 8, runSpacing: 4, children: [
                        _Etiqueta(
                          texto: p.disponibleCompra ? 'Disponible' : 'No disponible en línea',
                          color: p.disponibleCompra ? tema.colorScheme.primary : tema.colorScheme.outline,
                        ),
                        _Etiqueta(
                            texto: p.esRecarga ? 'Recarga' : 'Pago de servicio', color: tema.colorScheme.tertiary),
                      ]),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(precioDe(p), style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        if (p.comision > 0)
                          Text('+ ${dinero(p.comision)} comisión', style: tema.textTheme.bodySmall),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProductoPantalla(servicio: servicio, producto: p))),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(texto, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}
