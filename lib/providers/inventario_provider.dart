import 'package:flutter/foundation.dart';
import '../models/producto.dart';
import '../services/firestore_service.dart';
import '../services/local_database.dart';

/// Gestiona el estado del inventario de productos.
///
/// Escucha Firestore en tiempo real y replica los datos en SQLite
/// para disponer de ellos sin conexion.
class InventarioProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();
  final LocalDatabase _local = LocalDatabase.instancia;

  List<Producto> _productos = [];
  bool _cargando = true;

  List<Producto> get productos => _productos;
  bool get cargando => _cargando;

  /// Productos cuyo stock esta por debajo o igual al minimo.
  List<Producto> get productosBajoStock =>
      _productos.where((p) => p.stock <= p.stockMinimo).toList();

  /// Valor total del inventario (precio x stock).
  double get valorInventario =>
      _productos.fold(0.0, (s, p) => s + p.precio * p.stock);

  InventarioProvider() {
    _iniciar();
  }

  Future<void> _iniciar() async {
    // 1. Cargar SQLite de inmediato — sin esperar red.
    //    Esto garantiza que _cargando = false siempre, incluso sin internet.
    _productos = await _local.productosLocales();
    _cargando = false;
    notifyListeners();

    // 2. Escuchar Firestore. Cuando responda, actualiza la lista
    //    y sincroniza SQLite. Si nunca responde, ya tenemos los datos locales.
    _fs.streamProductos().listen((lista) {
      _productos = lista;
      _local.sincronizarProductos(lista);
      notifyListeners();
    }, onError: (_) {
      // Firestore fallo: ya mostramos datos de SQLite, no hacer nada.
    });
  }

  /// Busqueda filtrada por nombre o categoria.
  List<Producto> buscar(String query) {
    if (query.trim().isEmpty) return _productos;
    final q = query.toLowerCase();
    return _productos
        .where((p) =>
            p.nombre.toLowerCase().contains(q) ||
            p.categoria.toLowerCase().contains(q))
        .toList();
  }

  Future<void> guardar(Producto p) => _fs.guardarProducto(p);

  Future<void> eliminar(String id) => _fs.eliminarProducto(id);

  /// Descuenta stock tras una venta.
  /// Actualiza el estado local inmediatamente y sincroniza con
  /// Firestore en segundo plano sin bloquear la UI.
  Future<void> descontarStock(String id, int cantidad) async {
    final idx = _productos.indexWhere((x) => x.id == id);
    if (idx == -1) return;
    final p = _productos[idx];
    final nuevo = (p.stock - cantidad).clamp(0, 999999);

    // Actualizar localmente de inmediato para reflejar el stock real.
    p.stock = nuevo;
    notifyListeners();

    // Sincronizar con Firestore en segundo plano.
    _fs.actualizarStock(id, nuevo).catchError((_) {});
  }
}
