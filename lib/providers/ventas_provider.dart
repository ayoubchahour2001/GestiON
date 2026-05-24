import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../services/firestore_service.dart';
import '../services/local_database.dart';

/// Gestiona el carrito del TPV y el historial de ventas.
///
/// Flujo de almacenamiento:
///   1. SQLite (local, inmediato) → la operacion regresa enseguida
///   2. Firestore (nube, en segundo plano) → sincronizacion async
///
/// Si Firestore falla, la venta queda marcada como pendiente en SQLite
/// y se puede reintentar mas adelante.
class VentasProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();
  final LocalDatabase _local = LocalDatabase.instancia;
  static const _uuid = Uuid();
  static const double tipoIva = 0.21;

  final List<LineaVenta> _carrito = [];
  List<Venta> _historial = [];

  List<LineaVenta> get carrito => _carrito;
  List<Venta> get historial => _historial;

  VentasProvider() {
    _iniciar();
  }

  Future<void> _iniciar() async {
    // 1. Cargar ventas locales de SQLite primero (sin esperar red)
    _historial = await _local.ventasLocales();
    notifyListeners();

    // 2. Escuchar Firestore para sincronizar
    _fs.streamVentas().listen((lista) {
      _historial = lista;
      notifyListeners();
      // Sincronizar ventas pendientes que no subieron antes
      _sincronizarPendientes();
    }, onError: (_) {
      // Sin conexion: mantenemos el historial local ya cargado
    });
  }

  /// Sube a Firestore las ventas que quedaron pendientes (sin conexion previa).
  Future<void> _sincronizarPendientes() async {
    try {
      final pendientes = await _local.ventasPendientes();
      for (final v in pendientes) {
        await _fs.registrarVenta(v);
        await _local.marcarSincronizada(v.id);
      }
    } catch (_) {
      // Reintentara en la proxima reconexion
    }
  }

  // ---------------- CARRITO (TPV) ----------------

  int get totalArticulos => _carrito.fold(0, (s, l) => s + l.cantidad);

  double get total => _carrito.fold(0.0, (s, l) => s + l.subtotal);

  double get baseImponible => total / (1 + tipoIva);

  double get iva => total - baseImponible;

  /// Anade un producto al carrito respetando el stock disponible.
  bool anadir(Producto p) {
    final existente = _carrito.where((l) => l.productoId == p.id);
    final enCarrito = existente.isEmpty ? 0 : existente.first.cantidad;
    if (enCarrito >= p.stock) return false;

    if (existente.isEmpty) {
      _carrito.add(LineaVenta(
        productoId: p.id,
        nombre: p.nombre,
        precio: p.precio,
      ));
    } else {
      existente.first.cantidad++;
    }
    notifyListeners();
    return true;
  }

  void cambiarCantidad(String productoId, int delta, int stockDisponible) {
    final linea = _carrito.firstWhere((l) => l.productoId == productoId);
    if (delta > 0 && linea.cantidad >= stockDisponible) return;
    linea.cantidad += delta;
    if (linea.cantidad <= 0) {
      _carrito.removeWhere((l) => l.productoId == productoId);
    }
    notifyListeners();
  }

  void vaciarCarrito() {
    _carrito.clear();
    notifyListeners();
  }

  // ---------------- REGISTRAR VENTA ----------------

  /// Guarda la venta y vacia el carrito.
  ///
  /// Paso 1 (sincrono): guarda en SQLite → regresa inmediatamente.
  /// Paso 2 (segundo plano): sube a Firestore sin bloquear la UI.
  Future<Venta> registrarVenta({
    required String metodoPago,
    String clienteId = '',
    String clienteNombre = 'Sin cliente',
  }) async {
    final venta = Venta(
      id: _uuid.v4(),
      fecha: DateTime.now(),
      lineas: List<LineaVenta>.from(
          _carrito.map((l) => LineaVenta.fromMap(l.toMap()))),
      total: total,
      metodoPago: metodoPago,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
    );

    // --- Paso 1: SQLite (local, rapido, sin red) ---
    await _local.guardarVentaLocal(venta, sincronizado: false);

    // Actualizamos el historial local inmediatamente
    _historial = [venta, ..._historial];
    vaciarCarrito(); // limpia carrito y notifica

    // --- Paso 2: Firestore (en segundo plano, no bloqueante) ---
    _subirAFirestore(venta);

    return venta;
  }

  /// Sube la venta a Firestore de forma asincrona sin bloquear la UI.
  void _subirAFirestore(Venta venta) {
    _fs.registrarVenta(venta).then((_) {
      _local.marcarSincronizada(venta.id);
    }).catchError((_) {
      // Queda marcada como pendiente en SQLite;
      // se reintentara cuando Firestore vuelva a estar disponible.
    });
  }

  // ---------------- ESTADISTICAS DASHBOARD ----------------

  List<Venta> get ventasHoy {
    final hoy = DateTime.now();
    return _historial
        .where((v) =>
            v.fecha.year == hoy.year &&
            v.fecha.month == hoy.month &&
            v.fecha.day == hoy.day)
        .toList();
  }

  double get totalVentasHoy =>
      ventasHoy.fold(0.0, (s, v) => s + v.total);
}
