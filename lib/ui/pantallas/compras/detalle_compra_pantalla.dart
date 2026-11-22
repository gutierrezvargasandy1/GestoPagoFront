import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../modelos.dart';
import '../../widgets/comunes.dart';

class DetalleCompraPantalla extends StatelessWidget {
  const DetalleCompraPantalla({super.key, required this.compra});

  final Compra compra;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final c = compra;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la compra')),
      body: Centrado(
        anchoMaximo: 560,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Center(child: AvatarServicio(nombre: c.servicio, tamano: 72)),
          const SizedBox(height: 12),
          Text(c.producto,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(c.servicio, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Center(
            child: Chip(avatar: Icon(Icons.check_circle, color: Color(0xFF2E7D32)), label: Text('Compra exitosa')),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: tema.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                FilaDato('Fecha y hora', fechaHora(c.fecha)),
                FilaDato('Número / referencia', c.referencia),
                FilaDato('Monto', dinero(c.monto)),
                FilaDato('Comisión', dinero(c.comision)),
                FilaDato('Total', dinero(c.montoTotal), destacado: true),
                const Divider(),
                FilaDato('No. de operación', '${c.transaccionId}'),
                FilaDato('Folio GestoPago', c.folioProveedor ?? '—'),
                FilaDato('Autorización', c.autorizacion ?? '—'),
              ]),
            ),
          ),
          if (c.pin != null) ...[
            const SizedBox(height: 12),
            Aviso('PIN: ${c.pin}${c.instrucciones == null ? '' : '\n${c.instrucciones}'}', tipo: TipoAviso.info),
          ],
          const SizedBox(height: 16),
          if (c.folioProveedor != null)
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: c.folioProveedor!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Folio copiado')));
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar folio'),
            ),
        ]),
      ),
    );
  }
}
