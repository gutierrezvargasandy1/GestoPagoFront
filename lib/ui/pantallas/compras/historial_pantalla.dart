import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../modelos.dart';
import '../../../servicios/pagos_service.dart';
import '../../widgets/chip_saldo.dart';
import '../../widgets/comunes.dart';
import 'detalle_compra_pantalla.dart';

/// Compras exitosas del usuario (el backend solo devuelve las CONFIRMADA).
class HistorialPantalla extends StatefulWidget {
  const HistorialPantalla({super.key});

  @override
  State<HistorialPantalla> createState() => _HistorialPantallaState();
}

class _HistorialPantallaState extends State<HistorialPantalla> {
  late Future<List<Compra>> _compras;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => _compras = context.read<PagosService>().historial();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis compras'), actions: const [ChipSaldo()]),
      body: FutureBuilder<List<Compra>>(
        future: _compras,
        builder: (context, estado) {
          if (estado.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (estado.hasError) {
            return EstadoVacio(
              icono: Icons.cloud_off_outlined,
              titulo: 'No pudimos cargar tu historial',
              mensaje: estado.error.toString(),
              accion: FilledButton(onPressed: () => setState(_cargar), child: const Text('Reintentar')),
            );
          }
          final compras = estado.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(_cargar);
              await _compras;
            },
            child: compras.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    EstadoVacio(
                      icono: Icons.receipt_long_outlined,
                      titulo: 'Aún no tienes compras exitosas',
                      mensaje: 'Cuando GestoPago confirme una compra, aparecerá aquí.',
                    ),
                  ])
                : Centrado(
                    anchoMaximo: 820,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: compras.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final c = compras[i];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: tema.colorScheme.outlineVariant),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: AvatarServicio(nombre: c.servicio, tamano: 44),
                            title: Text(c.producto, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${c.servicio}\n${fechaHora(c.fecha)} · Folio ${c.folioProveedor ?? '—'}'),
                            isThreeLine: true,
                            trailing: Text(dinero(c.montoTotal),
                                style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => DetalleCompraPantalla(compra: c))),
                          ),
                        );
                      },
                    ),
                  ),
          );
        },
      ),
    );
  }
}
