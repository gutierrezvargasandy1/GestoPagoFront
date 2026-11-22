import 'package:flutter/material.dart';

import 'catalogo/catalogo_pantalla.dart';
import 'compras/historial_pantalla.dart';
import 'cuenta/cuenta_pantalla.dart';

/// Estructura principal: barra inferior en celular, riel lateral en pantallas anchas.
class InicioPantalla extends StatefulWidget {
  const InicioPantalla({super.key});

  @override
  State<InicioPantalla> createState() => _InicioPantallaState();
}

class _InicioPantallaState extends State<InicioPantalla> {
  int _indice = 0;
  int _versionHistorial = 0;

  static const _destinos = [
    (Icons.storefront_outlined, Icons.storefront, 'Catálogo'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Mis compras'),
    (Icons.person_outline, Icons.person, 'Cuenta'),
  ];

  void _seleccionar(int indice) => setState(() {
        _indice = indice;
        // El historial se vuelve a pedir cada vez que se abre.
        if (indice == 1) _versionHistorial++;
      });

  @override
  Widget build(BuildContext context) {
    final paginas = [
      const CatalogoPantalla(),
      HistorialPantalla(key: ValueKey(_versionHistorial)),
      const CuentaPantalla(),
    ];
    final contenido = IndexedStack(index: _indice, children: paginas);
    final ancho = MediaQuery.sizeOf(context).width;

    if (ancho >= 840) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            selectedIndex: _indice,
            onDestinationSelected: _seleccionar,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.bolt_rounded, size: 36, color: Theme.of(context).colorScheme.primary),
            ),
            destinations: [
              for (final (icono, seleccionado, etiqueta) in _destinos)
                NavigationRailDestination(
                    icon: Icon(icono), selectedIcon: Icon(seleccionado), label: Text(etiqueta)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: contenido),
        ]),
      );
    }
    return Scaffold(
      body: contenido,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _seleccionar,
        destinations: [
          for (final (icono, seleccionado, etiqueta) in _destinos)
            NavigationDestination(icon: Icon(icono), selectedIcon: Icon(seleccionado), label: etiqueta),
        ],
      ),
    );
  }
}
