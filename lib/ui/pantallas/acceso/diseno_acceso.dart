import 'package:flutter/material.dart';

import '../../tema.dart';

/// Marco de las pantallas de acceso: en pantallas anchas muestra un panel de
/// marca a la izquierda; en celular solo el formulario.
class DisenoAcceso extends StatelessWidget {
  const DisenoAcceso({super.key, required this.child, this.conRegreso = false});

  final Widget child;
  final bool conRegreso;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final formulario = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: child),
        ),
      ),
    );
    return Scaffold(
      appBar: conRegreso ? AppBar(backgroundColor: Colors.transparent) : null,
      extendBodyBehindAppBar: true,
      body: ancho >= 900
          ? Row(children: [const Expanded(child: _PanelMarca()), Expanded(child: formulario)])
          : formulario,
    );
  }
}

class _PanelMarca extends StatelessWidget {
  const _PanelMarca();

  @override
  Widget build(BuildContext context) {
    const blanco = TextStyle(color: Colors.white);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [colorMarca, Color(0xFF004D40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(56),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 56),
          const SizedBox(height: 16),
          Text('GestoPago',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Recargas y servicios en segundos, desde la web o tu celular.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 40),
          for (final (icono, texto) in const [
            (Icons.verified_user_outlined, 'Doble factor de autenticación'),
            (Icons.devices_outlined, 'Una sola sesión activa: web o móvil'),
            (Icons.receipt_long_outlined, 'Historial de tus compras exitosas'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(children: [
                Icon(icono, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(texto, style: blanco)),
              ]),
            ),
        ],
      ),
    );
  }
}

/// Encabezado con logo para el formulario (en celular hace las veces del panel).
class EncabezadoAcceso extends StatelessWidget {
  const EncabezadoAcceso({super.key, required this.titulo, required this.subtitulo});

  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: tema.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.bolt_rounded, color: tema.colorScheme.onPrimaryContainer, size: 32),
      ),
      const SizedBox(height: 20),
      Text(titulo, style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(subtitulo, style: tema.textTheme.bodyLarge?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 24),
    ]);
  }
}
