import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/producto.dart';
import '../models/cliente.dart';
import '../models/venta.dart';

/// Servicio de acceso a Firebase Firestore.
///
/// Cada negocio (usuario autenticado) guarda sus datos bajo
/// `usuarios/{uid}/...` para que la informacion quede aislada por cuenta.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'demo';

  CollectionReference<Map<String, dynamic>> get _productos =>
      _db.collection('usuarios').doc(_uid).collection('productos');

  CollectionReference<Map<String, dynamic>> get _clientes =>
      _db.collection('usuarios').doc(_uid).collection('clientes');

  CollectionReference<Map<String, dynamic>> get _ventas =>
      _db.collection('usuarios').doc(_uid).collection('ventas');

  // ---------------- PRODUCTOS ----------------

  /// Stream en tiempo real de productos (Firestore mantiene cache offline).
  Stream<List<Producto>> streamProductos() {
    return _productos.orderBy('nombre').snapshots().map(
          (snap) => snap.docs
              .map((d) => Producto.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> guardarProducto(Producto p) async {
    if (p.id.isEmpty) {
      await _productos.add(p.toMap());
    } else {
      await _productos.doc(p.id).set(p.toMap());
    }
  }

  Future<void> eliminarProducto(String id) => _productos.doc(id).delete();

  Future<void> actualizarStock(String id, int nuevoStock) =>
      _productos.doc(id).update({'stock': nuevoStock});

  // ---------------- CLIENTES ----------------

  Stream<List<Cliente>> streamClientes() {
    return _clientes.orderBy('nombre').snapshots().map(
          (snap) =>
              snap.docs.map((d) => Cliente.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> guardarCliente(Cliente c) async {
    if (c.id.isEmpty) {
      await _clientes.add(c.toMap());
    } else {
      await _clientes.doc(c.id).set(c.toMap());
    }
  }

  Future<void> eliminarCliente(String id) => _clientes.doc(id).delete();

  Future<void> sumarPuntos(String id, int puntos, int compras) =>
      _clientes.doc(id).update({'puntos': puntos, 'compras': compras});

  // ---------------- VENTAS ----------------

  Stream<List<Venta>> streamVentas() {
    return _ventas.orderBy('fecha', descending: true).snapshots().map(
          (snap) =>
              snap.docs.map((d) => Venta.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> registrarVenta(Venta v) => _ventas.add(v.toMap());
}
