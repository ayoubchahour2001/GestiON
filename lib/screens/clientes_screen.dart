import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/theme.dart';
import '../models/cliente.dart';
import '../providers/clientes_provider.dart';
import '../widgets/common_widgets.dart';

/// Pantalla 4: Clientes. Ficha de cliente, historial y fidelizacion.
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ClientesProvider>();
    final lista = prov.buscar(_query);

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar cliente...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textFaint),
                ),
              ),
            ),
            Expanded(
              child: prov.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : lista.isEmpty
                      ? const EmptyState(
                          icono: Icons.people_outline,
                          mensaje: 'No hay clientes registrados')
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          itemCount: lista.length,
                          itemBuilder: (_, i) =>
                              _ClienteTile(cliente: lista[i]),
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
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo cliente'),
          ),
        ),
      ],
    );
  }

  void _abrirFormulario(BuildContext context, [Cliente? cliente]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioCliente(cliente: cliente),
    );
  }
}

class _ClienteTile extends StatelessWidget {
  final Cliente cliente;
  const _ClienteTile({required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.accent,
          child: Text(
            cliente.nombre.isNotEmpty
                ? cliente.nombre[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(cliente.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${cliente.telefono.isEmpty ? 'Sin telefono' : cliente.telefono}'
          '  ·  ${cliente.compras} compras',
          style: const TextStyle(fontSize: 12, color: AppColors.textDim),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('★ ${cliente.puntos} pts',
                  style: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textFaint),
              color: AppColors.panel2,
              onSelected: (op) {
                final prov = context.read<ClientesProvider>();
                if (op == 'editar') {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _FormularioCliente(cliente: cliente),
                  );
                } else if (op == 'eliminar') {
                  prov.eliminar(cliente.id);
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
}

class _FormularioCliente extends StatefulWidget {
  final Cliente? cliente;
  const _FormularioCliente({this.cliente});

  @override
  State<_FormularioCliente> createState() => _FormularioClienteState();
}

class _FormularioClienteState extends State<_FormularioCliente> {
  late final TextEditingController _nombre;
  late final TextEditingController _telefono;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nombre = TextEditingController(text: c?.nombre ?? '');
    _telefono = TextEditingController(text: c?.telefono ?? '');
    _email = TextEditingController(text: c?.email ?? '');
  }

  void _guardar() {
    if (_nombre.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio')),
      );
      return;
    }
    final cliente = Cliente(
      id: widget.cliente?.id ?? const Uuid().v4(),
      nombre: _nombre.text.trim(),
      telefono: _telefono.text.trim(),
      email: _email.text.trim(),
      puntos: widget.cliente?.puntos ?? 0,
      compras: widget.cliente?.compras ?? 0,
    );
    context.read<ClientesProvider>().guardar(cliente);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.cliente != null;
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
            Text(esEdicion ? 'Editar cliente' : 'Nuevo cliente',
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            TextField(
              controller: _nombre,
              decoration:
                  const InputDecoration(labelText: 'Nombre completo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefono'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
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
