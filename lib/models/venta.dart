/// Linea de una venta (un producto + cantidad)
class LineaVenta {
  final String productoId;
  final String nombre;
  final double precio;
  int cantidad;

  LineaVenta({
    required this.productoId,
    required this.nombre,
    required this.precio,
    this.cantidad = 1,
  });

  double get subtotal => precio * cantidad;

  Map<String, dynamic> toMap() => {
        'productoId': productoId,
        'nombre': nombre,
        'precio': precio,
        'cantidad': cantidad,
      };

  factory LineaVenta.fromMap(Map<String, dynamic> map) => LineaVenta(
        productoId: map['productoId'] ?? '',
        nombre: map['nombre'] ?? '',
        precio: (map['precio'] ?? 0).toDouble(),
        cantidad: (map['cantidad'] ?? 1).toInt(),
      );
}

/// Modelo de datos: Venta
class Venta {
  final String id;
  final DateTime fecha;
  final List<LineaVenta> lineas;
  final double total;
  final String metodoPago;
  final String clienteId;
  final String clienteNombre;

  Venta({
    required this.id,
    required this.fecha,
    required this.lineas,
    required this.total,
    required this.metodoPago,
    this.clienteId = '',
    this.clienteNombre = 'Sin cliente',
  });

  int get totalArticulos => lineas.fold(0, (s, l) => s + l.cantidad);

  Map<String, dynamic> toMap() => {
        'fecha': fecha.millisecondsSinceEpoch,
        'lineas': lineas.map((l) => l.toMap()).toList(),
        'total': total,
        'metodoPago': metodoPago,
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
      };

  factory Venta.fromMap(String id, Map<String, dynamic> map) => Venta(
        id: id,
        fecha: DateTime.fromMillisecondsSinceEpoch(map['fecha'] ?? 0),
        lineas: (map['lineas'] as List? ?? [])
            .map((e) => LineaVenta.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        total: (map['total'] ?? 0).toDouble(),
        metodoPago: map['metodoPago'] ?? 'Efectivo',
        clienteId: map['clienteId'] ?? '',
        clienteNombre: map['clienteNombre'] ?? 'Sin cliente',
      );
}
