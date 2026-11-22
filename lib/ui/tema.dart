import 'package:flutter/material.dart';

const Color colorMarca = Color(0xFF00796B);

ThemeData construirTema(Brightness brillo) {
  final esquema = ColorScheme.fromSeed(seedColor: colorMarca, brightness: brillo);
  return ThemeData(
    colorScheme: esquema,
    useMaterial3: true,
    scaffoldBackgroundColor: brillo == Brightness.light ? const Color(0xFFF5F7F6) : esquema.surface,
  );
}

/// Estilo común de los campos de texto.
InputDecoration decoracionCampo(BuildContext context, String etiqueta,
    {IconData? icono, String? ayuda, Widget? sufijo}) {
  return InputDecoration(
    labelText: etiqueta,
    helperText: ayuda,
    helperMaxLines: 2,
    prefixIcon: icono == null ? null : Icon(icono),
    suffixIcon: sufijo,
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
