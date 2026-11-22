import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/errores.dart';
import '../../../servicios/auth_service.dart';
import '../../tema.dart';
import '../../widgets/comunes.dart';
import 'diseno_acceso.dart';

class RegistroPantalla extends StatefulWidget {
  const RegistroPantalla({super.key});

  @override
  State<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends State<RegistroPantalla> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _usuario = TextEditingController();
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _cargando = false;
  bool _ocultar = true;
  String? _error;

  @override
  void dispose() {
    for (final c in [_nombre, _usuario, _password, _confirmacion]) {
      c.dispose();
    }
    super.dispose();
  }

  // Mismas reglas que el backend (que vuelve a validar todo).
  String? _validarUsuario(String? v) {
    if (v == null || v.trim().isEmpty) return 'Escribe un usuario';
    if (!RegExp(r'^[a-z0-9._-]{4,50}$').hasMatch(v.trim())) {
      return 'De 4 a 50 caracteres: minúsculas, números, punto, guion o guion bajo';
    }
    return null;
  }

  String? _validarPassword(String? v) {
    if (v == null || v.length < 8 || v.length > 72) return 'Entre 8 y 72 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Incluye al menos una letra y un número';
    }
    return null;
  }

  Future<void> _registrar() async {
    if (!_formulario.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final cuenta = await auth.registrar(
          usuario: _usuario.text.trim(), password: _password.text, nombre: _nombre.text.trim());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (contexto) => AlertDialog(
          icon: const Icon(Icons.celebration_outlined),
          title: const Text('¡Cuenta creada!'),
          content: Text('Tu número de cuenta es ${enmascarar(cuenta)}.\n\n'
              'Al iniciar sesión por primera vez configurarás tu doble factor de autenticación.'),
          actions: [
            FilledButton(onPressed: () => Navigator.of(contexto).pop(), child: const Text('Iniciar sesión')),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.mensaje);
    } on ComunicacionException catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DisenoAcceso(
      conRegreso: true,
      child: Form(
        key: _formulario,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const EncabezadoAcceso(
              titulo: 'Crea tu cuenta', subtitulo: 'Te servirá para la web y para la app móvil.'),
          if (_error != null) ...[Aviso(_error!), const SizedBox(height: 16)],
          TextFormField(
            controller: _nombre,
            enabled: !_cargando,
            textCapitalization: TextCapitalization.words,
            decoration: decoracionCampo(context, 'Nombre completo', icono: Icons.badge_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe tu nombre' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usuario,
            enabled: !_cargando,
            decoration: decoracionCampo(context, 'Usuario',
                icono: Icons.person_outline, ayuda: 'Minúsculas y números, por ejemplo: andres.gtz'),
            validator: _validarUsuario,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            enabled: !_cargando,
            obscureText: _ocultar,
            decoration: decoracionCampo(context, 'Contraseña',
                icono: Icons.lock_outline,
                ayuda: 'Mínimo 8 caracteres, con letras y números',
                sufijo: IconButton(
                  tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _ocultar = !_ocultar),
                )),
            validator: _validarPassword,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmacion,
            enabled: !_cargando,
            obscureText: _ocultar,
            decoration: decoracionCampo(context, 'Confirma la contraseña', icono: Icons.lock_reset),
            validator: (v) => v != _password.text ? 'Las contraseñas no coinciden' : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _cargando ? null : _registrar,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _cargando
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Crear cuenta'),
          ),
        ]),
      ),
    );
  }
}
