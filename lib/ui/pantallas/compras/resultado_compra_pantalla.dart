import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/errores.dart';
import '../../../estado/sesion_controller.dart';
import '../../../modelos.dart';
import '../../../servicios/pagos_service.dart';
import '../../widgets/comunes.dart';

class SolicitudCompra {
  SolicitudCompra({
    required this.numeroCuenta,
    required this.servicio,
    required this.producto,
    required this.referencia,
    required this.monto,
    required this.clave,
  });

  final String numeroCuenta;
  final Servicio servicio;
  final Producto producto;
  final String referencia;
  final double monto;
  final String clave;
}

enum _Fase { procesando, exitosa, rechazada, pendiente, errorComunicacion }

/// Envía la compra y muestra su resultado. Distingue exitosa, rechazada,
/// pendiente (el backend la está conciliando con GestoPago) y error de comunicación.
class ResultadoCompraPantalla extends StatefulWidget {
  const ResultadoCompraPantalla({super.key, required this.solicitud});

  final SolicitudCompra solicitud;

  @override
  State<ResultadoCompraPantalla> createState() => _ResultadoCompraPantallaState();
}

class _ResultadoCompraPantallaState extends State<ResultadoCompraPantalla> {
  _Fase _fase = _Fase.procesando;
  ResultadoPago? _resultado;
  int? _transaccionId;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    _enviar();
  }

  /// Reintentar usa la MISMA Idempotency-Key: si la primera llegó al servidor,
  /// se recibe ese mismo pago y no se cobra otra vez.
  Future<void> _enviar() async {
    final pagos = context.read<PagosService>();
    final sesion = context.read<SesionController>();
    final s = widget.solicitud;
    setState(() => _fase = _Fase.procesando);
    try {
      final r = await pagos.comprar(
        numeroCuenta: s.numeroCuenta,
        producto: s.producto,
        referencia: s.referencia,
        monto: s.monto,
        clave: s.clave,
      );
      _aplicar(r);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _transaccionId = e.transaccionId;
        _mensaje = e.mensaje;
        // Ya hay un pago en curso con esta clave: su resultado está pendiente.
        _fase = e.codigo == 'PAGO_EN_PROCESO' ? _Fase.pendiente : _Fase.rechazada;
      });
    } on ComunicacionException {
      if (!mounted) return;
      setState(() {
        _fase = _Fase.errorComunicacion;
        _mensaje = 'No recibimos respuesta del servidor, así que no sabemos si la compra se aplicó. '
            'Toca “Reintentar”: consulta la misma operación y nunca cobra dos veces.';
      });
    } finally {
      sesion.recargarPerfil(); // saldo actualizado
    }
  }

  Future<void> _consultarEstado() async {
    final id = _transaccionId;
    if (id == null) return _enviar();
    final pagos = context.read<PagosService>();
    setState(() => _fase = _Fase.procesando);
    try {
      _aplicar(await pagos.consultar(id));
    } on ApiException catch (e) {
      _pendienteCon(e.mensaje);
    } on ComunicacionException catch (e) {
      _pendienteCon(e.mensaje);
    }
    if (mounted) context.read<SesionController>().recargarPerfil();
  }

  void _pendienteCon(String mensaje) {
    if (!mounted) return;
    setState(() {
      _fase = _Fase.pendiente;
      _mensaje = mensaje;
    });
  }

  void _aplicar(ResultadoPago r) {
    if (!mounted) return;
    setState(() {
      _resultado = r;
      _transaccionId = r.transaccionId;
      _mensaje = r.mensaje;
      _fase = r.exitosa
          ? _Fase.exitosa
          : r.rechazada
              ? _Fase.rechazada
              : _Fase.pendiente;
    });
  }

  @override
  Widget build(BuildContext context) {
    final procesando = _fase == _Fase.procesando;
    return PopScope(
      canPop: !procesando,
      child: Scaffold(
        appBar: AppBar(title: const Text('Resultado de la compra'), automaticallyImplyLeading: !procesando),
        body: Centrado(
          anchoMaximo: 560,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: procesando ? _procesando(context) : _resultadoVista(context),
          ),
        ),
      ),
    );
  }

  Widget _procesando(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(children: [
          const SizedBox(width: 64, height: 64, child: CircularProgressIndicator(strokeWidth: 5)),
          const SizedBox(height: 24),
          Text('Procesando tu compra con GestoPago…', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('No cierres esta ventana. Puede tardar hasta un minuto.', textAlign: TextAlign.center),
        ]),
      );

  Widget _resultadoVista(BuildContext context) {
    final tema = Theme.of(context);
    final s = widget.solicitud;
    final r = _resultado;
    final (Color color, IconData icono, String titulo, String descripcion) = switch (_fase) {
      _Fase.exitosa => (const Color(0xFF2E7D32), Icons.check_circle_rounded, '¡Compra exitosa!',
          'GestoPago confirmó tu compra.'),
      _Fase.rechazada => (tema.colorScheme.error, Icons.cancel_rounded, 'Compra rechazada',
          'No se realizó la compra. Si se había descontado el dinero, ya se devolvió a tu cuenta.'),
      _Fase.pendiente => (const Color(0xFFF57C00), Icons.schedule_rounded, 'Compra pendiente',
          'GestoPago no dio una respuesta definitiva. El monto queda apartado mientras lo confirmamos; '
              'si no se aplica, se te devuelve.'),
      _Fase.errorComunicacion => (tema.colorScheme.outline, Icons.wifi_off_rounded, 'Error de comunicación',
          'No pudimos comunicarnos con el servidor.'),
      _Fase.procesando => (tema.colorScheme.primary, Icons.hourglass_top, '', ''),
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CircleAvatar(radius: 44, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icono, color: color, size: 56)),
      const SizedBox(height: 16),
      Text(titulo,
          textAlign: TextAlign.center,
          style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 8),
      Text(descripcion, textAlign: TextAlign.center),
      if (_mensaje != null && _mensaje!.isNotEmpty) ...[
        const SizedBox(height: 12),
        Aviso(_mensaje!,
            tipo: switch (_fase) {
              _Fase.exitosa => TipoAviso.exito,
              _Fase.rechazada => TipoAviso.error,
              _ => TipoAviso.advertencia,
            }),
      ],
      const SizedBox(height: 20),
      Card(
        elevation: 0,
        color: tema.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            FilaDato('Producto', s.producto.nombre),
            FilaDato('Servicio', s.servicio.nombre),
            FilaDato(s.producto.esRecarga ? 'Número' : 'Referencia', s.referencia),
            FilaDato('Monto', dinero(r?.monto ?? s.monto)),
            FilaDato('Comisión', dinero(r?.comision ?? s.producto.comision)),
            FilaDato('Total', dinero(r?.montoTotal ?? s.monto + s.producto.comision), destacado: true),
            if (_transaccionId != null) FilaDato('No. de operación', '$_transaccionId'),
            if (r?.folioProveedor != null) FilaDato('Folio GestoPago', r!.folioProveedor!),
            if (r?.autorizacion != null) FilaDato('Autorización', r!.autorizacion!),
            if (r?.resueltoEn != null) FilaDato('Fecha', fechaHora(r!.resueltoEn)),
          ]),
        ),
      ),
      if (r?.pin != null) ...[
        const SizedBox(height: 12),
        Aviso('PIN: ${r!.pin}${r.instrucciones == null ? '' : '\n${r.instrucciones}'}', tipo: TipoAviso.info),
      ],
      const SizedBox(height: 24),
      if (_fase == _Fase.pendiente)
        FilledButton.icon(
          onPressed: _consultarEstado,
          icon: const Icon(Icons.refresh),
          label: const Text('Consultar estado'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      if (_fase == _Fase.errorComunicacion)
        FilledButton.icon(
          onPressed: _enviar,
          icon: const Icon(Icons.replay),
          label: const Text('Reintentar'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () => Navigator.of(context).popUntil((ruta) => ruta.isFirst),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        child: Text(_fase == _Fase.exitosa ? 'Seguir comprando' : 'Volver al catálogo'),
      ),
    ]);
  }
}
