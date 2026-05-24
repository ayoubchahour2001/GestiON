/// Modelo de datos: Cliente
class Cliente {
  final String id;
  String nombre;
  String telefono;
  String email;
  int puntos;
  int compras;

  Cliente({
    required this.id,
    required this.nombre,
    this.telefono = '',
    this.email = '',
    this.puntos = 0,
    this.compras = 0,
  });

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'telefono': telefono,
        'email': email,
        'puntos': puntos,
        'compras': compras,
      };

  factory Cliente.fromMap(String id, Map<String, dynamic> map) => Cliente(
        id: id,
        nombre: map['nombre'] ?? '',
        telefono: map['telefono'] ?? '',
        email: map['email'] ?? '',
        puntos: (map['puntos'] ?? 0).toInt(),
        compras: (map['compras'] ?? 0).toInt(),
      );

  Map<String, dynamic> toSqlite() => {'id': id, ...toMap()};

  factory Cliente.fromSqlite(Map<String, dynamic> row) =>
      Cliente.fromMap(row['id'], row);
}
