import 'package:flutter/foundation.dart';
import '../models/cliente.dart';
import '../services/firestore_service.dart';
import '../services/local_database.dart';

/// Gestiona el estado de la lista de clientes.
class ClientesProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();
  final LocalDatabase _local = LocalDatabase.instancia;

  List<Cliente> _clientes = [];
  bool _cargando = true;

  List<Cliente> get clientes => _clientes;
  bool get cargando => _cargando;

  ClientesProvider() {
    _iniciar();
  }

  Future<void> _iniciar() async {
    // 1. SQLite primero — sin esperar red
    _clientes = await _local.clientesLocales();
    _cargando = false;
    notifyListeners();

    // 2. Firestore en tiempo real — actualiza cuando responda
    _fs.streamClientes().listen((lista) {
      _clientes = lista;
      // Sincronizar SQLite con los datos de Firestore
      for (final c in lista) {
        _local.guardarClienteLocal(c);
      }
      notifyListeners();
    }, onError: (_) {
      // Firestore fallo: ya mostramos datos de SQLite
    });
  }

  List<Cliente> buscar(String query) {
    if (query.trim().isEmpty) return _clientes;
    final q = query.toLowerCase();
    return _clientes
        .where((c) =>
            c.nombre.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q))
        .toList();
  }

  Future<void> guardar(Cliente c) => _fs.guardarCliente(c);

  Future<void> eliminar(String id) => _fs.eliminarCliente(id);

  /// Suma puntos de fidelizacion e incrementa el contador de compras.
  Future<void> registrarCompra(String clienteId, double importe) async {
    final c = _clientes.firstWhere((x) => x.id == clienteId);
    await _fs.sumarPuntos(
        clienteId, c.puntos + importe.floor(), c.compras + 1);
  }
}
