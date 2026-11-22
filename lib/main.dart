import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/almacen_token.dart';
import 'core/api_client.dart';
import 'estado/sesion_controller.dart';
import 'servicios/auth_service.dart';
import 'servicios/catalogo_service.dart';
import 'servicios/pagos_service.dart';
import 'ui/pantallas/acceso/login_pantalla.dart';
import 'ui/pantallas/inicio_pantalla.dart';
import 'ui/tema.dart';

final GlobalKey<NavigatorState> navegador = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  final tokens = AlmacenToken();
  final api = ApiClient(tokens: tokens);
  final auth = AuthService(api);
  final sesion = SesionController(auth, tokens);
  api.alTerminarSesion = sesion.sesionTerminada;
  // Al entrar o salir se cierran las pantallas abiertas encima del inicio.
  sesion.alCambiarSesion = () => navegador.currentState?.popUntil((ruta) => ruta.isFirst);

  runApp(MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: api),
      Provider<AuthService>.value(value: auth),
      Provider<CatalogoService>(create: (_) => CatalogoService(api)),
      Provider<PagosService>(create: (_) => PagosService(api)),
      ChangeNotifierProvider<SesionController>.value(value: sesion),
    ],
    child: const GestoPagoApp(),
  ));
  sesion.iniciar();
}

class GestoPagoApp extends StatelessWidget {
  const GestoPagoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navegador,
      title: 'GestoPago',
      debugShowCheckedModeBanner: false,
      theme: construirTema(Brightness.light),
      darkTheme: construirTema(Brightness.dark),
      home: const PuertaSesion(),
    );
  }
}

/// Decide qué ver según la sesión: inicio de sesión o la app.
class PuertaSesion extends StatelessWidget {
  const PuertaSesion({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionController>();
    return switch (sesion.estado) {
      EstadoSesion.cargando => const Scaffold(body: Center(child: CircularProgressIndicator())),
      EstadoSesion.anonima => LoginPantalla(aviso: sesion.aviso),
      EstadoSesion.autenticada => const InicioPantalla(),
    };
  }
}
