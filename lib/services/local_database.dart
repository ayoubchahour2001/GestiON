import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/producto.dart';
import '../models/cliente.dart';
import '../models/venta.dart';

/// Base de datos local SQLite para soporte offline.
///
/// Almacena productos, clientes y ventas localmente.
/// Firestore se usa como sincronizacion en la nube; SQLite es la
/// fuente primaria de verdad en el dispositivo.
///
/// Estructura de tablas:
///   productos  — catalogo de productos
///   clientes   — lista de clientes
///   ventas     — historial de ventas (lineas serializadas como JSON)
class LocalDatabase {
  static final LocalDatabase instancia = LocalDatabase._();
  LocalDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (kIsWeb) throw UnsupportedError('SQLite not available on web');
    _db ??= await _abrir();
    return _db!;
  }

  Future<Database> _abrir() async {
    final ruta = join(await getDatabasesPath(), 'gestion.db');
    return openDatabase(
      ruta,
      version: 2,
      onCreate: (db, version) async {
        await _crearTablas(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migración v1 → v2: añadir tabla ventas
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ventas(
              id TEXT PRIMARY KEY,
              fecha INTEGER,
              lineas TEXT,
              total REAL,
              metodoPago TEXT,
              clienteId TEXT,
              clienteNombre TEXT,
              sincronizado INTEGER DEFAULT 0
            )
          ''');
        }
      },
    );
  }

  Future<void> _crearTablas(Database db) async {
    await db.execute('''
      CREATE TABLE productos(
        id TEXT PRIMARY KEY,
        nombre TEXT, descripcion TEXT, categoria TEXT, emoji TEXT,
        precio REAL, stock INTEGER, stockMinimo INTEGER, imagenURL TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE clientes(
        id TEXT PRIMARY KEY,
        nombre TEXT, telefono TEXT, email TEXT,
        puntos INTEGER, compras INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE ventas(
        id TEXT PRIMARY KEY,
        fecha INTEGER,
        lineas TEXT,
        total REAL,
        metodoPago TEXT,
        clienteId TEXT,
        clienteNombre TEXT,
        sincronizado INTEGER DEFAULT 0
      )
    ''');
  }

  // ---------------- PRODUCTOS ----------------

  Future<void> guardarProductoLocal(Producto p) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('productos', p.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Producto>> productosLocales() async {
    if (kIsWeb) return [];
    final db = await database;
    final filas = await db.query('productos', orderBy: 'nombre');
    return filas.map((f) => Producto.fromSqlite(f)).toList();
  }

  Future<void> eliminarProductoLocal(String id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> sincronizarProductos(List<Producto> remotos) async {
    if (kIsWeb) return;
    final db = await database;
    final batch = db.batch();
    batch.delete('productos');
    for (final p in remotos) {
      batch.insert('productos', p.toSqlite());
    }
    await batch.commit(noResult: true);
  }

  // ---------------- CLIENTES ----------------

  Future<void> guardarClienteLocal(Cliente c) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('clientes', c.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Cliente>> clientesLocales() async {
    if (kIsWeb) return [];
    final db = await database;
    final filas = await db.query('clientes', orderBy: 'nombre');
    return filas.map((f) => Cliente.fromSqlite(f)).toList();
  }

  // ---------------- VENTAS ----------------

  /// Guarda una venta en SQLite (inmediato, sin red).
  /// [sincronizado] = 0 → pendiente de subir a Firestore.
  Future<void> guardarVentaLocal(Venta v, {bool sincronizado = false}) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'ventas',
      {
        'id': v.id,
        'fecha': v.fecha.millisecondsSinceEpoch,
        'lineas': jsonEncode(v.lineas.map((l) => l.toMap()).toList()),
        'total': v.total,
        'metodoPago': v.metodoPago,
        'clienteId': v.clienteId,
        'clienteNombre': v.clienteNombre,
        'sincronizado': sincronizado ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Devuelve todas las ventas guardadas localmente, las más recientes primero.
  Future<List<Venta>> ventasLocales() async {
    if (kIsWeb) return [];
    final db = await database;
    final filas = await db.query('ventas', orderBy: 'fecha DESC');
    return filas.map((f) {
      final lineasJson = jsonDecode(f['lineas'] as String) as List;
      return Venta(
        id: f['id'] as String,
        fecha: DateTime.fromMillisecondsSinceEpoch(f['fecha'] as int),
        lineas: lineasJson
            .map((e) => LineaVenta.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        total: f['total'] as double,
        metodoPago: f['metodoPago'] as String,
        clienteId: f['clienteId'] as String? ?? '',
        clienteNombre: f['clienteNombre'] as String? ?? 'Sin cliente',
      );
    }).toList();
  }

  /// Ventas que aún no se han sincronizado con Firestore.
  Future<List<Venta>> ventasPendientes() async {
    if (kIsWeb) return [];
    final db = await database;
    final filas = await db.query('ventas',
        where: 'sincronizado = ?', whereArgs: [0], orderBy: 'fecha ASC');
    return filas.map((f) {
      final lineasJson = jsonDecode(f['lineas'] as String) as List;
      return Venta(
        id: f['id'] as String,
        fecha: DateTime.fromMillisecondsSinceEpoch(f['fecha'] as int),
        lineas: lineasJson
            .map((e) => LineaVenta.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        total: f['total'] as double,
        metodoPago: f['metodoPago'] as String,
        clienteId: f['clienteId'] as String? ?? '',
        clienteNombre: f['clienteNombre'] as String? ?? 'Sin cliente',
      );
    }).toList();
  }

  /// Marca una venta como ya sincronizada con Firestore.
  Future<void> marcarSincronizada(String id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'ventas',
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
