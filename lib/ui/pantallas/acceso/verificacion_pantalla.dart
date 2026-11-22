import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errores.dart';
import '../../../estado/sesion_controller.dart';
import '../../../modelos.dart';
import '../../../servicios/auth_service.dart';
import '../../tema.dart';
import '../../widgets/comunes.dart';
import 'diseno_acceso.dart';

/// Segundo factor: código de 6 dígitos de la app autenticadora. El servidor lo
/// valida; la app solo lo envía. La primera vez se muestra el QR para registrarla.
class VerificacionPantalla extends StatefulWidget {
  const VerificacionPantalla({super.key, required this.paso, required this.usuario});

  final PrimerPaso paso;
  final String usuario;

  @override
  State<VerificacionPantalla> createState() => _VerificacionPantallaState();
}

class _VerificacionPantallaState extends State<VerificacionPantalla> {
  final _codigo = TextEditingController();
  bool _cargando = false;
  bool _desafioVencido = false;
  String? _error;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _verificar({bool forzar = false}) async {
    final codigo = _codigo.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(codigo)) {
      setState(() => _error = 'Escribe los 6 dígitos que muestra tu app.');
      return;
    }
    final auth = context.read<AuthService>();
    final sesion = context.read<SesionController>();
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final nueva = await auth.verificar(widget.paso.desafio, codigo, forzar: forzar);
      await sesion.completarLogin(nueva); // la app cambia sola a la pantalla principal
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.codigo == 'SESION_ACTIVA' && !forzar) {
        setState(() => _cargando = false);
        final cerrarOtra = await _confirmarCierre(e.mensaje);
        if (cerrarOtra == true) await _verificar(forzar: true);
        return;
      }
      setState(() {
        _error = e.mensaje;
        _desafioVencido = e.codigo == 'DESAFIO_INVALIDO';
        _codigo.clear();
      });
    } on ComunicacionException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<bool?> _confirmarCierre(String detalle) => showDialog<bool>(
        context: context,
        builder: (contexto) => AlertDialog(
          icon: const Icon(Icons.devices_other_outlined),
          title: const Text('Ya tienes una sesión abierta'),
          content: Text('$detalle\n\nSi continúas, esa sesión se cerrará de inmediato y '
              'tendrás que volver a entrar si quieres usarla.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.of(contexto).pop(true),
                child: const Text('Cerrar la otra sesión y entrar')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final paso = widget.paso;
    return DisenoAcceso(
      conRegreso: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        EncabezadoAcceso(
          titulo: paso.requiereConfiguracion ? 'Activa tu doble factor' : 'Verificación en dos pasos',
          subtitulo: paso.requiereConfiguracion
              ? 'Protege tu cuenta con un código que cambia cada 30 segundos.'
              : 'Escribe el código de 6 dígitos de tu app autenticadora.',
        ),
        if (paso.requiereConfiguracion) ...[
          _Configuracion(paso: paso, usuario: widget.usuario),
          const SizedBox(height: 24),
        ],
        if (_error != null) ...[Aviso(_error!), const SizedBox(height: 16)],
        TextField(
          controller: _codigo,
          enabled: !_cargando && !_desafioVencido,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 12),
          decoration: decoracionCampo(context, 'Código de verificación', icono: Icons.pin_outlined)
              .copyWith(counterText: ''),
          onChanged: (v) {
            if (v.length == 6 && !_cargando) _verificar();
          },
          onSubmitted: (_) => _verificar(),
        ),
        const SizedBox(height: 24),
        if (_desafioVencido)
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Volver a iniciar sesión'),
          )
        else
          FilledButton(
            onPressed: _cargando ? null : () => _verificar(),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _cargando
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Verificar y entrar'),
          ),
      ]),
    );
  }
}

class _Configuracion extends StatelessWidget {
  const _Configuracion({required this.paso, required this.usuario});

  final PrimerPaso paso;
  final String usuario;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final uri = paso.otpauthUri ?? '';
    final secreto = paso.secreto ?? '';
    return Card(
      elevation: 0,
      color: tema.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _PasoNumerado(1, 'Instala Google Authenticator, Microsoft Authenticator o Authy en tu celular.'),
          const _PasoNumerado(2, 'En la app toca “Agregar” y escanea este código QR:'),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: QrImageView(
                data: uri,
                size: 200,
                backgroundColor: Colors.white,
                semanticsLabel: 'Código QR para registrar la cuenta $usuario en la app autenticadora',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('¿No puedes escanear? Escribe esta clave en la app:', style: tema.textTheme.bodySmall),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: SelectableText(secreto,
                  style: tema.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace', letterSpacing: 1.5)),
            ),
            IconButton(
              tooltip: 'Copiar clave',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: secreto));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Clave copiada')));
              },
            ),
          ]),
          if (!kIsWeb && uri.isNotEmpty)
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir en mi app autenticadora'),
            ),
          const SizedBox(height: 8),
          const _PasoNumerado(3, 'Escribe abajo el código de 6 dígitos que aparece en la app.'),
        ]),
      ),
    );
  }
}

class _PasoNumerado extends StatelessWidget {
  const _PasoNumerado(this.numero, this.texto);

  final int numero;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: esquema.primary,
          child: Text('$numero', style: TextStyle(color: esquema.onPrimary, fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(texto)),
      ]),
    );
  }
}
