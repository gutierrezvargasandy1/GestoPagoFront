import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../estado/sesion_controller.dart';
import 'comunes.dart';

/// Saldo disponible, siempre visible en la barra superior.
class ChipSaldo extends StatelessWidget {
  const ChipSaldo({super.key});

  @override
  Widget build(BuildContext context) {
    final cuenta = context.watch<SesionController>().perfil?.cuentaPrincipal;
    if (cuenta == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Chip(
        avatar: const Icon(Icons.account_balance_wallet_outlined, size: 18),
        label: Text('Saldo ${dinero(cuenta.saldo)}'),
      ),
    );
  }
}
