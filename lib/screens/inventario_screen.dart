import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/theme.dart';
import '../models/producto.dart';
import '../providers/inventario_provider.dart';
import '../widgets/common_widgets.dart';

/// Pantalla 2: Inventario. Lista, busqueda y gestion (CRUD) de productos.
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventarioProvider>();
    final lista = inv.buscar(_query);

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar producto...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textFaint),
                ),
              ),
            ),
            Expanded(
              child: inv.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : lista.isEmpty
                      ? const EmptyState(
                          mensaje: 'No se encontraron productos')
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          itemCount: lista.length,
                          itemBuilder: (_, i) =>
                              _ProductoTile(producto: lista[i]),
                        ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            backgroundColor: AppColors.accent,
            onPressed: () => _abrirFormulario(context),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo producto'),
          ),
        ),
      ],
    );
  }

  void _abrirFormulario(BuildContext context, [Producto? producto]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioProducto(producto: producto),
    );
  }
}

/// Fila de la tabla de inventario.
class _ProductoTile extends StatelessWidget {
  final Producto producto;
  const _ProductoTile({required this.producto});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Text(producto.emoji, style: const TextStyle(fontSize: 26)),
        title: Text(producto.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${producto.categoria}  ·  ${formatEuro(producto.precio)}  ·  '
          'Stock: ${producto.stock}/${producto.stockMinimo}',
          style: const TextStyle(fontSize: 12, color: AppColors.textDim),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StockTag(producto.estado),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textFaint),
              color: AppColors.panel2,
              onSelected: (op) {
                final inv = context.read<InventarioProvider>();
                if (op == 'editar') {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) =>
                        _FormularioProducto(producto: producto),
                  );
                } else if (op == 'eliminar') {
                  _confirmarBorrado(context, inv);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarBorrado(BuildContext context, InventarioProvider inv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que quieres eliminar "${producto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              inv.eliminar(producto.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

/// Formulario de alta / edicion de producto.
class _FormularioProducto extends StatefulWidget {
  final Producto? producto;
  const _FormularioProducto({this.producto});

  @override
  State<_FormularioProducto> createState() => _FormularioProductoState();
}

class _FormularioProductoState extends State<_FormularioProducto> {
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _categoria;
  late final TextEditingController _emoji;
  late final TextEditingController _precio;
  late final TextEditingController _stock;
  late final TextEditingController _min;
  late final TextEditingController _imagenURL;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _descripcion = TextEditingController(text: p?.descripcion ?? '');
    _categoria = TextEditingController(text: p?.categoria ?? '');
    _emoji = TextEditingController(text: p?.emoji ?? '📦');
    _precio = TextEditingController(text: p?.precio.toString() ?? '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '');
    _min = TextEditingController(text: p?.stockMinimo.toString() ?? '');
    _imagenURL = TextEditingController(text: p?.imagenURL ?? '');
  }

  void _guardar() {
    final nombre = _nombre.text.trim();
    final precio = double.tryParse(_precio.text.replaceAll(',', '.'));
    final stock = int.tryParse(_stock.text);
    final min = int.tryParse(_min.text);

    if (nombre.isEmpty || precio == null || stock == null || min == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rellena todos los campos')),
      );
      return;
    }

    final producto = Producto(
      id: widget.producto?.id ?? const Uuid().v4(),
      nombre: nombre,
      descripcion: _descripcion.text.trim(),
      categoria: _categoria.text.trim(),
      emoji: _emoji.text.trim().isEmpty ? '📦' : _emoji.text.trim(),
      precio: precio,
      stock: stock,
      stockMinimo: min,
      imagenURL: _imagenURL.text.trim(),
    );

    context.read<InventarioProvider>().guardar(producto);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.producto != null;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(esEdicion ? 'Editar producto' : 'Nuevo producto',
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcion,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Ej: Botella 1.5L, agua mineral...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _categoria,
                    decoration:
                        const InputDecoration(labelText: 'Categoría'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _emoji,
                    decoration: const InputDecoration(labelText: 'Emoji'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _precio,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Precio (€)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _min,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock mínimo (alerta)',
                hintText: 'Ej: 5',
                prefixIcon: Icon(Icons.warning_amber_outlined, size: 18,
                    color: AppColors.amber),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imagenURL,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL de imagen (opcional)',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.image_outlined, size: 18,
                    color: AppColors.textFaint),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _guardar,
                    child: Text(esEdicion ? 'Guardar' : 'Crear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
