import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../modelos.dart';
import '../../../servicios/catalogo_service.dart';
import '../../tema.dart';
import '../../widgets/chip_saldo.dart';
import '../../widgets/comunes.dart';
import 'productos_pantalla.dart';

class CatalogoPantalla extends StatefulWidget {
  const CatalogoPantalla({super.key});

  @override
  State<CatalogoPantalla> createState() => _CatalogoPantallaState();
}

class _CatalogoPantallaState extends State<CatalogoPantalla> {
  late Future<List<Servicio>> _servicios;
  String _busqueda = '';
  CategoriaUi? _categoria;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() => _servicios = context.read<CatalogoService>().servicios();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo'), actions: const [ChipSaldo()]),
      body: FutureBuilder<List<Servicio>>(
        future: _servicios,
        builder: (context, estado) {
          if (estado.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (estado.hasError) {
            return EstadoVacio(
              icono: Icons.cloud_off_outlined,
              titulo: 'No pudimos cargar el catálogo',
              mensaje: estado.error.toString(),
              accion: FilledButton(onPressed: () => setState(_cargar), child: const Text('Reintentar')),
            );
          }
          final todos = estado.data!;
          if (todos.isEmpty) {
            return const EstadoVacio(
              icono: Icons.inventory_2_outlined,
              titulo: 'El catálogo está vacío',
              mensaje: 'El servidor todavía no sincroniza los productos de GestoPago.',
            );
          }
          final categorias = {for (final s in todos) CategoriaUi.de(s.categoria)}.toList()
            ..sort((a, b) => a.index.compareTo(b.index));
          final filtro = _busqueda.toLowerCase();
          final visibles = todos
              .where((s) => _categoria == null || CategoriaUi.de(s.categoria) == _categoria)
              .where((s) => filtro.isEmpty || s.nombre.toLowerCase().contains(filtro))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(_cargar);
              await _servicios;
            },
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Centrado(
                  anchoMaximo: 1200,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      TextField(
                        decoration: decoracionCampo(context, 'Buscar servicio (Telcel, CFE, Netflix…)',
                            icono: Icons.search),
                        onChanged: (v) => setState(() => _busqueda = v.trim()),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('Todos'),
                              selected: _categoria == null,
                              onSelected: (_) => setState(() => _categoria = null),
                            ),
                          ),
                          for (final c in categorias)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                avatar: Icon(c.icono, size: 18),
                                label: Text(c.etiqueta),
                                selected: _categoria == c,
                                onSelected: (_) => setState(() => _categoria = _categoria == c ? null : c),
                              ),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      Text('${visibles.length} servicios', style: Theme.of(context).textTheme.labelMedium),
                    ]),
                  ),
                ),
              ),
              if (visibles.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EstadoVacio(icono: Icons.search_off, titulo: 'Sin resultados para tu búsqueda'),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisExtent: 168,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: visibles.length,
                    itemBuilder: (context, i) => _TarjetaServicio(servicio: visibles[i]),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}

class _TarjetaServicio extends StatelessWidget {
  const _TarjetaServicio({required this.servicio});

  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 0,
      color: tema.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tema.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ProductosPantalla(servicio: servicio))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AvatarServicio(nombre: servicio.nombre, categoria: servicio.categoria),
            const Spacer(),
            Text(servicio.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(CategoriaUi.de(servicio.categoria).etiqueta,
                style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
