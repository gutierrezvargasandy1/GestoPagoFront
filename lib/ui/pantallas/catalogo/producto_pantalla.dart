import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../estado/sesion_controller.dart';
import '../../../modelos.dart';
import '../../tema.dart';
import '../../widgets/comunes.dart';
import '../compras/resultado_compra_pantalla.dart';
import 'productos_pantalla.dart';

/// Detalle del producto y captura de la compra (pocos pasos: dato, confirmar, listo).
class ProductoPantalla extends StatefulWidget {
  const ProductoPantalla({super.key, required this.servicio, required this.producto});

  final Servicio servicio;
  final Producto producto;

  @override
  State<ProductoPantalla> createState() => _ProductoPantallaState();
}

class _ProductoPantallaState extends State<ProductoPantalla> {
  final _formulario = GlobalKey<FormState>();
  final _referencia = TextEditingController();
  final _monto = TextEditingController();

  Producto get _p => widget.producto;

  @override
  void dispose() {
    _referencia.dispose();
    _monto.dispose();
    super.dispose();
  }

  double? get _montoCapturado =>
      _p.montoFijoEstablecido ? _p.montoFijo : double.tryParse(_monto.text.replaceAll(',', '').trim());

  // El backend vuelve a validar todo contra el catálogo; aquí solo se ayuda al usuario.
  String? _validarReferencia(String? v) {
    final valor = (v ?? '').trim();
    if (valor.isEmpty) return _p.esRecarga ? 'Escribe el número a recargar' : 'Escribe la referencia';
    if (!RegExp(r'^[A-Za-z0-9]{1,40}$').hasMatch(valor)) return 'Solo letras y números';
    if (_p.esRecarga && !RegExp(r'^\d+$').hasMatch(valor)) return 'Solo números';
    final largo = _p.longitudReferencia;
    if (largo != null && valor.length != largo) return 'Debe tener $largo caracteres';
    return null;
  }

  String? _validarMonto(String? _) {
    if (_p.montoFijoEstablecido) return null;
    final monto = _montoCapturado;
    if (monto == null || monto <= 0) return 'Escribe un monto válido';
    if (_p.montoMinimo != null && monto < _p.montoMinimo!) return 'Mínimo ${dinero(_p.montoMinimo!)}';
    if (_p.montoMaximo != null && monto > _p.montoMaximo!) return 'Máximo ${dinero(_p.montoMaximo!)}';
    return null;
  }

  Future<void> _comprar() async {
    if (!_formulario.currentState!.validate()) return;
    final cuenta = context.read<SesionController>().perfil?.cuentaPrincipal;
    if (cuenta == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tu usuario no tiene una cuenta asociada.')));
      return;
    }
    final monto = _montoCapturado!;
    final total = monto + _p.comision;
    final referencia = _referencia.text.trim();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        icon: const Icon(Icons.shopping_bag_outlined),
        title: const Text('Confirma tu compra'),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FilaDato('Producto', _p.nombre),
            FilaDato('Servicio', widget.servicio.nombre),
            FilaDato(_p.esRecarga ? 'Número' : 'Referencia', referencia),
            FilaDato('Cuenta', enmascarar(cuenta.numero)),
            const Divider(),
            FilaDato('Monto', dinero(monto)),
            FilaDato('Comisión', dinero(_p.comision)),
            FilaDato('Total a cobrar', dinero(total), destacado: true),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(contexto).pop(true), child: Text('Pagar ${dinero(total)}')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultadoCompraPantalla(
        solicitud: SolicitudCompra(
          numeroCuenta: cuenta.numero,
          servicio: widget.servicio,
          producto: _p,
          referencia: referencia,
          monto: monto,
          // Una clave por intención de compra; se reutiliza si hay que reintentar.
          clave: const Uuid().v4(),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cuenta = context.watch<SesionController>().perfil?.cuentaPrincipal;
    final monto = _montoCapturado ?? 0;
    final total = monto + _p.comision;
    final sinSaldo = cuenta != null && monto > 0 && cuenta.saldo < total;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: Centrado(
        anchoMaximo: 640,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formulario,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Card(
                elevation: 0,
                color: tema.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      AvatarServicio(nombre: widget.servicio.nombre, categoria: widget.servicio.categoria, tamano: 64),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_p.nombre, style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text(widget.servicio.nombre, style: tema.textTheme.bodyMedium),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Text(precioDe(_p),
                        style: tema.textTheme.headlineMedium
                            ?.copyWith(color: tema.colorScheme.primary, fontWeight: FontWeight.bold)),
                    if (_p.comision > 0) Text('Comisión: ${dinero(_p.comision)}'),
                    const SizedBox(height: 12),
                    Text(
                      (_p.leyenda?.trim().isNotEmpty ?? false)
                          ? _p.leyenda!
                          : _p.esRecarga
                              ? 'Recarga de tiempo aire. El saldo llega al número indicado en cuanto GestoPago confirma la operación.'
                              : 'Pago de servicio con la referencia impresa en tu recibo.',
                      style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              if (!_p.disponibleCompra)
                const Aviso(
                  'Este producto se muestra como referencia: todavía no se puede comprar en línea. '
                  'Elige una recarga marcada como “Disponible”.',
                  tipo: TipoAviso.info,
                )
              else ...[
                TextFormField(
                  controller: _referencia,
                  keyboardType: _p.esRecarga ? TextInputType.phone : TextInputType.text,
                  inputFormatters: [
                    if (_p.esRecarga) FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_p.longitudReferencia ?? 40),
                  ],
                  decoration: decoracionCampo(
                    context,
                    _p.esRecarga ? 'Número a recargar' : 'Referencia del recibo',
                    icono: _p.esRecarga ? Icons.phone_iphone : Icons.receipt_outlined,
                    ayuda: _p.longitudReferencia == null ? null : '${_p.longitudReferencia} dígitos',
                  ),
                  validator: _validarReferencia,
                ),
                if (!_p.montoFijoEstablecido) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _monto,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    decoration: decoracionCampo(context, 'Monto a pagar', icono: Icons.attach_money),
                    onChanged: (_) => setState(() {}),
                    validator: _validarMonto,
                  ),
                ],
                const SizedBox(height: 16),
                if (cuenta != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: Text('Se cobrará de tu cuenta ${enmascarar(cuenta.numero)}'),
                    subtitle: Text('Saldo disponible: ${dinero(cuenta.saldo)}'),
                  ),
                if (sinSaldo) ...[
                  const Aviso('Tu saldo no alcanza para esta compra.', tipo: TipoAviso.advertencia),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _comprar,
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: Text(monto > 0 ? 'Comprar · ${dinero(total)}' : 'Comprar'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
