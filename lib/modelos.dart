/// Modelos que llegan del backend. Los montos vienen como texto ("100.00")
/// para no perder precisión; se convierten a número solo para mostrarlos.
double _num(dynamic valor) => valor == null ? 0 : double.tryParse(valor.toString()) ?? 0;

double? _numONulo(dynamic valor) => valor == null ? null : double.tryParse(valor.toString());

DateTime? _fecha(dynamic valor) =>
    valor == null ? null : DateTime.tryParse(valor.toString())?.toLocal();

class Servicio {
  Servicio({required this.idServicio, required this.nombre, this.categoria});

  factory Servicio.fromJson(Map<String, dynamic> j) => Servicio(
        idServicio: j['idServicio'].toString(),
        nombre: (j['nombre'] ?? '').toString(),
        categoria: j['categoria']?.toString(),
      );

  final String idServicio;
  final String nombre;
  final String? categoria;
}

class Producto {
  Producto({
    required this.idServicio,
    required this.idProducto,
    required this.nombre,
    required this.modalidad,
    required this.tipoMonto,
    this.montoFijo,
    this.montoMinimo,
    this.montoMaximo,
    this.multiplo,
    required this.comision,
    this.longitudReferencia,
    this.leyenda,
    required this.disponibleCompra,
  });

  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
        idServicio: j['idServicio'].toString(),
        idProducto: j['idProducto'].toString(),
        nombre: (j['nombre'] ?? '').toString(),
        modalidad: (j['modalidad'] ?? '').toString(),
        tipoMonto: (j['tipoMonto'] ?? '').toString(),
        montoFijo: _numONulo(j['montoFijo']),
        montoMinimo: _numONulo(j['montoMinimo']),
        montoMaximo: _numONulo(j['montoMaximo']),
        multiplo: _numONulo(j['multiplo']),
        comision: _num(j['comision']),
        longitudReferencia: (j['longitudReferencia'] as num?)?.toInt(),
        leyenda: j['leyenda']?.toString(),
        disponibleCompra: j['disponibleCompra'] != false,
      );

  final String idServicio;
  final String idProducto;
  final String nombre;
  final String modalidad;
  final String tipoMonto;
  final double? montoFijo;
  final double? montoMinimo;
  final double? montoMaximo;
  final double? multiplo;
  final double comision;
  final int? longitudReferencia;
  final String? leyenda;
  final bool disponibleCompra;

  bool get esRecarga => modalidad == 'RECARGA';
  bool get montoFijoEstablecido => tipoMonto == 'FIJO' && montoFijo != null;
}

class PrimerPaso {
  PrimerPaso({
    required this.desafio,
    required this.expiraEnSegundos,
    required this.requiereConfiguracion,
    this.secreto,
    this.otpauthUri,
  });

  factory PrimerPaso.fromJson(Map<String, dynamic> j) => PrimerPaso(
        desafio: j['desafio'].toString(),
        expiraEnSegundos: (j['expiraEnSegundos'] as num?)?.toInt() ?? 300,
        requiereConfiguracion: j['requiereConfiguracion'] == true,
        secreto: j['secreto']?.toString(),
        otpauthUri: j['otpauthUri']?.toString(),
      );

  final String desafio;
  final int expiraEnSegundos;
  final bool requiereConfiguracion;
  final String? secreto;
  final String? otpauthUri;
}

class SesionNueva {
  SesionNueva({required this.accessToken, required this.plataforma, this.expiraEn});

  factory SesionNueva.fromJson(Map<String, dynamic> j) => SesionNueva(
        accessToken: j['accessToken'].toString(),
        plataforma: (j['plataforma'] ?? '').toString(),
        expiraEn: _fecha(j['expiraEn']),
      );

  final String accessToken;
  final String plataforma;
  final DateTime? expiraEn;
}

class Cuenta {
  Cuenta({required this.numero, required this.saldo, required this.estado, required this.limiteDiario});

  factory Cuenta.fromJson(Map<String, dynamic> j) => Cuenta(
        numero: j['numero'].toString(),
        saldo: _num(j['saldo']),
        estado: (j['estado'] ?? '').toString(),
        limiteDiario: _num(j['limiteDiario']),
      );

  final String numero;
  final double saldo;
  final String estado;
  final double limiteDiario;
}

class InfoSesion {
  InfoSesion({required this.plataforma, this.iniciadaEn, this.expiraEn, required this.minutosInactividad});

  factory InfoSesion.fromJson(Map<String, dynamic> j) => InfoSesion(
        plataforma: (j['plataforma'] ?? '').toString(),
        iniciadaEn: _fecha(j['iniciadaEn']),
        expiraEn: _fecha(j['expiraEn']),
        minutosInactividad: (j['minutosInactividad'] as num?)?.toInt() ?? 30,
      );

  final String plataforma;
  final DateTime? iniciadaEn;
  final DateTime? expiraEn;
  final int minutosInactividad;

  String get plataformaTexto => plataforma == 'MOVIL' ? 'Aplicación móvil' : 'Aplicación web';
}

class Perfil {
  Perfil({
    required this.usuario,
    required this.nombre,
    required this.dosPasosActivo,
    required this.pagosHabilitados,
    this.sesion,
    required this.cuentas,
  });

  factory Perfil.fromJson(Map<String, dynamic> j) => Perfil(
        usuario: j['usuario'].toString(),
        nombre: (j['nombre'] ?? '').toString(),
        dosPasosActivo: j['dosPasosActivo'] == true,
        pagosHabilitados: j['pagosHabilitados'] == true,
        sesion: j['sesion'] is Map<String, dynamic> ? InfoSesion.fromJson(j['sesion']) : null,
        cuentas: ((j['cuentas'] as List?) ?? const [])
            .map((c) => Cuenta.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  final String usuario;
  final String nombre;
  final bool dosPasosActivo;
  final bool pagosHabilitados;
  final InfoSesion? sesion;
  final List<Cuenta> cuentas;

  Cuenta? get cuentaPrincipal => cuentas.isEmpty ? null : cuentas.first;
}

/// Resultado de POST /api/v1/pagos o GET /api/v1/pagos/{id}.
class ResultadoPago {
  ResultadoPago({
    required this.transaccionId,
    required this.estado,
    this.motivo,
    required this.monto,
    required this.comision,
    required this.montoTotal,
    this.folioProveedor,
    this.autorizacion,
    this.pin,
    this.instrucciones,
    this.creadoEn,
    this.resueltoEn,
    this.mensaje,
  });

  factory ResultadoPago.fromJson(Map<String, dynamic> j) => ResultadoPago(
        transaccionId: (j['transaccionId'] as num).toInt(),
        estado: (j['estado'] ?? '').toString(),
        motivo: j['motivo']?.toString(),
        monto: _num(j['monto']),
        comision: _num(j['comision']),
        montoTotal: _num(j['montoTotal']),
        folioProveedor: j['folioProveedor']?.toString(),
        autorizacion: j['autorizacion']?.toString(),
        pin: j['pin']?.toString(),
        instrucciones: j['instrucciones']?.toString(),
        creadoEn: _fecha(j['creadoEn']),
        resueltoEn: _fecha(j['resueltoEn']),
        mensaje: j['mensaje']?.toString(),
      );

  final int transaccionId;
  final String estado;
  final String? motivo;
  final double monto;
  final double comision;
  final double montoTotal;
  final String? folioProveedor;
  final String? autorizacion;
  final String? pin;
  final String? instrucciones;
  final DateTime? creadoEn;
  final DateTime? resueltoEn;
  final String? mensaje;

  /// Solo una compra CONFIRMADA por GestoPago es una compra realizada.
  bool get exitosa => estado == 'CONFIRMADA';
  bool get rechazada => estado == 'REVERSADA';
  bool get pendiente => !exitosa && !rechazada;
}

/// Una compra del historial (solo confirmadas).
class Compra {
  Compra({
    required this.transaccionId,
    this.fecha,
    required this.servicio,
    required this.producto,
    required this.referencia,
    required this.monto,
    required this.comision,
    required this.montoTotal,
    this.folioProveedor,
    this.autorizacion,
    this.pin,
    this.instrucciones,
  });

  factory Compra.fromJson(Map<String, dynamic> j) => Compra(
        transaccionId: (j['transaccionId'] as num).toInt(),
        fecha: _fecha(j['fecha']),
        servicio: (j['servicio'] ?? '').toString(),
        producto: (j['producto'] ?? '').toString(),
        referencia: (j['referencia'] ?? '').toString(),
        monto: _num(j['monto']),
        comision: _num(j['comision']),
        montoTotal: _num(j['montoTotal']),
        folioProveedor: j['folioProveedor']?.toString(),
        autorizacion: j['autorizacion']?.toString(),
        pin: j['pin']?.toString(),
        instrucciones: j['instrucciones']?.toString(),
      );

  final int transaccionId;
  final DateTime? fecha;
  final String servicio;
  final String producto;
  final String referencia;
  final double monto;
  final double comision;
  final double montoTotal;
  final String? folioProveedor;
  final String? autorizacion;
  final String? pin;
  final String? instrucciones;
}
