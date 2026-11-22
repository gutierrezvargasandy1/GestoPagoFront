import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/errores.dart';
import '../../../servicios/auth_service.dart';
import '../../tema.dart';
import '../../widgets/comunes.dart';
import 'diseno_acceso.dart';
import 'registro_pantalla.dart';
import 'verificacion_pantalla.dart';

class LoginPantalla extends StatefulWidget {
  const LoginPantalla({super.key, this.aviso});

  /// Motivo por el que se volvió aquí (sesión cerrada en otro dispositivo, etc.).
  final String? aviso;

  @override
  State<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends State<LoginPantalla> {
  final _formulario = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _password = TextEditingController();
  bool _cargando = false;
  bool _ocultar = true;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formulario.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final navegador = Navigator.of(context);
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final usuario = _usuario.text.trim();
      final paso = await auth.iniciar(usuario, _password.text);
      _password.clear();
      await navegador.push(MaterialPageRoute(
          builder: (_) => VerificacionPantalla(paso: paso, usuario: usuario)));
    } on ApiException catch (e) {
      setState(() => _error = e.mensaje);
    } on ComunicacionException catch (e) {
      setState(() => _error =
          '${e.mensaje} Si es el primer acceso del día, el servidor puede tardar hasta un minuto en despertar.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DisenoAcceso(
      child: Form(
        key: _formulario,
        child: AutofillGroup(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const EncabezadoAcceso(
                titulo: 'Inicia sesión', subtitulo: 'Usa la misma cuenta en la web y en la app móvil.'),
            if (widget.aviso != null) ...[Aviso(widget.aviso!, tipo: TipoAviso.info), const SizedBox(height: 16)],
            if (_error != null) ...[Aviso(_error!), const SizedBox(height: 16)],
            TextFormField(
              controller: _usuario,
              enabled: !_cargando,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: decoracionCampo(context, 'Usuario', icono: Icons.person_outline),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe tu usuario' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              enabled: !_cargando,
              obscureText: _ocultar,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _entrar(),
              decoration: decoracionCampo(context, 'Contraseña',
                  icono: Icons.lock_outline,
                  sufijo: IconButton(
                    tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
                    icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _ocultar = !_ocultar),
                  )),
              validator: (v) => (v == null || v.isEmpty) ? 'Escribe tu contraseña' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _cargando ? null : _entrar,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _cargando
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Continuar'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _cargando
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegistroPantalla())),
              child: const Text('¿No tienes cuenta? Crea una'),
            ),
          ]),
        ),
      ),
    );
  }
}
