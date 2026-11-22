import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../estado/sesion_controller.dart';
import '../../widgets/comunes.dart';

class CuentaPantalla extends StatelessWidget {
  const CuentaPantalla({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    final sesion = context.read<SesionController>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        icon: const Icon(Icons.logout),
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Podrás entrar de nuevo desde la web o desde la app móvil.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(contexto).pop(true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirmar == true) await sesion.cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sesion = context.watch<SesionController>();
    final perfil = sesion.perfil;
    if (perfil == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final cuenta = perfil.cuentaPrincipal;
    final info = perfil.sesion;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: RefreshIndicator(
        onRefresh: sesion.recargarPerfil,
        child: Centrado(
          anchoMaximo: 640,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: tema.colorScheme.primaryContainer,
                child: Text(perfil.nombre.isEmpty ? '?' : perfil.nombre.characters.first.toUpperCase(),
                    style: tema.textTheme.headlineSmall?.copyWith(color: tema.colorScheme.onPrimaryContainer)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(perfil.nombre, style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text('@${perfil.usuario}', style: tema.textTheme.bodyMedium),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            if (cuenta != null)
              Card(
                elevation: 0,
                color: tema.colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Saldo disponible', style: TextStyle(color: tema.colorScheme.onPrimary.withValues(alpha: 0.8))),
                    const SizedBox(height: 4),
                    Text(dinero(cuenta.saldo),
                        style: tema.textTheme.headlineMedium
                            ?.copyWith(color: tema.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('Cuenta ${enmascarar(cuenta.numero)} · ${cuenta.estado}',
                        style: TextStyle(color: tema.colorScheme.onPrimary)),
                    Text('Límite diario: ${dinero(cuenta.limiteDiario)}',
                        style: TextStyle(color: tema.colorScheme.onPrimary.withValues(alpha: 0.8))),
                  ]),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: tema.colorScheme.surfaceContainerLow,
              child: Column(children: [
                ListTile(
                  leading: Icon(perfil.dosPasosActivo ? Icons.verified_user : Icons.gpp_maybe_outlined,
                      color: perfil.dosPasosActivo ? const Color(0xFF2E7D32) : tema.colorScheme.error),
                  title: const Text('Doble factor de autenticación'),
                  subtitle: Text(perfil.dosPasosActivo ? 'Activo con app autenticadora' : 'Pendiente'),
                ),
                if (info != null) ...[
                  ListTile(
                    leading: Icon(info.plataforma == 'MOVIL' ? Icons.smartphone : Icons.computer),
                    title: Text('Sesión activa en: ${info.plataformaTexto}'),
                    subtitle: Text('Iniciada: ${fechaHora(info.iniciadaEn)}\nExpira: ${fechaHora(info.expiraEn)}'),
                    isThreeLine: true,
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Cierre automático'),
                    subtitle: Text('Tras ${info.minutosInactividad} minutos sin actividad. '
                        'Solo puedes tener una sesión abierta: web o móvil.'),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _cerrarSesion(context),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: tema.colorScheme.error,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
