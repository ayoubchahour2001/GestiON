import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/venta.dart';
import '../providers/inventario_provider.dart';
import '../providers/ventas_provider.dart';
import '../providers/clientes_provider.dart';
import '../widgets/common_widgets.dart';

/// Pantalla 3: TPV. Catalogo visual tactil para registrar ventas.
class TpvScreen extends StatefulWidget {
  const TpvScreen({super.key});

  @override
  State<TpvScreen> createState() => _TpvScreenState();
}

class _TpvScreenState extends State<TpvScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventarioProvider>();
    final ventas = context.watch<VentasProvider>();
    final productos = inv.buscar(_query);

    return Column(
      children: [
        // ---- Catalogo ----
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Buscar en el catalogo...',
              prefixIcon: Icon(Icons.search, color: AppColors.textFaint),
            ),
          ),
        ),
        Expanded(
          child: productos.isEmpty
              ? const EmptyState(mensaje: 'Sin productos en el catalogo')
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: productos.length,
                  itemBuilder: (_, i) {
                    final p = productos[i];
                    final agotado = p.stock == 0;
                    return InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: agotado
                          ? null
                          : () {
                              final ok = ventas.anadir(p);
                              if (!ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'No hay mas stock disponible')),
                                );
                              }
                            },
                      child: Opacity(
                        opacity: agotado ? 0.4 : 1,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.panel,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.emoji,
                                  style: const TextStyle(fontSize: 26)),
                              const Spacer(),
                              Text(p.nombre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(formatEuro(p.precio),
                                      style: const TextStyle(
                                          color: AppColors.accentBright,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                  Text('${p.stock} ud.',
                                      style: const TextStyle(
                                          color: AppColors.textFaint,
                                          fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        // ---- Resumen del ticket ----
        _BarraTicket(ventas: ventas, inv: inv),
      ],
    );
  }
}

/// Barra inferior con el resumen del ticket y acceso al cobro.
class _BarraTicket extends StatelessWidget {
  final VentasProvider ventas;
  final InventarioProvider inv;
  const _BarraTicket({required this.ventas, required this.inv});

  @override
  Widget build(BuildContext context) {
    final vacio = ventas.carrito.isEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.bgSoft,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${ventas.totalArticulos} articulos',
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 12)),
              Text(formatEuro(ventas.total),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: vacio
                ? null
                : () => _abrirTicket(context),
            icon: const Icon(Icons.shopping_cart_checkout),
            label: const Text('Ver ticket'),
          ),
        ],
      ),
    );
  }

  void _abrirTicket(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HojaTicket(inv: inv, screenContext: context),
    );
  }
}

/// Hoja deslizable con el detalle del ticket y el cobro.
class _HojaTicket extends StatelessWidget {
  final InventarioProvider inv;
  final BuildContext screenContext;
  const _HojaTicket({required this.inv, required this.screenContext});

  @override
  Widget build(BuildContext context) {
    final ventas = context.watch<VentasProvider>();
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ticket actual',
              style:
                  TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: ventas.carrito.map((l) {
                final p = inv.productos
                    .firstWhere((x) => x.id == l.productoId);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text('${formatEuro(l.precio)} / ud.',
                                style: const TextStyle(
                                    color: AppColors.textFaint,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      _BotonCantidad(
                        icono: Icons.remove,
                        onTap: () => ventas.cambiarCantidad(
                            l.productoId, -1, p.stock),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('${l.cantidad}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                      ),
                      _BotonCantidad(
                        icono: Icons.add,
                        onTap: () => ventas.cambiarCantidad(
                            l.productoId, 1, p.stock),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(formatEuro(l.subtotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(color: AppColors.line, height: 24),
          _FilaTotal('Base imponible', ventas.baseImponible),
          _FilaTotal('IVA (21%)', ventas.iva),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              Text(formatEuro(ventas.total),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _abrirCobro(context),
              child: Text('Cobrar ${formatEuro(ventas.total)}'),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirCobro(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: screenContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HojaCobro(inv: inv),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  const _BotonCantidad({required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.panel2,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icono, size: 15, color: AppColors.text),
      ),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  final String label;
  final double valor;
  const _FilaTotal(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textDim, fontSize: 13)),
          Text(formatEuro(valor),
              style: const TextStyle(
                  color: AppColors.textDim, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Hoja final de cobro: formulario de pago → recibo de confirmacion.
/// El mismo modal transforma su contenido para evitar cadenas de contextos.
class _HojaCobro extends StatefulWidget {
  final InventarioProvider inv;
  const _HojaCobro({required this.inv});

  @override
  State<_HojaCobro> createState() => _HojaCobroState();
}

class _HojaCobroState extends State<_HojaCobro> {
  String _metodo = 'Efectivo';
  String? _clienteId;
  bool _cargando = false;
  Venta? _ventaCompletada;
  List<String> _alertasStock = [];

  // Datos del comprador (cuando no hay cliente registrado seleccionado)
  final _ctrlNombre = TextEditingController();
  final _ctrlTelefono = TextEditingController();

  @override
  void dispose() {
    _ctrlNombre.dispose();
    _ctrlTelefono.dispose();
    super.dispose();
  }

  String get _nombreEfectivo {
    if (_clienteId != null) return ''; // lo resuelve el cliente seleccionado
    final n = _ctrlNombre.text.trim();
    return n.isEmpty ? 'Sin cliente' : n;
  }

  Future<void> _confirmar() async {
    if (_cargando) return;
    setState(() => _cargando = true);

    final ventas = context.read<VentasProvider>();
    final clientes = context.read<ClientesProvider>();
    final lineas = List.of(ventas.carrito);

    final cliente = _clienteId == null
        ? null
        : clientes.clientes.firstWhere((c) => c.id == _clienteId);

    try {
      // Calcular alertas de stock ANTES de descontar (el estado es el actual)
      final alertas = <String>[];
      for (final l in lineas) {
        try {
          final prod =
              widget.inv.productos.firstWhere((p) => p.id == l.productoId);
          final nuevoStock = prod.stock - l.cantidad;
          if (nuevoStock <= prod.stockMinimo) {
            final txt = nuevoStock <= 0
                ? '${prod.emoji} ${prod.nombre}: AGOTADO'
                : '${prod.emoji} ${prod.nombre}: quedan $nuevoStock ud. (mín. ${prod.stockMinimo})';
            alertas.add(txt);
          }
        } catch (_) {}
      }

      // Paso 1: SQLite local (instantaneo, sin red)
      final venta = await ventas.registrarVenta(
        metodoPago: _metodo,
        clienteId: cliente?.id ?? '',
        clienteNombre: cliente?.nombre ?? _nombreEfectivo,
      );

      // Paso 2: operaciones de red en SEGUNDO PLANO
      for (final l in lineas) {
        widget.inv.descontarStock(l.productoId, l.cantidad);
      }
      if (cliente != null) {
        clientes.registrarCompra(cliente.id, venta.total);
      }

      if (mounted) {
        setState(() {
          _ventaCompletada = venta;
          _alertasStock = alertas;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar la venta: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ventaCompletada != null
        ? _buildRecibo(context, _ventaCompletada!)
        : _buildFormulario(context);
  }

  Widget _buildFormulario(BuildContext context) {
    final ventas = context.watch<VentasProvider>();
    final clientes = context.watch<ClientesProvider>();
    final sinCliente = _clienteId == null;

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
            // ── Cabecera ──────────────────────────────────────────────
            const Text('Finalizar venta',
                style:
                    TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Total a cobrar: ${formatEuro(ventas.total)}',
                style: const TextStyle(
                    color: AppColors.accentBright,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),

            // ── Método de pago ────────────────────────────────────────
            const Text('Método de pago',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textFaint)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _metodo,
              dropdownColor: AppColors.panel2,
              items: const ['Efectivo', 'Tarjeta', 'Bizum']
                  .map((m) =>
                      DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged:
                  _cargando ? null : (v) => setState(() => _metodo = v!),
            ),
            const SizedBox(height: 14),

            // ── Cliente registrado ────────────────────────────────────
            const Text('Cliente registrado (opcional)',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textFaint)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _clienteId,
              dropdownColor: AppColors.panel2,
              hint: const Text('Sin cliente'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Sin cliente')),
                ...clientes.clientes.map((c) =>
                    DropdownMenuItem(value: c.id, child: Text(c.nombre))),
              ],
              onChanged: _cargando
                  ? null
                  : (v) => setState(() => _clienteId = v),
            ),

            // ── Datos del comprador (visible solo si sin cliente) ─────
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: sinCliente
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.panel2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 14,
                                      color: AppColors.textFaint),
                                  SizedBox(width: 6),
                                  Text('Datos del comprador (opcional)',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textFaint,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _ctrlNombre,
                                enabled: !_cargando,
                                textCapitalization:
                                    TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Nombre',
                                  prefixIcon: Icon(Icons.badge_outlined,
                                      size: 18,
                                      color: AppColors.textFaint),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _ctrlTelefono,
                                enabled: !_cargando,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: 'Teléfono (opcional)',
                                  prefixIcon: Icon(Icons.phone_outlined,
                                      size: 18,
                                      color: AppColors.textFaint),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 22),

            // ── Botón confirmar ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _confirmar,
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar cobro'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecibo(BuildContext context, Venta v) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✓ Venta completada',
              style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              'Ticket #${v.id.substring(0, 6).toUpperCase()} · '
              '${DateFormat('dd MMM HH:mm', 'es').format(v.fecha)}',
              style: const TextStyle(
                  color: AppColors.textDim, fontSize: 12)),
          const SizedBox(height: 16),
          ...v.lineas.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${l.cantidad}× ${l.nombre}'),
                    Text(formatEuro(l.subtotal)),
                  ],
                ),
              )),
          const Divider(color: AppColors.line),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              Text(formatEuro(v.total),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          // ── Alertas de stock bajo ──────────────────────────────────
          if (_alertasStock.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 15, color: AppColors.amber),
                      SizedBox(width: 6),
                      Text('Stock bajo tras esta venta',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amber)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._alertasStock.map((a) => Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text('· $a',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.amber)),
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // context es valido: _HojaCobro sigue abierto hasta aqui
              onPressed: () => Navigator.pop(context),
              child: const Text('Nueva venta'),
            ),
          ),
        ],
      ),
    );
  }
}
