/// Modelo de datos: Producto
class Producto {
  final String id;
  String nombre;
  String descripcion;
  String categoria;
  String emoji;
  double precio;
  int stock;
  int stockMinimo;
  String imagenURL;

  Producto({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    this.categoria = '',
    this.emoji = '📦',
    required this.precio,
    required this.stock,
    required this.stockMinimo,
    this.imagenURL = '',
  });

  /// Estado del stock para mostrar alertas
  StockEstado get estado {
    if (stock == 0) return StockEstado.agotado;
    if (stock <= stockMinimo) return StockEstado.bajo;
    return StockEstado.disponible;
  }

  /// Conversion a mapa para Firebase Firestore
  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'categoria': categoria,
        'emoji': emoji,
        'precio': precio,
        'stock': stock,
        'stockMinimo': stockMinimo,
        'imagenURL': imagenURL,
      };

  /// Construccion desde un documento de Firestore
  factory Producto.fromMap(String id, Map<String, dynamic> map) => Producto(
        id: id,
        nombre: map['nombre'] ?? '',
        descripcion: map['descripcion'] ?? '',
        categoria: map['categoria'] ?? '',
        emoji: map['emoji'] ?? '📦',
        precio: (map['precio'] ?? 0).toDouble(),
        stock: (map['stock'] ?? 0).toInt(),
        stockMinimo: (map['stockMinimo'] ?? 0).toInt(),
        imagenURL: map['imagenURL'] ?? '',
      );

  /// Para SQLite local (offline)
  Map<String, dynamic> toSqlite() => {'id': id, ...toMap()};

  factory Producto.fromSqlite(Map<String, dynamic> row) =>
      Producto.fromMap(row['id'], row);
}

enum StockEstado { disponible, bajo, agotado }
