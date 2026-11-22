import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _moneda = NumberFormat.currency(locale: 'es_MX', symbol: r'$', decimalDigits: 2);

String dinero(double valor) => _moneda.format(valor);

String fechaHora(DateTime? fecha) =>
    fecha == null ? '—' : DateFormat("d 'de' MMMM y, HH:mm", 'es').format(fecha);

/// Muestra solo los últimos 4 caracteres (números de cuenta, teléfonos).
String enmascarar(String valor) =>
    valor.length <= 4 ? valor : '•••• ${valor.substring(valor.length - 4)}';

/// Contenido centrado con ancho máximo: se ve bien en monitor y en celular.
class Centrado extends StatelessWidget {
  const Centrado({super.key, required this.child, this.anchoMaximo = 960});

  final Widget child;
  final double anchoMaximo;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: anchoMaximo), child: child),
      );
}

enum TipoAviso { error, info, exito, advertencia }

class Aviso extends StatelessWidget {
  const Aviso(this.mensaje, {super.key, this.tipo = TipoAviso.error});

  final String mensaje;
  final TipoAviso tipo;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final (Color fondo, Color texto, IconData icono) = switch (tipo) {
      TipoAviso.error => (esquema.errorContainer, esquema.onErrorContainer, Icons.error_outline),
      TipoAviso.info => (esquema.secondaryContainer, esquema.onSecondaryContainer, Icons.info_outline),
      TipoAviso.exito => (esquema.primaryContainer, esquema.onPrimaryContainer, Icons.check_circle_outline),
      TipoAviso.advertencia => (const Color(0xFFFFF3CD), const Color(0xFF664D03), Icons.warning_amber_rounded),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icono, color: texto, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(mensaje, style: TextStyle(color: texto))),
        ]),
      ),
    );
  }
}

class EstadoVacio extends StatelessWidget {
  const EstadoVacio({super.key, required this.icono, required this.titulo, this.mensaje, this.accion});

  final IconData icono;
  final String titulo;
  final String? mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icono, size: 56, color: tema.colorScheme.primary.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(titulo, style: tema.textTheme.titleMedium, textAlign: TextAlign.center),
          if (mensaje != null) ...[
            const SizedBox(height: 8),
            Text(mensaje!, textAlign: TextAlign.center, style: tema.textTheme.bodyMedium),
          ],
          if (accion != null) ...[const SizedBox(height: 16), accion!],
        ]),
      ),
    );
  }
}

/// Fila "etiqueta: valor" para resúmenes y comprobantes.
class FilaDato extends StatelessWidget {
  const FilaDato(this.etiqueta, this.valor, {super.key, this.destacado = false});

  final String etiqueta;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            flex: 2,
            child: Text(etiqueta,
                style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant))),
        Expanded(
          flex: 3,
          child: SelectableText(valor,
              textAlign: TextAlign.right,
              style: destacado
                  ? tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                  : tema.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}

/// Categorías para organizar el catálogo. El backend manda la categoría de
/// GestoPago (idCatTipoServicio → "TIPO_n") o la del catálogo de ejemplo.
enum CategoriaUi {
  recargas('Recargas', Icons.phone_iphone),
  servicios('Servicios', Icons.receipt_long_outlined),
  entretenimiento('Entretenimiento', Icons.movie_outlined),
  financieros('Financieros', Icons.account_balance_outlined),
  otros('Otros', Icons.category_outlined);

  const CategoriaUi(this.etiqueta, this.icono);

  final String etiqueta;
  final IconData icono;

  static CategoriaUi de(String? categoria) => switch (categoria) {
        'TIEMPO_AIRE' || 'TIPO_1' || 'TIPO_2' || 'TIPO_3' || 'TIPO_4' || 'TIPO_6' || 'TIPO_12' ||
        'TIPO_13' || 'TIPO_17' =>
          CategoriaUi.recargas,
        'SERVICIOS' || 'TIPO_5' || 'TIPO_7' || 'TIPO_15' || 'TIPO_18' => CategoriaUi.servicios,
        'TELEVISION' || 'TIPO_10' || 'TIPO_11' || 'TIPO_16' || 'TIPO_19' => CategoriaUi.entretenimiento,
        'TIPO_8' || 'TIPO_14' => CategoriaUi.financieros,
        _ => CategoriaUi.otros,
      };
}

/// Imagen representativa del servicio: color propio de la marca (derivado del
/// nombre), sus iniciales y el ícono de su categoría.
class AvatarServicio extends StatelessWidget {
  const AvatarServicio({super.key, required this.nombre, this.categoria, this.tamano = 56});

  final String nombre;
  final String? categoria;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final hue = (nombre.toLowerCase().codeUnits.fold<int>(7, (a, c) => (a * 31 + c) % 360)).toDouble();
    final color = HSLColor.fromAHSL(1, hue, 0.55, 0.42).toColor();
    final palabras = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final iniciales = palabras.isEmpty
        ? '?'
        : palabras.take(2).map((p) => p.characters.first.toUpperCase()).join();
    return Semantics(
      label: 'Logotipo de $nombre',
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, HSLColor.fromColor(color).withLightness(0.30).toColor()],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(tamano * 0.28),
            ),
            alignment: Alignment.center,
            child: Text(iniciales,
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: tamano * 0.34)),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: CircleAvatar(
              radius: tamano * 0.18,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Icon(CategoriaUi.de(categoria).icono, size: tamano * 0.22, color: color),
            ),
          ),
        ]),
      ),
    );
  }
}
